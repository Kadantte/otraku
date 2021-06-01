import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';

abstract class Convert {
  // Replaces _ with [blank_space] and makes each word
  // start with an upper case letter and continue with
  // lower case ones.
  static String? clarifyEnum(String? str) {
    if (str == null) return null;
    return str.splitMapJoin(
      '_',
      onMatch: (_) => ' ',
      onNonMatch: (s) => s[0].toUpperCase() + s.substring(1).toLowerCase(),
    );
  }

  // Transforms a string into enum. The string must be
  // as if it was acquired through "describeEnum()"
  // and the values must be the enum values
  static T? strToEnum<T>(String? str, List<T> values) =>
      values.firstWhereOrNull((v) => describeEnum(v!) == str);

  // Removes all html tags
  static String clearHtml(String? str) {
    if (str == null) return '';
    return str.replaceAll(RegExp(r'<[^>]+>'), '');
  }

  static String? mapToDateStr(Map<String, dynamic>? map) {
    if (map?['year'] == null) return null;

    final String? month = _MONTHS[map!['month']];
    final day = map['day'] ?? '';

    if (month == '' && day == '') return '${map['year']}';

    return '$month $day, ${map['year']}';
  }

  static DateTime? mapToDateTime(Map<String, dynamic> map) {
    if (map['year'] == null || map['month'] == null || map['day'] == null)
      return null;
    return DateTime(map['year'], map['month'], map['day']);
  }

  static Map<String, int>? dateTimeToMap(DateTime? date) {
    if (date == null) return null;
    return {'year': date.year, 'month': date.month, 'day': date.day};
  }

  static String millisToTimeStr(int? millis) {
    if (millis == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(millis * 1000);
    return '${_WEEK_DAYS[date.weekday - 1]}, ${date.day} ${_MONTHS[date.month]} '
        '${date.year}, ${date.hour <= 9 ? 0 : ""}${date.hour}:'
        '${date.minute <= 9 ? 0 : ""}${date.minute}';
  }

  static String? secondsToCountdownStr(int? seconds) {
    if (seconds == null) return null;

    int minutes = seconds ~/ 60;
    int hours = minutes ~/ 60;
    minutes %= 60;
    int days = hours ~/ 24;
    hours %= 24;

    return '${days != 0 ? '${days}d ' : ''}${hours != 0 ? '${hours}h ' : ''}${minutes != 0 ? '${minutes}m' : ''}';
  }

  static const COUNTRY_CODES = {
    'JP': 'Japan',
    'CN': 'China',
    'KR': 'South Korea',
    'TW': 'Taiwan',
  };

  static const _WEEK_DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const _MONTHS = {
    1: 'Jan',
    2: 'Feb',
    3: 'Mar',
    4: 'Apr',
    5: 'May',
    6: 'Jun',
    7: 'Jul',
    8: 'Aug',
    9: 'Sep',
    10: 'Oct',
    11: 'Nov',
    12: 'Dec',
    null: '',
  };
}
