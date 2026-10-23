class ServerDateTimeParser {
  static DateTime? parseToLocal(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;

    final direct = DateTime.tryParse(raw);
    if (direct != null) {
      return direct.toLocal();
    }

    final jsDateMatch = RegExp(
      r'^[A-Za-z]{3}\s+([A-Za-z]{3})\s+(\d{1,2})\s+(\d{4})\s+'
      r'(\d{2}):(\d{2}):(\d{2})\s+GMT([+-]\d{2})(\d{2})',
    ).firstMatch(raw);

    if (jsDateMatch == null) return null;

    final month = _monthIndex(jsDateMatch.group(1));
    if (month == null) return null;

    final day = int.tryParse(jsDateMatch.group(2) ?? '');
    final year = int.tryParse(jsDateMatch.group(3) ?? '');
    final hour = int.tryParse(jsDateMatch.group(4) ?? '');
    final minute = int.tryParse(jsDateMatch.group(5) ?? '');
    final second = int.tryParse(jsDateMatch.group(6) ?? '');
    final offsetHour = int.tryParse(jsDateMatch.group(7) ?? '');
    final offsetMinute = int.tryParse(jsDateMatch.group(8) ?? '');

    if (day == null ||
        year == null ||
        hour == null ||
        minute == null ||
        second == null ||
        offsetHour == null ||
        offsetMinute == null) {
      return null;
    }

    final localUtc = DateTime.utc(year, month, day, hour, minute, second);
    final sign = offsetHour.isNegative ? -1 : 1;
    final offsetDuration = Duration(
      hours: offsetHour.abs(),
      minutes: offsetMinute,
    );
    final utc = sign == 1
        ? localUtc.subtract(offsetDuration)
        : localUtc.add(offsetDuration);
    return utc.toLocal();
  }

  static int? _monthIndex(String? month) {
    switch ((month ?? '').toLowerCase()) {
      case 'jan':
        return 1;
      case 'feb':
        return 2;
      case 'mar':
        return 3;
      case 'apr':
        return 4;
      case 'may':
        return 5;
      case 'jun':
        return 6;
      case 'jul':
        return 7;
      case 'aug':
        return 8;
      case 'sep':
        return 9;
      case 'oct':
        return 10;
      case 'nov':
        return 11;
      case 'dec':
        return 12;
      default:
        return null;
    }
  }
}
