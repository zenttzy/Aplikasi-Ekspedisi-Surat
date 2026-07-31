# Aplikasi Ekspedisi Surat — Kurir Flutter

Aplikasi Android untuk kurir dalam menerima dan mengantarkan surat ekspedisi. Aplikasi terhubung ke REST API milik perusahaan dan dirancang **offline-first**, sehingga kurir tetap dapat mengambil surat, mengisi nama penerima, mengambil foto bukti, serta merekam lokasi ketika berada di area tanpa internet.

## Kompatibilitas Android

Aplikasi membutuhkan Android 6.0 / API 23 atau lebih baru karena fitur scanner QR menggunakan CameraX. Build Android dikompilasi menggunakan SDK 36.

## Fitur Utama

- Login kurir menggunakan akun dari backend perusahaan.
- Scan QR Tata Usaha untuk pairing satu kurir dengan satu akun TU.
- Profil menampilkan divisi dan nama Tata Usaha penanggung jawab yang terhubung.
- Dashboard dengan statistik surat dan tugas prioritas.
- Navigasi Android-style: **Home, Aktivitas, Riwayat, dan Akun**.
- Daftar surat baru yang perlu dikirimkan.
- Badge notifikasi untuk tugas baru.
- Pengambilan tugas oleh kurir.
- Input nama penerima sebelum mengambil bukti foto.
- Foto bukti dengan watermark:
  - Nomor surat.
  - Nama penerima.
  - Koordinat GPS.
  - Alamat lokasi.
  - Waktu pengambilan foto.
- Hash SHA-256 untuk membantu menjaga integritas foto.
- Upload bukti foto ke website.
- Penyimpanan lokal SQLite untuk mode offline.
- Sinkronisasi otomatis saat koneksi internet kembali.
- Antrean upload dengan indikator status pending.
- Push notification Firebase Cloud Messaging untuk surat baru.
- Halaman **Cara Pemakaian** di menu Akun.
- Dukungan tampilan putih dengan warna utama biru.

## Alur Penggunaan Kurir

```text
Kurir scan QR Tata Usaha dari tab Akun (online)
        ↓
Akun TU membuat surat di website
        ↓
Surat berstatus Draft dan hanya ditugaskan ke kurir pasangan TU
        ↓
Surat masuk ke aplikasi kurir tersebut
        ↓
Kurir menerima notifikasi atau melihat badge Aktivitas
        ↓
Kurir menekan Ambil Tugas
        ↓
Status surat menjadi Dikirim
        ↓
Kurir memasukkan nama penerima
        ↓
Kurir mengambil foto bukti pengiriman
        ↓
Foto diberi watermark GPS, alamat, waktu, dan nama penerima
        ↓
Status lokal menjadi Diterima
        ↓
Data dikirim ke server
        ↓
Bukti tampil pada website
```

### Status Surat

| Status | Keterangan |
|---|---|
| `draft` | Surat baru dibuat dan belum diambil kurir. |
| `dikirim` | Surat sudah diambil kurir dan sedang diantar. |
| `diterima` | Surat sudah selesai diantar dan bukti pengiriman tersimpan. |

## Pairing Tata Usaha dan Kurir

Sebelum menerima tugas, kurir harus terhubung dengan akun Tata Usaha:

1. TU login ke website dan membuka menu **Hubungkan Kurir**.
2. TU menekan **Buat QR koneksi**.
3. Kurir membuka tab **Akun** di aplikasi lalu menekan **Scan QR Tata Usaha**.
4. Kurir scan QR sebelum masa berlaku 5 menit berakhir.
5. Aplikasi menyegarkan profil dan daftar surat setelah pairing berhasil.

Satu kurir hanya dapat terhubung ke satu akun TU aktif. Jika kurir scan QR dari TU lain, hubungan sebelumnya diputus. Surat yang telah menjadi milik kurir sebelumnya tetap tidak berpindah, sedangkan surat baru mengikuti pairing terbaru. Pairing selalu membutuhkan internet; proses pengantaran tetap mendukung mode offline setelah pairing selesai.

## Mode Offline

Aplikasi menggunakan SQLite sebagai penyimpanan lokal utama. Data tetap dapat diproses ketika perangkat tidak terhubung ke internet.

### Saat offline

Kurir tetap dapat:

1. Membuka daftar surat yang sudah tersimpan di perangkat.
2. Mengambil tugas pengiriman.
3. Mengisi nama penerima.
4. Mengambil foto bukti.
5. Merekam GPS dan alamat.
6. Melihat indikator perubahan yang menunggu sinkronisasi.

### Saat online kembali

`SyncManager` otomatis menjalankan proses berikut:

1. Mengirim klaim surat ke server melalui `PUT /api/surat/:uuid`.
2. Mengupload foto bukti melalui `POST /api/surat/:uuid/bukti`.
3. Mengirim nama penerima, GPS, alamat, dan hash foto.
4. Mengambil data surat terbaru dari `GET /api/surat`.
5. Menghapus status pending lokal setelah server mengonfirmasi keberhasilan.

Jika upload gagal sementara, data lokal tidak dihapus. Sinkronisasi akan dicoba kembali ketika koneksi berubah atau melalui retry periodik.

> Jangan logout atau menghapus aplikasi ketika masih ada perubahan pending. Foto bukti disimpan di penyimpanan lokal sampai proses upload berhasil.

## API Backend

Aplikasi menggunakan backend REST perusahaan, bukan Supabase.

URL default:

```text
http://43.134.228.34:3001/api
```

URL production untuk GitHub Actions disimpan pada `env/production.json`. Untuk pindah ke server PT, ubah nilai `API_BASE_URL` pada file tersebut, lalu jalankan workflow build ulang. Untuk menjalankan lokal dengan konfigurasi yang sama, gunakan `--dart-define-from-file=env/production.json`.

### Endpoint yang digunakan

| Method | Endpoint | Fungsi |
|---|---|---|
| `POST` | `/api/auth/login` | Login kurir. |
| `GET` | `/api/auth/me` | Memeriksa sesi akun. |
| `POST` | `/api/pairing/claim` | Menghubungkan kurir dengan QR Tata Usaha. |
| `GET` | `/api/pairing/status` | Membaca koneksi TU yang aktif pada profil kurir. |
| `GET` | `/api/surat` | Mengambil daftar surat. |
| `PUT` | `/api/surat/:uuid` | Mengambil/menetapkan surat kepada kurir. |
| `POST` | `/api/surat/:uuid/bukti` | Mengupload bukti pengiriman multipart. |
| `POST` | `/api/users/device-token` | Mendaftarkan token FCM perangkat. |

### Payload upload bukti

Endpoint bukti menggunakan `multipart/form-data` dengan field:

```text
foto          File foto watermark
lat           Latitude GPS
long          Longitude GPS
nama_penerima Nama penerima surat
foto_hash     Hash SHA-256 foto
```

## Struktur Project

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/                  Konfigurasi API dan konstanta aplikasi
│   ├── database/                SQLite dan migrasi schema
│   ├── di/                      Dependency injection dengan get_it
│   ├── network/                 Dio, konektivitas, dan secure storage
│   ├── notifications/           Firebase Cloud Messaging dan notifikasi lokal
│   ├── sync/                    Queue offline dan sinkronisasi REST
│   └── utils/                   Watermark dan hash foto
└── features/
    ├── account/                 Akun, scanner QR, dan Cara Pemakaian
    ├── activity/                Daftar aktivitas/tugas
    ├── auth/                    Login dan autentikasi
    ├── dashboard/               Dashboard kurir
    ├── expeditions/             Model, API, kamera, detail surat
    ├── history/                 Riwayat surat selesai
    └── home/                    Shell navigasi aplikasi
```

## Persyaratan Development

- Flutter stable `3.29.x` / Dart `3.5.4`.
- Java `17` untuk Android build.
- Android SDK sesuai konfigurasi Flutter.
- Perangkat Android atau emulator.
- Backend ekspedisi surat aktif jika ingin menguji fitur online.

Jangan menjalankan `flutter upgrade` sembarangan karena versi Flutter dan dependency saat ini dikunci untuk menjaga kompatibilitas build Android.

## Setup Lokal

Clone repository lalu masuk ke folder project:

```bash
git clone https://github.com/zenttzy/Aplikasi-Ekspedisi-Surat.git
cd Aplikasi-Ekspedisi-Surat
flutter pub get
```

Pastikan file Firebase Android tersedia di:

```text
android/app/google-services.json
```

File tersebut berisi konfigurasi aplikasi Firebase Android. **Jangan pernah menambahkan Firebase service account JSON atau private key ke repository public.**

## Menjalankan Aplikasi

Gunakan URL API production dari file konfigurasi:

```bash
flutter run --dart-define-from-file=env/production.json
```

Atau gunakan URL backend lain:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://domain-backend-anda/api
```

Melihat daftar device:

```bash
flutter devices
```

Menjalankan pada device tertentu:

```bash
flutter run -d <device_id>
```

## Validasi Lokal

Sebelum push:

```bash
flutter pub get
flutter analyze
flutter test
```

Repository memiliki folder `test/` dengan widget smoke test. Tambahkan test baru di folder tersebut ketika fitur aplikasi bertambah.

## GitHub Actions

Workflow tersedia di:

```text
.github/workflows/build-android.yml
```

Workflow mengambil endpoint dari `env/production.json`, sehingga endpoint tidak perlu diubah pada dua perintah build yang berbeda.

Workflow berjalan ketika:

- Push ke branch `main`, `master`, atau `dev`.
- Pull request ke `main` atau `master`.
- Dijalankan manual melalui `workflow_dispatch`.

Tahapan workflow:

1. Checkout repository.
2. Menyiapkan Java 17.
3. Menyiapkan Flutter stable `3.29.x`.
4. Menjalankan `flutter pub get`.
5. Menjalankan `flutter analyze`.
6. Menjalankan `flutter test`.
7. Build APK release.
8. Build Android App Bundle.
9. Upload artifact `release-apk`.
10. Upload artifact `release-aab`.

## Download APK Manual

Karena update otomatis belum digunakan, setiap rilis aplikasi diunduh secara manual dari GitHub Actions.

1. Buka repository GitHub.
2. Masuk ke tab **Actions**.
3. Pilih workflow **Build Android APK**.
4. Pilih workflow run dengan status berhasil.
5. Scroll ke bagian **Artifacts**.
6. Download artifact `release-apk`.
7. Extract file ZIP.
8. Install `app-release.apk` pada perangkat kurir.
9. Konfirmasi instalasi jika Android menampilkan peringatan sumber tidak dikenal.

Artifact `release-aab` digunakan untuk distribusi melalui Google Play atau proses release Android, sedangkan instalasi langsung pada perangkat menggunakan `release-apk`.

## Versioning APK

Versi aplikasi diatur pada `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Formatnya:

```text
version_name + version_code
```

Contoh update:

```yaml
version: 1.1.0+2
```

`version_code` harus selalu lebih tinggi untuk rilis baru. Sebelum build release produksi, pastikan signing key Android konsisten agar APK dapat dipasang sebagai update pada perangkat yang sudah memiliki versi sebelumnya.

## Keamanan

Jangan commit file atau nilai berikut ke repository public:

```text
*.jks
*.keystore
service-account.json
firebase-adminsdk*.json
.env
GitHub PAT
google-services admin credentials
```

Gunakan GitHub Secrets untuk credential build dan service account. File `google-services.json` Android hanya boleh berisi konfigurasi client Firebase, bukan private key server.

## Troubleshooting

### `flutter analyze` gagal

Baca file dan nomor baris yang disebutkan pada output, perbaiki lint, lalu jalankan ulang:

```bash
flutter analyze
```

### `flutter test` gagal karena folder test tidak ada

Tambahkan folder `test/` dan unit test, atau ubah workflow jika test belum menjadi bagian dari tahap saat ini.

### APK tidak dapat meng-update aplikasi lama

Pastikan:

- `applicationId` sama: `com.timah.ekspedisi_surat`.
- `versionCode` lebih tinggi.
- APK ditandatangani dengan signing key yang sama.
- Versi lama tidak dihapus sebelum instalasi update.

### Data belum tampil ketika offline

Aplikasi hanya dapat menampilkan surat yang sebelumnya sudah tersimpan di SQLite. Surat baru dari server memerlukan koneksi internet setidaknya satu kali agar dapat diunduh ke perangkat.

### Bukti belum tampil di website

Periksa indikator sinkronisasi pada aplikasi. Jika masih pending, pastikan koneksi internet tersedia dan file foto belum terhapus dari perangkat.

## Status Fitur

- [x] Login REST API backend sendiri.
- [x] Dashboard kurir.
- [x] Tab Home, Aktivitas, Riwayat, dan Akun.
- [x] Badge tugas baru.
- [x] Pairing QR Tata Usaha–kurir.
- [x] Ambil tugas surat.
- [x] Input nama penerima.
- [x] Kamera dan watermark foto.
- [x] GPS dan alamat lokasi.
- [x] Hash SHA-256 bukti foto.
- [x] SQLite offline-first.
- [x] Queue klaim surat dan upload bukti.
- [x] Auto-sync saat internet kembali.
- [x] Firebase push notification.
- [x] Halaman Cara Pemakaian termasuk pairing QR.
- [x] GitHub Actions build APK dan AAB.
- [ ] Auto-update aplikasi dengan download dan instalasi dari dalam aplikasi.
- [ ] Unit test Flutter lengkap.

## Catatan

Aplikasi kurir ini merupakan client mobile. Pembuatan surat, pengelolaan divisi, pengelolaan pengguna, analitik, dan tampilan bukti pengiriman dilakukan melalui website manajemen surat.
