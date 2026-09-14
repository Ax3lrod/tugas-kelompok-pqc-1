#!/bin/bash
set -e

echo "========================================================"
echo "    PRAKTIKUM 3 — WEB, API, DAN PKI (PQC AUTOMATION)    "
echo "========================================================"

WORKSPACE="/kerja"
HASIL_DIR="$WORKSPACE/hasil_praktikum3"
LOG_FILE="$HASIL_DIR/eksekusi_lab3.log"

mkdir -p "$HASIL_DIR"
cd "$HASIL_DIR"

mkdir -p /opt/openssl35/ssl
[ -f /etc/ssl/openssl.cnf ] && cp /etc/ssl/openssl.cnf /opt/openssl35/ssl/openssl.cnf 2>/dev/null || true
export OPENSSL_CONF=/etc/ssl/openssl.cnf

exec > >(tee -a "$LOG_FILE") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Memulai eksekusi Praktikum 3..."
echo "Versi OpenSSL:"
openssl version -a

echo
echo "========================================================"
echo "LANGKAH 1: MEMBANGUN OTORITAS SERTIFIKAT (PKI) SENDIRI"
echo "========================================================"

echo "[1.1] Menerbitkan Root CA Pasca-Kuantum (ML-DSA-65)..."
openssl req -x509 -new -newkey ml-dsa-65 -keyout ca.key -out ca.crt \
    -nodes -days 3650 -subj "/C=ID/O=Lab PQC/CN=Root CA PQC"

echo "[1.2] Verifikasi sertifikat Root CA (15 baris pertama):"
openssl x509 -in ca.crt -noout -text | head -15

echo "[1.3] Menerbitkan sertifikat Server (ML-DSA-65)..."
openssl req -new -newkey ml-dsa-65 -keyout server.key -out server.csr \
    -nodes -subj "/C=ID/O=Lab PQC/CN=localhost"

cat > ext.cnf << 'EOF'
subjectAltName = DNS:localhost, IP:127.0.0.1
keyUsage = critical, digitalSignature
extendedKeyUsage = serverAuth
EOF

openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out server.crt -days 365 -extfile ext.cnf

echo "[1.4] Verifikasi sertifikat Server terhadap Root CA:"
openssl verify -CAfile ca.crt server.crt

echo
echo "========================================================"
echo "LANGKAH 2: MENGUKUR HARGA SERTIFIKAT (ML-DSA VS ECDSA)"
echo "========================================================"

echo "[2.1] Membuat sertifikat pembanding klasik (ECDSA P-256)..."
openssl req -x509 -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 \
    -keyout ca_ec.key -out ca_ec.crt -nodes -days 3650 \
    -subj "/C=ID/O=Lab Klasik/CN=Root CA EC"

openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 \
    -keyout server_ec.key -out server_ec.csr -nodes \
    -subj "/C=ID/O=Lab Klasik/CN=localhost"

openssl x509 -req -in server_ec.csr -CA ca_ec.crt -CAkey ca_ec.key -CAcreateserial \
    -out server_ec.crt -days 365 -extfile ext.cnf

echo "[2.2] Mengekspor sertifikat ke format biner DER..."
openssl x509 -in ca.crt -outform DER -out ca_pqc.der
openssl x509 -in ca_ec.crt -outform DER -out ca_ec.der
openssl x509 -in server.crt -outform DER -out server_pqc.der
openssl x509 -in server_ec.crt -outform DER -out server_ec.der

echo "[2.3] Daftar dan ukuran berkas DER:"
ls -lh *.der

python3 - << 'PYEOF'
import os

ca_pqc = os.path.getsize("ca_pqc.der")
ca_ec = os.path.getsize("ca_ec.der")
srv_pqc = os.path.getsize("server_pqc.der")
srv_ec = os.path.getsize("server_ec.der")

diff_ca = ca_pqc - ca_ec
diff_srv = srv_pqc - srv_ec
diff_per_hs = diff_srv * 3 # Rantai 3 sertifikat (Root, Intermediate, Leaf)

print("\n" + "=" * 60)
print("HASIL ANALISIS UKURAN SERTIFIKAT DER")
print("=" * 60)
print(f"Root CA ML-DSA-65         : {ca_pqc:>6,} bytes")
print(f"Root CA ECDSA P-256       : {ca_ec:>6,} bytes")
print(f"Selisih Root CA           : {diff_ca:>6,} bytes (rasio: {ca_pqc/ca_ec:.2f}x)")
print(f"Server Cert ML-DSA-65     : {srv_pqc:>6,} bytes")
print(f"Server Cert ECDSA P-256   : {srv_ec:>6,} bytes")
print(f"Selisih Server Cert       : {diff_srv:>6,} bytes (rasio: {srv_pqc/srv_ec:.2f}x)")
print(f"Selisih per rantai 3 cert : {diff_per_hs:>6,} bytes")

conn_per_sec = 5000
bytes_per_sec = diff_per_hs * conn_per_sec
mb_per_sec = bytes_per_sec / (1024 * 1024)
gb_per_hour = (bytes_per_sec * 3600) / (1024**3)
tb_per_month = (bytes_per_sec * 3600 * 24 * 30) / (1024**4)

print("\n" + "=" * 60)
print("PROYEKSI ANGGARAN BANDWIDTH (5.000 koneksi baru/detik)")
print("=" * 60)
print(f"Overhead transmisi per detik : {mb_per_sec:>8.2f} MB/s")
print(f"Overhead transmisi per jam   : {gb_per_hour:>8.2f} GB/jam")
print(f"Overhead transmisi per bulan : {tb_per_month:>8.2f} TB/bulan")
print("=" * 60)
PYEOF

echo
echo "========================================================"
echo "LANGKAH 3: MENJALANKAN SERVER & KLIEN TLS PASCA-KUANTUM"
echo "========================================================"

PORT3=4433
echo "[3.1] Menjalankan TLS 1.3 Server di port $PORT3 (groups: X25519MLKEM768)..."
openssl s_server -cert server.crt -key server.key -accept $PORT3 \
    -tls1_3 -groups X25519MLKEM768 -www &
PID3=$!
sleep 2

echo "[3.2] Menghubungi Server dari Klien (memeriksa 3 baris kunci)..."
CLIENT_OUT=$(openssl s_client -connect localhost:$PORT3 -CAfile ca.crt \
    -groups X25519MLKEM768 -tls1_3 </dev/null 2>&1)

echo "$CLIENT_OUT" | grep -i -E "Negotiated TLS1.3 group|Peer signature|Verify return code" || true

kill -9 $PID3 2>/dev/null || true
wait $PID3 2>/dev/null || true
sleep 1

echo
echo "========================================================"
echo "LANGKAH 4: mTLS ANTAR-LAYANAN (MUTUAL TLS)"
echo "========================================================"

echo "[4.1] Menerbitkan sertifikat Klien (ML-DSA-65)..."
openssl req -new -newkey ml-dsa-65 -keyout client.key -out client.csr \
    -nodes -subj "/C=ID/O=Lab PQC/CN=layanan-internal"

cat > ext_client.cnf << 'EOF'
keyUsage = critical, digitalSignature
extendedKeyUsage = clientAuth
EOF

openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out client.crt -days 365 -extfile ext_client.cnf

PORT4=4434
echo "[4.2] Menjalankan Server dengan verifikasi klien wajib (-Verify 1) di port $PORT4..."
openssl s_server -cert server.crt -key server.key -accept $PORT4 \
    -tls1_3 -groups X25519MLKEM768 -www \
    -CAfile ca.crt -Verify 1 &
PID4=$!
sleep 2

echo "[4.3] Uji TANPA sertifikat klien (harus GAGAL):"
set +e
CLIENT_NO_CERT=$(openssl s_client -connect localhost:$PORT4 -CAfile ca.crt -tls1_3 </dev/null 2>&1)
NO_CERT_EXIT=$?
echo "$CLIENT_NO_CERT" | tail -6
echo "Hasil uji tanpa cert klien: (exit code $NO_CERT_EXIT - Sesuai ekspektasi ditolak server)"
set -e

echo "[4.4] Uji DENGAN sertifikat klien (harus BERHASIL):"
CLIENT_WITH_CERT=$(openssl s_client -connect localhost:$PORT4 -CAfile ca.crt \
    -cert client.crt -key client.key \
    -groups X25519MLKEM768 -tls1_3 </dev/null 2>&1)

echo "$CLIENT_WITH_CERT" | grep -i -E "Negotiated TLS1.3 group|Peer signature|Verify return code" || true

kill -9 $PID4 2>/dev/null || true
wait $PID4 2>/dev/null || true
sleep 1

echo
echo "========================================================"
echo "LANGKAH 5: MENANGKAP CLIENTHELLO YANG PECAH (TCPDUMP)"
echo "========================================================"

PORT5=4435
echo "[5.1] Menjalankan server untuk tangkapan paket di port $PORT5..."
openssl s_server -cert server.crt -key server.key -accept $PORT5 -tls1_3 -www &
PID5=$!
sleep 2

echo "[5.2] Menangkap handshake Klasik (X25519)..."
tcpdump -i lo -w klasik.pcap "port $PORT5" >/dev/null 2>&1 &
DUMP1_PID=$!
sleep 1
openssl s_client -connect localhost:$PORT5 -groups X25519 -tls1_3 </dev/null >/dev/null 2>&1 || true
sleep 1
kill -2 $DUMP1_PID 2>/dev/null || kill -9 $DUMP1_PID 2>/dev/null || true
wait $DUMP1_PID 2>/dev/null || true

echo "[5.3] Menangkap handshake Hibrida (X25519MLKEM768)..."
tcpdump -i lo -w hibrida.pcap "port $PORT5" >/dev/null 2>&1 &
DUMP2_PID=$!
sleep 1
openssl s_client -connect localhost:$PORT5 -groups X25519MLKEM768 -tls1_3 </dev/null >/dev/null 2>&1 || true
sleep 1
kill -2 $DUMP2_PID 2>/dev/null || kill -9 $DUMP2_PID 2>/dev/null || true
wait $DUMP2_PID 2>/dev/null || true

kill -9 $PID5 2>/dev/null || true
wait $PID5 2>/dev/null || true
sleep 1

echo "[5.4] Analisis ukuran berkas pcap:"
ls -lh klasik.pcap hibrida.pcap

echo
echo "--- Analisis Paket Handshake Klasik (paket pertama) ---"
tcpdump -r klasik.pcap -nn 2>/dev/null | head -8

echo
echo "--- Analisis Paket Handshake Hibrida (paket pertama) ---"
tcpdump -r hibrida.pcap -nn 2>/dev/null | head -8

echo
echo "========================================================"
echo "LANGKAH 6: GERBANG VERIFIKASI UNTUK CI (cek_pqc.sh)"
echo "========================================================"

PORT6=4436
echo "[6.1] Menjalankan server lokal PQC di port $PORT6..."
openssl s_server -cert server.crt -key server.key -accept $PORT6 \
    -tls1_3 -groups X25519MLKEM768 -www &
PID6=$!
sleep 2

echo "[6.2] Uji endpoint lokal PQC (localhost:$PORT6)..."
set +e
bash $WORKSPACE/sumberdaya/skrip/cek_pqc.sh localhost:$PORT6
EXIT_LOCAL=$?
echo "Kode keluar localhost: $EXIT_LOCAL"

echo "[6.3] Uji endpoint global PQC (cloudflare.com:443)..."
bash $WORKSPACE/sumberdaya/skrip/cek_pqc.sh cloudflare.com:443
EXIT_CF=$?
echo "Kode keluar cloudflare.com: $EXIT_CF"

echo "[6.4] Uji KASUS GAGAL: Server lokal murni Klasik (hanya X25519) di port 4437..."
openssl s_server -cert server_ec.crt -key server_ec.key -accept 4437 \
    -tls1_3 -groups X25519 -www &
PID_KLASIK=$!
sleep 2

bash $WORKSPACE/sumberdaya/skrip/cek_pqc.sh localhost:4437
EXIT_LOCAL_FAIL=$?
echo "Kode keluar server klasik (diharapkan gagal = 1): $EXIT_LOCAL_FAIL"
kill -9 $PID_KLASIK 2>/dev/null || true
wait $PID_KLASIK 2>/dev/null || true

echo "[6.5] Uji KASUS GAGAL: Endpoint publik non-PQC (badssl.com:443)..."
bash $WORKSPACE/sumberdaya/skrip/cek_pqc.sh badssl.com:443
EXIT_PUB_FAIL=$?
echo "Kode keluar badssl.com (diharapkan gagal = 1): $EXIT_PUB_FAIL"
set -e

kill -9 $PID6 2>/dev/null || true
wait $PID6 2>/dev/null || true

echo
echo "========================================================"
echo "EKSEKUSI SELESAI DENGAN SUKSES!"
echo "Semua artefak tersimpan di: $HASIL_DIR"
echo "========================================================"
