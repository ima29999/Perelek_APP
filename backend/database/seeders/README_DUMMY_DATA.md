# Data Dummy Perelek (Periode Januari 2024 - Juni 2026)

Seeder ini sudah diperbarui sesuai permintaan:

- **Warga**: 30 akun, masing-masing mewakili **1 Kartu Keluarga (KK)**.
- **Periode**: **Januari 2024 - Juni 2026 saja** (tidak dilebihkan, karena
  tanggal berjalan sekarang baru sampai Juli 2026 — data dibuat seolah
  benar-benar real/berjalan, bukan data masa depan).
- **Nominal tagihan**: maksimal **Rp30.000**, contoh yang diminta yaitu
  **iuran sampah mingguan Rp5.000**.
  | Jenis Tagihan     | Frekuensi | Nominal   |
  |-------------------|-----------|-----------|
  | Iuran Sampah      | Mingguan  | Rp5.000   |
  | Iuran Kas RT      | Bulanan   | Rp15.000  |
  | Iuran Keamanan    | Bulanan   | Rp25.000  |
  | Iuran Kebersihan  | Triwulan  | Rp30.000  |
- **Status pembayaran**: SEMUA tagihan periode Jan 2024 - Jun 2026 sudah
  berstatus **`confirmed` (lunas)**. Ini disengaja, supaya kamu bisa
  menambahkan pembayaran baru secara manual (mis. untuk mensimulasikan
  warga yang telat/menunggak di bulan Juli 2026 dst) tanpa perlu
  menghapus data lain dulu.
- Data pendukung lain (Expenses, Events, FAQ) juga dibatasi sampai
  Juni 2026 (tidak ada data di bulan Juli 2026 atau setelahnya).

Total data yang dihasilkan: **202 tagihan** x 30 warga = **6.060
pembayaran** (semua lunas).

## Cara menjalankan

Dari folder `backend`:

```bash
composer install
cp .env.example .env   # jika belum ada, lalu sesuaikan koneksi database
php artisan key:generate
php artisan migrate:fresh --seed
```

Ini akan menjalankan:
1. `AdminUserSeeder` → akun admin (`admin@gmail.com` / `password123`)
2. `DemoDataSeeder` → 30 warga + tagihan + pembayaran lunas + expenses + events + faq
3. `NotificationSeeder` → notifikasi berdasarkan data di atas

## Akun login demo

- **Admin**: `admin@gmail.com` / `password123`
- **Warga**: password semua `password123`, email mengikuti pola
  `nama.depan.nama.belakang@gmail.com` (lihat isi `DemoDataSeeder::createWargas()`
  untuk daftar 30 nama lengkapnya — salah satunya **Amanda Putri**, dipakai
  sebagai contoh skenario "nonaktifkan tombol Bayar" di bawah).

## Menambahkan pembayaran baru secara manual

Karena semua tagihan Jan 2024 - Jun 2026 sudah lunas, kamu tinggal:
- Membuat tagihan baru (mis. bulan Juli 2026 dst) lewat halaman admin
  (Invoices), **atau**
- Mengubah salah satu payment yang sudah ada menjadi `pending`/`rejected`
  lewat database jika ingin mensimulasikan kasus belum bayar/ditolak.

## Fitur baru: kontrol status warga di halaman Detail Warga

Ada 2 mekanisme independen, dipakai untuk kasus yang berbeda:

| Mekanisme | Endpoint | Efek |
|---|---|---|
| **Nonaktifkan Warga** (`is_active`) | `DELETE /admin/users/{id}` → nonaktif<br>`PATCH /admin/users/{id}/activate` → aktifkan | Akun **tidak bisa login sama sekali** selama nonaktif. Otomatis tidak ada tagihan yang terlihat karena warga tidak bisa masuk aplikasi. Cocok untuk warga pindah rumah / akun baru yang belum siap dipakai. |
| **Nonaktifkan Tombol Bayar** (`can_pay`, baru) | `PATCH /admin/users/{id}/disable-payment` → nonaktifkan<br>`PATCH /admin/users/{id}/enable-payment` → aktifkan | Warga **tetap bisa login & tetap melihat tagihannya**, hanya tombol "Bayar" yang disembunyikan (di InvoicesPage, DashboardWargaPage, dan diblokir juga di endpoint pembayaran manual & Midtrans). Cocok untuk kasus seperti **Amanda Putri** yang sedang kesusahan dan diberi keringanan sementara — bisa diaktifkan lagi kapan saja lewat toggle di halaman Detail Warga. |

Keduanya ada di kartu **"Pengaturan Pembayaran"** (untuk `can_pay`) dan tombol ikon di header (untuk `is_active`) pada halaman `WargaDetailPage`.

## Mengubah rentang periode

Kalau rentang tanggalnya perlu diubah lagi nanti, cukup ubah 3 konstanta
di bagian atas `DemoDataSeeder.php`:

```php
private const YEAR_START     = 2024; // tahun mulai
private const YEAR_END       = 2026; // tahun akhir
private const YEAR_END_MONTH = 6;    // bulan terakhir pada YEAR_END
```
