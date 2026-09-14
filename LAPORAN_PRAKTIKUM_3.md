# LAPORAN PRAKTIKUM 3: WEB, API, DAN PKI PASCA-KUANTUM (PQC)

**Mata Kuliah / Modul:** Keamanan Siber & Kriptografi Pasca-Kuantum  
**Topik:** Praktikum 3 — Integrasi ke Aplikasi Web, API, dan Public Key Infrastructure (PKI)  
**Waktu Eksekusi:** 14 September 2026  
**Status Eksekusi:** 100% Berhasil (Semua langkah 1–6 tuntas terverifikasi)  
**Lokasi Artefak & Bukti:** [`hasil_praktikum3/`](file:///C:/Users/Aryasatya%20Alaauddin/quantum/tugas-kelompok1/hasil_praktikum3)

---

## 1. Menjawab Pertanyaan Prasyarat: Apakah Perlu Mengerjakan Lab 00–02 Dulu?

| Modul | Status Kebutuhan | Penjelasan Teknis |
|---|---|---|
| **Lab 00 (Persiapan Lingkungan)** | **WAJIB DIJALANKAN** | Algoritma pasca-kuantum (`ML-DSA-65`, `ML-KEM-768`, grup hibrida `X25519MLKEM768`) baru didukung secara bawaan pada **OpenSSL versi 3.5+**. Sistem host Windows Anda menggunakan OpenSSL 3.2.0 (belum mendukung PQC). Oleh karena itu, kita membangun container Docker **`pqc-lab`** berbasis Ubuntu 24.04 dengan OpenSSL 3.5.4 yang dikompilasi dari sumber agar semua perintah kriptografi kuantum dapat berjalan. |
| **Praktikum 01 (Memotret Kondisi Awal)** | **TIDAK PERLU** | Praktikum 1 fokus pada survei domain publik dan audit SSH lokal. Tidak ada berkas kunci, sertifikat, ataupun data keluaran dari Praktikum 1 yang menjadi input bagi Praktikum 3. |
| **Praktikum 02 (Mengukur Algoritma)** | **TIDAK PERLU** | Praktikum 2 fokus pada benchmark micro-level KEM & signature mentah di Python. Praktikum 3 membangun sistem PKI, TLS 1.3, dan mTLS dari awal (*scratch*) secara mandiri. |

**Kesimpulan:** Anda dapat langsung mengerjakan Praktikum 3 segera setelah lingkungan Docker (Lab 00) siap.

---

## 2. Alur Pengerjaan dan Hasil Pengujian Nyata

Seluruh tahapan dieksekusi secara otomatis dan deterministik di dalam lingkungan container Docker menggunakan skrip [`run_praktikum3.sh`](file:///C:/Users/Aryasatya%20Alaauddin/quantum/tugas-kelompok1/run_praktikum3.sh). Seluruh output mentah tersimpan pada log [`eksekusi_lab3.log`](file:///C:/Users/Aryasatya%20Alaauddin/quantum/tugas-kelompok1/hasil_praktikum3/eksekusi_lab3.log).

---

### Langkah 1 — Membangun Otoritas Sertifikat (PKI) Pasca-Kuantum

Pada langkah ini, kita membangun hirarki PKI privat berbasis tanda tangan digital kisi tahan kuantum (**ML-DSA-65** / NIST FIPS 204).

#### 1.1 Penerbitan Root CA Pasca-Kuantum
Perintah yang dijalankan:
```bash
openssl req -x509 -new -newkey ml-dsa-65 -keyout ca.key -out ca.crt \
    -nodes -days 3650 -subj "/C=ID/O=Lab PQC/CN=Root CA PQC"
```
**Hasil Verifikasi Struktur Sertifikat Root CA (`openssl x509 -in ca.crt -noout -text`):**
```text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            3d:94:1a:2c:17:b3:67:58:a3:c0:7a:15:06:e5:2c:86:e1:f9:5d:bf
        Signature Algorithm: ML-DSA-65
        Issuer: C=ID, O=Lab PQC, CN=Root CA PQC
        Validity
            Not Before: Sep 14 13:34:19 2026 GMT
            Not After : Sep 11 13:34:19 2036 GMT
        Subject: C=ID, O=Lab PQC, CN=Root CA PQC
        Subject Public Key Info:
            Public Key Algorithm: ML-DSA-65
                ML-DSA-65 Public-Key:
                pub: ...
```
> **Temuan Kunci:** Baik `Signature Algorithm` maupun `Public Key Algorithm` menggunakan `ML-DSA-65`. Root CA ini sepenuhnya kebal terhadap dekomposisi logaritma diskret Shor.

#### 1.2 Penerbitan dan Penandatanganan Sertifikat Server
Perintah pembuatan CSR dan penandatanganan sertifikat dengan Subject Alternative Name (SAN):
```bash
openssl req -new -newkey ml-dsa-65 -keyout server.key -out server.csr \
    -nodes -subj "/C=ID/O=Lab PQC/CN=localhost"

# File ext.cnf: SAN localhost & IP 127.0.0.1, keyUsage digitalSignature, serverAuth
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out server.crt -days 365 -extfile ext.cnf
```
**Hasil Verifikasi Validitas Rantai Sertifikat:**
```bash
$ openssl verify -CAfile ca.crt server.crt
server.crt: OK
```

#### Tangkapan Layar Bukti Eksekusi Langkah 1
![Bukti Eksekusi Langkah 1 - Otoritas Sertifikat PKI PQC](dokumentasi/01_pki_root_server.png)


---

### Langkah 2 — Mengukur Beban Ukuran Sertifikat (ML-DSA vs ECDSA)

Untuk membandingkan ukuran secara adil tanpa terdistorsi encoding Base64/PEM, sertifikat diekspor ke format biner **DER** (*Distinguished Encoding Rules*). Kita juga menerbitkan sertifikat pembanding klasik berbasis kurva eliptik standar industri (**ECDSA P-256**).

#### Tabel Hasil Pengukuran Ukuran Biner (DER)

| Komponen Sertifikat | Klasik (ECDSA P-256) | Pasca-Kuantum (ML-DSA-65) | Selisih Beban (Byte) | Rasio Pembesaran |
|---|---|---|---|---|
| **Root CA (`ca.der`)** | **454 byte** | **5.576 byte** | **+5.122 byte** | **12,28x lipat** |
| **Server Leaf (`server.der`)** | **504 byte** | **5.624 byte** | **+5.120 byte** | **11,16x lipat** |
| **Rantai 3 Sertifikat (Tipikal Web)** | **~1.462 byte** | **~16.822 byte** | **+15.360 byte** | **11,51x lipat** |

#### Analisis Proyeksi Anggaran Bandwidth Produksi
Dalam skenario infrastruktur web/API skala besar dengan **5.000 koneksi TLS baru per detik** (*new handshakes/sec*):

$$\text{Overhead per detik} = 15.360\text{ byte} \times 5.000 = 76.800.000\text{ byte/s} \approx \mathbf{73,24\text{ MB/s}}$$

$$\text{Overhead per jam} = 73,24\text{ MB/s} \times 3.600 \approx \mathbf{257,49\text{ GB/jam}}$$

$$\text{Overhead per bulan (30 hari)} = 257,49\text{ GB/jam} \times 24 \times 30 \approx \mathbf{181,05\text{ TB/bulan}}$$

> [!WARNING]
> **Dampak Nyata:** Penambahan bandwidth sebesar **~181 TB per bulan** hanya untuk pertukaran sertifikat SSL/TLS. Jika biaya *egress* cloud provider sebesar \$0,08 per GB, migrasi sertifikat ke PQC tanpa optimasi (*session resumption* atau sertifikat kompresi RFC 8879) menambah biaya operasional cloud sebesar **~\$14.800/bulan**. Ini membuktikan secara kuantitatif mengapa migrasi tanda tangan PKI jauh lebih mahal daripada migrasi KEM.

#### Tangkapan Layar Bukti Eksekusi Langkah 2
![Bukti Eksekusi Langkah 2 - Ukuran Biner DER & Anggaran Bandwidth](dokumentasi/02_der_bandwidth.png)


---

### Langkah 3 — Menjalankan Server & Klien TLS 1.3 Pasca-Kuantum

Kita menjalankan server TLS 1.3 penuh di port 4433 yang dikonfigurasi secara eksklusif menggunakan grup pertukaran kunci hibrida `X25519MLKEM768` dan sertifikat server `ML-DSA-65`.

```bash
# Server (Terminal A)
openssl s_server -cert server.crt -key server.key -accept 4433 \
    -tls1_3 -groups X25519MLKEM768 -www

# Klien (Terminal B)
openssl s_client -connect localhost:4433 -CAfile ca.crt \
    -groups X25519MLKEM768 -tls1_3 </dev/null
```

**Hasil Keluaran Kunci:**
```text
Peer signature type: mldsa65
Negotiated TLS1.3 group: X25519MLKEM768
Verify return code: 0 (ok)
```

**Makna ketiga baris tersebut:**
1. **`Negotiated TLS1.3 group: X25519MLKEM768`**: Kunci sesi enkripsi diturunkan secara hibrida (X25519 klasik + ML-KEM-768). Jika penyerang merekam lalu lintas data hari ini (*Harvest Now*), data tersebut tetap aman dari dekripsi komputer kuantum di masa depan (*Decrypt Later*).
2. **`Peer signature type: mldsa65`**: Server mengautentikasi kepemilikan kunci privatnya menggunakan tanda tangan digital berbasis kisi ML-DSA-65 yang tahan kuantum secara matematis.
3. **`Verify return code: 0 (ok)`**: Rantai sertifikat server berhasil divalidasi hingga ke Root CA lokal terpercaya tanpa kesalahan.

#### Tangkapan Layar Bukti Eksekusi Langkah 3
![Bukti Eksekusi Langkah 3 - Handshake TLS 1.3 Pasca-Kuantum Penuh](dokumentasi/03_tls13_pqc_handshake.png)


---

### Langkah 4 — Pengujian mTLS Antar-Layanan (Mutual TLS)

Pada komunikasi *microservices* / *service mesh* privat, kedua belah pihak harus saling membuktikan identitas.

1. **Pembuatan Sertifikat Klien:**
   - Diterbitkan sertifikat klien `client.crt` (ML-DSA-65) dengan ekstensi `extendedKeyUsage = clientAuth`.
2. **Menjalankan Server dengan Otorisasi Wajib:**
   - Server dijalankan dengan opsi `-Verify 1` (wajib menyertakan sertifikat klien yang sah).

#### Uji Kasus A: Klien Tanpa Sertifikat (Harus Gagal)
```bash
openssl s_client -connect localhost:4434 -CAfile ca.crt -tls1_3 </dev/null
```
**Hasil:**
```text
SSL routines:tls_process_client_certificate:peer did not return a certificate
SSL routines:ssl3_read_bytes:tlsv13 alert certificate required (SSL alert number 116)
Kode keluar: 1 (Koneksi DITOLAK server)
```

#### Uji Kasus B: Klien dengan Sertifikat ML-DSA-65 (Harus Berhasil)
```bash
openssl s_client -connect localhost:4434 -CAfile ca.crt \
    -cert client.crt -key client.key -groups X25519MLKEM768 -tls1_3 </dev/null
```
**Hasil:**
```text
depth=1 C=ID, O=Lab PQC, CN=Root CA PQC
verify return:1
depth=0 C=ID, O=Lab PQC, CN=layanan-internal
verify return:1
Peer signature type: mldsa65
Negotiated TLS1.3 group: X25519MLKEM768
Verify return code: 0 (ok)
```
> **Kesimpulan:** mTLS pasca-kuantum berhasil berjalan secara penuh. Pada lingkungan tertutup seperti ini, fallback klasik dapat dinonaktifkan secara total.

#### Tangkapan Layar Bukti Eksekusi Langkah 4
![Bukti Eksekusi Langkah 4 - mTLS Antar-Layanan](dokumentasi/04_mtls_service_mesh.png)


---

### Langkah 5 — Analisis Tangkapan Paket Wireshark/tcpdump (ClientHello yang Pecah)

Melalui `tcpdump`, kita menangkap lalu lintas paket pada dua handshake yang berbeda:
1. Handshake Klasik (`klasik.pcap`): Grup pertukaran kunci `X25519`
2. Handshake Hibrida (`hibrida.pcap`): Grup pertukaran kunci `X25519MLKEM768`

```bash
ls -lh *.pcap
-rw-r--r-- 1 root root  12K klasik.pcap
-rw-r--r-- 1 root root  14K hibrida.pcap
```

#### Perbandingan Ukuran Payload Paket ClientHello

```text
=== HANDSHAKE KLASIK (X25519) ===
13:34:28.829293 IP 127.0.0.1.56398 > 127.0.0.1.4435: Flags [P.], seq 1:218, length 217

=== HANDSHAKE HIBRIDA (X25519MLKEM768) ===
13:34:30.915483 IP 127.0.0.1.56408 > 127.0.0.1.4435: Flags [P.], seq 1:1394, length 1393
```

| Parameter | Handshake Klasik | Handshake Hibrida PQC | Peningkatan |
|---|---|---|---|
| **Panjang Paket ClientHello TCP** | **217 byte** | **1.393 byte** | **+1.176 byte (6,4x lipat)** |

#### Bahaya di Jaringan Nyata (MTU 1500 & Middlebox Failure)
- Pada Ethernet standar, **MTU = 1500 byte**.
- Header TCP/IP memakan 40–60 byte (IP 20B + TCP 20B + TCP Options 12B–20B), sehingga **MSS (*Maximum Segment Size*) $\approx$ 1440–1460 byte**.
- Jika klien berada di balik **VPN (WireGuard/IPsec)**, **GRE tunnel**, atau **VLAN tagging**, MTU turun menjadi **1420 atau 1380 byte**.
- Paket ClientHello hibrida (1.393 byte) bersama header TLS dan TCP/IP akan **melampaui MTU jaringan** dan **terpecah (*packet fragmentation*)** menjadi 2 segmen TCP.
- **Dampak Fatal:** Banyak *firewall* / *middlebox* enterprise lama yang mengasumsikan ClientHello selalu berada dalam 1 paket TCP utuh. Ketika ClientHello terpecah, firewall tidak dapat mem-parsing TLS extension pada paket kedua sehingga paket di-*drop* secara diam-diam (*silent drop*). Akibatnya, koneksi pengguna mengalami *hanging* / *timeout* tanpa pesan error di sisi server.

#### Tangkapan Layar Bukti Eksekusi Langkah 5
![Bukti Eksekusi Langkah 5 - Tangkapan Paket tcpdump](dokumentasi/05_tcpdump_clienthello_split.png)


---

### Langkah 6 — Gerbang Verifikasi untuk Pipeline CI/CD

Kita menguji keandalan skrip [`cek_pqc.sh`](file:///C:/Users/Aryasatya%20Alaauddin/quantum/tugas-kelompok1/sumberdaya/skrip/cek_pqc.sh) baik untuk kondisi valid (exit code 0) maupun kondisi gagal/regresi (exit code 1).

```bash
# 1. Endpoint PQC lokal
$ bash sumberdaya/skrip/cek_pqc.sh localhost:4436
OK    localhost:4436 -> X25519MLKEM768
Kode keluar: 0 (LULUS)

# 2. Endpoint PQC global terkemuka
$ bash sumberdaya/skrip/cek_pqc.sh cloudflare.com:443
OK    cloudflare.com:443 -> X25519MLKEM768
Kode keluar: 0 (LULUS)

# 3. KASUS GAGAL: Server lokal murni klasik (X25519 saja)
$ bash sumberdaya/skrip/cek_pqc.sh localhost:4437
GAGAL localhost:4437 tidak menegosiasikan X25519MLKEM768
Kode keluar: 1 (GAGAL - Regresi terdeteksi!)

# 4. KASUS GAGAL: Endpoint publik non-PQC (badssl.com)
$ bash sumberdaya/skrip/cek_pqc.sh badssl.com:443
GAGAL badssl.com:443 tidak menegosiasikan X25519MLKEM768
Kode keluar: 1 (GAGAL - Tepat menolak endpoint klasik)
```

#### Tangkapan Layar Bukti Eksekusi Langkah 6
![Bukti Eksekusi Langkah 6 - Gerbang Verifikasi CI](dokumentasi/06_ci_gate_verification.png)


---

## 3. Jawaban Gerbang Kompetensi Praktikum 3

Berikut jawaban konseptual dan empiris atas 5 pertanyaan evaluasi Praktikum 3 berdasarkan data pengukuran nyata:

### 1. Berapa selisih ukuran DER sertifikat ML-DSA-65 dan ECDSA P-256 di lab Anda, dan berapa biaya bandwidth bulanan untuk 5.000 koneksi baru per detik?
- **Selisih ukuran DER individual:**
  - Sertifikat Server: ML-DSA-65 (**5.624 byte**) vs ECDSA P-256 (**504 byte**), selisih **+5.120 byte** (~11,16x lipat).
  - Sertifikat Root CA: ML-DSA-65 (**5.576 byte**) vs ECDSA P-256 (**454 byte**), selisih **+5.122 byte** (~12,28x lipat).
- **Selisih per handshake (rantai 3 sertifikat):** **15.360 byte** (~15 KB per koneksi).
- **Biaya Bandwidth Bulanan (5.000 koneksi baru/detik):**
  - Beban transfer data tambahan: **73,24 MB/detik** = **257,49 GB/jam** = **181,05 TB/bulan**.
  - Dengan asumsi tarif rata-rata *egress data transfer* cloud (AWS/GCP/Azure) sebesar \$0,08/GB, estimasi biaya bandwidth tambahan mencapai **~\$14.800/bulan**.

### 2. Di Langkah 3, tiga baris keluaran itu masing-masing membuktikan apa?
1. `Negotiated TLS1.3 group: X25519MLKEM768`: Membuktikan bahwa pertukaran kunci sesi dilakukan secara hibrida, melindungi kerahasiaan data terhadap ancaman *Harvest Now, Decrypt Later*.
2. `Peer signature type: mldsa65`: Membuktikan bahwa autentikasi server dilakukan menggunakan tanda tangan digital pasca-kuantum ML-DSA-65, bukan RSA atau ECDSA.
3. `Verify return code: 0 (ok)`: Membuktikan integritas dan keabsahan rantai kepercayaan (*trust chain*) dari sertifikat server hingga Root CA yang dipercaya.
Ketiga baris ini bersama-sama membuktikan bahwa **tidak ada algoritma klasik rentan Shor yang tersisa pada jalur kritis TLS**.

### 3. Kenapa di Langkah 4 Anda bisa menonaktifkan fallback klasik, padahal di endpoint publik tidak boleh?
- Pada **mTLS antar-layanan (Langkah 4)**, kita mengendalikan **kedua belah pihak** (baik server maupun klien/microservice). Kita dapat memastikan secara sepihak bahwa seluruh dependensi klien sudah mendukung PQC, sehingga penonaktifan fallback klasik aman dan justru memperkuat keamanan (*zero legacy attack surface*).
- Pada **endpoint publik (web/API umum)**, klien terdiri dari jutaan perangkat heterogen (browser lama, sistem operasi legacy, embedded client) yang belum diperbarui. Menonaktifkan fallback klasik di endpoint publik akan menyebabkan pemutusan akses massal (*break backward compatibility*).

### 4. Berapa ukuran ClientHello hibrida Anda, dan kenapa angka itu bermasalah di jaringan ber-MTU 1500?
- Ukuran ClientHello hibrida mencapai **1.393 byte** (dibandingkan **217 byte** pada handshake klasik).
- Ditambah dengan header IP (20 byte), TCP (20–40 byte), dan opsi TCP, total ukuran paket berada di ambang batas MSS (~1440–1460 byte). Jika paket melewati rute dengan MTU lebih rendah dari 1500 (misalnya VPN, jaringan seluler, atau VLAN encapsulation dengan MTU 1420), paket ClientHello **terfragmentasi menjadi 2 segmen**. Banyak firewall atau inspektor jaringan lama yang tidak mampu merakit ulang segmen TLS handshake dan langsung membuang paket (*silent packet drop*), mengakibatkan koneksi macet total tanpa error log.

### 5. Kenapa gerbang CI perlu diuji untuk kasus gagal juga?
Gerbang CI (*verification gate*) yang hanya diuji pada kasus sukses tidak dapat membuktikan apakah detektor tersebut benar-benar berfungsi atau hanya selalu mengembalikan kode `0`. Menguji kasus gagal (misalnya terhadap server lokal non-PQC dan host klasik `badssl.com`) adalah satu-satunya cara memastikan bahwa pipeline CI/CD akan **secara andal memblokir build dan memicu alarm ketika terjadi regresi konfigurasi kriptografi**.

---

## 4. Struktur Berkas Deliverables

Semua berkas hasil eksekusi praktikum telah dibuat dan disimpan di direktori [`hasil_praktikum3/`](file:///C:/Users/Aryasatya%20Alaauddin/quantum/tugas-kelompok1/hasil_praktikum3):

```text
hasil_praktikum3/
├── ca.crt               # Sertifikat Root CA (ML-DSA-65) format PEM
├── ca.key               # Kunci privat Root CA format PEM
├── ca_pqc.der           # Sertifikat Root CA biner DER (5.576 byte)
├── server.crt           # Sertifikat Server (ML-DSA-65) format PEM
├── server.key           # Kunci privat Server format PEM
├── server_pqc.der       # Sertifikat Server biner DER (5.624 byte)
├── client.crt           # Sertifikat Klien mTLS (ML-DSA-65) format PEM
├── client.key           # Kunci privat Klien mTLS format PEM
├── ca_ec.der            # Sertifikat Root CA klasik ECDSA (454 byte)
├── server_ec.der        # Sertifikat Server klasik ECDSA (504 byte)
├── klasik.pcap          # Tangkapan tcpdump handshake klasik (ClientHello 217 byte)
├── hibrida.pcap         # Tangkapan tcpdump handshake hibrida (ClientHello 1.393 byte)
├── ext.cnf              # Konfigurasi ekstensi SAN & keyUsage server
├── ext_client.cnf       # Konfigurasi ekstensi clientAuth mTLS
└── eksekusi_lab3.log    # Log eksekusi lengkap dari awal hingga akhir
```

---

*Laporan ini disusun secara otomatis berdasarkan hasil pengukuran langsung pada laboratorium praktikum container PQC.*
