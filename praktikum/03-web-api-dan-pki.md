# Praktikum 3 — Web, API, dan PKI

> **Level:** L2 → L3
> **Bab pasangan:** Bab 3 — Integrasi ke Aplikasi Web dan API
> **Waktu:** 150 menit
> **Prasyarat:** Praktikum 2 selesai

---

## Kenapa lab ini yang paling penting

Kalau Anda cuma punya waktu untuk satu praktikum dari seluruh modul, kerjakan yang ini.

Di sini Anda membangun otoritas sertifikat pasca-kuantum sendiri, menjalankan server TLS yang tahan kuantum sepenuhnya, dan menangkap paket yang menunjukkan penyebab kegagalan produksi nomor satu.

Langkah 5 khususnya. Sebagian besar orang membaca soal ClientHello yang pecah dan mengangguk tanpa benar-benar mengerti. Setelah melihatnya di Wireshark sendiri, pemahamannya berubah jenis.

**Capaian keterampilan:**
- membangun hirarki PKI pasca-kuantum dari nol;
- menjalankan dan memverifikasi TLS 1.3 hibrida;
- mengaktifkan mTLS antar-layanan;
- mengukur biaya nyata handshake dari tangkapan paket;
- menulis gerbang verifikasi untuk CI.

---

## Langkah 1 — Bangun otoritas sertifikat sendiri

```bash
mkdir -p ~/lab3 && cd ~/lab3

# Root CA dengan ML-DSA-65
ossl req -x509 -new -newkey ml-dsa-65 -keyout ca.key -out ca.crt \
    -nodes -days 3650 -subj "/C=ID/O=Lab PQC/CN=Root CA PQC"

ossl x509 -in ca.crt -noout -text | head -15
```

### Yang harus Anda lihat

Di keluaran `x509 -text`, cari dua baris:

```
        Signature Algorithm: ML-DSA-65
        ...
            Public Key Algorithm: ML-DSA-65
```

Selamat, Anda baru saja membuat root CA yang tahan kuantum. Kalau ini terasa terlalu mudah, memang begitu. Sisi sulitnya bukan membuatnya, melainkan membuat dunia mempercayainya, dan itu masalah yang tidak Anda punya di PKI privat.

### Langkah 1b — Terbitkan sertifikat server

```bash
ossl req -new -newkey ml-dsa-65 -keyout server.key -out server.csr \
    -nodes -subj "/C=ID/O=Lab PQC/CN=localhost"

cat > ext.cnf << 'EOF'
subjectAltName = DNS:localhost, IP:127.0.0.1
keyUsage = critical, digitalSignature
extendedKeyUsage = serverAuth
EOF

ossl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out server.crt -days 365 -extfile ext.cnf

ossl verify -CAfile ca.crt server.crt
```

Harus muncul `server.crt: OK`.

---

## Langkah 2 — Ukur harga sertifikatnya

Sekarang bandingkan dengan versi klasik, memakai format biner supaya adil.

```bash
# Versi ECDSA sebagai pembanding
ossl req -x509 -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 \
    -keyout ca_ec.key -out ca_ec.crt -nodes -days 3650 \
    -subj "/C=ID/O=Lab Klasik/CN=Root CA EC"

ossl x509 -in ca.crt    -outform DER -out ca_pqc.der
ossl x509 -in ca_ec.crt -outform DER -out ca_ec.der
ossl x509 -in server.crt -outform DER -out server_pqc.der

ls -l *.der
```

### Yang harus Anda lihat

Sertifikat ML-DSA berukuran belasan kali lipat sertifikat ECDSA. Catat angka persisnya.

Sekarang hitung dengan angka Anda sendiri:

- Selisih per sertifikat: _____ byte
- Rantai tipikal berisi 3 sertifikat, jadi selisih per handshake: _____ byte
- Untuk 5.000 koneksi baru per detik: _____ MB per detik
- Per bulan: _____ TB

Buka daftar harga transfer data penyedia awan mana pun dan kalikan. Angka itu adalah alasan sesungguhnya kenapa migrasi sertifikat lebih berat daripada migrasi pertukaran kunci.

---

## Langkah 3 — Jalankan server TLS pasca-kuantum

Butuh **dua terminal**.

**Terminal A** (server):

```bash
cd ~/lab3
ossl s_server -cert server.crt -key server.key -accept 4433 \
    -tls1_3 -groups X25519MLKEM768 -www
```

Biarkan berjalan.

**Terminal B** (klien):

```bash
cd ~/lab3
ossl s_client -connect localhost:4433 -CAfile ca.crt \
    -groups X25519MLKEM768 -tls1_3 </dev/null 2>&1 | \
    grep -i -E "Negotiated TLS1.3 group|Peer signature|Verify return code"
```

### Yang harus Anda lihat

```
Negotiated TLS1.3 group: X25519MLKEM768
Peer signature type: ML-DSA-65
Verify return code: 0 (ok)
```

Baca ketiga baris itu pelan-pelan.

Baris pertama: kunci sesi disepakati secara hibrida, tahan terhadap serangan rekam-sekarang-buka-nanti.
Baris kedua: server membuktikan identitasnya dengan tanda tangan pasca-kuantum.
Baris ketiga: rantai sertifikatnya terverifikasi sampai ke CA Anda.

**Tidak ada satu pun bagian klasik yang tersisa di jalur kritis.** Anda menjalankan TLS yang sepenuhnya tahan kuantum, di laptop biasa, dalam tiga perintah.

Kalau salah satu baris tidak muncul, jalankan ulang `s_client` tanpa `grep` dan baca seluruh keluarannya. Pesan errornya biasanya cukup jelas.

---

## Langkah 4 — mTLS antar-layanan

Sekarang tambahkan autentikasi dua arah, seperti komunikasi antar-layanan di dalam sistem Anda.

```bash
# Sertifikat untuk klien
ossl req -new -newkey ml-dsa-65 -keyout client.key -out client.csr \
    -nodes -subj "/C=ID/O=Lab PQC/CN=layanan-internal"

cat > ext_client.cnf << 'EOF'
keyUsage = critical, digitalSignature
extendedKeyUsage = clientAuth
EOF

ossl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out client.crt -days 365 -extfile ext_client.cnf
```

Hentikan server di Terminal A, jalankan ulang dengan verifikasi klien wajib:

```bash
ossl s_server -cert server.crt -key server.key -accept 4433 \
    -tls1_3 -groups X25519MLKEM768 -www \
    -CAfile ca.crt -Verify 1
```

Di Terminal B, coba **tanpa** sertifikat klien lebih dulu:

```bash
ossl s_client -connect localhost:4433 -CAfile ca.crt -tls1_3 </dev/null 2>&1 | tail -5
```

Harus gagal. Server menolak karena klien tidak membuktikan identitasnya.

Sekarang dengan sertifikat:

```bash
ossl s_client -connect localhost:4433 -CAfile ca.crt \
    -cert client.crt -key client.key \
    -groups X25519MLKEM768 -tls1_3 </dev/null 2>&1 | \
    grep -i -E "Negotiated TLS1.3 group|Verify return code"
```

Berhasil. Anda baru saja menjalankan mTLS pasca-kuantum penuh, persis pola yang dipakai service mesh.

Perhatikan bahwa di sini Anda menonaktifkan seluruh fallback klasik tanpa masalah, karena Anda mengendalikan kedua ujungnya. Ini yang tidak bisa Anda lakukan di endpoint publik.

---

## Langkah 5 — Menangkap ClientHello yang pecah

Bagian yang paling berharga di seluruh modul.

Hentikan server yang tadi, jalankan ulang tanpa `-Verify`:

```bash
# Terminal A
ossl s_server -cert server.crt -key server.key -accept 4433 -tls1_3 -www
```

Di **Terminal B**, tangkap dua jenis handshake:

```bash
cd ~/lab3

# Handshake klasik
sudo tcpdump -i lo -w klasik.pcap "port 4433" &
sleep 1
ossl s_client -connect localhost:4433 -groups X25519 -tls1_3 </dev/null >/dev/null 2>&1
sleep 1
sudo pkill tcpdump

# Handshake hibrida
sudo tcpdump -i lo -w hibrida.pcap "port 4433" &
sleep 1
ossl s_client -connect localhost:4433 -groups X25519MLKEM768 -tls1_3 </dev/null >/dev/null 2>&1
sleep 1
sudo pkill tcpdump

ls -l klasik.pcap hibrida.pcap
```

### Analisis cepat di terminal

```bash
echo "=== KLASIK ==="
tcpdump -r klasik.pcap -nn 2>/dev/null | head -8
echo
echo "=== HIBRIDA ==="
tcpdump -r hibrida.pcap -nn 2>/dev/null | head -8
```

### Yang harus Anda lihat

Bandingkan ukuran paket pertama dari klien pada kedua tangkapan.

Pada handshake klasik, ClientHello berukuran beberapa ratus byte dan muat dalam satu paket.

Pada handshake hibrida, ukurannya melonjak melewati 1.400-an byte. Di antarmuka loopback ini masih mungkin muat karena MTU loopback besar, tetapi **di jaringan sungguhan dengan MTU 1500, paket ini pecah.**

Untuk melihatnya lebih jelas, buka `hibrida.pcap` di Wireshark dan filter dengan `tls.handshake.type == 1`. Lihat panjang `Client Hello`-nya.

### Kenapa ini penting

Sekarang bayangkan paket itu melewati firewall lama di kantor pelanggan yang berasumsi ClientHello selalu satu paket.

Koneksinya menggantung. Tidak ada error di log server Anda, karena paketnya tidak pernah sampai. Pengguna melapor "situsnya tidak bisa dibuka", sementara di laptop Anda semuanya normal.

Anda baru saja melihat penyebabnya dengan mata sendiri. Ketika suatu hari Anda menghadapi tiket bug seperti itu di tempat kerja, Anda akan langsung tahu ke mana harus melihat.

### Uji di jaringan yang lebih buruk

Kalau Anda punya akses, ulangi langkah ini lewat jaringan lain: WiFi kampus, hotspot ponsel, atau jaringan kantor dengan perangkat inspeksi. Bandingkan hasilnya.

Ini bukan langkah opsional kalau Anda serius. Menguji hanya dari jaringan terbaik adalah cara paling andal untuk melewatkan masalah ini sampai pelanggan yang menemukannya.

---

## Langkah 6 — Gerbang verifikasi untuk CI

Regresi kripto itu senyap. Upgrade appliance, perubahan kebijakan di load balancer, rollback image; semuanya bisa mengembalikan Anda ke klasik tanpa satu pun alarm berbunyi.

Satu-satunya cara tahu adalah memeriksa terus-menerus.

```bash
bash sumberdaya/skrip/cek_pqc.sh localhost:4433
echo "kode keluar: $?"

bash sumberdaya/skrip/cek_pqc.sh cloudflare.com:443
echo "kode keluar: $?"
```

Sekarang uji kasus gagalnya, karena gerbang yang tidak pernah gagal tidak membuktikan apa pun:

```bash
bash sumberdaya/skrip/cek_pqc.sh example.com:443
echo "kode keluar: $?"
```

### Yang harus Anda lihat

Kode keluar 0 untuk endpoint yang mendukung, 1 untuk yang tidak. Dengan itu, skrip ini bisa langsung dipasang di pipeline mana pun.

Contoh untuk GitHub Actions:

```yaml
- name: Verifikasi endpoint masih pasca-kuantum
  run: bash sumberdaya/skrip/cek_pqc.sh ${{ vars.ENDPOINT }}:443
```

Kalau suatu hari seseorang mengubah konfigurasi TLS dan menghilangkan dukungan hibrida, build gagal hari itu juga. Bukan enam bulan kemudian saat audit.

---

## Deliverable Praktikum 3

1. Hirarki PKI lengkap: `ca.crt`, `server.crt`, `client.crt`, semuanya ML-DSA.
2. Tabel perbandingan ukuran DER, plus perhitungan anggaran bandwidth Anda.
3. Tangkapan layar keluaran `s_client` yang menunjukkan tiga baris kunci di Langkah 3.
4. `klasik.pcap` dan `hibrida.pcap`, dengan catatan perbandingan ukuran ClientHello.
5. Bukti gerbang CI berjalan untuk kasus berhasil maupun gagal.

---

## Gerbang kompetensi Praktikum 3

1. Berapa selisih ukuran DER sertifikat ML-DSA-65 dan ECDSA P-256 di lab Anda, dan berapa biaya bandwidth bulanan untuk 5.000 koneksi baru per detik?
2. Di Langkah 3, tiga baris keluaran itu masing-masing membuktikan apa?
3. Kenapa di Langkah 4 Anda bisa menonaktifkan fallback klasik, padahal di endpoint publik tidak boleh?
4. Berapa ukuran ClientHello hibrida Anda, dan kenapa angka itu bermasalah di jaringan ber-MTU 1500?
5. Kenapa gerbang CI perlu diuji untuk kasus gagal juga?

Nomor 3 dan 5 yang membedakan orang yang mengerti dari orang yang cuma menyalin perintah.

---

## Perluasan mandiri

**Pasang di reverse proxy sungguhan.** Bangun Nginx yang dilink ke OpenSSL 3.5, taruh di depan aplikasi web apa pun milik Anda, aktifkan grup hibrida. Buktikan aplikasinya berjalan tanpa satu baris kode pun berubah. Ini demonstrasi paling meyakinkan untuk ditunjukkan ke atasan.

**Ukur dampak resumption.** Bandingkan handshake penuh dengan session resumption. Selisihnya akan menjelaskan kenapa connection pooling jauh lebih menentukan daripada pilihan algoritma.

**Rantai tiga tingkat.** Bangun root, intermediate, lalu leaf. Ukur rantai lengkapnya. Sekarang Anda melihat masalah ukuran dalam bentuknya yang sesungguhnya.

---

## Sebelum lanjut

Anda sudah bisa mengamankan aplikasi web dan API. Yang belum: lingkungan tempat Anda tidak punya kemewahan TLS.

Perangkat IoT dengan memori 64 kilobyte. Aplikasi pesan yang harus terenkripsi ujung ke ujung, bukan cuma sampai server. Firmware yang kunci verifikasinya tertanam permanen dan tidak bisa diganti sepanjang umur perangkat.

Bab 4 dan Praktikum 4 masuk ke wilayah yang lebih tidak ramah itu.
