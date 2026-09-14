# Praktikum 1 — Memotret Kondisi Awal

> **Level:** L1 → L2
> **Bab pasangan:** Bab 1 — Ancaman, Urgensi, dan Peta Keputusan
> **Waktu:** 90 menit
> **Prasyarat:** Lab Persiapan lulus tanpa catatan

---

## Kenapa lab ini duluan

Di Bab 1 saya banyak mengklaim. Kripto kunci publik akan runtuh, serangan pengumpulan sudah berjalan, langkah pertama migrasi adalah inventarisasi. Semuanya masih klaim, dan Anda tidak punya alasan mempercayainya begitu saja.

Lab ini mengubah klaim jadi data. Data Anda sendiri, dari mesin Anda sendiri, tentang situs yang Anda buka setiap hari.

Saya perlu memperingatkan satu hal. Sebagian orang selesai mengerjakan lab ini dengan perasaan tidak enak, karena menemukan bahwa layanan yang mereka percayai ternyata belum siap sama sekali. Perasaan itu wajar, dan sebetulnya itu tujuannya. Rasa mendesak yang datang dari data sendiri jauh lebih tahan lama daripada rasa mendesak yang datang dari buku.

**Capaian keterampilan:**
- mengaudit kriptografi yang aktif di mesin sendiri;
- menguji dukungan pertukaran kunci hibrida pada endpoint publik;
- menghasilkan data survei berformat baku yang layak digabungkan ke dataset bersama;
- menerapkan Teorema Mosca pada sistem nyata.

---

## Langkah 1 — Apa yang sedang Anda pakai sekarang

Mulai dari yang paling dekat: kunci SSH Anda sendiri.

```bash
for k in ~/.ssh/*.pub; do ssh-keygen -lf "$k"; done
```

### Yang harus Anda lihat

Keluaran berbentuk seperti ini:

```
256 SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxx nama@mesin (ED25519)
3072 SHA256:yyyyyyyyyyyyyyyyyyyyyyyyyyyy nama@mesin (RSA)
```

Yang dalam kurung di ujung adalah algoritmanya. Kemungkinan besar Anda melihat `ED25519` atau `RSA`.

Sekarang buka lagi tabel di Bab 1 bagian 1.2 dan cari keduanya.

Keduanya ada di baris paling atas. Runtuh total oleh Shor.

Kalau Anda memakai kunci itu untuk mengakses server produksi atau repositori kode, Anda baru saja menemukan aset kriptografis pertama Anda yang perlu masuk daftar migrasi. Tidak mendesak, karena autentikasi tidak punya tenggat mundur. Tapi dia ada di daftar.

### Langkah 1b — Sertifikat di sistem Anda

```bash
find /etc/ssl /etc/pki -name "*.pem" -o -name "*.crt" 2>/dev/null | head -20 | \
while read c; do
  alg=$(ossl x509 -in "$c" -noout -text 2>/dev/null | grep -m1 "Public Key Algorithm")
  [ -n "$alg" ] && echo "$(basename $c) | $(echo $alg | cut -d: -f2)"
done
```

Anda akan melihat daftar panjang berisi `rsaEncryption` dan `id-ecPublicKey`. Itu root CA yang dipercaya sistem Anda. Semuanya klasik.

Catat berapa banyak yang Anda temukan. Angka itu akan berguna di Praktikum 5 ketika kita membahas skala pekerjaan migrasi PKI.

---

## Langkah 2 — Menguji internet yang Anda pakai

Sekarang bagian yang menarik.

Mulai dari pembanding global, sesuatu yang seharusnya sudah siap:

```bash
ossl s_client -connect cloudflare.com:443 -groups X25519MLKEM768 \
    </dev/null 2>/dev/null | grep -i "Negotiated TLS1.3 group"
```

### Yang harus Anda lihat

```
Negotiated TLS1.3 group: X25519MLKEM768
```

Kalau baris itu muncul, koneksi Anda barusan memakai pertukaran kunci hibrida. Setengahnya klasik, setengahnya pasca-kuantum. Data sesi itu tahan terhadap serangan rekam-sekarang-buka-nanti.

Anda baru saja melakukan handshake pasca-kuantum. Tanpa perangkat kuantum apa pun, dari laptop biasa, dalam satu baris perintah.

Kalau baris itu tidak muncul, jangan panik dulu. Jalankan lagi tanpa `grep` dan lihat keseluruhan keluarannya; kemungkinan besar masalahnya di OpenSSL Anda, bukan di Cloudflare.

### Langkah 2b — Sekarang uji milik Anda sendiri

Buat berkas berisi domain yang benar-benar Anda pakai. Isi minimal 20 baris. Wajib ada: kampus Anda, bank Anda, satu layanan pemerintah, dan satu toko online yang sering Anda buka.

```bash
cp sumberdaya/data/domain-contoh.txt domain-saya.txt
nano domain-saya.txt
```

Format tiap baris: `domain,sektor`

```
ui.ac.id,pendidikan
kampussaya.ac.id,pendidikan
banksaya.co.id,perbankan
lapor.go.id,pemerintah
tokoonline.com,ecommerce
```

Lalu jalankan:

```bash
bash sumberdaya/skrip/survei_domain.sh domain-saya.txt hasil-survei.csv
```

### Yang harus Anda lihat

```
  cloudflare.com                   YA
  kampussaya.ac.id                 tidak
  banksaya.co.id                   tidak
  ...

Selesai. 4 dari 22 domain mendukung X25519MLKEM768.
Persentase: 18%
```

Angka persisnya akan berbeda untuk setiap orang dan setiap waktu. Yang biasanya sama adalah polanya: layanan global besar sudah siap, layanan lokal sebagian besar belum.

Diamkan sebentar angka itu. Lalu tanyakan pada diri sendiri: data apa yang selama ini Anda kirim ke domain-domain yang bertanda "tidak"?

---

## Langkah 3 — Uji ulang, karena satu pengukuran bukan data

Ini langkah yang paling sering dilewati orang, dan justru yang membedakan survei dari tebakan.

Jaringan bisa berbohong. Ada CDN yang menjawab berbeda dari lokasi berbeda, ada firewall kampus yang ikut campur, ada kegagalan sesaat yang tidak berarti apa-apa. Satu pengukuran tidak cukup.

Jalankan survei yang sama minimal sekali lagi, di waktu yang berbeda, kalau bisa dari jaringan yang berbeda juga. Misalnya sekali dari WiFi kampus, sekali dari data seluler.

```bash
bash sumberdaya/skrip/survei_domain.sh domain-saya.txt hasil-survei-2.csv
diff <(cut -d, -f1,3 hasil-survei.csv) <(cut -d, -f1,3 hasil-survei-2.csv)
```

Kalau `diff` tidak mengeluarkan apa-apa, hasil Anda konsisten. Kalau ada perbedaan, catat domain mana dan dari jaringan mana. Perbedaan itu justru temuan yang menarik dan layak dilaporkan.

---

## Langkah 4 — Menghitung urgensi untuk sistem yang Anda kenal

Sekarang pakai Teorema Mosca dari Bab 1 pada sistem nyata, bukan contoh buku.

Pilih tiga sistem yang benar-benar Anda kenal. Sistem informasi akademik kampus. Aplikasi tempat Anda magang. Proyek pribadi yang menyimpan data orang lain. Apa pun yang Anda tahu isinya.

Untuk masing-masing, isi:

| Pertanyaan | Cara menjawabnya |
|---|---|
| **X** — data ini harus rahasia berapa lama? | Pikirkan konsekuensinya kalau bocor 10 tahun lagi. Nilai kuliah? Rekam medis? Data KTP? |
| **Y** — berapa lama migrasinya? | Jujur. Kalau organisasinya lambat, tulis angka yang lambat. |
| **Z** — kapan mesinnya datang? | Perkiraan Anda sendiri. Tulis alasannya. |

Lalu hitung X + Y dan bandingkan dengan Z.

### Yang harus Anda hasilkan

Tabel terisi, plus satu paragraf untuk setiap sistem yang menjelaskan urutan prioritas Anda. Bukan cuma angkanya, tapi alasannya.

Kalau ada satu sistem dengan X + Y jauh melampaui Z manapun yang masuk akal, tandai. Itu sistem yang seharusnya sudah dikerjakan kemarin, dan itu temuan yang layak Anda sampaikan ke orang yang bertanggung jawab atasnya.

---

## Langkah 5 — Menyumbang ke dataset bersama

Berkas `hasil-survei.csv` Anda sudah dalam format baku. Kalau Anda bersedia, kirimkan ke repositori bersama.

Kenapa ini bukan sekadar tugas kuliah: **belum ada dataset publik tentang kesiapan PQC domain Indonesia.** Setiap pembaca yang menyumbang membuat gambaran itu sedikit lebih lengkap, dan datanya bertumbuh sendiri seiring buku ini dipakai orang.

Baca `sumberdaya/data/format-dataset.md` sebelum mengirim. Ada tiga aturan yang perlu Anda patuhi, dan satu bagian tentang etika yang wajib dibaca.

Intinya begini: yang Anda lakukan setara dengan mengetuk pintu depan dan mencatat apakah pintunya terbuka. Itu wajar dan legal. Yang tidak wajar adalah mencoba masuk. Batasi diri pada handshake TLS biasa di port 443, jangan pernah lebih.

---

## Deliverable Praktikum 1

1. Tabel audit mesin sendiri: algoritma kunci SSH, jumlah sertifikat root, algoritmanya.
2. `hasil-survei.csv` dan `hasil-survei-2.csv`, minimal 20 domain, minimal dua kali pengukuran.
3. Ringkasan satu paragraf tentang pola yang Anda temukan.
4. Tiga perhitungan Mosca lengkap dengan alasan urutan prioritas.

---

## Gerbang kompetensi Praktikum 1

Anda lulus kalau bisa menjawab keempat pertanyaan ini dari data Anda sendiri, bukan dari buku:

1. Algoritma apa yang sedang melindungi akses SSH Anda, dan apa nasibnya menurut tabel Bab 1?
2. Berapa persen domain di daftar Anda yang sudah mendukung pertukaran kunci hibrida, dan sektor mana yang paling tertinggal?
3. Ada domain yang hasilnya berbeda antar-pengukuran? Kalau ada, apa kemungkinan penyebabnya?
4. Dari tiga sistem yang Anda hitung, mana yang paling mendesak, dan kenapa jawabannya bukan sekadar "karena X-nya paling besar"?

Pertanyaan nomor 4 yang paling penting. Urgensi bukan cuma soal seberapa rahasia datanya, tapi soal hubungan antara umur rahasia, lamanya migrasi, dan waktu yang tersisa. Kalau jawaban Anda hanya menyebut satu variabel, baca ulang bagian 1.4.

---

## Perluasan mandiri

Untuk yang ingin melampaui level minimum:

**Perluas jadi survei sungguhan.** Kumpulkan 100–200 domain `.id` yang tersebar merata di lima sektor. Ambil daftarnya dari sumber publik seperti peringkat situs populer atau direktori resmi perguruan tinggi. Hitung persentase per sektor, buat grafiknya, dan tulis analisis dua halaman.

Kalau Anda melakukannya dengan rapi, hasil itu bukan lagi tugas praktikum. Itu data yang belum dimiliki siapa pun, dan cukup layak untuk dikembangkan jadi makalah.

**Tambahkan dimensi waktu.** Jadwalkan survei berulang tiap bulan dengan cron, simpan hasilnya. Setelah enam bulan Anda punya sesuatu yang jauh lebih menarik daripada potret sesaat: laju perubahan.

---

## Sebelum lanjut

Anda sekarang punya potret kondisi awal. Yang belum Anda punya adalah pemahaman tentang apa yang sebenarnya terjadi di balik baris `Negotiated TLS1.3 group` itu.

Bab 2 dan Praktikum 2 masuk ke sana. Anda akan membangkitkan kunci pasca-kuantum sendiri, mengukur ukurannya, membandingkan kecepatannya, dan menemukan satu hal yang mengejutkan hampir semua orang: soal mana yang sebenarnya lambat, dan mana yang ternyata jauh lebih cepat dari dugaan.
