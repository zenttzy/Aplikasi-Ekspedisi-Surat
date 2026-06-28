# Buku Ekspedisi Surat Digital — Aplikasi Mobile (Flutter)

Klien lapangan untuk kurir: pelacakan surat fisik, pemotretan bukti
pengiriman (berwatermark anti-tampering), dan sinkronisasi **offline-first**
dengan backend Supabase.

## Arsitektur

```
lib/
├── main.dart                      # Entry point: init DI + DB, runApp
├── app.dart                       # MaterialApp (tema, routing awal)
├── core/
│   ├── config/                    # AppConfig (dart-define), AppConstants
│   ├── database/                  # DatabaseHelper (sqflite singleton + schema)
│   ├── di/                        # service_locator (get_it)
│   ├── network/                   # DioClient (+interceptor refresh), SecureStorage, Connectivity
│   └── sync/                      # SyncManager (download/upload), SyncPrefs
└── features/
    ├── auth/data/                 # AuthRepository (Supabase Auth)
    ├── expeditions/data/          # Expedition model + repository (CRUD SQLite)
    └── home/                      # HomePage (verifikasi fondasi)
```

**Prinsip offline-first:** UI selalu membaca dari SQLite lokal. SyncManager
menjembatani ke server saat ada koneksi (connectivity_plus).

## Setup

SDK terkunci: **Flutter 3.24.5 / Dart 3.5.4** (macOS 12). JANGAN flutter upgrade.

```bash
flutter pub get
```

## Menjalankan

Konfigurasi Supabase disuntik via --dart-define-from-file.

**Setup sekali:** salin `env/example.json` → `env/dev.json` lalu isi
`SUPABASE_URL` dan `SUPABASE_ANON_KEY` (pakai **anon/public** key, BUKAN
service_role). File `env/dev.json` sudah di-.gitignore.

```bash
flutter run -d <device_id> --dart-define-from-file=env/dev.json
```

Contoh ke tablet:

```bash
flutter run -d 32NBB25110202807 --dart-define-from-file=env/dev.json
```

Tanpa konfigurasi, app tetap jalan (mode offline) dan menampilkan
status "Konfigurasi belum diset" di beranda.

## Status Implementasi

- [x] Scaffold project + dependencies (kompatibel Dart 3.5.4)
- [x] Struktur core/ & features/
- [x] SQLite schema expeditions + repository CRUD
- [x] Network layer: Dio + interceptor refresh token, secure storage
- [x] SyncManager (download/upload sesuai API contract) — transport siap
- [x] DI (get_it) + entrypoint
- [ ] Halaman Login (Supabase Auth)
- [ ] Daftar Surat (baca SQLite)
- [ ] Kamera kustom + overlay watermark (dart:ui) + hash SHA-256
- [ ] Background sync saat koneksi pulih

## API Contract (ringkas)

- POST /sync/download — body { "last_sync_at": "<iso>" }
- POST /expeditions/{uuid}/upload-bukti — multipart (file_overlay,
  file_original, penerima, tanggal_diterima, lat, long, foto_hash)
- Auth: POST /auth/v1/token?grant_type=password

Detail lengkap: flutter_developer_guide.md
