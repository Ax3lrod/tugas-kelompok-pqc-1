#!/usr/bin/env python3
"""
inventaris_kripto.py - Pemindai sederhana untuk kriptografi rentan kuantum.

Dipakai di Praktikum 5. Sengaja dibuat berbasis regex supaya Anda
merasakan sendiri keterbatasannya: banyak positif palsu, dan buta
terhadap kripto yang masuk lewat dependensi. Keterbatasan itu bahan
diskusi, bukan cacat.

Pemakaian:
    python3 inventaris_kripto.py /path/ke/proyek
    python3 inventaris_kripto.py . --csv cbom.csv
"""
import argparse
import csv
import re
from collections import defaultdict
from pathlib import Path

POLA = {
    "RSA (rentan Shor)":
        r"\bRSA\b|rsa_generate|RSA_generate|PKCS1|rsa\.generate|RSAPrivateKey",
    "ECDSA/ECDH (rentan Shor)":
        r"\bECDSA\b|\bECDH\b|SECP256|P-?256\b|prime256v1|secp256r1|secp384r1",
    "DH/DSA (rentan Shor)":
        r"\bDiffieHellman\b|\bDSA\b|dhparam|DH_generate",
    "X25519/Ed25519 (rentan Shor)":
        r"[Xx]25519|[Ee]d25519",
    "Hash usang (bukan isu kuantum)":
        r"\bMD5\b|\bSHA-?1\b|hashlib\.md5|hashlib\.sha1",
    "Sudah pasca-kuantum":
        r"ML-KEM|ML_KEM|MLKEM|ML-DSA|ML_DSA|MLDSA|SLH-DSA|Kyber|Dilithium|SPHINCS",
}

EKSTENSI = {".py", ".js", ".ts", ".jsx", ".tsx", ".java", ".kt", ".go",
            ".c", ".h", ".cpp", ".hpp", ".rs", ".php", ".rb", ".cs",
            ".yaml", ".yml", ".conf", ".cnf", ".tf", ".json", ".toml"}

LEWATI = {"node_modules", ".git", "venv", ".venv", "__pycache__",
          "vendor", "dist", "build", "target", ".next"}


def pindai(akar: Path):
    temuan = defaultdict(list)
    jumlah_berkas = 0
    for berkas in akar.rglob("*"):
        if not berkas.is_file() or berkas.suffix not in EKSTENSI:
            continue
        if any(bagian in LEWATI for bagian in berkas.parts):
            continue
        jumlah_berkas += 1
        try:
            isi = berkas.read_text(errors="ignore")
        except OSError:
            continue
        for label, pola in POLA.items():
            for m in re.finditer(pola, isi):
                nomor = isi[:m.start()].count("\n") + 1
                kutipan = isi.splitlines()[nomor - 1].strip()[:70]
                temuan[label].append((str(berkas), nomor, kutipan))
    return temuan, jumlah_berkas


def main():
    p = argparse.ArgumentParser()
    p.add_argument("akar", nargs="?", default=".")
    p.add_argument("--csv", help="simpan hasil ke CSV")
    p.add_argument("--maks", type=int, default=6, help="temuan yang ditampilkan per kategori")
    args = p.parse_args()

    akar = Path(args.akar)
    temuan, jumlah = pindai(akar)

    print(f"\nINVENTARIS KRIPTOGRAFI")
    print(f"Direktori : {akar.resolve()}")
    print(f"Berkas dipindai: {jumlah}")
    print("=" * 70)

    for label in POLA:
        daftar = temuan.get(label, [])
        if label == "Sudah pasca-kuantum":
            tanda = "[OK]"
        elif "bukan isu kuantum" in label:
            tanda = "[..]"
        else:
            tanda = "[!!]"
        print(f"\n{tanda} {label}: {len(daftar)} temuan")
        for berkas, nomor, kutipan in daftar[:args.maks]:
            print(f"      {berkas}:{nomor}")
            print(f"        | {kutipan}")
        if len(daftar) > args.maks:
            print(f"      ... dan {len(daftar) - args.maks} lainnya")

    print()
    print("-" * 70)
    print("Ingat: pemindai ini hanya melihat kode Anda sendiri.")
    print("Kripto yang masuk lewat dependensi tidak akan terlihat di sini.")
    print("Lengkapi dengan pemeriksaan sertifikat, konfigurasi server, dan SBOM.")

    if args.csv:
        with open(args.csv, "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["kategori", "berkas", "baris", "kutipan"])
            for label, daftar in temuan.items():
                for berkas, nomor, kutipan in daftar:
                    w.writerow([label, berkas, nomor, kutipan])
        print(f"\nCSV tersimpan: {args.csv}")


if __name__ == "__main__":
    main()
