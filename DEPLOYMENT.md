# Deployment Aplikasi Kurir Flutter

## Konfigurasi endpoint tunggal

Endpoint build production disimpan pada `env/production.json`.

```json
{
  "API_BASE_URL": "http://43.134.228.34:3001/api"
}
```

Untuk pindah ke server PT, ubah hanya nilai `API_BASE_URL`:

```json
{
  "API_BASE_URL": "http://IP_SERVER_KANTOR:3001/api"
}
```

Workflow GitHub Actions menggunakan file ini untuk APK dan AAB, sehingga endpoint tidak perlu diubah di beberapa perintah build.

## Build lokal

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define-from-file=env/production.json
```

Hasil APK berada di `build/app/outputs/flutter-apk/app-release.apk`.

## GitHub Actions

Workflow berada di `.github/workflows/build-android.yml` dan berjalan saat push ke `main`, `master`, atau `dev`, pull request, maupun manual melalui `workflow_dispatch`.

Setelah workflow berhasil:

1. Buka tab **Actions** pada repository.
2. Buka workflow **Build Android APK**.
3. Pilih run yang berhasil.
4. Download artifact `release-apk` untuk instalasi manual.
5. Gunakan `release-aab` jika akan diproses melalui Google Play atau distribusi bundle.

## Firebase dan secret

- `android/app/google-services.json` adalah konfigurasi client Firebase Android.
- Firebase Admin service account hanya digunakan backend dan tidak boleh dimasukkan ke aplikasi Flutter.
- Jangan commit private key, token PAT, atau file service account ke repository public.
- Jika service account pernah dibagikan atau terekspos, revoke key lama dan buat key baru sebelum deployment PT.

## Checklist sebelum rilis

1. Pastikan `env/production.json` menunjuk ke backend yang aktif.
2. Pastikan `google-services.json` memakai package name aplikasi yang benar.
3. Jalankan `flutter analyze` dan `flutter test` melalui GitHub Actions.
4. Uji login kurir, Scan QR Tata Usaha, refresh profil/divisi, daftar surat, klaim surat, foto GPS, nama penerima, mode offline, dan sinkronisasi.
5. Download APK artifact dan install manual pada perangkat uji.
