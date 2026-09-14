#!/usr/bin/env bash
# survei_domain.sh <berkas-daftar-domain> [berkas-keluaran.csv]
# Menguji dukungan hybrid key exchange pada sekumpulan domain.
# Keluaran CSV siap digabungkan ke dataset bersama.
#
# Format berkas masukan: satu domain per baris, boleh diikuti sektor
#   ui.ac.id,pendidikan
#   bri.co.id,perbankan

set -uo pipefail

MASUKAN="${1:-}"
KELUARAN="${2:-hasil-survei.csv}"
GRUP="X25519MLKEM768"

[ -z "$MASUKAN" ] && { echo "Pemakaian: $0 <daftar-domain.txt> [keluaran.csv]"; exit 2; }
[ ! -f "$MASUKAN" ] && { echo "Berkas tidak ditemukan: $MASUKAN"; exit 2; }

echo "domain,sektor,mendukung_pqc,grup_ternegosiasi,tanggal_uji" > "$KELUARAN"

TOTAL=0; DUKUNG=0

while IFS=, read -r domain sektor; do
    domain=$(echo "$domain" | tr -d ' \r')
    sektor=$(echo "${sektor:-tidak-diketahui}" | tr -d ' \r')
    [ -z "$domain" ] && continue
    [[ "$domain" == \#* ]] && continue

    TOTAL=$((TOTAL+1))
    HASIL=$(timeout 15 openssl s_client -connect "${domain}:443" -groups "$GRUP" \
            </dev/null 2>/dev/null | grep -i "Negotiated TLS1.3 group" || true)

    if echo "$HASIL" | grep -qi "$GRUP"; then
        DUKUNG=$((DUKUNG+1))
        printf "  %-32s YA\n" "$domain"
        echo "$domain,$sektor,ya,$GRUP,$(date -I)" >> "$KELUARAN"
    else
        printf "  %-32s tidak\n" "$domain"
        echo "$domain,$sektor,tidak,,$(date -I)" >> "$KELUARAN"
    fi
done < "$MASUKAN"

echo
echo "Selesai. $DUKUNG dari $TOTAL domain mendukung $GRUP."
[ "$TOTAL" -gt 0 ] && echo "Persentase: $(( DUKUNG * 100 / TOTAL ))%"
echo "Hasil tersimpan di: $KELUARAN"
