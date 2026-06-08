# Software Requirements Specification (SRS)
## Sistem Keuangan Perelek Digital Modern Berbasis Donasi Sosial

**Versi 1.0 Approved**

Prepared by: Tim Pengembang Perelek Digital  
Organization: Perelek Digital Development Team  
Date: 2025

---
**Disusun Oleh:**

| Nama |
|------|
|Muhammad Ilyas Fauzi  |
|Julia Desteny Deodonia Langkedeng |
|Nazwa Ima Fadia|
|Gilang Anugrah |
|muhammad rifqy wildan|
|Wahyu Bonita Juliana Sari |
|Aal Maulana |
|Caryksha Aulia Putri |

**PROGRAM STUDI SISTEM INFORMASI**
**FAKULTAS ILMU KOMPUTER DAN SISTEM INFORMASI**
**UNIVERSITAS KEBANGSAAN REPUBLIK INDONESIA**
**TAHUN 2026**


---

## Revision History

| Name | Date | Reason For Changes | Version |
|------|------|-------------------|---------|
| Tim Pengembang | 2025 | Initial SRS Document Creation | 1.0 |

---

## 1. Introduction

### 1.1 Purpose

Dokumen ini bertujuan untuk menjelaskan fungsi, fitur, serta batasan dari sistem keuangan perelek digital yang memungkinkan pengelolaan donasi sosial secara transparan, efisien, dan terintegrasi. Selain itu, dokumen ini juga menjadi acuan utama bagi tim pengembang dalam merancang, membangun, dan mengimplementasikan sistem sesuai dengan kebutuhan pengguna dan stakeholder.

Dengan adanya dokumen SKPL ini, diharapkan proses pengembangan sistem dapat berjalan lebih terarah, sistematis, serta mampu menghasilkan aplikasi yang sesuai dengan tujuan utama, yaitu mempermudah pengumpulan, pengelolaan, dan distribusi dana donasi sosial secara digital dan modern.

### 1.2 Document Conventions

Dokumen ini ditulis menggunakan Bahasa Indonesia. Adapun definisi, istilah dan singkatan yang digunakan dalam dokumen ini merupakan bahasa teknik yang umum digunakan dalam area pengembangan perangkat lunak.

### 1.3 Intended Audience and Reading Suggestions

Dokumen ini ditujukan kepada pihak-pihak yang berkepentingan dan berhak menggunakan perangkat lunak ini, yaitu antara lain:

1. **Pihak pengembang perangkat lunak:** Pihak pengembang akan menggunakan dokumen SKPL ini sebagai bahan acuan dan peduan dalam mengembangkan perangkat lunak.

2. **Pihak stakeholder:** Pihak stakeholder yang meliputi pemilik proyek, manajemen proyek, dan pihak yang berkepentingan dalam pengembangan perangkat lunak. Diharapkan dokumen ini memberikan pandangan umum tentang tujuan proyek yang ingin dicapai.

### 1.4 Product Scope

Website Pengembangan Sistem Keuangan Perelek Digital Modern Berbasis Donasi Sosial merupakan sebuah aplikasi berbasis web yang memanfaatkan teknologi Laravel Framework dan MySQL yang dikembangkan dengan tujuan untuk:

1. Melakukan pengelolaan data warga yang terdaftar dalam sistem perelek, meliputi Nama, Alamat, No Telepon warga yang terlibat dalam kegiatan donasi sosial.

2. Menyediakan fitur autentikasi pengguna (login) untuk memastikan bahwa hanya pengguna yang memiliki akun yang dapat mengakses sistem sesuai dengan hak akses yang dimiliki.

3. Menyediakan dashboard interaktif yang menampilkan informasi ringkasan terkait jumlah warga, total pemasukan dana perelek, total pengeluaran, serta informasi kegiatan terbaru.

4. Melakukan pencatatan pembayaran atau pemasukan dana perelek dari warga secara digital sehingga seluruh transaksi dapat tersimpan dengan rapi dan mudah diakses kembali.

5. Melakukan pencatatan pengeluaran dana perelek yang digunakan untuk kegiatan sosial atau kebutuhan masyarakat sehingga penggunaan dana dapat tercatat secara transparan.

6. Menyediakan fitur kalender atau jadwal kegiatan yang berfungsi untuk mencatat dan menampilkan agenda penting seperti jadwal pengumpulan perelek atau kegiatan sosial masyarakat.

7. Menyediakan panduan pengguna yang berisi petunjuk penggunaan sistem sehingga memudahkan pengguna dalam memahami cara menggunakan aplikasi.

8. Menyediakan fitur laporan dimana warga bisa melaporkan secara real time tentang permasalahan yang terjadi di sekitar lingkungan.

### 1.5 References

Referensi yang digunakan pada dokumen Spesifikasi Kebutuhan Perangkat Lunak (SKPL) ini adalah:

1. Asanti, D. N., dkk., "Sistem Informasi Donasi Digital Amal Now Berbasis Laravel: Studi Perancangan dan Implementasi," Jurnal Ilmiah Sistem Informasi dan Ilmu Komputer, 2025.
   - Penelitian ini menjelaskan bahwa perkembangan teknologi informasi mendorong transformasi donasi menjadi digital, namun masih terdapat tantangan dalam hal transparansi, akses, dan akuntabilitas sistem donasi online.

2. JATI (Jurnal Mahasiswa Teknik Informatika), "Transparansi dan Kepercayaan pada Sistem Donasi Online."
   - Dijelaskan bahwa sistem donasi digital yang baik dapat meningkatkan kepercayaan publik melalui transparansi dan pengelolaan dana yang jelas.

3. Ardhianto, E., dkk., "Peningkatan Akuntabilitas Data pada Pengelolaan Donasi dan Keuangan Komunitas," Jurnal Abdi Masyarakat Indonesia.
   - Penelitian ini menunjukkan bahwa kurangnya sistem pencatatan menyebabkan rendahnya akuntabilitas dalam pengelolaan donasi, sehingga dibutuhkan sistem digital yang terintegrasi.

---

## 2. Overall Description

### 2.1 Product Perspective

Website Pengembangan Sistem Keuangan Perelek Digital Modern Berbasis Donasi Sosial merupakan sebuah platform yang dirancang untuk memfasilitasi pengelolaan donasi secara digital, transparan, dan terstruktur. Sistem ini bertujuan untuk menggantikan metode perelek konvensional menjadi berbasis teknologi, sehingga mampu meningkatkan efisiensi dalam pencatatan, pengelolaan, serta pelaporan dana sosial. Pihak yang terlibat dalam sistem ini meliputi admin, donatur, serta pengelola atau penerima manfaat dana.

Selain itu, sistem ini dikembangkan sebagai bagian dari solusi transformasi digital di bidang sosial dan keuangan masyarakat, dengan menyediakan fitur seperti pencatatan donasi, monitoring dana masuk dan keluar, serta laporan keuangan yang dapat diakses secara real-time. Dalam implementasinya, sistem ini memanfaatkan teknologi seperti framework modern (Laravel), serta basis data MySQL guna mendukung proses pengembangan dan operasional sistem yang efektif, aman, dan mudah digunakan.

### 2.2 Product Functions

Website ini dirancang untuk dapat melakukan beberapa fungsi diantaranya adalah sebagai berikut:

1. **Login:** Fitur untuk menjamin keamanan akses pengguna ke dalam sistem sesuai dengan hak akses masing-masing.

2. **Dashboard (Halaman Utama):** Menyajikan ringkasan data keuangan, statistik donasi terbaru, dan informasi penting lainnya secara visual dan cepat.

3. **Data Warga:** Pengguna dapat mengelola informasi identitas warga yang terdaftar sebagai partisipan dalam sistem perelek digital.

4. **Pembayaran:** Warga atau donatur dapat melakukan proses penyetoran dana perelek secara digital dan sistem akan mencatat transaksi tersebut secara otomatis.

5. **Pengeluaran dan Transparansi Anggaran:** Fitur untuk mencatat setiap penggunaan dana sosial serta menampilkan rincian alokasi anggaran secara terbuka kepada seluruh pengguna.

6. **Panduan Pengguna:** Menyediakan informasi instruksional dan bantuan teknis mengenai tata cara penggunaan fitur-fitur yang ada di dalam website.

7. **Kalender (Jadwal):** Menampilkan jadwal pengumpulan perelek, agenda kegiatan sosial, serta tenggat waktu penting lainnya yang berkaitan dengan program donasi.

8. **Laporan:**Sistem mampu menghasilkan laporan keluhan yang disampaikan oleh warga terkait berbagai permasalahan yang terjadi.
9. **Logout**

### 2.3 User Classes and Characteristics

#### Warga (User)

**Fungsi:**
- Login
- Mengakses halaman dashboard warga
- Input data setoran perelek
- Melihat riwayat iuran
- Logout

**Hak Akses:**
- Melihat informasi iuran pribadi
- Melihat transparansi saldo total tingkat RT/RW
- Mengunggah/melaporkan bukti setoran

#### Admin (Pengurus/RT)

**Fungsi:**
- Login
- Mengakses halaman dashboard admin
- Mengelola data warga
- Verifikasi setoran warga
- Mengelola pengeluaran dana
- Membuat laporan bulanan
- Logout

**Hak Akses:**
- Memiliki kontrol penuh terhadap sistem
- Mengelola akun warga
- Mengatur dan memvalidasi data keuangan
- Mengakses seluruh laporan sistem

### 2.4 Operating Environment

| Spesifikasi | Jenis |
|------------|-------|
| Sistem Operasi | Windows 10 dan 11, Linux |
| Jaringan | Terhubung dengan jaringan internet yang stabil |
| Perangkat Keras | Laptop / Komputer |
| Spesifikasi Perangkat Keras | Kapasitas RAM minimum 2 GB, Processor minimal 4 core CPU |
| Platform Akses | Microsoft Edge, Mozilla Firefox, Google Chrome, Safari, dan lain sebagainya |

### 2.5 Design and Implementation Constraints

- Sistem dikembangkan menggunakan Laravel 11 (PHP 8.2) untuk backend API.
- Mobile app dikembangkan dengan React Native atau Flutter (cross-platform).
- Autentikasi menggunakan JWT (JSON Web Token) dengan masa berlaku access token 24 jam.
- Pembayaran dilakukan secara manual (tanpa payment gateway otomatis) pada versi 1.0.
- Fitur Machine Learning terbatas pada analisis pola pembayaran dan prediksi keterlambatan.
- Data warga dibatasi pada satu lingkungan RT/RW atau kompleks perumahan.
- Upload bukti pembayaran dibatasi format JPG/PNG dengan ukuran maksimal 5MB.
- Laporan keuangan hanya tersedia dalam format PDF.
- Integrasi payment gateway otomatis di luar cakupan versi 1.0.

### 2.6 User Documentation

- **Panduan Pengguna In-App:** Tersedia langsung di dalam aplikasi dalam format teks dan gambar (modul FAQ).
- **Video Tutorial:** Tersedia di dalam aplikasi sebagai link atau embed video.
- **Dokumentasi API:** Dokumentasi lengkap endpoint API untuk developer.
- **README Teknis:** Panduan instalasi dan konfigurasi sistem untuk tim IT/DevOps.

### 2.7 Assumptions and Dependencies

- Diasumsikan pengguna memiliki smartphone Android atau iOS dengan koneksi internet yang memadai.
- Diasumsikan warga melakukan pembayaran melalui transfer bank atau e-wallet yang tersedia.
- Sistem bergantung pada layanan Firebase Cloud Messaging untuk push notification.
- Sistem bergantung pada layanan MinIO atau S3-compatible storage untuk penyimpanan foto.
- Automasi workflow bergantung pada ketersediaan layanan n8n.
- Prediksi ML bergantung pada ketersediaan data historis pembayaran yang memadai.
- SSL certificate bergantung pada layanan Let's Encrypt untuk koneksi HTTPS.

---

## 3. External Interface Requirements

### 3.1 User Interfaces

Antarmuka pengguna dirancang sebagai aplikasi mobile native dengan panduan desain berikut:

- Material Design (Android) dan Human Interface Guidelines (iOS) sebagai referensi desain.
- Navigasi utama menggunakan bottom navigation bar dengan maksimal 5 item menu.
- Setiap halaman menyediakan tombol kembali (back button) yang konsisten.
- Pesan error ditampilkan dengan teks deskriptif yang jelas di bawah field terkait.
- Loading state ditampilkan saat terjadi proses data (spinner atau skeleton screen).
- Konfirmasi dialog ditampilkan sebelum aksi destruktif (hapus data, batalkan pembayaran).
- Antarmuka mendukung bahasa Indonesia sebagai bahasa utama.
- Ukuran font minimal 14sp untuk keterbacaan yang baik pada semua ukuran layar.

### 3.2 Hardware Interfaces

- **Kamera:** Digunakan untuk mengambil foto bukti pembayaran dan foto KTP warga. Akses kamera memerlukan izin eksplisit dari pengguna.
- **Storage/Gallery:** Akses galeri foto untuk pemilihan gambar bukti pembayaran.
- **Notifikasi:** Akses push notification melalui FCM memerlukan izin dari pengguna.
- **Koneksi Jaringan:** Sistem memerlukan koneksi internet (WiFi atau data seluler minimal 3G).

### 3.3 Software Interfaces

- **Firebase Cloud Messaging (FCM):** Untuk pengiriman push notification ke perangkat mobile Android dan iOS.
- **MinIO / AWS S3:** Object storage untuk penyimpanan foto bukti pembayaran, foto KTP, dan aset media.
- **MySQL 8.0:** Database relasional utama untuk penyimpanan data aplikasi.
- **Redis 7:** Digunakan sebagai cache layer, session management, dan message broker untuk Laravel Queue.
- **n8n:** Platform automasi workflow untuk pengiriman notifikasi terjadwal dan integrasi layanan.
- **FastAPI (Python ML Service):** REST API untuk mengakses prediksi machine learning dari backend Laravel.
- **DomPDF / Snappy:** Library PDF generation untuk laporan keuangan.

### 3.4 Communications Interfaces

- Protokol HTTPS (TLS 1.2+) untuk semua komunikasi antara mobile app dan backend API.
- Format data: JSON (application/json) untuk request dan response API.
- Multipart/form-data untuk upload file (foto bukti pembayaran).
- WebSocket atau Server-Sent Events dapat dipertimbangkan untuk notifikasi real-time di versi mendatang.
- SMTP untuk pengiriman email transaksional (OTP reset password, laporan bulanan).
- Firebase HTTP v1 API untuk pengiriman push notification.
- Base URL API: `https://api.perelek-digital.id/api/v1`.
- Authentication Header: `Authorization: Bearer {access_token}`.

---

## 4. System Features

Bagian ini mendeskripsikan kebutuhan fungsional sistem Perelek Digital yang diorganisasi berdasarkan modul fitur utama.

### 4.1 Fitur Autentikasi & Manajemen Sesi

#### 4.1.1 Description and Priority

Fitur ini menyediakan mekanisme login, logout, dan manajemen sesi berbasis JWT dengan role-based access control. 

**Prioritas:** High - merupakan fondasi keamanan seluruh sistem.

#### 4.1.2 Stimulus/Response Sequences

- Pengguna memasukkan email/nomor HP dan password → Sistem memvalidasi dan menghasilkan JWT token → Pengguna diarahkan ke dashboard sesuai role.
- Pengguna logout → Sistem menginvalidasi token → Sesi dihapus dari perangkat.
- Pengguna lupa password → Input email → Terima OTP → Reset password baru.

#### 4.1.3 Functional Requirements

| No | Fitur | Deskripsi | Role |
|----|-------|-----------|------|
| 1 | Login Pengguna | Pengguna dapat masuk menggunakan email/nomor HP dan password. Sistem menghasilkan JWT access token dan refresh token. | Admin, Pengguna |
| 2 | Logout | Sistem menginvalidasi token aktif dan menghapus sesi pengguna dari perangkat. | Admin, Pengguna |
| 3 | Role-Based Access Control | Sistem membedakan hak akses: Admin (full access) dan Pengguna (read + self-service). Endpoint dilindungi middleware role. | Admin, Pengguna |
| 4 | Refresh Token | Sistem menyediakan mekanisme refresh token agar sesi dapat diperbarui tanpa login ulang. | Admin, Pengguna |
| 5 | Reset Password | Pengguna dapat mereset password via email/SMS OTP. | Admin, Pengguna |

### 4.2 Dashboard

#### 4.2.1 Description and Priority

Dashboard menyajikan ringkasan informasi penting secara real-time. Dashboard Admin dan Pengguna memiliki tampilan yang berbeda sesuai role. 

**Prioritas:** High.

#### 4.2.2 Functional Requirements

| No | Fitur | Deskripsi | Role |
|----|-------|-----------|------|
| 6 | Dashboard Admin | Menampilkan ringkasan: total warga, total pemasukan bulan ini, total pengeluaran, saldo kas, jumlah pembayaran pending, grafik tren pembayaran, dan notifikasi terbaru. | Admin |
| 7 | Dashboard Pengguna | Menampilkan status tagihan aktif, riwayat pembayaran terakhir, pengumuman terbaru, saldo kas lingkungan, dan kalender jadwal kegiatan. | Pengguna |

### 4.3 Manajemen Data Warga

#### 4.3.1 Description and Priority

Fitur CRUD untuk mengelola data warga lingkungan. Admin memiliki akses penuh; warga dapat memperbarui data pribadi sendiri. 

**Prioritas:** High.

#### 4.3.2 Functional Requirements

| No | Fitur | Deskripsi | Role |
|----|-------|-----------|------|
| 8 | Tambah Data Warga | Admin menambahkan data warga baru: nama, NIK, nomor HP, email, alamat, RT/RW, foto KTP. | Admin |
| 9 | Lihat Daftar Warga | Admin melihat daftar warga dengan fitur pencarian dan filter (status aktif/nonaktif, blok rumah). | Admin |
| 10 | Edit Data Warga | Admin memperbarui informasi warga. Warga dapat memperbarui data pribadi (email, HP, foto profil). | Admin, Pengguna (self) |
| 11 | Hapus/Nonaktifkan Warga | Admin dapat menonaktifkan akun warga yang pindah atau tidak aktif (soft delete). | Admin |
| 12 | Detail Profil Warga | Setiap warga memiliki halaman profil berisi data diri, riwayat pembayaran, dan status tagihan. | Admin, Pengguna (self) |

### 4.4 Manajemen Tagihan & Pembayaran

#### 4.4.1 Description and Priority

Fitur inti sistem: pembuatan tagihan oleh admin, pengiriman bukti pembayaran oleh warga, dan verifikasi oleh admin. Upload foto bukti menggunakan format JPG/PNG maks. 5MB. 

**Prioritas:** High.

#### 4.4.2 Stimulus/Response Sequences

- Admin membuat tagihan → n8n trigger → Push notif ke seluruh warga.
- Warga upload bukti bayar → Status 'pending' → Notif ke admin → Admin verifikasi → Status berubah 'lunas'/'ditolak' → Notif ke warga.

#### 4.4.3 Functional Requirements

| No | Fitur | Deskripsi | Role |
|----|-------|-----------|------|
| 13 | Buat Tagihan | Admin membuat tagihan periodik (bulanan/insidental) dengan nominal, periode, dan deadline. | Admin |
| 14 | Submit Pembayaran | Warga mengisi form pembayaran: pilih tagihan, nominal, tanggal, metode bayar, dan upload foto bukti (JPG/PNG, maks 5MB). | Pengguna |
| 15 | Verifikasi Pembayaran | Admin melihat daftar pembayaran pending, preview foto bukti, dan melakukan konfirmasi atau penolakan dengan catatan. | Admin |
| 16 | Riwayat Pembayaran | Admin melihat seluruh riwayat. Warga melihat riwayat pribadi dengan status (pending/lunas/ditolak). | Admin, Pengguna |
| 17 | Edit/Hapus Pembayaran | Admin dapat mengedit atau menghapus data pembayaran. Warga dapat menarik pembayaran yang masih pending. | Admin, Pengguna (pending) |

### 4.5 Pengeluaran & Transparansi Anggaran

#### 4.5.1 Description and Priority

Modul pencatatan dan tampilan pengeluaran kas lingkungan yang dapat diakses oleh seluruh warga untuk menjamin transparansi. 

**Prioritas:** High.

#### 4.5.2 Functional Requirements

| No | Fitur | Deskripsi | Role |
|----|-------|-----------|------|
| 18 | Catat Pengeluaran | Admin mencatat pengeluaran: tanggal, kategori (kebersihan, keamanan, sosial, dll.), nominal, deskripsi, dan opsional foto nota. | Admin |
| 19 | Halaman Transparansi | Semua warga dapat melihat rincian pengeluaran, ringkasan per kategori, grafik pie alokasi dana, dan saldo kas terkini. | Admin, Pengguna |
| 20 | Edit/Hapus Pengeluaran | Admin dapat mengedit atau menghapus catatan pengeluaran. | Admin |
| 21 | Ringkasan Keuangan | Sistem menampilkan total pemasukan, total pengeluaran, dan saldo kas per periode yang dipilih. | Admin, Pengguna |

### 4.6 Panduan Pengguna

#### 4.6.1 Description and Priority

Menyediakan materi panduan, FAQ, dan tutorial video di dalam aplikasi. 

**Prioritas:** Medium.

#### 4.6.2 Functional Requirements

| No | Fitur | Deskripsi | Role |
|----|-------|-----------|------|
| 22 | Halaman Panduan | Panduan penggunaan aplikasi dalam format teks + gambar. | Admin, Pengguna |
| 23 | FAQ | Daftar pertanyaan dan jawaban umum yang dapat dikelola admin. | Admin, Pengguna |
| 24 | Video Tutorial | Link atau embed video panduan penggunaan aplikasi. | Admin, Pengguna |

### 4.7 Kalender & Jadwal Kegiatan

#### 4.7.1 Description and Priority

Fitur kalender interaktif untuk menampilkan dan mengelola jadwal kegiatan lingkungan, dilengkapi notifikasi otomatis H-1 dan H-0. 

**Prioritas:** Medium.

#### 4.7.2 Functional Requirements

| No | Fitur | Deskripsi | Role |
|----|-------|-----------|------|
| 25 | Tambah Kegiatan | Admin menambahkan kegiatan ke kalender: judul, tanggal, waktu, lokasi, deskripsi. | Admin |
| 26 | Lihat Kalender | Semua pengguna melihat kalender interaktif dengan kegiatan lingkungan. | Admin, Pengguna |
| 27 | Notifikasi Jadwal | Sistem mengirim notifikasi H-1 dan H-0 sebelum kegiatan via push notification (n8n). | Admin, Pengguna |
| 28 | Edit/Hapus Kegiatan | Admin dapat memperbarui atau membatalkan jadwal kegiatan. | Admin |

### 4.8 Laporan Keuangan

#### 4.8.1 Description and Priority

Generasi laporan keuangan otomatis dalam format PDF untuk admin dan warga. 

**Prioritas:** High.

#### 4.8.2 Functional Requirements

| No | Fitur | Deskripsi | Role |
|----|-------|-----------|------|
| 29 | Laporan Keuangan Periodik | Admin menghasilkan laporan keuangan bulanan/tahunan dalam format PDF berisi pemasukan, pengeluaran, saldo, dan daftar pembayar. | Admin |
| 30 | Laporan Tunggakan | Admin melihat dan mengekspor daftar warga dengan tunggakan pembayaran. | Admin |
| 31 | Laporan Pribadi Warga | Warga dapat melihat dan mengunduh riwayat pembayaran pribadi dalam format PDF. | Pengguna |
| 32 | Statistik Dashboard | Grafik dan statistik visual: tren pembayaran bulanan, perbandingan pemasukan vs pengeluaran. | Admin |

---

## 5. Other Nonfunctional Requirements

### 5.1 Performance Requirements

- **NFR-01:** Response time API untuk endpoint umum tidak boleh melebihi 2 detik pada kondisi normal (beban <= 100 concurrent users).
- **NFR-02:** Proses upload foto bukti pembayaran (maks. 5MB) harus selesai dalam waktu 10 detik pada koneksi 3G.
- **NFR-03:** Generasi laporan PDF untuk data 1 tahun harus selesai dalam 30 detik.
- **NFR-04:** Sistem harus mampu menangani minimal 500 concurrent users tanpa degradasi performa yang signifikan.
- **NFR-05:** Database query untuk daftar pembayaran harus menggunakan pagination (maksimal 50 data per halaman).
- **NFR-06:** Push notification harus terkirim dalam waktu 60 detik setelah event dipicu.

### 5.2 Safety Requirements

- **NFR-07:** Semua data pembayaran dan keuangan harus di-backup secara otomatis setiap hari ke storage terpisah.
- **NFR-08:** Sistem harus menyimpan log audit untuk semua aksi kritis (verifikasi pembayaran, perubahan data warga, pengeluaran kas).
- **NFR-09:** Foto bukti pembayaran harus disimpan secara permanen dan tidak dapat dihapus oleh warga setelah verifikasi.
- **NFR-10:** Sistem harus memiliki mekanisme rollback untuk transaksi database yang gagal.

### 5.3 Security Requirements

- **NFR-11:** Semua komunikasi antara mobile app dan server HARUS menggunakan HTTPS (TLS 1.2 atau lebih tinggi).
- **NFR-12:** Password pengguna HARUS di-hash menggunakan bcrypt sebelum disimpan di database.
- **NFR-13:** JWT access token memiliki masa berlaku 24 jam; refresh token 30 hari.
- **NFR-14:** Endpoint API HARUS dilindungi middleware autentikasi kecuali endpoint publik (login, forgot password).
- **NFR-15:** Sistem HARUS menerapkan rate limiting pada endpoint login (maksimal 5 percobaan per menit per IP).
- **NFR-16:** Data sensitif (NIK, nomor HP) HARUS dienkripsi di database menggunakan AES-256.
- **NFR-17:** Akses foto di object storage HARUS menggunakan pre-signed URL dengan masa berlaku terbatas.
- **NFR-18:** Input pengguna HARUS divalidasi dan di-sanitasi untuk mencegah SQL Injection dan XSS.

### 5.4 Software Quality Attributes

- **Usability:** Antarmuka aplikasi harus dapat dioperasikan oleh pengguna awam tanpa pelatihan khusus. Task utama (submit pembayaran) harus dapat diselesaikan dalam 5 langkah atau kurang.

- **Reliability:** Sistem harus memiliki uptime minimal 99% (downtime tidak lebih dari 7.2 jam/bulan).

- **Maintainability:** Kode backend harus mengikuti PSR-12 coding standard dan arsitektur MVC Laravel. Cakupan unit test minimal 80%.

- **Portability:** Aplikasi mobile harus tersedia di Android (API 21+) dan iOS (13+).

- **Scalability:** Arsitektur Docker memungkinkan horizontal scaling untuk mengakomodasi pertumbuhan jumlah warga.

- **Testability:** Setiap endpoint API harus memiliki API test yang dapat dijalankan secara otomatis.

### 5.5 Business Rules

- Hanya Admin yang dapat membuat tagihan, memverifikasi pembayaran, dan mencatat pengeluaran.
- Warga hanya dapat melihat dan mengelola data pribadi mereka sendiri.
- Pembayaran yang sudah berstatus 'lunas' tidak dapat diubah atau dihapus.
- Pembayaran yang berstatus 'pending' dapat dibatalkan oleh warga yang bersangkutan.
- Saldo kas lingkungan diperbarui secara otomatis setelah admin memverifikasi pembayaran.
- Laporan keuangan hanya dapat digenerate dan diunduh oleh Admin.
- Warga yang dinonaktifkan tidak dapat login tetapi data historisnya tetap tersimpan.

---

## 6. Other Requirements

### 6.1 Database Requirements

- Sistem menggunakan MySQL 8.0 sebagai database utama.
- Migrasi database dikelola menggunakan Laravel Migrations untuk version control schema.
- Indeks database harus diterapkan pada kolom yang sering diquery (user_id, tagihan_id, status, created_at).
- Soft delete diterapkan pada tabel warga dan pembayaran untuk menjaga integritas data historis.

### 6.2 Internationalization Requirements

- Bahasa utama aplikasi adalah Bahasa Indonesia.
- Format tanggal menggunakan format Indonesia (DD/MM/YYYY).
- Format mata uang menggunakan Rupiah (Rp) dengan pemisah ribuan titik.

### 6.3 Legal Requirements

- Pengumpulan dan penyimpanan data pribadi warga (NIK, nomor HP) harus sesuai dengan Undang-Undang Perlindungan Data Pribadi (UU PDP) Indonesia.
- Pengguna harus memberikan persetujuan (consent) sebelum data pribadi mereka diproses.
- Data pribadi tidak boleh dibagikan kepada pihak ketiga tanpa persetujuan pengguna.

### 6.4 Machine Learning Requirements

- Model prediksi keterlambatan menggunakan algoritma Random Forest dengan data historis minimal 3 bulan.
- ML service di-deploy sebagai REST API (FastAPI) yang dikonsumsi oleh backend Laravel.
- Insight prediksi dikirimkan ke admin secara berkala (mingguan) melalui workflow n8n.
- Model harus di-retrain secara berkala setiap bulan menggunakan data terbaru.

---

## Appendix A: Glossary

| Istilah | Definisi |
|---------|----------|
| API | Application Programming Interface - Antarmuka pemrograman untuk komunikasi antar sistem. |
| JWT | JSON Web Token - Standar token untuk autentikasi dan otorisasi berbasis JSON. |
| n8n | Platform workflow automation open-source untuk mengotomasi proses dan integrasi layanan. |
| Perelek | Sistem iuran warga berbasis gotong royong yang dipraktikkan di masyarakat Indonesia. |
| RBAC | Role-Based Access Control - Sistem kontrol akses berdasarkan peran pengguna. |
| SRS | Software Requirements Specification - Dokumen spesifikasi kebutuhan perangkat lunak. |
| MinIO | Object storage open-source yang kompatibel dengan Amazon S3 API. |
| FCM | Firebase Cloud Messaging - Layanan push notification dari Google. |
| Docker | Platform containerisasi untuk menjalankan aplikasi dalam lingkungan terisolasi. |
| OTP | One-Time Password - Kode verifikasi satu kali yang dikirim via email atau SMS. |
| Soft Delete | Teknik penghapusan data secara logis tanpa menghapus record dari database. |
| Pending | Status pembayaran yang belum diverifikasi oleh admin. |
| Lunas | Status pembayaran yang telah diverifikasi dan dikonfirmasi oleh admin. |
| Ditolak | Status pembayaran yang ditolak oleh admin karena bukti tidak valid. |

---

## Appendix B: Analysis Models


**Use Case Diagram**
![Diagram Use Case](UseCaseDiagram_fix.jpg)

**Activity Diagram**
![Activity Diagram](ActivityDiagram.jpg)
![Activity Diagram Fitur 4](ActivityDiagramFitur-4.png)
![Activity Diagram Fitur 5](ActivityDiagramFitur-5.png)
![Activity Diagram Fitur 6](ActivityDiagramFitur-6.png)
![Activity Diagram Fitur 7](ActivityDiagramFitur-7.png)





**Rancangan Database**

**Rancangan Arsitektur sistem**
<img width="600" height="652" alt="Diagram Arsitektur sistem" src="https://github.com/user-attachments/assets/db7040d1-3e72-45b6-b7a2-1ce94bc85625" />



**Rancangan Arsitektur Teknologi**
<img width="735" height="606" alt="Diagram Teknologi" src="https://github.com/user-attachments/assets/87698218-cbf9-4f4b-99ba-abf545e78af4" />


**Class Diagram**

**Sequence Diagram**

**Component Diagram**

**Deployment Diagram**

**UI&UX**
**Versi Web**
**Login**

#### 1. Halaman Login
![UI Login](UiUxLogin.png)

**Deskripsi:**
Halaman login adalah pintu masuk utama sistem. Pengguna dapat login menggunakan email/nomor HP dan password. Sistem akan memvalidasi kredensial dan menghasilkan JWT token untuk autentikasi. Fitur-fitur:
- Input field untuk email/nomor HP
- Input field untuk password
- Tombol "Login" untuk submit
- Link "Lupa Password" untuk reset password
- Opsi "Ingat Saya" untuk memperpanjang sesi

---

#### 2. Halaman Dashboard Admin
![UI Dashboard Admin](UiUxDashboardAdmin.png)

**Deskripsi:**
Dashboard Admin menampilkan ringkasan komprehensif status sistem. Admin dapat melihat total warga, total pemasukan bulan ini, total pengeluaran, saldo kas, jumlah pembayaran pending, grafik tren pembayaran, dan notifikasi terbaru. Desain responsif dengan widget-widget interaktif untuk monitoring real-time.

---

#### 3. Halaman Dashboard Warga
![UI Dashboard Warga](UiUxDashboardWarga.png)

**Deskripsi:**
Dashboard Warga menampilkan informasi personal yang relevan untuk warga. Meliputi status tagihan aktif, riwayat pembayaran terakhir, pengumuman terbaru dari admin, saldo kas lingkungan, dan kalender jadwal kegiatan komunitas. Antarmuka dirancang sederhana dan user-friendly.

---

#### 4. Halaman Daftar Warga (Admin)
![UI Daftar Warga Admin](UiUxDaftarWargaAdmin.png)

**Deskripsi:**
Halaman ini menampilkan daftar lengkap semua warga yang terdaftar dalam sistem dengan informasi detail meliputi nama, nomor identitas, status keanggotaan, dan aksi pengelolaan. Fitur yang tersedia:
- Pencarian warga berdasarkan nama atau nomor identitas
- Filter berdasarkan status (aktif/nonaktif)
- Filter berdasarkan blok/lokasi rumah
- Tombol aksi untuk melihat detail, mengedit, dan menonaktifkan akun warga
- Pagination untuk menampilkan data secara bertahap (maksimal 50 data per halaman)
- Tombol tambah warga baru

---

#### 5. Halaman Pembayaran Warga
![UI Pembayaran Warga](UiUxPembayaranWarga.png)

**Deskripsi:**
Halaman pembayaran memungkinkan warga untuk mengirimkan bukti pembayaran iuran. Warga mengisi form pembayaran dengan memilih tagihan yang akan dibayar, nominal, tanggal pembayaran, metode bayar, dan upload foto bukti (JPG/PNG, maks 5MB). Sistem akan mencatat status pembayaran sebagai "pending" menunggu verifikasi admin.

---

#### 6. Halaman Verifikasi Pembayaran (Admin)
![UI Pembayaran Warga Admin](UiUxPembayaranWargaAdmin.png)

**Deskripsi:**
Halaman verifikasi pembayaran memungkinkan admin untuk melihat daftar pembayaran yang pending, preview foto bukti pembayaran, dan melakukan konfirmasi atau penolakan dengan catatan. Admin dapat:
- Melihat detail pembayaran dan foto bukti
- Mengubah status pembayaran menjadi "lunas" atau "ditolak"
- Menambahkan catatan atau feedback untuk warga
- Melihat riwayat verifikasi pembayaran

---

#### 7. Halaman Profil Warga
![UI Profil Warga](UiUxProfilWarga.png)

**Deskripsi:**
Halaman profil menampilkan informasi lengkap warga termasuk data diri, riwayat pembayaran, dan status tagihan. Warga dapat melihat:
- Data pribadi (nama, NIK, nomor HP, email, alamat)
- Foto profil dan foto KTP
- Riwayat pembayaran lengkap dengan status
- Tagihan yang masih pending
- Opsi untuk mengedit informasi pribadi
- Opsi untuk download laporan pembayaran pribadi

---

#### 8. Halaman Laporan Keuangan (Admin)
![UI Laporan Admin](UiUxLaporanAdmin.png)

**Deskripsi:**
Halaman laporan keuangan admin menyajikan analisis komprehensif keuangan lingkungan. Admin dapat:
- Melihat ringkasan pemasukan, pengeluaran, dan saldo
- Melihat grafik tren pembayaran bulanan
- Melihat perbandingan pemasukan vs pengeluaran
- Melihat daftar pembayar dan tunggakan pembayaran
- Generate dan download laporan dalam format PDF
- Filter laporan berdasarkan periode waktu

---

#### 9. Halaman Laporan Warga
![UI Laporan Warga](UiUxLaporanWarga.png)

**Deskripsi:**
Halaman laporan warga menampilkan riwayat pembayaran pribadi dalam format yang terstruktur. Warga dapat:
- Melihat riwayat pembayaran lengkap
- Melihat status setiap pembayaran (pending/lunas/ditolak)
- Melihat ringkasan total pembayaran per bulan/tahun
- Download laporan pembayaran pribadi dalam format PDF
- Filter riwayat berdasarkan periode waktu



---

## Appendix C: To Be Determined List

| No | Item TBD | Keterangan |
|----|----------|-----------|
| 1 | Integrasi Payment Gateway | Integrasi otomatis dengan payment gateway (Midtrans/Xendit) direncanakan untuk versi 2.0. |
| 2 | Multi-Lingkungan Support | Dukungan untuk lebih dari satu RT/RW dalam satu instance aplikasi. |
| 3 | Fitur Chat/Forum Warga | Fitur komunikasi antar warga dalam aplikasi. |
| 4 | Integrasi SMS Gateway | Pengiriman OTP dan notifikasi melalui SMS untuk pengguna tanpa smartphone. |
| 5 | Web Admin Dashboard | Panel admin berbasis web sebagai alternatif aplikasi mobile. |

---

**Copyright © 2025 Tim Pengembang Perelek Digital. Dokumen ini bersifat rahasia dan hanya untuk keperluan internal pengembangan sistem.**
