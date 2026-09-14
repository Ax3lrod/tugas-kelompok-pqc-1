# Lab Persiapan — Lingkungan yang Tidak Boleh Gagal

> **Waktu:** 30–60 menit, sekali seumur hidup modul ini
> **Tidak dihitung sebagai salah satu dari enam sesi praktikum**

Saya taruh lab ini di depan karena satu alasan yang tidak enak diakui: **penyebab nomor satu orang berhenti belajar dari buku teknis adalah instalasi yang gagal di halaman kedua.** Bukan materinya yang sulit. Instalasinya.

Jadi mari kita bereskan dulu, sekali, sampai benar-benar bersih. Setelah lab ini selesai, Anda tidak perlu memikirkan lingkungan lagi sampai akhir modul.

Ada tiga jalur. Pilih satu, jangan campur.

---

## Jalur A — Docker (disarankan, paling tidak menyakitkan)

Kalau Anda punya Docker, berhenti berpikir dan pakai ini. Seluruh lingkungan sudah dibangun dan diuji.

```bash
cd sumberdaya
docker build -t pqc-lab .
docker run -it --rm -v "$PWD":/kerja pqc-lab
```

Pembangunan pertama memakan 5–15 menit karena OpenSSL dikompilasi dari sumber. Biarkan berjalan, ambil kopi. Setelah selesai, Anda masuk ke shell di dalam kontainer.

Di dalam kontainer, jalankan:

```bash
bash skrip/verifikasi_lingkungan.sh
```

Langsung lompat ke bagian "Membaca hasil verifikasi" di bawah.

---

## Jalur B — Pemasangan native (Ubuntu 22.04/24.04, WSL2, Debian)

Pilih ini kalau Anda mau memahami apa yang sebenarnya dipasang, atau kalau Docker bermasalah di mesin Anda.

### B.1 Periksa dulu apa yang sudah ada

```bash
openssl version
```

Kalau keluarannya menunjukkan **3.5 atau lebih baru**, Anda beruntung. Lompat ke B.3.

Kalau 3.0.x, 3.2.x, atau 1.1.1, lanjut ke B.2. Ini kasus yang paling umum, karena distro Linux biasanya tertinggal beberapa versi.

### B.2 Pasang OpenSSL baru berdampingan

Baca peringatan ini sebelum mengetik apa pun.

> **Jangan pernah menimpa OpenSSL bawaan sistem.** Paket `apt`, `ssh`, `git`, dan puluhan program lain bergantung padanya. Menimpanya adalah cara tercepat merusak sistem Anda sampai perlu instal ulang. Kita akan memasang versi baru di direktori terpisah dan memanggilnya lewat alias.

```bash
sudo apt update
sudo apt install -y build-essential cmake ninja-build wget git

cd ~
wget https://github.com/openssl/openssl/releases/download/openssl-3.5.4/openssl-3.5.4.tar.gz
tar xf openssl-3.5.4.tar.gz
cd openssl-3.5.4

./Configure --prefix=$HOME/openssl35 --openssldir=$HOME/openssl35/ssl
make -j$(nproc)
make install_sw
```

Kompilasi memakan 5–15 menit tergantung mesin. Setelah selesai:

```bash
echo "alias ossl='$HOME/openssl35/bin/openssl'" >> ~/.bashrc
source ~/.bashrc
ossl version
```

Harus muncul `OpenSSL 3.5.4`.

**Mulai sekarang, di seluruh modul ini, `ossl` berarti OpenSSL 3.5+.** Kalau versi sistem Anda sudah 3.5+, cukup baca `ossl` sebagai `openssl` biasa.

### B.3 Lingkungan Python

```bash
sudo apt install -y python3 python3-pip python3-venv

python3 -m venv ~/pqc-lab
source ~/pqc-lab/bin/activate

cd /path/ke/sumberdaya
pip install -r requirements.txt
```

Pemasangan `liboqs-python` akan mengunduh dan mengompilasi liboqs. Ini butuh 2–5 menit dan terlihat seperti macet. Tidak macet, memang begitu. Biarkan.

Uji:

```bash
python3 -c "import oqs; print('liboqs siap, versi', oqs.oqs_version())"
```

### B.4 Alat tambahan

```bash
sudo apt install -y tcpdump xxd
```

`tcpdump` baru dipakai di Praktikum 3, tapi lebih baik dipasang sekarang.

---

## Jalur C — macOS

```bash
brew install openssl@3 cmake ninja python@3.12

# Cek versi yang terpasang
$(brew --prefix openssl@3)/bin/openssl version

echo "alias ossl='$(brew --prefix openssl@3)/bin/openssl'" >> ~/.zshrc
source ~/.zshrc
```

Kalau Homebrew masih menyediakan OpenSSL di bawah 3.5, gunakan Jalur A. Mengompilasi OpenSSL di macOS bisa merepotkan dan tidak sepadan dengan waktunya.

Selanjutnya ikuti B.3 dan B.4, ganti `apt` dengan `brew`.

---

## Membaca hasil verifikasi

Jalankan:

```bash
bash skrip/verifikasi_lingkungan.sh
```

Skrip ini memeriksa enam hal, termasuk satu uji fungsional sungguhan: dia benar-benar membangkitkan kunci ML-KEM, melakukan enkapsulasi dan dekapsulasi, lalu memastikan kedua sisi menghasilkan rahasia yang identik.

**Yang harus Anda lihat kalau semuanya beres:**

```
1. OpenSSL
  [ OK ] openssl 3.5.4 (butuh >= 3.5)

2. Algoritma pasca-kuantum di OpenSSL
  [ OK ] ML-KEM tersedia
  [ OK ] ML-DSA tersedia

...

6. Uji fungsional (encap/decap sungguhan)
  [ OK ] encap/decap ML-KEM-768 berhasil, ciphertext 1088 byte

==================================================
 SEMUA SIAP. Silakan mulai Praktikum 1.
==================================================
```

Angka **1088 byte** itu bukan kebetulan. Itu ukuran ciphertext ML-KEM-768 sesuai standar, dan Anda akan bertemu angka itu lagi di Praktikum 2. Kalau angka yang muncul berbeda, catat. Itu informasi, bukan kesalahan.

Kalau ada baris bertanda GAGAL, **jangan lanjut ke Praktikum 1.** Saya serius. Lebih baik Anda tertahan dua puluh menit di sini daripada tersesat tiga jam di tengah Praktikum 3 dan tidak tahu apakah masalahnya ada di lab atau di lingkungan Anda.

---

## Sepuluh kegagalan yang paling sering terjadi

Disusun berdasarkan gejala, bukan berdasarkan penyebab, karena saat Anda macet yang Anda punya cuma gejalanya.

**1. `openssl version` menunjukkan versi lama padahal saya sudah kompilasi yang baru**
Alias belum aktif di shell ini. Jalankan `source ~/.bashrc`, atau tutup dan buka terminal. Pastikan Anda mengetik `ossl`, bukan `openssl`.

**2. `ML-KEM-768: algorithm not found`**
Anda sedang memakai OpenSSL yang salah. Cek dengan `which ossl` dan `ossl version`. Kalau masih di bawah 3.5, kembali ke B.2.

**3. `pip install` gagal saat membangun liboqs**
Alat kompilasi belum lengkap. Pasang `cmake`, `ninja-build`, dan `build-essential`, lalu ulangi.

**4. `import oqs` gagal padahal pip bilang sukses**
Biasanya karena virtualenv tidak aktif. Jalankan `source ~/pqc-lab/bin/activate` dan coba lagi. Kalau masih gagal, hapus virtualenv dan buat ulang; itu lebih cepat daripada mendiagnosisnya.

**5. Proses `pip install` terlihat menggantung berpuluh menit**
Kemungkinan besar sedang mengompilasi liboqs, dan memang selama itu. Tunggu sampai 10 menit sebelum curiga. Kalau lewat itu, batalkan dan pakai Jalur A.

**6. `make -j$(nproc)` gagal dengan error compiler**
Biasanya kehabisan memori pada mesin kecil atau WSL dengan alokasi RAM terbatas. Ulangi dengan `make -j2` saja.

**7. Docker build gagal saat mengunduh OpenSSL**
Periksa koneksi internet dan proxy. Kalau di balik proxy kampus, tambahkan konfigurasi proxy Docker.

**8. Permission denied saat menjalankan skrip**
`chmod +x skrip/*.sh`

**9. Di WSL2, `tcpdump` tidak menangkap apa pun**
WSL2 punya keanehan jaringan. Untuk Praktikum 3, jalankan `tcpdump` pada antarmuka `lo` saja, karena server dan klien sama-sama lokal. Kalau tetap tidak jalan, gunakan Jalur A.

**10. Uji fungsional gagal tapi semua nomor lain OK**
Kasus paling langka. Biasanya berarti ada dua instalasi OpenSSL yang bercampur di PATH. Jalankan `ossl version -a` dan periksa direktori modulnya.

Kalau masalah Anda tidak ada di daftar ini, catat gejalanya dan laporkan ke repositori. Daftar ini tumbuh dari laporan pembaca, dan laporan Anda membantu orang berikutnya.

---

## Gerbang Lab Persiapan

Satu syarat, tidak bisa ditawar:

**`verifikasi_lingkungan.sh` harus keluar dengan status lulus untuk seluruh komponen wajib.**

Setelah itu terpenuhi, buka Praktikum 1. Anda tidak akan menyentuh lingkungan lagi sampai modul selesai.
