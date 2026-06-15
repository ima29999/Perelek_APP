# Perelek Backend — Sistem Manajemen Warga & Keuangan RT

Backend REST API berbasis **Laravel 10** untuk sistem manajemen iuran, keuangan, warga, dan kegiatan RT/RW.

---

## 🚀 Instalasi & Setup

### Prasyarat
- PHP >= 8.1
- Composer
- MySQL 8+ / MariaDB 10+
- Node.js (untuk asset jika diperlukan)

### Langkah Instalasi

```bash
# 1. Install dependency
composer install

# 2. Copy environment
cp .env.example .env

# 3. Generate app key
php artisan key:generate

# 4. Konfigurasi .env (DB, APP_URL, dll)
# Edit file .env sesuai environment Anda

# 5. Jalankan migrasi + seeder
php artisan migrate --seed

# 6. Buat symbolic link storage
php artisan storage:link

# 7. Jalankan server
php artisan serve
```

### Akun Default (setelah seeder)
| Role  | Email                  | Password     |
|-------|------------------------|--------------|
| Admin | admin@perelek.local    | password123  |
| Warga | budi@example.com       | password123  |
| Warga | siti@example.com       | password123  |

---

## 📡 API Endpoints

Base URL: `http://localhost:8000/api`

### Auth
| Method | Endpoint                    | Deskripsi                     | Auth |
|--------|-----------------------------|-------------------------------|------|
| POST   | `/auth/login`               | Login, dapat token            | ❌   |
| POST   | `/auth/logout`              | Logout, hapus token           | ✅   |
| POST   | `/auth/refresh`             | Refresh token                 | ✅   |
| GET    | `/auth/me`                  | Data user login               | ✅   |
| POST   | `/auth/forgot-password`     | Kirim link reset password     | ❌   |
| POST   | `/auth/reset-password`      | Reset password dengan token   | ❌   |

### Dashboard
| Method | Endpoint              | Deskripsi                              | Role  |
|--------|-----------------------|----------------------------------------|-------|
| GET    | `/dashboard`          | Dashboard warga (tagihan, riwayat)     | Warga |
| GET    | `/admin/dashboard`    | Dashboard admin (statistik, grafik)    | Admin |

### Warga (Admin)
| Method | Endpoint                | Deskripsi                   |
|--------|-------------------------|-----------------------------|
| GET    | `/admin/users`          | Daftar warga (search, filter)|
| POST   | `/admin/users`          | Tambah warga baru            |
| GET    | `/admin/users/{id}`     | Detail warga + riwayat       |
| PUT    | `/admin/users/{id}`     | Update data warga            |
| DELETE | `/admin/users/{id}`     | Nonaktifkan warga            |

### Profil Warga
| Method | Endpoint   | Deskripsi                                    |
|--------|------------|----------------------------------------------|
| GET    | `/profile` | Profil sendiri                               |
| PATCH  | `/profile` | Update profil, foto, ganti password          |

### Tagihan
| Method | Endpoint                  | Deskripsi                              |
|--------|---------------------------|----------------------------------------|
| GET    | `/invoices`               | Tagihan aktif (warga + status bayar)   |
| GET    | `/admin/invoices`         | Semua tagihan (admin)                  |
| POST   | `/admin/invoices`         | Buat tagihan baru                      |
| GET    | `/admin/invoices/{id}`    | Detail tagihan + rekap pembayaran      |
| PUT    | `/admin/invoices/{id}`    | Update tagihan                         |
| DELETE | `/admin/invoices/{id}`    | Hapus tagihan                          |

### Pembayaran
| Method | Endpoint                          | Deskripsi                            |
|--------|-----------------------------------|--------------------------------------|
| GET    | `/payments/my`                    | Riwayat pembayaran warga sendiri      |
| POST   | `/payments`                       | Submit pembayaran + upload bukti foto |
| GET    | `/payments/{id}`                  | Detail pembayaran + URL preview foto  |
| DELETE | `/payments/{id}`                  | Batalkan pembayaran (pending only)    |
| GET    | `/admin/payments`                 | Semua pembayaran (admin, filter)      |
| PATCH  | `/admin/payments/{id}/verify`     | Konfirmasi / Tolak pembayaran         |

### Pengeluaran (Admin)
| Method | Endpoint                  | Deskripsi                         |
|--------|---------------------------|-----------------------------------|
| GET    | `/admin/expenses`         | Daftar pengeluaran (filter, total)|
| POST   | `/admin/expenses`         | Catat pengeluaran baru            |
| GET    | `/admin/expenses/{id}`    | Detail pengeluaran                |
| PUT    | `/admin/expenses/{id}`    | Edit pengeluaran                  |
| DELETE | `/admin/expenses/{id}`    | Hapus pengeluaran                 |

### Laporan Keuangan
| Method | Endpoint                       | Deskripsi                                   |
|--------|--------------------------------|---------------------------------------------|
| GET    | `/admin/reports/financial`     | Laporan keuangan lengkap (periode filter)    |
| GET    | `/admin/reports/arrears`       | Laporan tunggakan per tagihan                |
| GET    | `/admin/reports/transparency`  | Data transparansi anggaran per bulan         |
| GET    | `/reports/personal`            | Laporan personal warga                       |
| GET    | `/reports/transparency`        | Transparansi publik (warga)                  |

### Kalender & Kegiatan
| Method | Endpoint                  | Deskripsi                         |
|--------|---------------------------|-----------------------------------|
| GET    | `/events`                 | Daftar kegiatan (publik)          |
| GET    | `/admin/events`           | Daftar kegiatan (admin)           |
| POST   | `/admin/events`           | Tambah kegiatan baru              |
| GET    | `/admin/events/{id}`      | Detail kegiatan                   |
| PUT    | `/admin/events/{id}`      | Update kegiatan                   |
| DELETE | `/admin/events/{id}`      | Hapus kegiatan                    |

### FAQ & Panduan
| Method | Endpoint              | Deskripsi                |
|--------|-----------------------|--------------------------|
| GET    | `/faqs`               | Daftar FAQ (publik)      |
| GET    | `/guidance`           | Panduan penggunaan       |
| POST   | `/admin/faqs`         | Tambah FAQ               |
| PUT    | `/admin/faqs/{id}`    | Update FAQ               |
| DELETE | `/admin/faqs/{id}`    | Hapus FAQ                |

---

## 🔐 Format Request/Response

### Header (authenticated endpoints)
```
Authorization: Bearer {token}
Accept: application/json
Content-Type: application/json
```

### Format Response Sukses
```json
{
  "success": true,
  "message": "Operasi berhasil.",
  "data": { ... }
}
```

### Format Response Error
```json
{
  "success": false,
  "message": "Pesan error.",
  "errors": { "field": ["validasi gagal"] }
}
```

### Contoh: Login
```bash
POST /api/auth/login
{
  "email": "admin@perelek.local",
  "password": "password123"
}
```

### Contoh: Submit Pembayaran (multipart/form-data)
```bash
POST /api/payments
Authorization: Bearer {token}

invoice_id: 1
amount: 50000
payment_date: 2025-06-08
method: transfer
proof: [file image]
notes: Transfer dari BCA
```

---

## 🔒 Keamanan

- **AES-256 Encryption**: NIK dan nomor HP dienkripsi otomatis via Laravel Crypt
- **Token Auth**: Laravel Sanctum (Bearer token)
- **Role Middleware**: `role:admin` memblokir akses non-admin ke endpoint admin
- **Soft Delete**: Data warga & pembayaran tidak dihapus permanen
- **File Validation**: Upload bukti pembayaran hanya JPG/PNG max 5MB

---

## 🗄️ Struktur Database

| Tabel                    | Keterangan                              |
|--------------------------|-----------------------------------------|
| `users`                  | Admin dan warga (NIK & HP terenkripsi)  |
| `invoices`               | Tagihan/iuran RT                        |
| `payments`               | Pembayaran warga + bukti foto           |
| `expenses`               | Pengeluaran RT per kategori             |
| `events`                 | Jadwal kegiatan RT                      |
| `faqs`                   | FAQ dan panduan                         |
| `personal_access_tokens` | Token Sanctum                           |

---

## ⚙️ Konfigurasi Storage

File upload disimpan di `storage/app/public/`:
- `payment_proofs/` — bukti pembayaran
- `profile_photos/` — foto profil warga
- `ktp_photos/` — foto KTP warga

Akses via: `http://localhost:8000/storage/{path}`

---

## 🔄 Backup Otomatis

Backup database dijadwalkan harian pukul 02:00 WIB.
Jalankan scheduler Laravel:
```bash
# Tambahkan ke crontab
* * * * * cd /path/to/project && php artisan schedule:run >> /dev/null 2>&1
```

---

## 📦 Tech Stack

- **Laravel 10** — Framework PHP
- **Laravel Sanctum** — API token authentication
- **MySQL/MariaDB** — Database
- **Laravel Crypt (AES-256)** — Enkripsi data sensitif
