# Sumber Daya Praktikum PQC

Semua yang dibutuhkan untuk menjalankan enam sesi praktikum.

## Isi

```
sumberdaya/
├── Dockerfile                    lingkungan siap pakai (jalur yang disarankan)
├── .devcontainer/                untuk VS Code
├── requirements.txt              pustaka Python
├── skrip/
│   ├── verifikasi_lingkungan.sh  JALANKAN INI DULU
│   ├── cek_pqc.sh                uji satu endpoint, cocok untuk CI
│   ├── survei_domain.sh          survei banyak domain -> CSV
│   ├── ukur_pqc.py               benchmark ukuran dan kecepatan
│   ├── kirim_aman.py             enkripsi hibrida + eksperimen kegagalan
│   ├── amplop_agile.py           kerangka amplop berversi
│   └── inventaris_kripto.py      pemindai CBOM sederhana
└── data/
    ├── format-dataset.md         format kontribusi survei
    └── domain-contoh.txt         daftar domain untuk diisi sendiri
```

## Mulai dari mana

Jalur tercepat, lewat Docker:

```bash
docker build -t pqc-lab .
docker run -it --rm -v "$PWD":/kerja pqc-lab
bash skrip/verifikasi_lingkungan.sh
```

Kalau semua baris menunjukkan OK, Anda siap membuka Praktikum 1.

Kalau ada yang GAGAL, jangan lanjut. Baca pesan di bawah baris merah,
perbaiki, jalankan ulang. Skrip itu memang dibuat untuk menahan Anda
di sini sampai lingkungannya benar. Lebih baik tertahan 20 menit di
awal daripada tersesat tiga jam di tengah lab.

## Jalur tanpa Docker

Lihat Lab Persiapan di `praktikum/00-lab-persiapan.md`. Di sana ada
langkah pemasangan native untuk Ubuntu, WSL2, dan macOS, lengkap
dengan sepuluh kegagalan pemasangan yang paling sering terjadi.

## Lisensi alat yang dipakai

- OpenSSL: Apache License 2.0
- liboqs dan liboqs-python (Open Quantum Safe): MIT
- pyca/cryptography: Apache 2.0 atau BSD

Kalau Anda memakai skrip di sini untuk publikasi atau produk, cantumkan
atribusi sesuai lisensi masing-masing.
