# Praktikum 6 — Proyek Integrasi Lintas Domain

> **Level:** L4 (Perancang)
> **Bab pasangan:** Bab 6 — Evaluasi Kritis dan Jembatan ke QML
> **Waktu:** 180 menit terbimbing + kerja mandiri
> **Prasyarat:** Praktikum 1 sampai 5 selesai

---

## Kenapa proyek, bukan lab lagi

Lima praktikum sebelumnya memberi Anda langkah yang harus diikuti. Lab yang baik memang begitu.

Tetapi pekerjaan nyata tidak datang dengan langkah. Datangnya sebagai masalah, dan Anda yang harus memutuskan langkahnya.

Proyek ini melepas pegangan itu. Anda memilih satu jalur, merancang sendiri pendekatannya, dan mempertanggungjawabkan keputusan Anda.

Satu nasihat sebelum memilih: **pilih yang paling mendekati pekerjaan yang benar-benar Anda inginkan.** Kalau ingin jadi backend engineer, ambil Jalur A. Kalau tertarik keamanan dan tata kelola, ambil Jalur B. Kalau ingin riset, Jalur C. Kalau suka perangkat keras, Jalur D.

Hasilnya akan jadi portofolio, bukan tugas yang dibuang setelah dinilai.

---

## Jalur A — Aplikasi lengkap

**Untuk siapa:** calon software engineer, backend, atau DevOps.

Bangun aplikasi berbagi berkas dengan keamanan pasca-kuantum menyeluruh.

**Yang wajib ada:**

- **Transport.** TLS 1.3 dengan grup hibrida, sertifikat dari PKI Anda sendiri.
- **Enkripsi aplikasi.** Berkas dienkripsi ujung ke ujung dengan pola KEM → KDF → AEAD. Server tidak boleh bisa membaca isinya.
- **Amplop berversi.** Format dengan penanda suite, registry, dan pemisahan izin baca dan tulis.
- **Autentikasi.** Tanda tangan pasca-kuantum untuk memverifikasi pengunggah.
- **Gerbang CI.** Verifikasi otomatis yang gagal kalau dukungan hibrida hilang.
- **Uji kelincahan.** Bukti bahwa mengganti algoritma menyentuh maksimal dua berkas.
- **Uji kompatibilitas mundur.** Bukti data lama tetap terbaca setelah pergantian.

**Yang membedakan pekerjaan bagus dari sekadar jalan:** dokumentasi yang jujur tentang apa yang **tidak** dilindungi. Metadata siapa mengunggah apa dan kapan. Ukuran berkas yang bocor lewat panjang ciphertext. Pola waktu akses. Sistem yang mengakui batasnya lebih dipercaya daripada yang mengklaim sempurna.

---

## Jalur B — Laporan kesiapan organisasi

**Untuk siapa:** calon analis keamanan, konsultan, auditor, atau siapa pun yang tertarik sisi tata kelola.

Pilih organisasi nyata yang Anda punya akses sah: unit di kampus, tempat magang, komunitas, atau proyek open source yang aktif.

**Yang wajib ada:**

- **Inventaris kriptografi.** Pakai pemindai, lalu lengkapi dengan pemeriksaan manual. Sebutkan secara eksplisit apa yang tidak bisa ditemukan alat.
- **Perhitungan Mosca per komponen.** Bukan satu angka untuk seluruh organisasi.
- **Peta prioritas.** Empat kategori dari Bab 5.6, dengan alasan tiap penempatan.
- **Estimasi biaya.** Anggaran bandwidth berdasarkan angka yang Anda ukur sendiri di Praktikum 2 dan 3, bukan angka kutipan.
- **Rencana bertahap.** Apa yang dikerjakan bulan ini, kuartal ini, tahun ini, dan apa yang menunggu pihak lain.
- **Kaitan kebijakan.** Hubungkan dengan kerangka peta jalan nasional dan kewajiban perlindungan data yang relevan.

**Etika, wajib dibaca:** hanya periksa sistem yang Anda punya izin untuk memeriksanya. Untuk sistem publik, batasi pada handshake TLS biasa, persis seperti aturan di Praktikum 1. Jangan pernah memindai apa pun yang lebih dalam tanpa izin tertulis. Kalau ragu, minta izin dulu.

**Yang membedakan pekerjaan bagus:** rekomendasi yang bisa dikerjakan orang lain minggu depan, bukan daftar keluhan.

---

## Jalur C — Riset kesiapan domain `.id`

**Untuk siapa:** yang tertarik riset dan berpotensi menghasilkan publikasi.

Perluas survei Praktikum 1 menjadi kajian yang layak.

**Yang wajib ada:**

- **Sampel 100 sampai 200 domain**, tersebar merata di minimal lima sektor.
- **Metodologi yang bisa diulang.** Bagaimana domain dipilih, kapan diuji, berapa kali, dari jaringan mana. Orang lain harus bisa mengulang persis.
- **Pengukuran berulang.** Minimal dua kali di waktu berbeda; kalau bisa dari jaringan berbeda.
- **Pelaporan jujur.** Domain yang gagal dihubungi dilaporkan sebagai gagal, bukan dihapus. Data yang rapi karena disortir adalah data yang rusak.
- **Analisis per sektor**, dengan grafik.
- **Perbandingan dengan data global**, beserta pembahasan kenapa berbeda.
- **Pembahasan keterbatasan.** Bias sampel, keterbatasan jaringan penguji, hal yang tidak terukur.

**Kenapa ini berbeda dari tugas biasa:** gambaran kesiapan PQC infrastruktur digital Indonesia belum ada. Kalau dikerjakan dengan metodologi yang bersih, ini data baru, bukan latihan.

Bagian keterbatasan itu bukan formalitas. Justru itu yang membedakan kajian dari klaim.

---

## Jalur D — Perangkat terbatas

**Untuk siapa:** yang bekerja dengan perangkat keras.

Implementasikan PQC di perangkat sungguhan: Raspberry Pi, ESP32, STM32, atau apa pun yang Anda punya.

**Yang wajib ada:**

- **Implementasi berjalan** di perangkat nyata, minimal verifikasi tanda tangan atau operasi KEM.
- **Pengukuran nyata.** Flash terpakai, RAM puncak, waktu operasi, konsumsi daya kalau bisa diukur.
- **Batas praktis.** Kombinasi mana yang muat, mana yang tidak, di titik mana persisnya gagal.
- **Perbandingan dengan hasil di komputer** dari Praktikum 2.
- **Rancangan skema firmware** untuk perangkat kelas itu, dengan pembelaan pilihan algoritma.

**Kenapa berharga:** hampir semua benchmark PQC yang dipublikasikan dijalankan di prosesor kelas server. Data dari perangkat yang benar-benar dipakai di lapangan jarang sekali ada.

---

## Format laporan

Berapa pun jalurnya, laporan lima sampai delapan halaman dengan struktur:

1. **Masalah dan konteks.** Apa yang Anda kerjakan dan kenapa itu penting.
2. **Keputusan dan alasannya.** Setiap pilihan algoritma dan arsitektur, dengan pembelaan yang menyebut angka.
3. **Implementasi atau metodologi.** Cukup detail untuk diulang orang lain.
4. **Hasil dan pengukuran.** Angka Anda sendiri, dengan spesifikasi lingkungan.
5. **Batasan.** Apa yang tidak dilindungi, tidak terukur, atau tidak selesai.
6. **Rekomendasi.** Apa langkah berikutnya kalau pekerjaan ini dilanjutkan.

Bagian 5 sering ditulis asal-asalan. Jangan. Untuk pembaca yang paham, bagian itulah yang paling banyak bercerita tentang kualitas pekerjaan Anda.

**Presentasi 10 menit.** Untuk mode mandiri, rekam video. Menjelaskan dengan suara sendiri memaksa Anda menemukan lubang yang tidak terlihat saat menulis.

---

## Rubrik

| Aspek | Bobot | Yang dinilai |
|---|---|---|
| Kebenaran kriptografis | 30% | Pola KEM → KDF → AEAD benar, hibrida di tempat yang tepat, tidak ada anti-pattern dari checklist |
| Kualitas integrasi | 25% | Cocok dengan kendala domain yang dipilih, keputusan bisa dipertahankan |
| Kelincahan yang terbukti | 20% | Uji dua berkas dan kompatibilitas mundur dijalankan, bukan diklaim |
| Bukti empiris dan kejujuran | 15% | Angka dari pengukuran sendiri, batasan disebut terus terang |
| Komunikasi | 10% | Laporan dan presentasi bisa dipahami orang di luar proyek |

### Yang otomatis mengurangi nilai besar

- Rahasia bersama KEM dipakai langsung tanpa KDF
- PQC murni untuk pertukaran kunci tanpa hibrida, tanpa alasan
- Nama algoritma di-hardcode tanpa registry
- Ciphertext tersimpan tanpa penanda suite
- Angka kutipan disajikan seolah hasil pengukuran sendiri
- Klaim "quantum-safe" untuk sistem yang sertifikatnya masih klasik
- Pengujian sistem tanpa izin

Poin terakhir bukan soal nilai. Itu soal etika, dan bisa jadi soal hukum.

---

## Checklist mandiri sebelum menyerahkan

Kriptografi:
- [ ] Setiap turunan kunci lewat KDF dengan `info` yang membedakan konteks
- [ ] Setiap enkripsi memakai AEAD, bukan mode tanpa autentikasi
- [ ] Pertukaran kunci hibrida, bukan PQC murni
- [ ] Fallback klasik dipertahankan di endpoint publik
- [ ] Tidak ada primitif kripto yang saya tulis sendiri

Kelincahan:
- [ ] Setiap ciphertext tersimpan membawa penanda suite
- [ ] Registry algoritma terpusat di satu tempat
- [ ] Uji dua berkas dijalankan, hasilnya dicatat
- [ ] Uji kompatibilitas mundur dijalankan, hasilnya dicatat

Bukti:
- [ ] Semua angka berasal dari pengukuran saya, spesifikasi lingkungan dicatat
- [ ] Data mentah disertakan, bukan cuma ringkasannya
- [ ] Klaim yang tidak saya ukur ditandai sebagai kutipan dengan sumbernya

Kejujuran:
- [ ] Bagian batasan menyebut minimal tiga hal yang tidak dilindungi
- [ ] Tidak ada klaim "quantum-safe" untuk komponen yang belum bermigrasi
- [ ] Semua pengujian dilakukan dengan izin

---

## Gerbang kompetensi terakhir

Setelah proyek selesai, jawab lima pertanyaan ini. Kalau semuanya bisa Anda jawab tanpa membuka catatan, Anda sudah di L4.

1. Jelaskan seluruh keputusan algoritma di proyek Anda kepada seseorang yang belum pernah mendengar PQC, dalam lima menit.
2. Sebutkan tiga hal yang **tidak** dilindungi sistem Anda, dan kenapa Anda menerima batasan itu.
3. Kalau algoritma yang Anda pakai dinyatakan tidak aman besok pagi, apa yang harus Anda ubah dan berapa lama?
4. Angka mana di laporan Anda yang Anda ukur sendiri, dan mana yang Anda kutip? Bisakah Anda menunjukkan data mentahnya?
5. Apa satu hal di proyek Anda yang tidak bisa ditemukan orang lain lewat pencarian 15 menit di internet?

Pertanyaan kelima adalah uji orisinalitas yang sama yang dipakai penulis buku ini untuk menilai setiap babnya. Kalau Anda punya jawabannya, pekerjaan Anda menambahkan sesuatu ke dunia, bukan cuma mengulang yang sudah ada.

---

## Setelah ini

Bagian PQC dari buku ini selesai.

Yang Anda bawa bukan sekumpulan perintah, karena perintah akan berubah. Yang Anda bawa adalah kebiasaan mengukur sebelum percaya, kerangka memutuskan apa yang dikerjakan lebih dulu, arsitektur yang siap berganti, dan kejujuran menyebut batasan.

Bagian berikutnya dari buku ini masuk ke Quantum Machine Learning. Anda akan melihat kenapa tiga titik temu di Bab 6.6 bukan sekadar pemanis penutup, dan kenapa memahami PQC lebih dulu membuat bagian itu jauh lebih masuk akal.

Sampai bertemu di sana.
