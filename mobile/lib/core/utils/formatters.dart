import 'package:intl/intl.dart';

class Formatters {
  static String formatDuration(num totalSeconds) {
    final int sec = totalSeconds.toInt();
    final int minutes = sec ~/ 60;
    final int remainingSec = sec % 60;
    final int hours = minutes ~/ 60;
    final int remainingMin = minutes % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${remainingMin.toString().padLeft(2, '0')}:${remainingSec.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${remainingSec.toString().padLeft(2, '0')}';
  }

  static String formatCoins(num amount) {
    final formatter = NumberFormat('#,##0.##');
    return formatter.format(amount);
  }

  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, y • h:mm a').format(date.toLocal());
    } catch (_) {
      return dateString;
    }
  }

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('MMM d, y • h:mm a').format(dateTime.toLocal());
  }
}
