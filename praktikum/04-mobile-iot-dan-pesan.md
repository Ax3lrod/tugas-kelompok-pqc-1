# Praktikum 4 — Pesan dan Perangkat Terbatas

> **Level:** L3
> **Bab pasangan:** Bab 4 — Mobile, IoT, dan Pesan Terenkripsi
> **Waktu:** 120 menit
> **Prasyarat:** Praktikum 3 selesai

---

## Kenapa lab ini berbeda dari yang lain

Di lab-lab sebelumnya, Anda mengerjakan sesuatu sampai berhasil.

Di lab ini, dua langkah sengaja dirancang supaya Anda mengerjakan sesuatu yang **berjalan mulus tetapi salah secara kriptografis.**

Alasannya begini. Kode yang error itu mudah dipelajari; komputer memberi tahu Anda ada yang salah. Kode yang jalan tanpa keluhan padahal salah adalah kegagalan yang lolos ke produksi, bertahan bertahun-tahun, dan baru ketahuan saat sudah terlambat.

Kalau Anda cuma mengerjakan satu langkah dari lab ini, kerjakan Langkah 3.

**Capaian keterampilan:**
- membangun enkripsi ujung ke ujung dengan pola KEM → KDF → AEAD;
- mengenali kesalahan kriptografis yang tidak menghasilkan error;
- mengukur kelayakan PQC pada anggaran sumber daya terbatas;
- merancang skema penandatanganan firmware.

---

## Langkah 1 — Jalankan pola yang benar

```bash
cd /path/ke/sumberdaya
source ~/pqc-lab/bin/activate

python3 skrip/kirim_aman.py
```

### Yang harus Anda lihat

```
Algoritma  : ML-KEM-768 + AES-256-GCM, tanda tangan ML-DSA-65
ct_kem     : 1088 byte
nonce      : 12 byte
ct_data    : 6x byte  (pesan 4x + tag 16)
tanda      : 3309 byte
TOTAL      : 44xx byte untuk pesan 4x byte
Overhead   : 44xx byte (9xxx% dari ukuran pesan)

Tanda tangan valid.
Dekapsulasi selesai tanpa error.
Hasil dekripsi: Nilai UAS Keamanan Siber: rahasia sampai 2040.
```

Perhatikan angka overhead itu. Untuk pesan pendek, biaya kriptografinya ratusan kali lipat ukuran pesannya sendiri.

Sekarang coba dengan pesan panjang:

```bash
python3 skrip/kirim_aman.py --pesan "$(head -c 100000 /dev/urandom | base64 | head -c 100000)"
```

Overhead-nya sekarang di bawah lima persen.

**Pelajarannya:** biaya PQC hampir seluruhnya bersifat tetap per-operasi, bukan proporsional terhadap data. Untuk perangkat IoT yang mengirim paket kecil setiap 15 menit, ini menentukan segalanya. Untuk transfer file besar, ini tidak berarti apa-apa.

Kalau nanti Anda merancang protokol untuk perangkat terbatas, angka inilah yang mendorong Anda menegosiasikan kunci sekali lalu memakainya berkali-kali, bukan menjalankan KEM di setiap pesan.

---

## Langkah 2 — Bedah amplopnya

Buka `skrip/kirim_aman.py` dan cari fungsi `turunkan_kunci`.

```python
def turunkan_kunci(shared_secret: bytes) -> bytes:
    return HKDF(algorithm=hashes.SHA256(), length=32,
                salt=None, info=INFO).derive(shared_secret)
```

Perhatikan parameter `info`, yang isinya `b"modul-praktikum-pqc/pesan/v1"`.

Itulah pemisahan domain. Nama protokol dan versinya ikut masuk ke turunan kunci, sehingga rahasia bersama yang sama akan menghasilkan kunci berbeda di konteks berbeda.

Sekarang bayangkan aplikasi Anda punya dua fitur: kirim pesan dan kirim berkas. Kalau keduanya menurunkan kunci dari rahasia bersama yang sama **tanpa** `info` yang berbeda, ciphertext dari satu fitur bisa diputar ulang ke fitur lain.

Biayanya nol. Menuliskannya butuh sepuluh detik. Melewatkannya bisa berarti kerentanan yang halus dan sulit ditemukan.

---

## Langkah 3 — Eksperimen kegagalan A: melompati KDF

Sekarang bagian terpenting.

```bash
python3 skrip/kirim_aman.py --tanpa-kdf
```

### Yang harus Anda lihat

```
[!] Mode --tanpa-kdf aktif. Perhatikan: program ini akan tetap
    berjalan mulus. Keberhasilan eksekusi bukan bukti kebenaran.

Tanda tangan valid.
Dekapsulasi selesai tanpa error.
Hasil dekripsi: Nilai UAS Keamanan Siber: rahasia sampai 2040.
```

Berhasil. Tidak ada peringatan, tidak ada error, pesannya terdekripsi sempurna.

Kalau ini kode produksi, dia akan lolos semua unit test. Lolos code review yang cuma memeriksa "apakah jalan". Lolos QA. Masuk produksi. Bertahan tiga tahun.

**Diam sebentar dan renungkan itu.** Anda baru saja menjalankan kode yang salah secara kriptografis, dan tidak ada satu pun mekanisme otomatis yang memberi tahu Anda.

### Kenapa salah kalau jalannya benar

Tuliskan jawaban Anda sendiri dulu sebelum membaca lanjutannya.

Tiga alasan:

**Pemisahan domain hilang.** Semua konteks di sistem Anda sekarang menurunkan kunci yang sama dari rahasia yang sama. Ciphertext bisa diputar ulang antar-konteks.

**Anda mengasumsikan sesuatu tentang rahasia bersama yang tidak dijamin.** Rahasia bersama KEM dijamin punya cukup entropi, tetapi bukan dijamin cocok dipakai langsung sebagai kunci untuk algoritma sembarang. KDF yang menjembatani keduanya.

**Kelincahan hilang.** Kalau suatu hari Anda pindah ke algoritma yang menghasilkan rahasia 48 byte, kode Anda yang mengambil 32 byte pertama diam-diam membuang sisanya. Tanpa error, lagi.

### Cara mencegah kesalahan ini di tim Anda

Perhatikan bahwa tidak ada tes otomatis yang bisa menangkapnya, karena keluarannya benar. Yang bisa menangkap cuma tiga hal: code review oleh orang yang tahu polanya, checklist eksplisit di panduan tim, dan pustaka internal yang tidak memberi jalan untuk melakukannya.

Ini alasan checklist di Bab 5 nanti bukan formalitas.

---

## Langkah 4 — Eksperimen kegagalan B: penolakan implisit

```bash
python3 skrip/kirim_aman.py --rusak-ct
```

### Yang harus Anda lihat

```
Tanda tangan valid.
[!] Satu byte ct_kem dirusak. Amati dari lapisan mana penolakan datang.
Dekapsulasi selesai tanpa error.
AEAD MENOLAK: InvalidTag
Inilah implicit rejection: ML-KEM tidak mengeluh, AEAD yang menangkap.
```

Baca urutannya baik-baik.

Dekapsulasi **berhasil**. Tidak ada error. ML-KEM menghasilkan rahasia bersama seperti biasa, hanya saja nilainya acak dan berbeda.

Yang menolak adalah AES-GCM, karena kunci yang salah menghasilkan tag autentikasi yang tidak cocok.

Anda sudah melihat perilaku ini di Praktikum 2 lewat CLI. Sekarang Anda melihat konsekuensinya di kode.

### Kenapa ini penting untuk rancangan Anda

Kalau Anda membangun sistem yang bergantung pada dekapsulasi untuk mendeteksi ciphertext rusak, sistem Anda tidak akan pernah mendeteksi apa pun. Deteksinya harus datang dari lapisan AEAD.

Ini konsekuensi rancangan yang nyata, bukan trivia. **AEAD bukan opsional dalam pola ini.** Kalau ada yang mengusulkan memakai mode enkripsi tanpa autentikasi karena "lebih ringan", Anda sekarang punya jawaban konkret kenapa tidak boleh.

---

## Langkah 5 — Simulasi perangkat terbatas

Sekarang uji kelayakan pada anggaran sumber daya kecil.

```bash
cd ~/lab4 2>/dev/null || mkdir -p ~/lab4 && cd ~/lab4

python3 - << 'EOF'
import tracemalloc
import time
import oqs

ANGGARAN_FLASH_KB = 256
ANGGARAN_RAM_KB = 64

def coba(nama_kem, nama_sig):
    hasil = {}
    tracemalloc.start()
    t0 = time.perf_counter()

    with oqs.KeyEncapsulation(nama_kem) as kem:
        pk = kem.generate_keypair()
        ct, ss = kem.encap_secret(pk)
        kem.decap_secret(ct)

    _, puncak_kem = tracemalloc.get_traced_memory()
    tracemalloc.reset_peak()

    with oqs.Signature(nama_sig) as sig:
        spk = sig.generate_keypair()
        tanda = sig.sign(b"firmware v1.2.3")
        t_ver0 = time.perf_counter()
        sig.verify(b"firmware v1.2.3", tanda, spk)
        t_verify = (time.perf_counter() - t_ver0) * 1000

    _, puncak_sig = tracemalloc.get_traced_memory()
    tracemalloc.stop()

    hasil["kem_pk"] = len(pk)
    hasil["kem_ct"] = len(ct)
    hasil["sig_pk"] = len(spk)
    hasil["sig"] = len(tanda)
    hasil["ram_kb"] = max(puncak_kem, puncak_sig) / 1024
    hasil["verify_ms"] = t_verify
    hasil["total_s"] = time.perf_counter() - t0
    return hasil

def cari(daftar, *kandidat):
    for k in kandidat:
        for t in daftar:
            if k.lower() in t.lower():
                return t
    return None

kem_list = oqs.get_enabled_kem_mechanisms()
sig_list = oqs.get_enabled_sig_mechanisms()

kombinasi = [
    ("ML-KEM-512", cari(sig_list, "ML-DSA-44", "Dilithium2")),
    ("ML-KEM-768", cari(sig_list, "ML-DSA-65", "Dilithium3")),
    ("ML-KEM-768", cari(sig_list, "SLH-DSA-SHA2-128s", "SPHINCS+-SHA2-128s")),
]

print(f"Anggaran: flash {ANGGARAN_FLASH_KB} KB, RAM kerja {ANGGARAN_RAM_KB} KB\n")
print(f"{'Kombinasi':<48}{'sig B':>8}{'RAM KB':>9}{'ver ms':>9}  Vonis")
print("-" * 88)

for kem_target, sig_nama in kombinasi:
    kem_nama = cari(kem_list, kem_target, kem_target.replace("ML-KEM", "Kyber"))
    if not kem_nama or not sig_nama:
        continue
    h = coba(kem_nama, sig_nama)
    # perkiraan kasar pemakaian flash: kunci + tanda tangan + ruang kode
    flash_kb = (h["sig_pk"] + h["sig"] + h["kem_pk"]) / 1024 + 40
    muat = flash_kb < ANGGARAN_FLASH_KB
    vonis = "LAYAK" if muat else "TIDAK MUAT"
    label = f"{kem_nama} + {sig_nama}"[:47]
    print(f"{label:<48}{h['sig']:>8}{h['ram_kb']:>9.1f}{h['verify_ms']:>9.3f}  {vonis}")

print("\nCatatan: RAM di sini diukur di Python, jadi jauh lebih besar")
print("daripada implementasi C di mikrokontroler. Yang penting bukan")
print("angka absolutnya, melainkan perbandingan antar-kombinasi.")
EOF
```

### Yang harus Anda lihat

Tabel yang menunjukkan bahwa kombinasi dengan SLH-DSA punya tanda tangan jauh lebih besar tetapi verifikasi yang tetap cepat.

Ingat batasan pengukuran ini: Python bukan mikrokontroler. Angka RAM-nya tidak bisa dipakai langsung. Yang berguna adalah **perbandingan relatif** antar-kombinasi, dan kesadaran bahwa memori kerja adalah dimensi yang tidak muncul di tabel ukuran mana pun.

---

## Langkah 6 — Rancang skema firmware

Latihan di atas kertas, tetapi ini keterampilan paling bernilai di bab ini.

**Skenario.** Anda merancang alat pemantau jantung untuk pasien di rumah. RAM 128 KB, flash 512 KB, umur pakai 10 tahun, pembaruan firmware lewat jaringan seluler berdaya rendah beberapa kali setahun. Kunci verifikasi ditanam di ROM saat produksi dan tidak bisa diubah.

Jawab keempat pertanyaan dari Bab 4.3, lalu rancang skemanya.

Yang harus ada di rancangan Anda:

- algoritma untuk akar kepercayaan, dengan alasannya
- algoritma untuk penandatanganan pembaruan rutin, dengan alasannya
- apakah Anda memakai satu kunci atau pola dua kunci, dan kenapa
- perhitungan anggaran flash: berapa byte untuk kunci, berapa untuk tanda tangan
- rencana kalau kunci operasional bocor di tahun ke-8
- rencana kalau akar kepercayaan bocor di tahun ke-8

Pertanyaan terakhir itu yang paling tidak nyaman. Jawaban jujurnya sering "tidak ada yang bisa dilakukan", dan menyadari itu sebelum produksi jauh lebih baik daripada menyadarinya setelah dua juta perangkat beredar.

---

## Deliverable Praktikum 4

1. Keluaran ketiga mode `kirim_aman.py` (normal, `--tanpa-kdf`, `--rusak-ct`).
2. Laporan satu halaman tentang kedua eksperimen kegagalan: apa yang terjadi, kenapa salah, bagaimana mencegahnya di tim nyata.
3. Tabel kelayakan perangkat terbatas dari Langkah 5.
4. Rancangan skema firmware lengkap dengan enam poin di atas.

---

## Gerbang kompetensi Praktikum 4

1. Kenapa mode `--tanpa-kdf` tetap berhasil, dan kenapa keberhasilan itu justru berbahaya?
2. Sebutkan tiga alasan konkret kenapa melompati KDF salah.
3. Waktu ciphertext KEM dirusak, lapisan mana yang menolak, dan apa konsekuensi rancangannya?
4. Untuk pesan 40 byte, berapa persen overhead di sistem Anda? Bagaimana angka itu memengaruhi rancangan protokol IoT?
5. Dalam rancangan firmware Anda, apa yang terjadi kalau akar kepercayaan bocor di tahun ke-8?

Nomor 1 dan 5 wajib benar. Keduanya menguji hal yang sama dari sudut berbeda: kesadaran bahwa tidak semua kegagalan mengumumkan dirinya.

---

## Perluasan mandiri

**Pindahkan ke perangkat sungguhan.** Kalau punya Raspberry Pi atau ESP32, coba jalankan operasi yang sama. Laporkan di mana batas praktisnya. Ini temuan yang jarang dimiliki orang dan sangat layak jadi bahan tulisan.

**Bangun rotasi kunci sederhana.** Ubah `kirim_aman.py` supaya kunci dinegosiasikan sekali lalu dipakai untuk beberapa pesan berturut-turut, dengan kunci diturunkan ulang tiap pesan. Bandingkan overhead-nya dengan versi asli. Anda baru saja menyentuh gagasan dasar forward secrecy.

**Uji pemisahan domain.** Buat dua konteks dengan `info` sama, lalu buktikan ciphertext dari satu konteks bisa didekripsi di konteks lain. Lalu bedakan `info`-nya dan buktikan tidak bisa lagi.

---

## Sebelum lanjut

Anda sudah bisa mengintegrasikan PQC ke aplikasi web, API, mobile, perangkat terbatas, dan pesan ujung ke ujung.

Yang belum: membuat semua itu bertahan terhadap pergantian algoritma berikutnya. Karena akan ada pergantian berikutnya, dan sistem yang meng-hardcode ML-KEM-768 hari ini akan menderita persis seperti sistem yang meng-hardcode RSA-2048 pada 2005.

Bab 5 dan Praktikum 5 tentang itu.
