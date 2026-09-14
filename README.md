# Tugas Praktikum Kriptografi Pasca-Kuantum (PQC)
## Modul 03 — Integrasi Aplikasi Web, API, dan Public Key Infrastructure (PKI)

Repositori ini memuat implementasi, artefak pengujian, bukti dokumentasi, dan laporan untuk **Praktikum 3 (Web, API, dan PKI)**.

### Anggota Kelompok:
1. **Aryasatya Alaauddin** - **5027231082** 
2. **Fiorenza Adelia Nalle** - **5027231053**
3. **Muhamad Arrayyan** - **5027231014**
4. **Muhammad Dzaky Ahnaf** - **5027231039**
5. **Azza Farichi Tjahjono** - **5027231071**
6. **Naufal Syafi' Hakim** - **5027231022**

### Laporan Praktikum
Laporan lengkap praktikum dapat diakses pada:
👉 **[LAPORAN_PRAKTIKUM_3.md](LAPORAN_PRAKTIKUM_3.md)**

### Ringkasan Pengerjaan:
- **Langkah 1 (PKI Pasca-Kuantum):** Pembuatan Root CA dan penerbitan sertifikat server berbasis **ML-DSA-65** (FIPS 204).
- **Langkah 2 (Pengukuran Biner DER):** Evaluasi pembesaran ukuran sertifikat (~11x–12x lipat dibanding ECDSA P-256) dan kalkulasi anggaran bandwidth (~181 TB/bulan pada 5.000 req/s).
- **Langkah 3 (Handshake TLS 1.3):** Pengoperasian server dan klien TLS 1.3 dengan pertukaran kunci hibrida **X25519MLKEM768** dan autentikasi identitas **ML-DSA-65**.
- **Langkah 4 (mTLS Antar-Layanan):** Penerapan Zero-Trust mTLS dengan sertifikat klien dan pembuktian penolakan koneksi tanpa sertifikat.
- **Langkah 5 (Inspeksi tcpdump):** Analisis lonjakan ClientHello dari 217 byte ke 1.393 byte serta evaluasi risiko fragmentasi pada jaringan MTU 1500.
- **Langkah 6 (Gerbang CI/CD):** Otomasi pengujian kepatuhan PQC menggunakan `cek_pqc.sh` dengan verifikasi kasus sukses dan kasus gagal regresi.

### Struktur Repositori:
```text
├── LAPORAN_PRAKTIKUM_3.md               # Laporan praktikum modul 03
├── run_praktikum3.sh                   # Skrip otomatisasi pengujian Langkah 1 - 6
├── generate_screenshots.ps1            # Skrip rendering bukti eksekusi terminal
├── dokumentasi/                        # Gambar tangkapan layar terminal hasil eksekusi
│   ├── 01_pki_root_server.png
│   ├── 02_der_bandwidth.png
│   ├── 03_tls13_pqc_handshake.png
│   ├── 04_mtls_service_mesh.png
│   ├── 05_tcpdump_clienthello_split.png
│   └── 06_ci_gate_verification.png
├── hasil_praktikum3/                   # Kunci kriptografi, sertifikat, file pcap, & log
└── sumberdaya/                         # Dockerfile (OpenSSL 3.5.4) & skrip modul
```
