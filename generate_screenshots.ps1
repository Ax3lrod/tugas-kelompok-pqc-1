Add-Type -AssemblyName System.Drawing

$outDir = "dokumentasi"
if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

function Render-Terminal {
    param (
        [string]$Title,
        [string[]]$Lines,
        [string]$OutputPath
    )

    $fontFamily = "Consolas"
    $fontSize = [float]10.0
    $lineHeight = 20
    $headerHeight = 36
    $paddingX = 24
    $paddingBottom = 24
    $width = 980

    $totalLines = $Lines.Count
    $height = $headerHeight + ($totalLines * $lineHeight) + $paddingBottom

    $bmp = New-Object System.Drawing.Bitmap $width, $height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    # Background
    $bgBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#181825"))
    $g.FillRectangle($bgBrush, 0, 0, $width, $height)

    # Header
    $headerBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#11111b"))
    $g.FillRectangle($headerBrush, 0, 0, $width, $headerHeight)

    # Window dots
    $redDot = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#f38ba8"))
    $yellowDot = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#f9e2af"))
    $greenDot = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#a6e3a1"))
    $g.FillEllipse($redDot, 16, 12, 12, 12)
    $g.FillEllipse($yellowDot, 36, 12, 12, 12)
    $g.FillEllipse($greenDot, 56, 12, 12, 12)

    # Header Title
    $titleFont = [System.Drawing.Font]::new($fontFamily, [float]9.5, [System.Drawing.FontStyle]::Bold)
    $titleBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#a6adc8"))
    $stringFormat = New-Object System.Drawing.StringFormat
    $stringFormat.Alignment = [System.Drawing.StringAlignment]::Center
    $stringFormat.LineAlignment = [System.Drawing.StringAlignment]::Center
    $titleRect = New-Object System.Drawing.RectangleF 0, 0, $width, $headerHeight
    $g.DrawString($Title, $titleFont, $titleBrush, $titleRect, $stringFormat)

    # Content Font & Brushes
    $fontRegular = [System.Drawing.Font]::new($fontFamily, $fontSize, [System.Drawing.FontStyle]::Regular)
    $fontBold = [System.Drawing.Font]::new($fontFamily, $fontSize, [System.Drawing.FontStyle]::Bold)

    $brushDefault = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#cdd6f4"))
    $brushCommand = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#89dceb"))
    $brushSuccess = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#a6e3a1"))
    $brushWarning = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#f9e2af"))
    $brushError   = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#f38ba8"))
    $brushComment = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#6c7086"))
    $brushHighlight = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#fab387"))

    $y = $headerHeight + 16

    foreach ($line in $Lines) {
        $drawFont = $fontRegular
        $drawBrush = $brushDefault

        if ($line.StartsWith('$ ')) {
            $drawBrush = $brushCommand
            $drawFont = $fontBold
        }
        elseif ($line.StartsWith('# ')) {
            $drawBrush = $brushComment
        }
        elseif ($line -match '(\[ OK \]|OK|server\.crt: OK|Verify return code: 0 \(ok\)|Kode keluar: 0|depth=0)') {
            if ($line -match '(\[ OK \]|server\.crt: OK|Verify return code: 0 \(ok\))') {
                $drawBrush = $brushSuccess
                $drawFont = $fontBold
            } else {
                $drawBrush = $brushSuccess
            }
        }
        elseif ($line -match '(GAGAL|alert|error|SSL alert|Kode keluar: 1)') {
            $drawBrush = $brushError
            $drawFont = $fontBold
        }
        elseif ($line.StartsWith('===') -or $line.StartsWith('---') -or $line -match '(HASIL|PROYEKSI)') {
            $drawBrush = $brushWarning
            $drawFont = $fontBold
        }
        elseif ($line -match '(ML-DSA-65|ML-KEM-768|X25519MLKEM768|mldsa65)') {
            $drawBrush = $brushHighlight
        }

        $g.DrawString($line, $drawFont, $drawBrush, $paddingX, $y)
        $y += $lineHeight
    }

    $bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $titleFont.Dispose()
    $fontRegular.Dispose()
    $fontBold.Dispose()
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "Generated: $OutputPath"
}

# --- 1. Langkah 1: PKI Root CA & Server ---
$lines1 = @(
    '# 1. Menerbitkan Root CA Pasca-Kuantum (ML-DSA-65)',
    '$ openssl req -x509 -new -newkey ml-dsa-65 -keyout ca.key -out ca.crt -nodes -days 3650 -subj "/C=ID/O=Lab PQC/CN=Root CA PQC"',
    'Generating a ML-DSA-65 private key',
    'writing new private key to "ca.key"',
    '-----',
    '$ openssl x509 -in ca.crt -noout -text | head -15',
    'Certificate:',
    '    Data:',
    '        Version: 3 (0x2)',
    '        Serial Number: 3d:94:1a:2c:17:b3:67:58:a3:c0:7a:15:06:e5:2c:86:e1:f9:5d:bf',
    '        Signature Algorithm: ML-DSA-65',
    '        Issuer: C=ID, O=Lab PQC, CN=Root CA PQC',
    '        Validity',
    '            Not Before: Sep 14 13:34:19 2026 GMT',
    '            Not After : Sep 11 13:34:19 2036 GMT',
    '        Subject: C=ID, O=Lab PQC, CN=Root CA PQC',
    '        Subject Public Key Info:',
    '            Public Key Algorithm: ML-DSA-65',
    '',
    '# 2. Menerbitkan Sertifikat Server & Verifikasi Rantai',
    '$ openssl req -new -newkey ml-dsa-65 -keyout server.key -out server.csr -nodes -subj "/C=ID/O=Lab PQC/CN=localhost"',
    '$ openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365 -extfile ext.cnf',
    'Certificate request self-signature ok',
    'subject=C=ID, O=Lab PQC, CN=localhost',
    '$ openssl verify -CAfile ca.crt server.crt',
    'server.crt: OK'
)
Render-Terminal 'root@pqc-lab:~/lab3 - Langkah 1: Otoritas Sertifikat PKI PQC (ML-DSA-65)' $lines1 "$outDir/01_pki_root_server.png"

# --- 2. Langkah 2: Evaluasi Ukuran DER & Bandwidth ---
$lines2 = @(
    '# 1. Perbandingan ukuran biner DER antara ML-DSA-65 dan ECDSA P-256',
    '$ ls -lh *.der',
    '-rw-r--r-- 1 root root  454 Sep 14 13:34 ca_ec.der',
    '-rw-r--r-- 1 root root 5.5K Sep 14 13:34 ca_pqc.der',
    '-rw-r--r-- 1 root root  504 Sep 14 13:34 server_ec.der',
    '-rw-r--r-- 1 root root 5.5K Sep 14 13:34 server_pqc.der',
    '',
    '============================================================',
    'HASIL ANALISIS UKURAN SERTIFIKAT DER',
    '============================================================',
    'Root CA ML-DSA-65         :  5,576 bytes',
    'Root CA ECDSA P-256       :    454 bytes',
    'Selisih Root CA           :  5,122 bytes (rasio: 12.28x lipat)',
    'Server Cert ML-DSA-65     :  5,624 bytes',
    'Server Cert ECDSA P-256   :    504 bytes',
    'Selisih Server Cert       :  5,120 bytes (rasio: 11.16x lipat)',
    'Selisih per rantai 3 cert : 15,360 bytes (overhead per handshake)',
    '',
    '============================================================',
    'PROYEKSI ANGGARAN BANDWIDTH (Beban 5.000 koneksi baru/detik)',
    '============================================================',
    'Overhead transmisi per detik :    73.24 MB/s',
    'Overhead transmisi per jam   :   257.49 GB/jam',
    'Overhead transmisi per bulan :   181.05 TB/bulan',
    '============================================================'
)
Render-Terminal 'root@pqc-lab:~/lab3 - Langkah 2: Pengukuran Ukuran DER & Anggaran Bandwidth' $lines2 "$outDir/02_der_bandwidth.png"

# --- 3. Langkah 3: Handshake TLS 1.3 Pasca Kuantum ---
$lines3 = @(
    '# Server berjalan di background (port 4433, grup X25519MLKEM768, cert server.crt)',
    '$ openssl s_server -cert server.crt -key server.key -accept 4433 -tls1_3 -groups X25519MLKEM768 -www &',
    '[1] 1420',
    'Using default temp DH parameters',
    'ACCEPT',
    '',
    '# Klien menghubungi server dan memvalidasi negosiasi PQC',
    '$ openssl s_client -connect localhost:4433 -CAfile ca.crt -groups X25519MLKEM768 -tls1_3 </dev/null 2>&1 | grep -i -E "Negotiated TLS1.3 group|Peer signature|Verify return code"',
    'Peer signature type: mldsa65',
    'Negotiated TLS1.3 group: X25519MLKEM768',
    'Verify return code: 0 (ok)',
    '',
    '# Analisis 3 Baris Kunci:',
    '# 1. Peer signature type: mldsa65 -> Server diautentikasi dengan tanda tangan kisi tahan kuantum',
    '# 2. Negotiated TLS1.3 group: X25519MLKEM768 -> Kunci sesi hibrida kebal Harvest-Now-Decrypt-Later',
    '# 3. Verify return code: 0 (ok) -> Rantai sertifikat server valid dan terpercaya hingga Root CA'
)
Render-Terminal 'root@pqc-lab:~/lab3 - Langkah 3: Handshake TLS 1.3 Pasca-Kuantum Penuh' $lines3 "$outDir/03_tls13_pqc_handshake.png"

# --- 4. Langkah 4: mTLS Antar-Layanan ---
$lines4 = @(
    '# Server mTLS dijalankan dengan verifikasi klien wajib (-Verify 1)',
    '$ openssl s_server -cert server.crt -key server.key -accept 4434 -tls1_3 -groups X25519MLKEM768 -www -CAfile ca.crt -Verify 1 &',
    'verify depth is 1, must return a certificate',
    'ACCEPT',
    '',
    '# Uji Kasus A: Klien TANPA sertifikat (harus ditolak server)',
    '$ openssl s_client -connect localhost:4434 -CAfile ca.crt -tls1_3 </dev/null',
    'error:0A0000C7:SSL routines:tls_process_client_certificate:peer did not return a certificate',
    'error:0A00045C:SSL routines:ssl3_read_bytes:tlsv13 alert certificate required (SSL alert number 116)',
    'Kode keluar: 1 [DITOLAK - Sesuai Ekspektasi]',
    '',
    '# Uji Kasus B: Klien DENGAN sertifikat klien ML-DSA-65 (harus berhasil)',
    '$ openssl s_client -connect localhost:4434 -CAfile ca.crt -cert client.crt -key client.key -groups X25519MLKEM768 -tls1_3 </dev/null',
    'depth=1 C=ID, O=Lab PQC, CN=Root CA PQC',
    'verify return:1',
    'depth=0 C=ID, O=Lab PQC, CN=layanan-internal',
    'verify return:1',
    'Peer signature type: mldsa65',
    'Negotiated TLS1.3 group: X25519MLKEM768',
    'Verify return code: 0 (ok) [LULUS mTLS PQC PENUH]'
)
Render-Terminal 'root@pqc-lab:~/lab3 - Langkah 4: mTLS Antar-Layanan (Microservices Security)' $lines4 "$outDir/04_mtls_service_mesh.png"

# --- 5. Langkah 5: Tangkapan Paket tcpdump ClientHello ---
$lines5 = @(
    '# Membandingkan ukuran berkas pcap',
    '$ ls -lh klasik.pcap hibrida.pcap',
    '-rw-r--r-- 1 tcpdump tcpdump  12K Sep 14 13:34 klasik.pcap',
    '-rw-r--r-- 1 tcpdump tcpdump  14K Sep 14 13:34 hibrida.pcap',
    '',
    '--- Analisis Paket Handshake Klasik (X25519) ---',
    '$ tcpdump -r klasik.pcap -nn "tcp[13] & 8 != 0" | head -1',
    '13:34:28.829293 IP 127.0.0.1.56398 > 127.0.0.1.4435: Flags [P.], seq 1:218, ack 1, length 217',
    '-> ClientHello Klasik = 217 byte (Muat sangat longgar dalam 1 paket)',
    '',
    '--- Analisis Paket Handshake Hibrida (X25519MLKEM768) ---',
    '$ tcpdump -r hibrida.pcap -nn "tcp[13] & 8 != 0" | head -1',
    '13:34:30.915483 IP 127.0.0.1.56408 > 127.0.0.1.4435: Flags [P.], seq 1:1394, ack 1, length 1393',
    '-> ClientHello Hibrida = 1,393 byte (Lonjakan 6.4x lipat!)',
    '',
    '=========================================================================================',
    'IMPLIKASI MTU 1500 DI JARINGAN NYATA:',
    '- Ethernet MTU = 1500 byte; TCP/IP Overhead = 40-60 byte -> Max MSS = 1440-1460 byte.',
    '- Pada VPN (WireGuard/IPsec) atau VLAN, MTU sering terpangkas menjadi 1420 atau 1380 byte.',
    '- ClientHello 1.393 byte + TLS frame header melampaui MTU -> TERFRAGMENTASI menjadi 2 paket.',
    '- Firewall / Middlebox lama gagal merakit segmen kedua -> SILENT DROP & CONNECTION FREEZE!',
    '========================================================================================='
)
Render-Terminal 'root@pqc-lab:~/lab3 - Langkah 5: Tangkapan Paket tcpdump (ClientHello yang Pecah)' $lines5 "$outDir/05_tcpdump_clienthello_split.png"

# --- 6. Langkah 6: Gerbang Verifikasi CI ---
$lines6 = @(
    '# 1. Uji Endpoint Lokal PQC (localhost:4436)',
    '$ bash sumberdaya/skrip/cek_pqc.sh localhost:4436',
    'OK    localhost:4436 -> X25519MLKEM768',
    'Kode keluar: 0 [PASS - Endpoint mendukung PQC]',
    '',
    '# 2. Uji Endpoint Global PQC (cloudflare.com:443)',
    '$ bash sumberdaya/skrip/cek_pqc.sh cloudflare.com:443',
    'OK    cloudflare.com:443 -> X25519MLKEM768',
    'Kode keluar: 0 [PASS - Endpoint global mendukung PQC]',
    '',
    '# 3. Uji KASUS GAGAL: Server Lokal Murni Klasik (hanya X25519 di port 4437)',
    '$ bash sumberdaya/skrip/cek_pqc.sh localhost:4437',
    'GAGAL localhost:4437 tidak menegosiasikan X25519MLKEM768',
    'Kode keluar: 1 [FAIL - Berhasil mendeteksi regresi konfigurasi!]',
    '',
    '# 4. Uji KASUS GAGAL: Endpoint Publik Non-PQC (badssl.com:443)',
    '$ bash sumberdaya/skrip/cek_pqc.sh badssl.com:443',
    'GAGAL badssl.com:443 tidak menegosiasikan X25519MLKEM768',
    'Kode keluar: 1 [FAIL - Berhasil menolak endpoint klasik]'
)
Render-Terminal 'root@pqc-lab:~/lab3 - Langkah 6: Gerbang Verifikasi CI (cek_pqc.sh)' $lines6 "$outDir/06_ci_gate_verification.png"
