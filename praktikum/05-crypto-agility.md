# Praktikum 5 — Crypto Agility dan Pipeline

> **Level:** L3 → L4
> **Bab pasangan:** Bab 5 — Cloud, DevOps, dan Rantai Pasok
> **Waktu:** 120 menit
> **Prasyarat:** Praktikum 4 selesai

---

## Kenapa lab ini

Semua yang Anda bangun sampai sekarang punya satu cacat yang sama: nama algoritmanya tertanam di dalam kode.

Itu tidak masalah hari ini. Masalahnya datang saat Anda harus berganti, dan Anda pasti akan berganti.

Lab ini mengubah kode dari Praktikum 4 menjadi sesuatu yang bisa berganti algoritma tanpa menyentuh logika aplikasi dan tanpa kehilangan data lama. Lalu Anda mengujinya secara objektif, bukan dengan merasa yakin.

**Capaian keterampilan:**
- merancang dan mengimplementasikan amplop berversi;
- membuktikan kelincahan lewat uji yang tidak bisa dibantah;
- menyusun inventaris kriptografi dan memprioritaskan hasilnya;
- memasang gerbang verifikasi di pipeline.

---

## Langkah 1 — Jalankan kerangka yang sudah ada

```bash
cd /path/ke/sumberdaya
source ~/pqc-lab/bin/activate

python3 skrip/amplop_agile.py
```

### Yang harus Anda lihat

```
Suite default saat ini: 0x03 (ML-KEM-768)

Ukuran amplop : 11xx byte
Byte kepala   : versi=1, suite=0x03
Hasil dekripsi: Uji crypto agility.
```

Dua byte pertama amplop itu inti seluruh lab. Byte pertama versi format, byte kedua identitas suite.

Sekarang buka `skrip/amplop_agile.py` dan baca strukturnya. Perhatikan tiga bagian:

- `REGISTRY`, daftar seluruh suite yang dikenal
- `SUITE_DEFAULT`, satu baris yang menentukan apa yang dipakai untuk menulis
- fungsi `enkripsi` dan `dekripsi`, yang tidak pernah menyebut nama algoritma secara langsung

Perhatikan juga bahwa fungsi `dekripsi` membaca suite dari amplop, bukan dari konfigurasi. Itulah yang membuat data lama tetap terbaca setelah default berubah.

---

## Langkah 2 — Uji dua berkas

Sekarang lakukan migrasi algoritma sungguhan dan hitung biayanya.

Sebelum mulai, **catat jumlah berkas yang Anda perkirakan harus diubah.** Tuliskan angkanya. Nanti kita bandingkan.

```bash
cd ~/lab5 2>/dev/null || mkdir -p ~/lab5 && cd ~/lab5
cp /path/ke/sumberdaya/skrip/amplop_agile.py .

# Simpan salinan untuk membandingkan nanti
cp amplop_agile.py amplop_sebelum.py
```

Sekarang ubah default dari ML-KEM-768 ke ML-KEM-1024. Satu baris:

```bash
sed -i 's/^SUITE_DEFAULT = 0x03/SUITE_DEFAULT = 0x04/' amplop_agile.py
python3 amplop_agile.py
```

### Yang harus Anda lihat

```
Suite default saat ini: 0x04 (ML-KEM-1024)

Ukuran amplop : 16xx byte
Byte kepala   : versi=1, suite=0x04
Hasil dekripsi: Uji crypto agility.
```

Berhasil. Amplopnya lebih besar karena ciphertext ML-KEM-1024 memang lebih besar.

Sekarang hitung:

```bash
diff amplop_sebelum.py amplop_agile.py
```

**Satu baris, di satu berkas.**

Bandingkan dengan perkiraan yang Anda tulis di awal. Sebagian besar orang memperkirakan lebih banyak, karena intuisi kita terbentuk dari kode yang tidak agile.

### Bandingkan dengan yang tidak agile

Sekarang lihat `skrip/kirim_aman.py`. Cari berapa kali nama algoritma muncul:

```bash
grep -n "ML-KEM\|ALG_KEM\|1088" /path/ke/sumberdaya/skrip/kirim_aman.py
```

Ada beberapa tempat, termasuk konstanta panjang ciphertext yang di-hardcode. Untuk mengganti algoritma di sana, Anda harus menyentuh setiap titik itu, dan yang lebih berbahaya, **data yang sudah dienkripsi dengan versi lama jadi tidak terbaca** karena tidak ada penanda suite di dalamnya.

Itulah selisih antara dua byte dan proyek migrasi data.

---

## Langkah 3 — Uji kompatibilitas mundur

Kelincahan tidak ada artinya kalau data lama hilang. Buktikan sekarang.

```bash
cd ~/lab5
python3 - << 'EOF'
import sys
sys.path.insert(0, ".")
from amplop_agile import buat_kunci, enkripsi, dekripsi, REGISTRY, SUITE_DEFAULT

print(f"Default sekarang: 0x{SUITE_DEFAULT:02x}\n")

hasil = []
for id_suite, suite in sorted(REGISTRY.items()):
    kem, pk = buat_kunci(id_suite)
    label = f"0x{id_suite:02x} {suite.kem}"
    if suite.usang:
        # Suite usang: tidak boleh menulis, tapi harus tetap bisa dibaca.
        try:
            enkripsi(pk, b"coba tulis", id_suite=id_suite)
            print(f"{label:<24} MASALAH: suite usang masih bisa menulis")
        except ValueError:
            print(f"{label:<24} tulis DITOLAK (benar, suite usang)")
        kem.free()
        continue

    amplop = enkripsi(pk, b"data lama", aad=b"uji", id_suite=id_suite)
    isi = dekripsi(kem, amplop, aad=b"uji")
    ok = isi == b"data lama"
    print(f"{label:<24} tulis OK, baca {'OK' if ok else 'GAGAL'}, "
          f"amplop {len(amplop)} byte")
    hasil.append(ok)
    kem.free()

print()
print("Semua suite aktif bisa ditulis dan dibaca."
      if all(hasil) else "ADA YANG GAGAL — periksa registry.")
EOF
```

### Yang harus Anda lihat

Setiap suite aktif bisa menulis dan membaca. Suite yang ditandai usang **menolak** permintaan menulis tetapi tetap bisa membaca.

Pemisahan inilah yang dibahas di Bab 5.5. Anda bisa menghentikan sebuah algoritma untuk data baru tanpa kehilangan akses ke data historis.

Coba pikirkan berapa lama sistem Anda perlu mempertahankan kemampuan membaca. Kalau ada data yang disimpan sepuluh tahun, berarti suite yang Anda pakai hari ini harus tetap bisa dibaca sampai sepuluh tahun lagi, jauh setelah Anda berhenti memakainya untuk menulis.

---

## Langkah 4 — Inventarisasi kriptografi

Sekarang pindah ke sisi organisasi.

```bash
# Mulai dari proyek Anda sendiri
python3 /path/ke/sumberdaya/skrip/inventaris_kripto.py ~/proyek-saya --csv ~/lab5/cbom-saya.csv
```

### Yang harus Anda lihat

Laporan berkategori. Kemungkinan besar Anda menemukan lebih banyak dari dugaan, dan sebagian di tempat yang tidak Anda ingat pernah menulisnya.

Sekarang jalankan pada sesuatu yang lebih besar:

```bash
git clone --depth 1 https://github.com/psf/requests /tmp/contoh-repo 2>/dev/null
python3 /path/ke/sumberdaya/skrip/inventaris_kripto.py /tmp/contoh-repo
```

### Sekarang bagian yang penting: nilai alatnya

Buka beberapa temuan satu per satu. Anda akan menemukan bahwa banyak di antaranya positif palsu: kata "RSA" di komentar, nama variabel yang kebetulan cocok, string di dokumentasi.

Ini bukan cacat yang perlu diperbaiki. Ini pelajaran.

Pemindai berbasis pola punya dua keterbatasan mendasar:

**Positif palsu.** Dia mencocokkan teks, bukan makna.

**Negatif palsu, yang jauh lebih berbahaya.** Dia buta terhadap kripto yang masuk lewat dependensi. Kalau proyek Anda memanggil pustaka HTTP yang di dalamnya memakai RSA, pemindai tidak akan melihat apa-apa. Padahal itu tetap kripto Anda, dan tetap harus dimigrasikan.

Tuliskan tiga jenis kripto di sistem Anda yang **tidak mungkin** ditemukan alat ini. Jawaban Anda adalah daftar pekerjaan manual yang harus dikerjakan siapa pun yang serius melakukan inventarisasi.

### Prioritaskan hasilnya

Inventaris tanpa prioritas cuma daftar panjang yang menakutkan. Klasifikasikan temuan Anda dengan tabel dari Bab 5.6, dan untuk setiap kategori tuliskan satu kalimat alasan.

---

## Langkah 5 — Tandatangani artefak rilis

```bash
cd ~/lab5
echo "artefak rilis versi 1.0" > rilis.tar

# Kunci penandatangan (di produksi ini ada di HSM/KMS)
ossl genpkey -algorithm ML-DSA-65 -out rilis_sk.pem
ossl pkey -in rilis_sk.pem -pubout -out rilis_pk.pem

# Tandatangani
ossl pkeyutl -sign -rawin -inkey rilis_sk.pem -in rilis.tar -out rilis.sig

# Verifikasi
ossl pkeyutl -verify -rawin -pubin -inkey rilis_pk.pem \
    -in rilis.tar -sigfile rilis.sig

ls -l rilis.tar rilis.sig
```

Sekarang buktikan bahwa verifikasinya benar-benar bekerja:

```bash
echo "artefak yang sudah diubah" > rilis.tar
ossl pkeyutl -verify -rawin -pubin -inkey rilis_pk.pem \
    -in rilis.tar -sigfile rilis.sig
echo "kode keluar: $?"
```

### Yang harus Anda lihat

Verifikasi pertama berhasil, verifikasi kedua gagal.

Poin dari langkah ini bukan cara menandatanganinya, itu bagian mudahnya. Poinnya adalah **verifikasi yang tidak pernah dijalankan tidak melindungi apa pun.** Banyak organisasi menandatangani artefak dengan rajin, lalu memasangnya ke produksi tanpa pernah memeriksa tanda tangannya.

---

## Langkah 6 — Pasang gerbang di pipeline

Gabungkan semuanya menjadi satu gerbang yang berjalan otomatis.

```bash
cat > ~/lab5/gerbang-kripto.sh << 'EOF'
#!/usr/bin/env bash
# Gerbang kripto untuk CI. Gagal berarti build gagal.
set -uo pipefail
GAGAL=0

echo "== 1. Endpoint masih mendukung pertukaran kunci hibrida =="
for ep in "${ENDPOINTS:-cloudflare.com:443}"; do
    bash sumberdaya/skrip/cek_pqc.sh "$ep" || GAGAL=1
done

echo
echo "== 2. Tidak ada algoritma rentan yang baru ditambahkan =="
BARU=$(python3 sumberdaya/skrip/inventaris_kripto.py . --maks 0 \
       | grep -c "^\[!!\]" || true)
echo "kategori rentan terdeteksi: $BARU"

echo
echo "== 3. Artefak rilis punya tanda tangan yang valid =="
if [ -f rilis.tar ] && [ -f rilis.sig ]; then
    ossl pkeyutl -verify -rawin -pubin -inkey rilis_pk.pem \
        -in rilis.tar -sigfile rilis.sig || GAGAL=1
else
    echo "lewat: tidak ada artefak untuk diperiksa"
fi

echo
[ $GAGAL -eq 0 ] && echo "GERBANG LULUS" || echo "GERBANG GAGAL"
exit $GAGAL
EOF

chmod +x ~/lab5/gerbang-kripto.sh
```

Contoh pemasangan di GitHub Actions:

```yaml
name: Gerbang Kripto
on: [push, pull_request]
jobs:
  kripto:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Jalankan gerbang
        env:
          ENDPOINTS: ${{ vars.ENDPOINTS }}
        run: bash gerbang-kripto.sh
```

Sekarang kalau ada yang mengubah konfigurasi TLS dan menghilangkan dukungan hibrida, build gagal **hari itu juga.** Bukan enam bulan kemudian saat audit, dan bukan tidak pernah.

Ini jawaban praktis untuk masalah "regresi kripto itu senyap" dari Bab 5.7.

---

## Deliverable Praktikum 5

1. Bukti uji dua berkas: perkiraan awal Anda, hasil `diff`, dan jumlah berkas sebenarnya.
2. Keluaran uji kompatibilitas mundur untuk seluruh suite.
3. `cbom-saya.csv` plus klasifikasi prioritas dan daftar tiga jenis kripto yang tidak terdeteksi alat.
4. Artefak bertanda tangan dengan bukti verifikasi berhasil dan gagal.
5. `gerbang-kripto.sh` yang berjalan, dengan bukti kasus lulus dan kasus gagal.

---

## Gerbang kompetensi Praktikum 5

1. Berapa berkas yang benar-benar berubah saat mengganti algoritma, dan berapa perkiraan awal Anda? Kalau meleset, kenapa?
2. Apa yang terjadi pada data lama setelah default diganti, dan mekanisme apa yang membuatnya tetap terbaca?
3. Kenapa suite usang boleh dibaca tapi tidak boleh ditulis? Beri satu contoh konkret kapan pemisahan ini menyelamatkan Anda.
4. Sebutkan tiga jenis kripto di sistem Anda yang tidak bisa ditemukan pemindai regex.
5. Kenapa gerbang CI diperlukan padahal Anda sudah memverifikasi konfigurasi secara manual saat migrasi?

Nomor 3 dan 4 yang membedakan L3 dari L4.

---

## Perluasan mandiri

**Tambahkan suite ketiga tanpa menyentuh logika.** Tambahkan entri baru di registry, misalnya kombinasi hibrida atau algoritma lain yang tersedia di liboqs Anda. Buktikan bahwa fungsi `enkripsi` dan `dekripsi` tidak berubah sama sekali. Kalau berubah, arsitektur Anda belum selesai.

**Jalankan gerbang di repositori sungguhan.** Pasang di proyek pribadi Anda, biarkan berjalan sebulan. Lihat apakah pernah gagal, dan kenapa.

**Rancang jadwal penghentian suite.** Kalau data disimpan sepuluh tahun, kapan suite 0x02 benar-benar boleh dihapus dari registry? Tuliskan aturannya sebagai kebijakan, bukan sebagai perasaan.

---

## Sebelum lanjut

Anda sekarang bisa mengintegrasikan PQC ke berbagai jenis aplikasi, dan membuat integrasi itu bertahan terhadap pergantian algoritma.

Yang tersisa satu: kemampuan menilai. Membaca klaim orang lain secara kritis, mengenali batas dari apa yang benar-benar kita ketahui hari ini, dan menempatkan semua ini dalam gambaran yang lebih besar.

Bab 6 dan Praktikum 6 menutup itu, sekaligus menjembatani ke bagian berikutnya dari buku ini.
