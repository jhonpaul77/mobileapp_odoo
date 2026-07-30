// lib/pages/home/utils/formatters.dart

class Formatters {
  /// Format currency ke Rupiah
  /// Contoh: 150000 -> "Rp 150.000"
  static String formatCurrency(num amount) {
    final formatter = _CurrencyFormatter();
    return formatter.format(amount.toInt());
  }

  /// Format number dengan separator ribuan
  /// Contoh: 15000 -> "15.000"
  static String formatNumber(num number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  /// Format persentase
  /// Contoh: 0.125 -> "12.5%"
  static String formatPercentage(double value) {
    return "${(value * 100).toStringAsFixed(1)}%";
  }

  /// Format status menjadi label yang user-friendly
  static String formatStatus(String status) {
    const statusMap = {
      "pending": "Menunggu",
      "processing": "Diproses",
      "completed": "Selesai",
      "cancelled": "Dibatalkan",
      "success": "Berhasil",
      "failed": "Gagal",
    };
    return statusMap[status.toLowerCase()] ?? status;
  }
}

class _CurrencyFormatter {
  String format(int amount) {
    final parts = <String>[];
    String numStr = amount.toString();

    // Proses dari belakang untuk menambah titik setiap 3 digit
    for (int i = numStr.length; i > 0; i -= 3) {
      int start = (i - 3) < 0 ? 0 : (i - 3);
      parts.insert(0, numStr.substring(start, i));
    }

    return "Rp ${parts.join('.')}";
  }
}
