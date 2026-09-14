# Format Dataset Survei Kesiapan PQC Domain `.id`

Dataset ini tumbuh dari kontribusi pembaca. Kalau Anda mengerjakan
Praktikum 1, hasil Anda bisa ikut masuk ke sini.

## Kolom

| Kolom | Isi | Contoh |
|---|---|---|
| `domain` | nama host tanpa skema | `contoh.ac.id` |
| `sektor` | salah satu: pendidikan, perbankan, pemerintah, ecommerce, kesehatan, media, lainnya | `pendidikan` |
| `mendukung_pqc` | `ya` atau `tidak` | `ya` |
| `grup_ternegosiasi` | nama grup jika mendukung, kosong jika tidak | `X25519MLKEM768` |
| `tanggal_uji` | format ISO, YYYY-MM-DD | `2026-09-08` |

## Aturan pengumpulan

1. Uji hanya lewat handshake TLS biasa. Jangan lakukan pemindaian
   agresif, jangan uji endpoint di balik autentikasi, jangan sentuh
   apa pun di luar port 443.
2. Uji setiap domain minimal dua kali pada waktu berbeda. Jaringan
   bisa berbohong sekali, jarang berbohong dua kali.
3. Laporkan apa adanya. Domain yang gagal dihubungi ditulis sebagai
   gagal, bukan dihapus diam-diam. Data yang rapi karena disortir
   adalah data yang rusak.
4. Cantumkan tanggal. Hasil hari ini bisa berbeda dari bulan depan,
   dan justru perubahannya yang menarik.

## Etika

Yang Anda lakukan setara dengan mengetuk pintu depan dan mencatat
apakah pintunya terbuka. Itu wajar. Yang tidak wajar adalah mencoba
masuk. Batasi diri pada handshake, dan jangan pernah menguji sistem
yang secara eksplisit melarang pengujian otomatis.
