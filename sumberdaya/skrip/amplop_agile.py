#!/usr/bin/env python3
"""
amplop_agile.py - Kerangka amplop berversi untuk Praktikum 5.

Inti gagasannya: setiap ciphertext membawa identitas suite-nya sendiri.
Dengan begitu, mengganti algoritma tidak pernah berarti migrasi data.

Uji penerimaan Praktikum 5: ganti SUITE_DEFAULT di bawah, lalu hitung
berapa berkas yang harus Anda sentuh. Target maksimal dua.
"""
import os
import struct
from dataclasses import dataclass

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF

import oqs

VERSI_FORMAT = 1


@dataclass(frozen=True)
class Suite:
    id: int
    kem: str
    panjang_ct: int
    info: bytes
    usang: bool = False        # masih boleh dibaca, tidak boleh dipakai menulis


REGISTRY = {
    0x02: Suite(0x02, "ML-KEM-512", 768, b"pqc-modul/suite2/v1", usang=True),
    0x03: Suite(0x03, "ML-KEM-768", 1088, b"pqc-modul/suite3/v1"),
    0x04: Suite(0x04, "ML-KEM-1024", 1568, b"pqc-modul/suite4/v1"),
}

SUITE_DEFAULT = 0x03          # <-- satu baris ini yang diganti saat migrasi


def _kunci(suite: Suite, shared: bytes) -> bytes:
    return HKDF(algorithm=hashes.SHA256(), length=32,
                salt=None, info=suite.info).derive(shared)


def buat_kunci(id_suite: int = SUITE_DEFAULT):
    suite = REGISTRY[id_suite]
    kem = oqs.KeyEncapsulation(suite.kem)
    return kem, kem.generate_keypair()


def enkripsi(pk: bytes, pesan: bytes, aad: bytes = b"",
             id_suite: int = SUITE_DEFAULT) -> bytes:
    suite = REGISTRY[id_suite]
    if suite.usang:
        raise ValueError(f"Suite 0x{id_suite:02x} sudah usang, tidak boleh dipakai menulis.")
    with oqs.KeyEncapsulation(suite.kem) as kem:
        ct_kem, shared = kem.encap_secret(pk)
    nonce = os.urandom(12)
    ct = AESGCM(_kunci(suite, shared)).encrypt(nonce, pesan, aad)
    kepala = struct.pack("BB", VERSI_FORMAT, suite.id)
    return kepala + ct_kem + nonce + ct


def dekripsi(kem_penerima, amplop: bytes, aad: bytes = b"") -> bytes:
    versi, id_suite = struct.unpack("BB", amplop[:2])
    if versi != VERSI_FORMAT:
        raise ValueError(f"Versi format {versi} tidak dikenal.")
    if id_suite not in REGISTRY:
        raise ValueError(f"Suite 0x{id_suite:02x} tidak ada di registry.")
    suite = REGISTRY[id_suite]          # suite usang tetap boleh dibaca

    isi = amplop[2:]
    ct_kem = isi[:suite.panjang_ct]
    nonce = isi[suite.panjang_ct:suite.panjang_ct + 12]
    ct = isi[suite.panjang_ct + 12:]

    shared = kem_penerima.decap_secret(ct_kem)
    return AESGCM(_kunci(suite, shared)).decrypt(nonce, ct, aad)


if __name__ == "__main__":
    print(f"Suite default saat ini: 0x{SUITE_DEFAULT:02x} "
          f"({REGISTRY[SUITE_DEFAULT].kem})\n")
    kem, pk = buat_kunci()
    amplop = enkripsi(pk, b"Uji crypto agility.", aad=b"demo")
    print(f"Ukuran amplop : {len(amplop)} byte")
    print(f"Byte kepala   : versi={amplop[0]}, suite=0x{amplop[1]:02x}")
    print(f"Hasil dekripsi: {dekripsi(kem, amplop, aad=b'demo').decode()}")
    kem.free()
