import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Palet warna Perelek — modern, gradasi hangat (oranye/peach) terinspirasi
/// desain aplikasi pesan-antar makanan, lengkap dengan varian Daylight
/// (terang) & Midnight (gelap).
/// ─────────────────────────────────────────────────────────────────────────
class AppColors {
  // Primary brand – oranye hangat & enerjik
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF9466);
  static const Color primaryDark = Color(0xFFE2502A);

  // Accent – hijau segar (status lunas / sukses)
  static const Color accent = Color(0xFF0E9F6E);
  static const Color accentLight = Color(0xFF31C48D);

  // Semantik
  static const Color success = Color(0xFF057A55);
  static const Color warning = Color(0xFFC27803);
  static const Color error = Color(0xFFE02424);
  static const Color info = Color(0xFF1C64F2);

  // Latar & permukaan — Daylight (terang)
  static const Color background = Color(0xFFFAF7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF5EFE9);
  static const Color border = Color(0xFFEDE3DB);

  // Teks — Daylight
  static const Color textPrimary = Color(0xFF1F1A17);
  static const Color textSecond = Color(0xFF7A716A);
  static const Color textHint = Color(0xFFAFA59C);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Latar & permukaan — Midnight (gelap)
  static const Color backgroundDark = Color(0xFF101114);
  static const Color surfaceDark = Color(0xFF1B1C20);
  static const Color surfaceAltDark = Color(0xFF24262B);
  static const Color borderDark = Color(0xFF2E3036);

  // Teks — Midnight
  static const Color textPrimaryDark = Color(0xFFF5F2EF);
  static const Color textSecondDark = Color(0xFFAAA9AD);
  static const Color textHintDark = Color(0xFF6F7177);

  // Status badges (dipakai untuk kedua mode — pastel, cukup kontras)
  static const Color pendingBg = Color(0xFFFFF3CD);
  static const Color pendingText = Color(0xFF856404);
  static const Color confirmatedBg = Color(0xFFD1FAE5);
  static const Color confirmatedText = Color(0xFF065F46);
  static const Color rejectedBg = Color(0xFFFEE2E2);
  static const Color rejectedText = Color(0xFF991B1B);
  static const Color unpaidBg = Color(0xFFF3F4F6);
  static const Color unpaidText = Color(0xFF374151);
}

/// Gradien siap pakai untuk header, kartu promo, dan tombol.
class AppGradients {
  /// Header lengkung peach hangat (mode Daylight)
  static const header = LinearGradient(
    colors: [Color(0xFFFFB37A), Color(0xFFFF7A45)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Header untuk mode Midnight — gelap dengan sentuhan oranye
  static const headerDark = LinearGradient(
    colors: [Color(0xFF3A2418), Color(0xFF17110E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Kartu promo / banner utama (gaya "Double Deluxe Burger")
  static const promo = LinearGradient(
    colors: [Color(0xFF6B3A24), Color(0xFF2C160D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Tombol & aksen utama
  static const brand = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const success = LinearGradient(
    colors: [AppColors.accentLight, Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Ekstensi praktis agar widget bisa membaca warna yang otomatis menyesuaikan
/// mode Daylight/Midnight tanpa harus mengganti seluruh basis kode.
/// Pakai: `context.colorBg`, `context.colorSurface`, dst.
extension AppColorsX on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get colorBg =>
      isDarkMode ? AppColors.backgroundDark : AppColors.background;
  Color get colorSurface =>
      isDarkMode ? AppColors.surfaceDark : AppColors.surface;
  Color get colorSurfaceAlt =>
      isDarkMode ? AppColors.surfaceAltDark : AppColors.surfaceAlt;
  Color get colorBorder => isDarkMode ? AppColors.borderDark : AppColors.border;
  Color get colorTextPrimary =>
      isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary;
  Color get colorTextSecond =>
      isDarkMode ? AppColors.textSecondDark : AppColors.textSecond;
  Color get colorTextHint =>
      isDarkMode ? AppColors.textHintDark : AppColors.textHint;
  LinearGradient get headerGradient =>
      isDarkMode ? AppGradients.headerDark : AppGradients.header;
}

class AppTheme {
  static ThemeData _build({required bool dark}) {
    final bg = dark ? AppColors.backgroundDark : AppColors.background;
    final surface = dark ? AppColors.surfaceDark : AppColors.surface;
    final surfaceAlt = dark ? AppColors.surfaceAltDark : AppColors.surfaceAlt;
    final border = dark ? AppColors.borderDark : AppColors.border;
    final textPrimary = dark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecond = dark ? AppColors.textSecondDark : AppColors.textSecond;
    final textHint = dark ? AppColors.textHintDark : AppColors.textHint;

    final base = ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: bg,
      fontFamily: GoogleFonts.poppins().fontFamily,
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.poppins(
            fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary),
        headlineMedium: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
        headlineSmall: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
        bodyLarge: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w400, color: textSecond),
        bodySmall: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w400, color: textHint),
        labelLarge: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: border,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: GoogleFonts.poppins(fontSize: 14, color: textSecond),
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: textHint),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return IconThemeData(color: textHint, size: 22);
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary);
          }
          return GoogleFonts.poppins(fontSize: 11, color: textHint);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Mode Daylight — terang & hangat
  static ThemeData get light => _build(dark: false);

  /// Mode Midnight — gelap, nyaman di mata
  static ThemeData get dark => _build(dark: true);
}
