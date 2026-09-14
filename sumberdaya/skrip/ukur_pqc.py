#!/usr/bin/env python3
"""
ukur_pqc.py - Mengukur ukuran dan kecepatan algoritma PQC.

Dipakai di Praktikum 2. Hasilnya adalah data milik Anda sendiri,
bukan angka kutipan. Catat spesifikasi mesin Anda saat melaporkannya.

Pemakaian:
    python3 ukur_pqc.py                 # tabel ke layar
    python3 ukur_pqc.py --csv hasil.csv # sekaligus simpan CSV
"""
import argparse
import csv
import platform
import statistics
import time

try:
    import oqs
except ImportError:
    raise SystemExit(
        "Modul 'oqs' belum terpasang.\n"
        "Aktifkan virtualenv lalu jalankan: pip install -r requirements.txt"
    )

PESAN = b"Praktikum PQC - Teknologi Informasi " * 8


def cari_nama(tersedia, *kandidat):
    """Nama algoritma di liboqs berbeda antar versi. Jangan di-hardcode."""
    for k in kandidat:
        if k in tersedia:
            return k
    for k in kandidat:
        for t in tersedia:
            if k.lower() in t.lower():
                return t
    return None


def ukur(fn, ulang):
    catatan = []
    for _ in range(ulang):
        t0 = time.perf_counter()
        fn()
        catatan.append((time.perf_counter() - t0) * 1000)
    return statistics.median(catatan)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--csv", help="simpan hasil ke berkas CSV")
    p.add_argument("--ulang", type=int, default=100, help="jumlah pengulangan (default 100)")
    args = p.parse_args()

    kem_ada = oqs.get_enabled_kem_mechanisms()
    sig_ada = oqs.get_enabled_sig_mechanisms()

    print(f"\nMesin  : {platform.processor() or platform.machine()}")
    print(f"Sistem : {platform.system()} {platform.release()}")
    print(f"Python : {platform.python_version()}")
    print("Catat baris di atas saat melaporkan hasil Anda.\n")

    baris = []

    # ---------- KEM ----------
    print("=" * 74)
    print("KEY ENCAPSULATION")
    print("=" * 74)
    print(f"{'Algoritma':<20}{'pk':>7}{'ct':>7}{'ss':>5}"
          f"{'keygen':>10}{'encap':>10}{'decap':>10}")
    print("-" * 74)

    for target in ["ML-KEM-512", "ML-KEM-768", "ML-KEM-1024"]:
        nama = cari_nama(kem_ada, target, target.replace("ML-KEM", "Kyber"))
        if not nama:
            print(f"{target:<20}  (tidak tersedia di liboqs versi ini)")
            continue
        with oqs.KeyEncapsulation(nama) as kem:
            pk = kem.generate_keypair()
            ct, ss = kem.encap_secret(pk)
            t_gen = ukur(lambda: oqs.KeyEncapsulation(nama).generate_keypair(), args.ulang)
            t_enc = ukur(lambda: kem.encap_secret(pk), args.ulang)
            t_dec = ukur(lambda: kem.decap_secret(ct), args.ulang)
        print(f"{nama:<20}{len(pk):>7}{len(ct):>7}{len(ss):>5}"
              f"{t_gen:>10.3f}{t_enc:>10.3f}{t_dec:>10.3f}")
        baris.append(["KEM", nama, len(pk), len(ct), len(ss),
                      round(t_gen, 4), round(t_enc, 4), round(t_dec, 4)])

    # ---------- SIGNATURE ----------
    print()
    print("=" * 74)
    print("DIGITAL SIGNATURE")
    print("=" * 74)
    print(f"{'Algoritma':<30}{'pk':>7}{'sig':>8}{'sign':>13}{'verify':>12}")
    print("-" * 74)

    target_sig = [
        ("ML-DSA-44", ["ML-DSA-44", "Dilithium2"], args.ulang),
        ("ML-DSA-65", ["ML-DSA-65", "Dilithium3"], args.ulang),
        ("ML-DSA-87", ["ML-DSA-87", "Dilithium5"], args.ulang),
        ("SLH-DSA-128s", ["SLH-DSA-SHA2-128s", "SPHINCS+-SHA2-128s-simple"], 5),
        ("SLH-DSA-128f", ["SLH-DSA-SHA2-128f", "SPHINCS+-SHA2-128f-simple"], 10),
    ]

    for label, kandidat, ulang in target_sig:
        nama = cari_nama(sig_ada, *kandidat)
        if not nama:
            print(f"{label:<30}  (tidak tersedia)")
            continue
        with oqs.Signature(nama) as sig:
            pk = sig.generate_keypair()
            tanda = sig.sign(PESAN)
            t_sign = ukur(lambda: sig.sign(PESAN), ulang)
            t_ver = ukur(lambda: sig.verify(PESAN, tanda, pk), ulang)
        tampil = nama if len(nama) <= 29 else nama[:26] + "..."
        print(f"{tampil:<30}{len(pk):>7}{len(tanda):>8}"
              f"{t_sign:>13.3f}{t_ver:>12.3f}")
        baris.append(["SIG", nama, len(pk), len(tanda), "",
                      round(t_sign, 4), round(t_ver, 4), ""])

    print()
    print("Semua waktu dalam milidetik (median). Semua ukuran dalam byte.")

    if args.csv:
        with open(args.csv, "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["jenis", "algoritma", "ukuran_pk", "ukuran_ct_atau_sig",
                        "ukuran_ss", "waktu_1_ms", "waktu_2_ms", "waktu_3_ms"])
            w.writerows(baris)
        print(f"CSV tersimpan: {args.csv}")


if __name__ == "__main__":
    main()
