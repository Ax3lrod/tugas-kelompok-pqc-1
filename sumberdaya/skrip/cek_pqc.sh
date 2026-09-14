#!/usr/bin/env bash
# cek_pqc.sh <host:port> [grup]
# Memeriksa apakah sebuah endpoint mau menegosiasikan hybrid key exchange.
# Dirancang untuk dipakai di pipeline CI: exit 0 kalau mendukung, 1 kalau tidak.
#
# Contoh:
#   ./cek_pqc.sh cloudflare.com:443
#   ./cek_pqc.sh api.kampus.ac.id:443 X25519MLKEM768

set -uo pipefail

TARGET="${1:-}"
GRUP="${2:-X25519MLKEM768}"

if [ -z "$TARGET" ]; then
    echo "Pemakaian: $0 <host:port> [nama-grup]"
    exit 2
fi

HASIL=$(timeout 15 openssl s_client -connect "$TARGET" -groups "$GRUP" \
        </dev/null 2>/dev/null | grep -i "Negotiated TLS1.3 group" || true)

if echo "$HASIL" | grep -qi "$GRUP"; then
    echo "OK    $TARGET -> ${HASIL##*: }"
    exit 0
else
    echo "GAGAL $TARGET tidak menegosiasikan $GRUP"
    exit 1
fi
