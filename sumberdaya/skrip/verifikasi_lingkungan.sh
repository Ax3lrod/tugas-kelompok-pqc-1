#!/usr/bin/env bash
# verifikasi_lingkungan.sh
# Memeriksa seluruh prasyarat modul praktikum PQC.
# Jalankan ini SEBELUM memulai praktikum mana pun.
# Keluar dengan kode 0 jika semua siap, 1 jika ada yang kurang.

set -uo pipefail

HIJAU='\033[0;32m'; MERAH='\033[0;31m'; KUNING='\033[0;33m'; RESET='\033[0m'
GAGAL=0

lulus() { echo -e "  ${HIJAU}[ OK ]${RESET} $1"; }
gagal() { echo -e "  ${MERAH}[GAGAL]${RESET} $1"; echo -e "         ${KUNING}-> $2${RESET}"; GAGAL=1; }

echo
echo "=================================================="
echo " Verifikasi Lingkungan Praktikum PQC"
echo "=================================================="
echo

# --- 1. OpenSSL ---
echo "1. OpenSSL"
if command -v openssl >/dev/null 2>&1; then
    VER=$(openssl version | awk '{print $2}')
    MAYOR=$(echo "$VER" | cut -d. -f1)
    MINOR=$(echo "$VER" | cut -d. -f2)
    if [ "$MAYOR" -gt 3 ] || { [ "$MAYOR" -eq 3 ] && [ "$MINOR" -ge 5 ]; }; then
        lulus "openssl $VER (butuh >= 3.5)"
    else
        gagal "openssl $VER terlalu lama" "Lihat Lab Persiapan bagian 2: pasang OpenSSL 3.5+ berdampingan."
    fi
else
    gagal "openssl tidak ditemukan" "Pasang OpenSSL, lalu ulangi."
fi

# --- 2. Algoritma PQC di OpenSSL ---
echo
echo "2. Algoritma pasca-kuantum di OpenSSL"
if openssl list -kem-algorithms 2>/dev/null | grep -qi "ML-KEM"; then
    lulus "ML-KEM tersedia"
else
    gagal "ML-KEM tidak terdaftar" "OpenSSL Anda kemungkinan masih versi lama. Cek 'openssl version -a'."
fi
if openssl list -signature-algorithms 2>/dev/null | grep -qi "ML-DSA"; then
    lulus "ML-DSA tersedia"
else
    gagal "ML-DSA tidak terdaftar" "Sama seperti di atas: periksa versi OpenSSL yang aktif di PATH."
fi

# --- 3. Python ---
echo
echo "3. Python"
if command -v python3 >/dev/null 2>&1; then
    PYVER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    lulus "python3 $PYVER"
else
    gagal "python3 tidak ditemukan" "Pasang Python 3.10 atau lebih baru."
fi

# --- 4. Pustaka Python ---
echo
echo "4. Pustaka Python"
for modul in oqs cryptography; do
    if python3 -c "import $modul" 2>/dev/null; then
        lulus "modul '$modul' bisa diimpor"
    else
        gagal "modul '$modul' tidak bisa diimpor" "Aktifkan virtualenv lalu: pip install -r requirements.txt"
    fi
done

# --- 5. Alat jaringan ---
echo
echo "5. Alat bantu jaringan"
for alat in tcpdump; do
    if command -v $alat >/dev/null 2>&1; then
        lulus "$alat tersedia"
    else
        echo -e "  ${KUNING}[CATATAN]${RESET} $alat tidak ada (hanya dibutuhkan di Praktikum 3)"
    fi
done

# --- 6. Uji fungsional singkat ---
echo
echo "6. Uji fungsional (encap/decap sungguhan)"
TMP=$(mktemp -d)
if openssl genpkey -algorithm ML-KEM-768 -out "$TMP/sk.pem" 2>/dev/null \
   && openssl pkey -in "$TMP/sk.pem" -pubout -out "$TMP/pk.pem" 2>/dev/null \
   && openssl pkeyutl -encap -inkey "$TMP/pk.pem" -pubin -secret "$TMP/ss1.bin" -out "$TMP/ct.bin" 2>/dev/null \
   && openssl pkeyutl -decap -inkey "$TMP/sk.pem" -in "$TMP/ct.bin" -secret "$TMP/ss2.bin" 2>/dev/null \
   && cmp -s "$TMP/ss1.bin" "$TMP/ss2.bin"; then
    UKCT=$(wc -c < "$TMP/ct.bin")
    lulus "encap/decap ML-KEM-768 berhasil, ciphertext $UKCT byte"
    [ "$UKCT" -ne 1088 ] && echo -e "  ${KUNING}[CATATAN]${RESET} ciphertext biasanya 1088 byte. Catat kalau berbeda."
else
    gagal "uji encap/decap gagal" "Periksa lagi nomor 1 dan 2 di atas."
fi
rm -rf "$TMP"

echo
echo "=================================================="
if [ "$GAGAL" -eq 0 ]; then
    echo -e "${HIJAU} SEMUA SIAP. Silakan mulai Praktikum 1.${RESET}"
else
    echo -e "${MERAH} ADA YANG BELUM SIAP.${RESET}"
    echo " Perbaiki baris bertanda GAGAL, lalu jalankan skrip ini lagi."
    echo " Jangan lanjut ke praktikum sebelum skrip ini bersih."
fi
echo "=================================================="
exit $GAGAL
