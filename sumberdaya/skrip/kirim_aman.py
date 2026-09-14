#!/usr/bin/env python3
"""
kirim_aman.py - Enkripsi hibrida ML-KEM + AES-256-GCM.

Dipakai di Praktikum 4. Ini pola yang dipakai sistem nyata:
KEM untuk menyepakati kunci, AEAD simetris untuk mengangkut data.

Ada dua mode eksperimen kegagalan yang sengaja disediakan:
    --tanpa-kdf   memakai shared secret langsung sebagai kunci (SALAH, tapi jalan)
    --rusak-ct    merusak satu byte ciphertext KEM sebelum dekapsulasi
"""
import argparse
import os

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF

try:
    import oqs
except ImportError:
    raise SystemExit("Modul 'oqs' belum terpasang. Jalankan: pip install -r requirements.txt")

ALG_KEM = "ML-KEM-768"
ALG_SIG = "ML-DSA-65"
INFO = b"modul-praktikum-pqc/pesan/v1"   # domain separation


def cari(tersedia, *kandidat):
    for k in kandidat:
        if k in tersedia:
            return k
    for k in kandidat:
        for t in tersedia:
            if k.lower() in t.lower():
                return t
    raise SystemExit(f"Algoritma tidak tersedia: {kandidat}")


def turunkan_kunci(shared_secret: bytes) -> bytes:
    """Selalu lewat KDF. Shared secret KEM bukan kunci simetris."""
    return HKDF(algorithm=hashes.SHA256(), length=32,
                salt=None, info=INFO).derive(shared_secret)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--pesan", default="Nilai UAS Keamanan Siber: rahasia sampai 2040.")
    p.add_argument("--tanpa-kdf", action="store_true",
                   help="EKSPERIMEN: pakai shared secret langsung (salah secara kriptografis)")
    p.add_argument("--rusak-ct", action="store_true",
                   help="EKSPERIMEN: rusak satu byte ciphertext KEM")
    args = p.parse_args()

    nama_kem = cari(oqs.get_enabled_kem_mechanisms(), ALG_KEM, "Kyber768")
    nama_sig = cari(oqs.get_enabled_sig_mechanisms(), ALG_SIG, "Dilithium3")
    pesan = args.pesan.encode()
    aad = b"pengirim=dosen;versi=1"

    # --- Penerima menyiapkan pasangan kunci ---
    penerima = oqs.KeyEncapsulation(nama_kem)
    pk_kem = penerima.generate_keypair()

    # --- Pengirim: enkapsulasi lalu enkripsi ---
    with oqs.KeyEncapsulation(nama_kem) as pengirim:
        ct_kem, ss_kirim = pengirim.encap_secret(pk_kem)

    kunci = ss_kirim[:32] if args.tanpa_kdf else turunkan_kunci(ss_kirim)
    nonce = os.urandom(12)
    ct_data = AESGCM(kunci).encrypt(nonce, pesan, aad)

    # --- Pengirim menandatangani amplop ---
    penandatangan = oqs.Signature(nama_sig)
    pk_sig = penandatangan.generate_keypair()
    amplop = ct_kem + nonce + ct_data
    tanda = penandatangan.sign(amplop)

    print(f"\nAlgoritma  : {nama_kem} + AES-256-GCM, tanda tangan {nama_sig}")
    print(f"ct_kem     : {len(ct_kem)} byte")
    print(f"nonce      : {len(nonce)} byte")
    print(f"ct_data    : {len(ct_data)} byte  (pesan {len(pesan)} + tag 16)")
    print(f"tanda      : {len(tanda)} byte")
    total = len(amplop) + len(tanda)
    print(f"TOTAL      : {total} byte untuk pesan {len(pesan)} byte")
    print(f"Overhead   : {total - len(pesan)} byte "
          f"({(total - len(pesan)) / len(pesan) * 100:.0f}% dari ukuran pesan)")

    if args.tanpa_kdf:
        print("\n[!] Mode --tanpa-kdf aktif. Perhatikan: program ini akan tetap")
        print("    berjalan mulus. Keberhasilan eksekusi bukan bukti kebenaran.")

    # --- Penerima: verifikasi lalu dekripsi ---
    print()
    if not penandatangan.verify(amplop, tanda, pk_sig):
        print("Tanda tangan TIDAK valid. Berhenti.")
        return
    print("Tanda tangan valid.")

    if args.rusak_ct:
        rusak = bytearray(ct_kem)
        rusak[0] ^= 0x01
        ct_kem = bytes(rusak)
        print("[!] Satu byte ct_kem dirusak. Amati dari lapisan mana penolakan datang.")

    ss_terima = penerima.decap_secret(ct_kem)
    print("Dekapsulasi selesai tanpa error.")   # perhatikan: selalu begini

    kunci2 = ss_terima[:32] if args.tanpa_kdf else turunkan_kunci(ss_terima)
    try:
        asli = AESGCM(kunci2).decrypt(nonce, ct_data, aad)
        print(f"Hasil dekripsi: {asli.decode()}")
    except Exception as e:
        print(f"AEAD MENOLAK: {type(e).__name__}")
        print("Inilah implicit rejection: ML-KEM tidak mengeluh, AEAD yang menangkap.")

    penerima.free()
    penandatangan.free()


if __name__ == "__main__":
    main()
