# Rencana Kerja: Praktikum 3 — Web, API, dan PKI

## Status Prasyarat (00-02)
- **Lab 00 (Persiapan Lingkungan)**: [x] Berhasil dibangun menggunakan Docker container `pqc-lab` (Ubuntu 24.04 + OpenSSL 3.5.4 kompilasi native + tcpdump + Python 3.12).
- **Lab 01 & Lab 02**: [x] Tidak diperlukan untuk Lab 03 karena arsitektur Lab 03 sepenuhnya mandiri mulai dari pembangunan PKI root hingga server TLS.

---

## Langkah Kerja Praktikum 3
- [x] **Langkah 0: Persiapan Lingkungan (Lab 00)**
  - [x] Build Docker image `pqc-lab` dengan OpenSSL 3.5.4 yang mendukung ML-KEM dan ML-DSA.
  - [x] Verifikasi ketersediaan algoritma (`ML-DSA-65`, `ML-KEM-768`, `X25519MLKEM768`).
- [x] **Langkah 1: Membangun Otoritas Sertifikat (PKI) Sendiri**
  - [x] Generate Root CA dengan ML-DSA-65 (`ca.key`, `ca.crt`).
  - [x] Verifikasi detail sertifikat Root CA (`Signature Algorithm: ML-DSA-65` & `Public Key Algorithm: ML-DSA-65`).
  - [x] Buat CSR dan terbitkan sertifikat server (`server.key`, `server.csr`, `server.crt`) dengan SAN localhost & 127.0.0.1.
  - [x] Verifikasi sertifikat server terhadap Root CA (`server.crt: OK`).
- [x] **Langkah 2: Mengukur Harga Sertifikat (ML-DSA vs Klasik ECDSA)**
  - [x] Generate Root CA & Server pembanding menggunakan ECDSA P-256 (`ca_ec.*`, `server_ec.*`).
  - [x] Ekspor format DER biner untuk `ca_pqc.der`, `ca_ec.der`, `server_pqc.der`, `server_ec.der`.
  - [x] Bandingkan ukuran byte nyata format DER: ML-DSA-65 (5.576 byte) vs ECDSA (454 byte) = **12.28x lipat**.
  - [x] Hitung estimasi anggaran bandwidth produksi (5.000 koneksi baru/detik = **73.24 MB/s** atau **181.05 TB/bulan**).
- [x] **Langkah 3: Menjalankan Server & Klien TLS 1.3 Pasca-Kuantum**
  - [x] Jalankan `openssl s_server` dengan `server.crt`, `server.key`, `-tls1_3`, dan `-groups X25519MLKEM768`.
  - [x] Hubungi via `openssl s_client` dan verifikasi 3 baris kunci:
    1. `Negotiated TLS1.3 group: X25519MLKEM768`
    2. `Peer signature type: mldsa65`
    3. `Verify return code: 0 (ok)`
- [x] **Langkah 4: Konfigurasi mTLS Antar-Layanan**
  - [x] Buat sertifikat klien (`client.key`, `client.csr`, `client.crt`) dengan ekstensi `clientAuth`.
  - [x] Jalankan server dengan verifikasi klien wajib (`-Verify 1`).
  - [x] Uji koneksi tanpa sertifikat klien: Gagal ditolak server (`tlsv13 alert certificate required`, exit code 1).
  - [x] Uji koneksi dengan sertifikat klien: Berhasil lolos mTLS PQC penuh.
- [x] **Langkah 5: Menangkap Paket ClientHello (Wireshark / tcpdump)**
  - [x] Jalankan `tcpdump` untuk menangkap handshake klasik (X25519) -> `klasik.pcap` (**217 bytes**).
  - [x] Jalankan `tcpdump` untuk menangkap handshake hibrida (X25519MLKEM768) -> `hibrida.pcap` (**1.393 bytes**).
  - [x] Analisis lonjakan ukuran ~6.4x dan implikasi fragmentasi paket MTU 1500 (silent connection hanging).
- [x] **Langkah 6: Gerbang Verifikasi untuk CI**
  - [x] Uji endpoint lokal PQC `localhost:4436` -> Exit code 0 (Lolos).
  - [x] Uji endpoint global PQC `cloudflare.com:443` -> Exit code 0 (Lolos).
  - [x] Uji kasus gagal server lokal klasik murni `localhost:4437` -> Exit code 1 (Ditolak).
  - [x] Uji kasus gagal endpoint publik non-PQC `badssl.com:443` -> Exit code 1 (Ditolak).
- [x] **Penyusunan Laporan & Deliverables**
  - [x] Semua 24 file artefak tersimpan di `hasil_praktikum3/`.
  - [x] Laporan lengkap disusun di `LAPORAN_PRAKTIKUM_3.md`.
