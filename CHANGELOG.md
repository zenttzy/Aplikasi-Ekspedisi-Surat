# Changelog - Pembaruan Aplikasi Kurir Ekspedisi Surat

Dokumen ini mencatat semua perubahan, perbaikan bug, integrasi, dan penambahan fitur yang dilakukan pada aplikasi mobile (Flutter) kurir.

## [1.1.0] - 2026-06-29

### Ditambahkan
* **Validasi Login Email `@pttimah.com`**:
  * Menambahkan validasi tingkat klien (*client-side validation*) pada kolom email login agar hanya menerima format email yang berakhiran `@pttimah.com` (contoh: `kurir_hadi@pttimah.com`).
  * Menambahkan proteksi lapis kedua pada repositori data [auth_repository.dart](file:///Users/macbook/development/ekspedisi_surat/lib/features/auth/data/auth_repository.dart) sebelum mengirimkan request autentikasi ke Supabase Auth.
* **Uji Koneksi REST API & Pengisian Database**:
  * Menambahkan pengujian integrasi sementara (`connection_test.dart`) untuk memverifikasi fungsionalitas GET surat dari server Supabase utama.
  * Menyisipkan baris data surat tiruan (*mock letter*) langsung ke database PostgreSQL menggunakan *Connection Pooler (Supavisor)* untuk verifikasi penarikan data awal (*get surat*) pada tablet.

### Diperbaiki
* **Kesalahan Kompilasi Dashboard & Detail Surat**:
  * **[home_page.dart](file:///Users/macbook/development/ekspedisi_surat/lib/features/home/home_page.dart)**: Menghapus pemanggilan method `_loadExpeditions()` yang tidak terdefinisi dan menggantinya dengan method `_loadCount()` yang benar untuk memuat ulang daftar surat dari SQLite.
  * **[expedition_detail_page.dart](file:///Users/macbook/development/ekspedisi_surat/lib/features/expeditions/presentation/expedition_detail_page.dart)**: Menambahkan import `app_constants.dart` untuk mengatasi error referensi `ExpeditionStatus` yang tidak ditemukan.
* **Perbaikan Unit Test**:
  * Memodifikasi [widget_test.dart](file:///Users/macbook/development/ekspedisi_surat/test/widget_test.dart) untuk mendaftarkan `FakeAuthRepository` di `GetIt` guna mencegah terjadinya *method channel exceptions* dari *secure storage* saat pengujian berlangsung.
  * Memperbaiki ekspektasi pencarian teks pada smoke test dari `"Buku Ekspedisi Digital"` menjadi `"Surat Digital"`.

### Otomatisasi & Pemasangan
* **Otomatisasi Instalasi via ADB**:
  * Melakukan build berkas APK debug secara mandiri menggunakan opsi parameter `--dart-define-from-file=env/dev.json`.
  * Memasang aplikasi secara langsung (*Streamed Install*) ke tablet kurir yang terhubung dengan serial `32NBB25110202807`.
  * Membuka aplikasi secara otomatis di layar tablet kurir pasca-instalasi.
