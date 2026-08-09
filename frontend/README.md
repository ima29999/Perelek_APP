# Perelek Frontend — Flutter App

Aplikasi mobile Flutter untuk sistem manajemen warga & keuangan RT.

---

## 🚀 Setup & Jalankan

### Prasyarat
- Flutter SDK >= 3.0.0
- Dart >= 3.0.0
- Android Studio / VS Code dengan plugin Flutter
- Device/Emulator (Android/iOS)

### Langkah Instalasi

```bash
# 1. Masuk ke folder frontend
cd perelek/frontend

# 2. Install dependencies
flutter pub get

# 3. Download font Poppins
# Unduh dari https://fonts.google.com/specimen/Poppins
# Letakkan di: assets/fonts/
# - Poppins-Regular.ttf
# - Poppins-Medium.ttf
# - Poppins-SemiBold.ttf
# - Poppins-Bold.ttf

# 4. Konfigurasi URL API
# Edit: lib/core/constants/app_constants.dart
# baseUrl: 'http://10.0.2.2:8000/api'  → Android Emulator
# baseUrl: 'http://localhost:8000/api'   → iOS Simulator
# baseUrl: 'http://192.168.x.x:8000/api' → Device fisik

# 5. Jalankan aplikasi
flutter run
```

---

## 📱 Fitur Aplikasi

### Halaman Login
- Form email & password dengan animasi
- Validasi real-time
- Fitur lupa password (email reset)
- Tampilan error yang informatif

### Dashboard Admin
- Statistik: total warga, pemasukan, pengeluaran, saldo
- Grafik tren pemasukan vs pengeluaran (LineChart)
- Daftar pembayaran terbaru
- Menu cepat ke semua fitur

### Dashboard Warga
- Banner total bayar tahun ini
- Tagihan belum bayar dengan tombol bayar langsung
- Pengumuman & jadwal kegiatan mendatang
- Grid menu layanan

### Kelola Warga (Admin)
- Daftar warga dengan search & filter status
- Form tambah/edit warga
- Detail warga + riwayat pembayaran
- Nonaktifkan warga

### Tagihan
- List tagihan dengan status bayar (warga)
- Buat/edit tagihan (admin)
- Filter & pencarian
- Tombol bayar langsung dari card

### Pembayaran
- Submit pembayaran + upload foto bukti
- Preview foto sebelum kirim
- Progress upload
- Riwayat pembayaran warga (filter status)
- Daftar semua pembayaran admin
- Detail pembayaran dengan preview foto full-screen
- Konfirmasi/tolak pembayaran (admin)

### Laporan Keuangan
- Transparansi anggaran: grafik batang bulanan
- Pengeluaran per kategori dengan progress bar
- Laporan keuangan detail (admin)
- Laporan tunggakan per tagihan (admin)
- Filter per tahun

### Kalender Kegiatan
- TableCalendar interaktif dengan event markers
- List kegiatan per hari yang dipilih
- Tambah/edit/hapus kegiatan (admin)
- Color picker untuk warna event

### FAQ & Panduan
- Accordion FAQ dengan search & filter kategori
- Tab panduan penggunaan step-by-step
- Tambah/edit/hapus FAQ (admin)

### Profil
- Edit data diri & foto profil
- Upload foto dari kamera/galeri
- Ganti password dengan tips keamanan
- Tombol logout

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

## 🎨 Design System

- **Font**: Poppins (Regular, Medium, SemiBold, Bold)
- **Primary Color**: #1A56DB (Biru RT)
- **Accent**: #0E9F6E (Hijau)
- **Design**: Material 3, card-based, rounded corners 14-16px
- **Breakpoints**: Mobile-first, responsif untuk tablet

---

## 📋 Akun Test (setelah seeder backend)

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@perelek.local | password123 |
| Warga | budi@example.com | password123 |
| Warga | siti@example.com | password123 |
