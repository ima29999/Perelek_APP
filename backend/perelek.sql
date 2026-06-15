-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3307
-- Generation Time: Jun 11, 2026 at 04:05 PM
-- Server version: 8.0.30
-- PHP Version: 8.1.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `perelek`
--

-- --------------------------------------------------------

--
-- Table structure for table `events`
--

CREATE TABLE `events` (
  `id` bigint UNSIGNED NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `location` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `start_date` datetime NOT NULL,
  `end_date` datetime DEFAULT NULL,
  `color` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '#3B82F6',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `events`
--

INSERT INTO `events` (`id`, `title`, `description`, `location`, `start_date`, `end_date`, `color`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'Rapat RT Bulanan', 'Rapat koordinasi bulanan', 'Balai RT', '2026-06-16 22:24:01', NULL, '#3B82F6', 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(2, 'Kerja Bakti Lingkungan', 'Gotong royong kebersihan', 'Seluruh area RT', '2026-06-23 22:24:01', NULL, '#10B981', 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(3, 'Posyandu Rutin', 'Posyandu balita dan lansia', 'Rumah Bu PKK', '2026-07-01 22:24:01', NULL, '#F59E0B', 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(4, 'Lomba 17 Agustus', 'Lomba HUT RI', 'Lapangan RT', '2026-08-17 08:00:00', NULL, '#EF4444', 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01');

-- --------------------------------------------------------

--
-- Table structure for table `expenses`
--

CREATE TABLE `expenses` (
  `id` bigint UNSIGNED NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `category` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `nominal` decimal(16,2) NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `date` date NOT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `expenses`
--

INSERT INTO `expenses` (`id`, `title`, `category`, `nominal`, `description`, `date`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'Pengecatan Pos Ronda', 'Keamanan', '350000.00', NULL, '2025-01-15', 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(2, 'Lampu Jalan Baru', 'Infrastruktur', '850000.00', NULL, '2025-02-01', 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(3, 'Alat Kebersihan', 'Kebersihan', '120000.00', NULL, '2025-02-10', 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(4, 'Kegiatan 17 Agustus', 'Kegiatan', '1200000.00', NULL, '2025-08-10', 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(5, 'Bensin Genset', 'Operasional', '200000.00', NULL, '2025-03-05', 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(6, 'ATK Administrasi RT', 'Administrasi', '85000.00', NULL, '2025-03-20', 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(7, 'Perbaikan Jalan Berlubang', 'Infrastruktur', '500000.00', NULL, '2025-04-12', 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(8, 'Hadiah Lomba Anak', 'Kegiatan', '300000.00', NULL, '2025-08-17', 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01');

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `connection` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `queue` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `exception` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `faqs`
--

CREATE TABLE `faqs` (
  `id` bigint UNSIGNED NOT NULL,
  `question` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `answer` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `category` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `order` int NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `faqs`
--

INSERT INTO `faqs` (`id`, `question`, `answer`, `category`, `order`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Bagaimana cara membayar iuran RT?', 'Bayar via aplikasi dengan upload bukti transfer, atau langsung ke bendahara RT. Metode: transfer bank, tunai, QRIS.', 'Pembayaran', 1, 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(2, 'Kapan batas waktu pembayaran iuran?', 'Batas waktu umumnya tanggal 10 setiap bulan. Lihat deadline di detail masing-masing tagihan.', 'Pembayaran', 2, 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(3, 'Bagaimana jika pembayaran saya ditolak?', 'Anda mendapat notifikasi beserta alasan. Kirim ulang bukti yang lebih jelas atau hubungi admin RT.', 'Pembayaran', 3, 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(4, 'Bagaimana cara mendaftar akun?', 'Akun dibuat oleh admin RT. Hubungi ketua atau sekretaris RT untuk mendaftar dan mendapatkan akses login.', 'Akun', 4, 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(5, 'Bagaimana cara reset password?', 'Klik \"Lupa Password\" di halaman login, masukkan email, ikuti instruksi yang dikirim ke email Anda.', 'Akun', 5, 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(6, 'Apakah data saya aman?', 'Ya. Data sensitif (NIK, nomor HP) dienkripsi AES-256. Kami menjaga privasi seluruh warga.', 'Keamanan', 6, 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(7, 'Bagaimana melihat transparansi keuangan?', 'Buka menu Laporan Keuangan untuk melihat ringkasan pemasukan dan pengeluaran RT secara transparan.', 'Keuangan', 7, 1, '2026-06-11 15:24:01', '2026-06-11 15:24:01');

-- --------------------------------------------------------

--
-- Table structure for table `invoices`
--

CREATE TABLE `invoices` (
  `id` bigint UNSIGNED NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `nominal` decimal(16,2) NOT NULL,
  `period` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deadline` date DEFAULT NULL,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `invoices`
--

INSERT INTO `invoices` (`id`, `title`, `description`, `nominal`, `period`, `deadline`, `created_by`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Iuran Keamanan Januari 2025', 'Iuran keamanan lingkungan RT bulan Januari', '50000.00', 'Januari 2025', '2025-01-10', 1, 1, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(2, 'Iuran Keamanan Februari 2025', 'Iuran keamanan lingkungan RT bulan Februari', '50000.00', 'Februari 2025', '2025-02-10', 1, 1, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(3, 'Iuran Keamanan Maret 2025', 'Iuran keamanan lingkungan RT bulan Maret', '50000.00', 'Maret 2025', '2025-03-10', 1, 1, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(4, 'Iuran Keamanan April 2025', 'Iuran keamanan lingkungan RT bulan April', '50000.00', 'April 2025', '2025-04-10', 1, 1, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(5, 'Iuran Keamanan Mei 2025', 'Iuran keamanan lingkungan RT bulan Mei', '50000.00', 'Mei 2025', '2025-05-10', 1, 1, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(6, 'Iuran Keamanan Juni 2025', 'Iuran keamanan lingkungan RT bulan Juni', '50000.00', 'Juni 2025', '2025-06-10', 1, 1, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(7, 'Iuran Kebersihan Q1 2025', 'Triwulan 1', '75000.00', 'Q1 2025', '2025-03-31', 1, 1, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(8, 'Kas RT Tahunan 2025', 'Kas tahunan', '150000.00', 'Tahunan 2025', '2025-01-31', 1, 1, '2026-06-11 15:24:00', '2026-06-11 15:24:00');

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int UNSIGNED NOT NULL,
  `migration` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '2014_10_12_000000_create_users_table', 1),
(2, '2014_10_12_100000_create_password_reset_tokens_table', 1),
(3, '2019_08_19_000000_create_failed_jobs_table', 1),
(4, '2019_12_14_000001_create_personal_access_tokens_table', 1),
(5, '2026_05_15_000001_add_fields_to_users_table', 1),
(6, '2026_05_15_000002_create_invoices_table', 1),
(7, '2026_05_15_000003_create_payments_table', 1),
(8, '2026_05_15_000004_create_expenses_table', 1),
(9, '2026_05_15_000005_create_events_table', 1),
(10, '2026_05_15_000006_create_faqs_table', 1);

-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `id` bigint UNSIGNED NOT NULL,
  `invoice_id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `amount` decimal(16,2) NOT NULL,
  `payment_date` date NOT NULL,
  `method` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `proof_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `verified_by` bigint UNSIGNED DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`id`, `invoice_id`, `user_id`, `amount`, `payment_date`, `method`, `proof_path`, `status`, `notes`, `verified_by`, `deleted_at`, `created_at`, `updated_at`) VALUES
(1, 1, 2, '50000.00', '2026-04-20', 'qris', 'demo_2_1.jpg', 'confirmed', NULL, 1, NULL, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(2, 2, 2, '50000.00', '2026-04-17', 'tunai', 'demo_2_2.jpg', 'confirmed', NULL, 1, NULL, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(3, 3, 2, '50000.00', '2026-05-01', 'transfer', 'demo_2_3.jpg', 'confirmed', NULL, 1, NULL, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(4, 4, 2, '50000.00', '2026-04-25', 'qris', 'demo_2_4.jpg', 'pending', NULL, NULL, NULL, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(5, 1, 3, '50000.00', '2026-05-10', 'tunai', 'demo_3_1.jpg', 'rejected', 'Bukti tidak jelas', 1, NULL, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(6, 2, 3, '50000.00', '2026-05-02', 'qris', 'demo_3_2.jpg', 'pending', NULL, NULL, NULL, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(7, 4, 3, '50000.00', '2026-05-29', 'qris', 'demo_3_4.jpg', 'confirmed', NULL, 1, NULL, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(8, 5, 3, '50000.00', '2026-05-11', 'transfer', 'demo_3_5.jpg', 'confirmed', NULL, 1, NULL, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(9, 1, 4, '50000.00', '2026-04-16', 'transfer', 'demo_4_1.jpg', 'confirmed', NULL, 1, NULL, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(10, 3, 4, '50000.00', '2026-05-03', 'tunai', 'demo_4_3.jpg', 'confirmed', NULL, 1, NULL, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(11, 4, 4, '50000.00', '2026-05-14', 'transfer', 'demo_4_4.jpg', 'rejected', 'Bukti tidak jelas', 1, NULL, '2026-06-11 15:24:00', '2026-06-11 15:24:00'),
(12, 5, 4, '50000.00', '2026-05-12', 'tunai', 'demo_4_5.jpg', 'confirmed', NULL, 1, NULL, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(13, 1, 5, '50000.00', '2026-05-12', 'tunai', 'demo_5_1.jpg', 'rejected', 'Bukti tidak jelas', 1, NULL, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(14, 2, 5, '50000.00', '2026-05-16', 'tunai', 'demo_5_2.jpg', 'confirmed', NULL, 1, NULL, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(15, 5, 5, '50000.00', '2026-05-19', 'qris', 'demo_5_5.jpg', 'rejected', 'Bukti tidak jelas', 1, NULL, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(16, 3, 6, '50000.00', '2026-05-18', 'transfer', 'demo_6_3.jpg', 'confirmed', NULL, 1, NULL, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(17, 5, 6, '50000.00', '2026-05-10', 'qris', 'demo_6_5.jpg', 'confirmed', NULL, 1, NULL, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(18, 2, 7, '50000.00', '2026-06-06', 'tunai', 'demo_7_2.jpg', 'confirmed', NULL, 1, NULL, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(19, 4, 7, '50000.00', '2026-04-12', 'transfer', 'demo_7_4.jpg', 'pending', NULL, NULL, NULL, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(20, 2, 8, '50000.00', '2026-06-05', 'qris', 'demo_8_2.jpg', 'rejected', 'Bukti tidak jelas', 1, NULL, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(21, 3, 8, '50000.00', '2026-04-21', 'transfer', 'demo_8_3.jpg', 'pending', NULL, NULL, NULL, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(22, 4, 8, '50000.00', '2026-05-05', 'tunai', 'demo_8_4.jpg', 'confirmed', NULL, 1, NULL, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(23, 5, 8, '50000.00', '2026-05-25', 'qris', 'demo_8_5.jpg', 'confirmed', NULL, 1, NULL, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(24, 1, 9, '50000.00', '2026-05-24', 'tunai', 'demo_9_1.jpg', 'confirmed', NULL, 1, NULL, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(25, 2, 9, '50000.00', '2026-06-03', 'transfer', 'demo_9_2.jpg', 'confirmed', NULL, 1, NULL, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(26, 3, 9, '50000.00', '2026-04-23', 'tunai', 'demo_9_3.jpg', 'pending', NULL, NULL, NULL, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(27, 4, 9, '50000.00', '2026-05-31', 'qris', 'demo_9_4.jpg', 'rejected', 'Bukti tidak jelas', 1, NULL, '2026-06-11 15:24:01', '2026-06-11 15:24:01'),
(28, 5, 9, '50000.00', '2026-05-27', 'transfer', 'demo_9_5.jpg', 'confirmed', NULL, 1, NULL, '2026-06-11 15:24:01', '2026-06-11 15:24:01');

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `tokenable_id` bigint UNSIGNED NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `abilities` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint UNSIGNED NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'user',
  `nik` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `rt_rw` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ktp_photo` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `profile_photo` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `remember_token` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `email_verified_at`, `password`, `role`, `nik`, `phone`, `address`, `rt_rw`, `ktp_photo`, `profile_photo`, `is_active`, `remember_token`, `created_at`, `updated_at`, `deleted_at`) VALUES
(1, 'Admin Perelek', 'admin@perelek.local', NULL, '$2y$12$efnen28L/rilnIdVo.cnMOZiLhnOlNfKw/tbnJynr1iroKQCcdGni', 'admin', NULL, 'eyJpdiI6ImRzY2FGME5TNWF1ME1iWk9YZm5OZ2c9PSIsInZhbHVlIjoiRmtueVdYWVpaZkhXWDIvdWh2d1V1dz09IiwibWFjIjoiN2JkYmU2YWYxYjQ5NmNmYjMzYWM5ZGFkYTdiN2RmYTYxMmZjMmY3ZmU4MDc1OWRlY2NlZjZhOGY0ODZhODYxYiIsInRhZyI6IiJ9', NULL, NULL, NULL, NULL, 1, NULL, '2026-06-11 15:23:57', '2026-06-11 15:23:57', NULL),
(2, 'Budi Santoso', 'budi@example.com', NULL, '$2y$12$Z/.AWQBYkfq0Q/Tcle2BN.yP9quE80UPtiZV.bRAJ51FssSKUlxdm', 'user', 'eyJpdiI6ImYzUFhDa2FZSnJUMldLOHpiU2UvWHc9PSIsInZhbHVlIjoibXh1Z1lVMWhiUlZpZGg5VkIvQTFsS28vYnRKaVFWM0dYQ1cza2Jld0VCUT0iLCJtYWMiOiJjYzUwYjExM2MyNzU4MGM3MmMxYjFmN2Q5NjYzZDdmYWY3MGYwNGY2MWI4MTBkMGU5ZjI2YzkzY2E3YzNiODE5IiwidGFnIjoiIn0=', 'eyJpdiI6ImxvYkRKSUlJbExSLzlVR2FEeHcweEE9PSIsInZhbHVlIjoiM3cvdTdmRjNTZXF1eGpSOWo4b2dIdz09IiwibWFjIjoiNzNkZDZlNDE0ZTkwNjhhOWIxN2ExNjI5ZGFlYmIyZjQ1OTI1YmI1N2E1ZDYzZDI5YzhkNzEzODcwMDBkN2ExNCIsInRhZyI6IiJ9', 'Jl. Mawar No. 12', 'RT 01/RW 05', NULL, NULL, 1, NULL, '2026-06-11 15:23:58', '2026-06-11 15:23:58', NULL),
(3, 'Siti Rahayu', 'siti@example.com', NULL, '$2y$12$gFV5NGKR2jaLmM5ucf7wfOVse882WmfBTTOS9bxhEBH6Uxyx0Ou5y', 'user', 'eyJpdiI6InlMSlJpeTlKRjNVT1oxK1VFRWRyTVE9PSIsInZhbHVlIjoiTlE4c1kyei81b2tqSFJmZmNkNTFDQVAvUXYvaVB2QTdzSEFTSFZjdWdERT0iLCJtYWMiOiIyMmQyOGQ5NTc2ZDA3Yjg3MmNjOWFjMWQzN2QyYjAyMjg2YmEzNjkwNjAyMjQyNzdmMzU3MGMwYzFjZGU2ODY5IiwidGFnIjoiIn0=', 'eyJpdiI6IitxZzRVUzI4bW5aSXkrcDFWMEo0REE9PSIsInZhbHVlIjoiSXJkRHR4ZnZGZHBDeTgwbDBjVFhIZz09IiwibWFjIjoiNzk2NjZkZTUwOTVmNTE3MDBhZmIwNGRmOTQ0OWFjMjFhMzY4ZTUwODA4NmU0ZDY5NjllNzJlMmRmMzFkMTExOCIsInRhZyI6IiJ9', 'Jl. Mawar No. 14', 'RT 01/RW 05', NULL, NULL, 1, NULL, '2026-06-11 15:23:58', '2026-06-11 15:23:58', NULL),
(4, 'Ahmad Fauzi', 'ahmad@example.com', NULL, '$2y$12$P0wPwj.D5ZqedpwuCIiDW.zfAV6ktx1FXMGYdqOJT2Ro/jtD8UaHG', 'user', 'eyJpdiI6Im5KNHNBc29zZDJGd2VTNDBUSS9vVXc9PSIsInZhbHVlIjoiR21DV2hXZksxOXg4VTFhRmpRYmZIRmY5b1BadzNaZ0pvOGtHRnVxYmVJOD0iLCJtYWMiOiJkNjQwZTRiMjIzYjYxMmYyNjEzYWM2YjcyNzBjMDVlYWMxOTJlNjM1N2RiMjRmNmZiNjE0ODBiNTcyOWJhNjhlIiwidGFnIjoiIn0=', 'eyJpdiI6Ik4vWENHa2krZThvc3FXMzF5WmFLM3c9PSIsInZhbHVlIjoiYTNaeGF5azQxMjRXQW9jTmtWTjJIZz09IiwibWFjIjoiYTc4ODIwYjhjNjc3NDcyZjE2NmRkNTE4ZTM1OTFhOTQzNDY0NGE5ZjM5MWFhNThmNzJhMzQwNDBlMmVhNDNiNyIsInRhZyI6IiJ9', 'Jl. Melati No. 3', 'RT 01/RW 05', NULL, NULL, 1, NULL, '2026-06-11 15:23:59', '2026-06-11 15:23:59', NULL),
(5, 'Dewi Kusuma', 'dewi@example.com', NULL, '$2y$12$LMy2TwFsloErJKKdPyaI3ejMnBy9EB00SMgR9FWJz4Hxalx73LOaC', 'user', 'eyJpdiI6IjZuRldrRm0vM0cyTVhDSHV4R0pFN2c9PSIsInZhbHVlIjoiQUxjTnZROXYzcjYrVmlKZzNVbzZrZnRqb1h0cWNyclJSZUpWbER1Nk9nND0iLCJtYWMiOiIzNjI2NmZmMTVmNDdmM2QyYzk5NWI4Yjk1MTc4NDc2ODkxMmNiNzVjZDY1OTQ3YTVlYjMxYTY2YzIzYTc5MTk4IiwidGFnIjoiIn0=', 'eyJpdiI6Inl5TmxvVGxHSVlCSFhDYU9MMk5KRFE9PSIsInZhbHVlIjoiWTNlc2RYSVVTM3E2ZFk1aEpPOGFFdz09IiwibWFjIjoiNTEzODFjYTY4OTA3MDM4Y2IyODRmN2NmYzIzYTc2OGY1OGVkMWJmMThmNmJjYmJkOTI0MzdlZDdjYjU2YjE2NCIsInRhZyI6IiJ9', 'Jl. Melati No. 5', 'RT 01/RW 05', NULL, NULL, 1, NULL, '2026-06-11 15:23:59', '2026-06-11 15:23:59', NULL),
(6, 'Hendra Wijaya', 'hendra@example.com', NULL, '$2y$12$gOzNj7JDjAw4D7QIT.Sv1O90CtAVSVLLWk29Twx1Uns30zrtMQHha', 'user', 'eyJpdiI6ImdRSFdBSE1CbnlhN0RLdWFtaW90bmc9PSIsInZhbHVlIjoiZDFpQ2xrMzcxUjBtYlVtaEpuaFFyRElUZyt6VXkzUXY0Y0dkWjhNTkpGTT0iLCJtYWMiOiJlY2Y2MjBkZDM1NzBjNmYxNDBhY2RkY2QzMWU2NGU0OGYyMDYxOTg5MTFmY2UxZmZlN2FkMTNkNjU5ZTMzNGUyIiwidGFnIjoiIn0=', 'eyJpdiI6InlPVm5MYTcwdDZSUVlXU1hKNGFBMWc9PSIsInZhbHVlIjoicFVlNFBid3IxR05MSUVOU3hIWjJnUT09IiwibWFjIjoiYmQyYzUxMzdiYTFjY2UyOWU0YjZkY2I3N2FkNTA2NDA3ZGZmMzMyNWE5YTkwYmYxZWJiMWM3MzMzZDFjMzQyNyIsInRhZyI6IiJ9', 'Jl. Anggrek No. 8', 'RT 01/RW 05', NULL, NULL, 1, NULL, '2026-06-11 15:23:59', '2026-06-11 15:23:59', NULL),
(7, 'Rina Wati', 'rina@example.com', NULL, '$2y$12$u/gIsqY6VXALeufyLhj4oO/ONsVujvZ3ydpQGxQ1jyPlmOm6xZ/.q', 'user', 'eyJpdiI6InJBM2Z2UUE5cUE0V3hpNTRRYzF3Wmc9PSIsInZhbHVlIjoicE5reWJuL2sweElZOHBLVzlTOEZYNWF6eVkwVyt3YXhvb0dETzF6YlZlYz0iLCJtYWMiOiI5MWYwZDNmYzA4NGM3ZjM3MTMxMWZjNWViNjNjZDkxYzE4OGE2OTVjNDE1ZWY2YmFlYTg4NTFlODc2NmJiMDQyIiwidGFnIjoiIn0=', 'eyJpdiI6Ik0zdEYwREEyR3hibWxFSDhuWTMvTGc9PSIsInZhbHVlIjoieGhUOHdXcG5ESldTdzVhRWd5SUtqUT09IiwibWFjIjoiYjMyZTNkMGE2MDEyOWNlNDhiMzU4MWQ0Nzg5YzM0YjBhNGExMzk0ZDFmZGM4ZjlkZmQwNjc2Nzk5ODE4ZGJmNCIsInRhZyI6IiJ9', 'Jl. Anggrek No. 10', 'RT 01/RW 05', NULL, NULL, 1, NULL, '2026-06-11 15:24:00', '2026-06-11 15:24:00', NULL),
(8, 'Joko Susanto', 'joko@example.com', NULL, '$2y$12$T1RNyN.Zwf/iTiRZm7.LsuJy6EHKsqysoE5jtXoHeMe1EvLmNAX7i', 'user', 'eyJpdiI6ImhQaktEcVJaNUtRRlhiOHhoZkEyM2c9PSIsInZhbHVlIjoiZTE3OWZvVG1OMjBrTjE2NzQwbGxJNVpDV01PbU5WSFB1SUFtUnNlSHMrbz0iLCJtYWMiOiJmMTYzNDZiMWY2NWZiOTgzM2Q3MWM5MDEzODczNGFmMDBkZGM1OGFiMzg5N2EzNWYxZGQxMGVhM2I0NDQwMTliIiwidGFnIjoiIn0=', 'eyJpdiI6ImVkemVadUpOYURIWTQ3K0l0YW1keHc9PSIsInZhbHVlIjoiZ3BtUVdHeThqZ29iYXBrTVY3ZjkrQT09IiwibWFjIjoiNGJjMzQ3ODA5YmI3YjgyZTY1NWEyOTkxZTIyM2VlNjRiZmJhMmI1MGMxYWIxOTc4OGU5OTc4ZGY5YTIxNmU5NiIsInRhZyI6IiJ9', 'Jl. Dahlia No. 2', 'RT 01/RW 05', NULL, NULL, 1, NULL, '2026-06-11 15:24:00', '2026-06-11 15:24:00', NULL),
(9, 'Lestari Indah', 'lestari@example.com', NULL, '$2y$12$I7DxuldP2OWIVZ/6wJXmp..haxcvV6wuhaeCLRjrZLYUiu2.lRN16', 'user', 'eyJpdiI6IldxMDFScG1handyckdaSkZVZUc4OFE9PSIsInZhbHVlIjoiYnBjNnF3Y2hpSjBHZGtFTm1hc0dCS29tdFJvaDNWNWtXSm5uZEZhL2ovMD0iLCJtYWMiOiI0NjI5ZjE4NDNlMWJkNDc1NWUyYWMyMDhhNGRmYWFlYzhkOWQ0NTg3YzhhMjkyOWQzODJiMTQ1MjY3MzA3NDY1IiwidGFnIjoiIn0=', 'eyJpdiI6Ik1ZVlpVWUE3RlNVUUFLRmhNQ0dHcXc9PSIsInZhbHVlIjoiR2xkSm42YnE1d1hPVSs5VVV5S1MwZz09IiwibWFjIjoiYmMwZWMyNDA3OTkyOTA2OWEyZWMyM2Q4MDYzMWE3NTkwNTU0MzFjMDhlODcxMjUxYmM0OWEyNmRlZDNjNjlkYiIsInRhZyI6IiJ9', 'Jl. Dahlia No. 4', 'RT 01/RW 05', NULL, NULL, 1, NULL, '2026-06-11 15:24:00', '2026-06-11 15:24:00', NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `events`
--
ALTER TABLE `events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `events_created_by_foreign` (`created_by`);

--
-- Indexes for table `expenses`
--
ALTER TABLE `expenses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `expenses_created_by_foreign` (`created_by`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indexes for table `faqs`
--
ALTER TABLE `faqs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `invoices`
--
ALTER TABLE `invoices`
  ADD PRIMARY KEY (`id`),
  ADD KEY `invoices_created_by_foreign` (`created_by`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `payments_invoice_id_foreign` (`invoice_id`),
  ADD KEY `payments_user_id_foreign` (`user_id`),
  ADD KEY `payments_verified_by_foreign` (`verified_by`);

--
-- Indexes for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`),
  ADD UNIQUE KEY `users_phone_unique` (`phone`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `events`
--
ALTER TABLE `events`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `expenses`
--
ALTER TABLE `expenses`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `faqs`
--
ALTER TABLE `faqs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `invoices`
--
ALTER TABLE `invoices`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `events`
--
ALTER TABLE `events`
  ADD CONSTRAINT `events_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `expenses`
--
ALTER TABLE `expenses`
  ADD CONSTRAINT `expenses_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `invoices`
--
ALTER TABLE `invoices`
  ADD CONSTRAINT `invoices_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_invoice_id_foreign` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `payments_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `payments_verified_by_foreign` FOREIGN KEY (`verified_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
