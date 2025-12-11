import 'package:intl/intl.dart';

DateTime? convertTwitterDateTime(String? twitterDateString) {
  if (twitterDateString == null) {
    return null;
  }

  try {
    return DateTime.parse(twitterDateString);
  } on Exception {
    try {
      final dateString = formatTwitterDateString(twitterDateString);
      return DateFormat(
        'E MMM dd HH:mm:ss yyyy',
        'en_US',
      ).parse(dateString, true);
    } on Exception {
      return null;
    }
  }
}

String formatTwitterDateString(String twitterDateString) {
  final sanitized = twitterDateString.split(' ')
    ..removeWhere((part) => part.startsWith('+'));

  return sanitized.join(' ');
}
