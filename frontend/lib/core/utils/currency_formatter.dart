import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Memformat nilai dynamic (String/num) menjadi format mata uang Rupiah secara aman
  static String format(dynamic amount) {
    if (amount == null) return 'Rp 0';

    double val = 0.0;
    if (amount is num) {
      val = amount.toDouble();
    } else if (amount is String) {
      val = double.tryParse(amount) ?? 0.0;
    } else {
      // Jaga-jaga jika ada tipe data lain yang tidak terduga
      val = double.tryParse(amount.toString()) ?? 0.0;
    }

    return _fmt.format(val);
  }

  /// Memformat ringkasan angka besar secara singkat (Lebih aman dengan parameter dynamic)
  static String compact(dynamic value) {
    if (value == null) return '0';

    double val = 0.0;
    if (value is num) {
      val = value.toDouble();
    } else if (value is String) {
      val = double.tryParse(value) ?? 0.0;
    } else {
      val = double.tryParse(value.toString()) ?? 0.0;
    }

    return NumberFormat.compact(locale: 'id_ID').format(val);
  }
}

class DateFormatter {
  static String format(String? dateStr, {String pattern = 'd MMM yyyy'}) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat(pattern, 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  static String timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 7) return format(dateStr);
      if (diff.inDays > 0) return '${diff.inDays} hari lalu';
      if (diff.inHours > 0) return '${diff.inHours} jam lalu';
      if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
      return 'Baru saja';
    } catch (_) {
      return dateStr;
    }
  }
}
