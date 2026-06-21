# Sistem Keuangan Perelek Digital Berbasis Donasi Sosial
# Kelompok 3


---
## 📱 Deskripsi Singkat Aplikasi
Perelek Digital adalah aplikasi mobile yang memudahkan pengelolaan keuangan RT/RW secara digital dan transparan. Aplikasi ini menggantikan sistem perelek (iuran warga) konvensional dengan platform berbasis teknologi yang lebih efisien.

Fitur Utama:

Admin: Dashboard statistik keuangan, kelola warga, verifikasi pembayaran, buat laporan keuangan, dan kelola kalender kegiatan RT
Warga: Cek tagihan, bayar iuran, lihat laporan keuangan transparan, cek pengumuman/jadwal kegiatan
Sistem Pembayaran: Upload bukti bayar, tracking status pembayaran real-time
Laporan Keuangan: Transparansi penuh dengan grafik tren pemasukan/pengeluaran
## 🚀 Cara Menjalankan Project
A. Persiapan Awal
Pastikan sudah install:

✅ Flutter SDK 3.0+ (download)
✅ Dart 3.0+ (included dengan Flutter)
✅ Android Studio / VS Code + ekstensi Flutter
✅ Device/Emulator (Android atau iOS)
B. Setup Backend (Laravel) 
# 1. Masuk folder backend
cd perelek/backend

# 2. Install dependencies PHP
composer install

# 3. Setup environment
cp .env.example .env
php artisan key:generate

# 4. Setup database (pastikan MySQL running)
php artisan migrate
php artisan db:seed  # (optional) untuk data dummy

# 5. Jalankan server Laravel
php artisan serve
# Server berjalan di http://localhost:8000
C. Setup Frontend (Flutter)
# 1. Masuk folder frontend
cd perelek/frontend

# 2. Install dependencies Flutter
flutter pub get

# 3. Download font Poppins (PENTING!)
# - Unduh dari https://fonts.google.com/specimen/Poppins
# - Copykan 4 file ke: assets/fonts/
#   • Poppins-Regular.ttf
#   • Poppins-Medium.ttf
#   • Poppins-SemiBold.ttf
#   • Poppins-Bold.ttf

# 4. Konfigurasi URL API
# Edit: lib/core/constants/app_constants.dart
# Pilih sesuai device:

# Android Emulator
baseUrl: 'http://10.0.2.2:8000/api'

# iOS Simulator
baseUrl: 'http://localhost:8000/api'

# Device fisik
baseUrl: 'http://192.168.x.x:8000/api'  # (ganti dengan IP lokal PC)
D. Jalankan Aplikasi
# Lihat device yang tersedia
flutter devices

# Jalankan di emulator/device pilihan
flutter run

# Atau specify device
flutter run -d emulator-5554

---

## 🗂️ Struktur Folder

```
lib/
├── main.dart                    # Entry point
├── core/
│   ├── api/
│   │   └── api_client.dart      # Dio HTTP client + interceptors
│   ├── constants/
│   │   └── app_constants.dart   # URL API, keys, konstanta
│   ├── router/
│   │   └── app_router.dart      # GoRouter + role-based redirect
│   ├── shells/
│   │   ├── admin_shell.dart     # Bottom nav admin (5 tab)
│   │   └── warga_shell.dart     # Bottom nav warga (5 tab)
│   ├── theme/
│   │   └── app_theme.dart       # Warna, tema Material 3
│   ├── utils/
│   │   ├── currency_formatter.dart
│   │   └── snackbar_helper.dart
│   └── widgets/
│       └── common_widgets.dart  # StatusBadge, Shimmer, EmptyState, dll
├── features/
│   ├── auth/
│   │   ├── auth_provider.dart   # Login state management
│   │   └── login_page.dart      # Halaman login
│   ├── dashboard_admin/
│   │   └── dashboard_admin_page.dart
│   ├── dashboard_warga/
│   │   └── dashboard_warga_page.dart
│   ├── invoices/
│   │   └── invoices_page.dart
│   ├── payments/
│   │   ├── payments_page.dart       # Warga + admin list
│   │   ├── submit_payment_page.dart # Form submit + upload foto
│   │   ├── payment_detail_page.dart # Detail + preview bukti
│   │   └── verify_payment_page.dart # Konfirmasi/tolak (admin)
│   ├── profile/
│   │   └── profile_page.dart
│   ├── reports/
│   │   └── report_page.dart     # Transparansi + keuangan + tunggakan
│   ├── events/
│   │   └── events_page.dart     # Kalender + CRUD kegiatan
│   ├── faq/
│   │   └── faq_page.dart        # FAQ + panduan
│   └── warga_admin/
│       ├── warga_list_page.dart
│       ├── warga_form_page.dart
│       └── warga_detail_page.dart
```

---

## 🔧 Konfigurasi URL API

Edit `lib/core/constants/app_constants.dart`:

```dart
// Android Emulator (akses host mesin)
static const String baseUrl = 'http://10.0.2.2:8000/api';

// iOS Simulator
static const String baseUrl = 'http://localhost:8000/api';

// Perangkat fisik (sesuaikan IP jaringan lokal)
static const String baseUrl = 'http://192.168.1.100:8000/api';

// Production
static const String baseUrl = 'https://api.perelek.id/api';
```

---

## 📦 Dependencies Utama

| Package | Versi | Fungsi |
|---|---|---|
| dio | ^5.4.0 | HTTP client + interceptors |
| provider | ^6.1.2 | State management |
| go_router | ^13.2.0 | Navigation + deep linking |
| shared_preferences | ^2.2.3 | Local storage |
| flutter_secure_storage | ^9.0.0 | Token storage aman |
| google_fonts | ^6.2.1 | Font Poppins |
| shimmer | ^3.0.0 | Loading skeleton |
| fl_chart | ^0.68.0 | Grafik line & bar |
| table_calendar | ^3.1.2 | Kalender interaktif |
| image_picker | ^1.1.2 | Upload foto |
| photo_view | ^0.15.0 | Preview foto fullscreen |
| intl | ^0.19.0 | Format tanggal & mata uang |

---


## 📋 Akun Test (setelah seeder backend)

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@perelek.local | password123 |
| Warga | budi@example.com | password123 |
| Warga | siti@example.com | password123 |
---
❓ Troubleshooting
Masalah	Solusi
Font tidak muncul	Pastikan folder assets/fonts/ punya 4 file Poppins dan update pubspec.yaml
API tidak terkoneksi	Cek URL API di app_constants.dart, pastikan Laravel running
Build error	Jalankan flutter clean lalu flutter pub get
Emulator blank	Tunggu loading, atau coba flutter run -d ulang
