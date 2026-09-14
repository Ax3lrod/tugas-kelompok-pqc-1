# Praktikum 2 — Mengukur dan Memilih

> **Level:** L2
> **Bab pasangan:** Bab 2 — Memilih Algoritma
> **Waktu:** 120 menit
> **Prasyarat:** Praktikum 1 selesai

---

## Kenapa lab ini penting

Di Bab 2 saya menaruh banyak angka. ML-KEM-768 punya ciphertext 1.088 byte. SLH-DSA lambat sekali. ML-DSA cepat.

Anda tidak perlu percaya satu pun dari angka itu.

Lab ini akan menghasilkan angka Anda sendiri, dari prosesor Anda sendiri. Dan angka Anda akan sedikit berbeda dari angka saya, karena mesin kita berbeda. Perbedaan itu bukan kesalahan; itu justru alasan kenapa hasil pengukuran sendiri lebih berharga daripada angka kutipan.

Satu peringatan supaya Anda tidak kaget: sebagian hasilnya akan bertentangan dengan intuisi Anda.

**Capaian keterampilan:**
- membangkitkan kunci PQC dan mengukur ukuran nyatanya;
- menjalankan enkapsulasi dan dekapsulasi secara manual;
- melakukan benchmark dan membaca hasilnya;
- menerapkan kuesioner enam pertanyaan pada kasus nyata.

---

## Langkah 1 — Bangkitkan kunci dan lihat ukurannya

```bash
mkdir -p ~/lab2 && cd ~/lab2

ossl genpkey -algorithm ML-KEM-768 -out mlkem_sk.pem
ossl pkey -in mlkem_sk.pem -pubout -out mlkem_pk.pem

ossl genpkey -algorithm X25519 -out x25519_sk.pem
ossl pkey -in x25519_sk.pem -pubout -out x25519_pk.pem

ls -l *_pk.pem
```

### Yang harus Anda lihat

Dua berkas dengan selisih ukuran yang mencolok. Sesuatu seperti 1.700-an byte untuk ML-KEM dan 100-an byte untuk X25519.

Sekarang buka salah satunya:

```bash
cat x25519_pk.pem
```

Anda melihat teks Base64 di antara dua baris penanda. Itulah format PEM.

### Kenapa angkanya tidak cocok dengan tabel

Tabel di Bab 2 bilang kunci publik ML-KEM-768 itu 1.184 byte, tapi berkas Anda lebih besar. Ke mana selisihnya?

Ada dua lapisan pembungkus. Pertama, struktur ASN.1 yang mencantumkan algoritma apa yang dipakai. Kedua, encoding Base64 yang mengubah data biner jadi teks, dan Base64 selalu menambah sekitar 33 persen.

Buktikan sendiri:

```bash
ossl pkey -in mlkem_pk.pem -pubin -outform DER -out mlkem_pk.der
ossl pkey -in x25519_pk.pem -pubin -outform DER -out x25519_pk.der
ls -l *.der
```

DER adalah versi binernya, tanpa Base64. Angkanya sekarang jauh lebih dekat ke tabel, meski masih ada beberapa byte tambahan dari header ASN.1.

**Ini pelajaran yang lebih besar dari kelihatannya.** Waktu Anda menghitung anggaran bandwidth nanti, jangan pakai angka teoretis dari standar. Pakai ukuran nyata setelah encoding. Selisih 33 persen bisa jadi masalah kalau Anda menghitung untuk jutaan koneksi.

---

## Langkah 2 — Enkapsulasi dan dekapsulasi

Sekarang jalankan KEM secara manual, supaya Anda melihat sendiri bahwa alurnya persis seperti diagram di Bab 2.

```bash
# Pihak pengirim: enkapsulasi dengan kunci publik penerima
ossl pkeyutl -encap -inkey mlkem_pk.pem -pubin \
    -secret ss_pengirim.bin -out ct.bin

# Pihak penerima: dekapsulasi dengan kunci privatnya
ossl pkeyutl -decap -inkey mlkem_sk.pem \
    -in ct.bin -secret ss_penerima.bin

# Buktikan keduanya identik
cmp ss_pengirim.bin ss_penerima.bin && echo "COCOK"

ls -l ct.bin ss_pengirim.bin
xxd ss_pengirim.bin
```

### Yang harus Anda lihat

```
COCOK
-rw------- 1 user user 1088 ... ct.bin
-rw------- 1 user user   32 ... ss_pengirim.bin
```

Ciphertext **1088 byte**, rahasia bersama **32 byte**. Cocok persis dengan tabel di Bab 2, tanpa toleransi.

Perhatikan sesuatu: pengirim tidak pernah memilih rahasia itu. Dia tidak mengirimkannya. Rahasia itu muncul dari proses enkapsulasi, dan penerima menghasilkan ulang nilai yang sama dari ciphertext. Tidak ada kunci yang pernah melintas.

Itulah yang dimaksud KEM bukan enkripsi.

### Langkah 2b — Coba rusak sedikit

```bash
cp ct.bin ct_rusak.bin
printf '\x00' | dd of=ct_rusak.bin bs=1 seek=0 conv=notrunc 2>/dev/null

ossl pkeyutl -decap -inkey mlkem_sk.pem -in ct_rusak.bin -secret ss_rusak.bin
echo "kode keluar: $?"
cmp ss_pengirim.bin ss_rusak.bin && echo "sama" || echo "BERBEDA"
```

### Yang harus Anda lihat

Kode keluar 0. Tidak ada error. Tetapi rahasianya **berbeda**.

Inilah penolakan implisit yang dibahas di Bab 2.6. Dekapsulasi tidak pernah mengeluh, dia cuma menghasilkan nilai lain. Kalau Anda membangun sistem yang mengandalkan error dari dekapsulasi untuk mendeteksi ciphertext rusak, sistem Anda tidak akan pernah mendeteksi apa pun.

Ingat ini baik-baik. Praktikum 4 akan menunjukkan konsekuensinya di kode nyata.

---

## Langkah 3 — Benchmark

Sekarang bagian utamanya.

```bash
cd /path/ke/sumberdaya
source ~/pqc-lab/bin/activate   # kalau pakai jalur native
python3 skrip/ukur_pqc.py --csv ~/lab2/hasil-benchmark.csv
```

Butuh satu sampai tiga menit. Bagian SLH-DSA memang terasa lama; itu bukan macet, itu temuannya.

### Yang harus Anda lihat

Dua tabel. Kira-kira bentuknya begini, dengan angka waktu yang berbeda-beda menurut mesin Anda:

```
KEY ENCAPSULATION
Algoritma                pk     ct   ss    keygen     encap     decap
ML-KEM-512              800    768   32     0.02x     0.02x     0.02x
ML-KEM-768             1184   1088   32     0.03x     0.03x     0.03x
ML-KEM-1024            1568   1568   32     0.04x     0.05x     0.05x

DIGITAL SIGNATURE
Algoritma                     pk     sig         sign      verify
ML-DSA-44                    1312    2420        0.1xx      0.0xx
ML-DSA-65                    1952    3309        0.2xx      0.1xx
ML-DSA-87                    2592    4627        0.2xx      0.1xx
SPHINCS+-SHA2-128s-simple      32    7856      2xx.xxx      0.xxx
SPHINCS+-SHA2-128f-simple      32   17088       1x.xxx      1.xxx
```

**Cocokkan seluruh kolom ukuran dengan tabel Bab 2.** Harus sama persis, semuanya. Ukuran ditentukan standar dan tidak bergantung mesin. Kalau ada yang meleset, kemungkinan besar Anda salah membaca nama algoritma.

### Tiga hal yang perlu Anda perhatikan di hasil Anda

**ML-KEM ternyata cepat.** Ini yang biasanya mengejutkan. Banyak orang mengira "pasca-kuantum" otomatis berarti "lambat". Bandingkan waktu encap ML-KEM-768 di mesin Anda dengan intuisi Anda sebelum menjalankan lab ini. Untuk sebagian besar orang, hasilnya di kisaran puluhan mikrodetik, sebanding atau bahkan lebih cepat daripada operasi kurva eliptik klasik.

Jadi kalau nanti ada yang bilang PQC terlalu mahal untuk sistem mereka, tanyakan apakah mereka sudah mengukur atau baru menduga.

**SLH-DSA signing memang sangat lambat.** Lihat selisihnya dengan ML-DSA di mesin Anda sendiri. Biasanya ratusan kali. Sekarang bayangkan sistem yang menandatangani 5.000 transaksi per detik memakai algoritma ini. Anda sudah bisa menjawab soal nomor 4 di gerbang kompetensi Bab 2 dengan angka, bukan dengan tebakan.

**Verifikasi SLH-DSA justru cepat.** Ini yang membuatnya masuk akal untuk firmware: menandatangani sekali di pabrik, memverifikasi jutaan kali di perangkat.

---

## Langkah 4 — Grafik trade-off

Angka dalam tabel sulit dirasakan. Grafik membuatnya masuk ke kepala.

```bash
cd ~/lab2
python3 - << 'EOF'
import csv
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

x, y, label = [], [], []
with open("hasil-benchmark.csv") as f:
    for b in csv.DictReader(f):
        if b["jenis"] != "SIG":
            continue
        x.append(float(b["waktu_1_ms"]))          # waktu signing
        y.append(int(b["ukuran_ct_atau_sig"]))    # ukuran tanda tangan
        label.append(b["algoritma"])

plt.figure(figsize=(9, 6))
plt.scatter(x, y, s=90)
for i, t in enumerate(label):
    plt.annotate(t, (x[i], y[i]), fontsize=8,
                 xytext=(6, 6), textcoords="offset points")
plt.xscale("log"); plt.yscale("log")
plt.xlabel("Waktu signing (ms, skala log)")
plt.ylabel("Ukuran tanda tangan (byte, skala log)")
plt.title("Trade-off tanda tangan pasca-kuantum")
plt.grid(True, which="both", alpha=0.3)
plt.tight_layout()
plt.savefig("trade-off.png", dpi=140)
print("Tersimpan: trade-off.png")
EOF
```

Buka `trade-off.png`. Perhatikan bahwa titik-titiknya tidak berbaris rapi di satu garis. Kalau begitu, tidak akan ada keputusan yang perlu diambil; Anda tinggal pilih yang paling kanan atas.

Kenyataannya ada wilayah berbeda, dan setiap wilayah punya kasus penggunaannya sendiri. Grafik ini layak Anda simpan; nanti Anda akan menunjukkannya ke orang lain untuk menjelaskan kenapa tidak ada satu algoritma terbaik.

---

## Langkah 5 — Pakai kuesioner enam pertanyaan

Sekarang gabungkan semuanya. Ambil tiga skenario ini, jawab keenam pertanyaan dari Bab 2.6 untuk masing-masing, lalu tentukan algoritmanya. Wajib menyebut angka dari hasil ukur Anda sendiri.

**Skenario A.** Gerbang pembayaran memverifikasi 8.000 tanda tangan per detik pada jam sibuk. Tanda tangan tidak perlu dipercaya lebih dari 30 hari.

**Skenario B.** Produsen perangkat medis menandatangani firmware empat kali setahun. Perangkat beredar 12 tahun. Kunci verifikasi tertanam di ROM dan tidak bisa diubah.

**Skenario C.** Aplikasi pesan mengenkripsi percakapan antar-pengguna. Isinya sensitif dan penggunanya berharap tetap rahasia selamanya. Berjalan di ponsel dengan koneksi seluler yang sering buruk.

### Yang harus Anda hasilkan

Untuk setiap skenario: enam jawaban, satu keputusan algoritma, dan tiga sampai lima kalimat pembelaan yang memuat angka nyata dari benchmark Anda.

Petunjuk untuk skenario C, karena ini yang paling sering keliru: pertanyaan pertama kuesioner menanyakan kerahasiaan atau autentikasi. Jawabannya mungkin keduanya. Kalau begitu, jangan cari satu algoritma; kerjakan dua keputusan terpisah.

---

## Deliverable Praktikum 2

1. `hasil-benchmark.csv` dengan spesifikasi mesin Anda tercatat.
2. `trade-off.png`.
3. Tabel perbandingan ukuran hasil ukur Anda versus tabel standar, dengan penjelasan tiap selisih.
4. Tiga keputusan algoritma lengkap dengan pembelaannya.

---

## Gerbang kompetensi Praktikum 2

1. Berapa ciphertext ML-KEM-768 di mesin Anda, dan kenapa berkas PEM-nya lebih besar dari angka itu?
2. Berapa kali lipat SLH-DSA-128s lebih lambat dari ML-DSA-65 dalam signing, menurut data Anda?
3. Kenapa `128s` dan `128f` ada dua-duanya padahal level keamanannya sama?
4. Waktu Anda merusak satu byte ciphertext, kenapa dekapsulasi tidak error?
5. Untuk skenario B di atas, kenapa jawabannya bukan ML-DSA saja yang jelas lebih cepat dan lebih kecil?

Nomor 5 yang paling penting. Kalau jawaban Anda cuma menyebut kecepatan dan ukuran, Anda belum menangkap intinya. Kembali ke Bab 2.1 dan 2.3.

---

## Perluasan mandiri

**Ukur di arsitektur lain.** Jalankan benchmark yang sama di Raspberry Pi, ponsel via Termux, atau mesin virtual awan. Bandingkan bentuk grafiknya. Apakah urutannya tetap? Apakah ada algoritma yang menderita jauh lebih parah di perangkat lemah? Temuan ini langsung berguna untuk Bab 4.

**Ukur konsumsi memori, bukan cuma waktu.** Pakai `tracemalloc` atau `/usr/bin/time -v`. Untuk perangkat terbatas, memori puncak sering lebih menentukan daripada kecepatan.

---

## Sebelum lanjut

Sekarang Anda punya angka sendiri dan kerangka untuk memilih. Yang belum: memasang semuanya ke aplikasi sungguhan.

Bab 3 dan Praktikum 3 masuk ke sana. Anda akan membangun otoritas sertifikat sendiri, menjalankan server TLS yang sepenuhnya pasca-kuantum, dan melihat langsung penyebab kegagalan produksi yang paling sering terjadi. Bagian terakhir itu, kalau Anda cukup teliti, akan muncul di layar Anda sendiri.
