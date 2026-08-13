import 'package:intl/intl.dart';

/// A test's time, as short as it can be while staying unambiguous.
///
/// Recent readings read as an interval; older ones as a date. The long form
/// used to spell the month out in full and always print the year — "12 August
/// 2026 10:30 AM" — which is most of a line on its own, and it sits beside a
/// subject ID on a card. Abbreviating the month and dropping the year for the
/// current one takes roughly a third off without losing anything a clinic
/// needs to tell two readings apart.
String formatDateTimeOrRelative(int timestamp) {
  final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  final DateTime now = DateTime.now();
  final Duration diff = now.difference(date);

  if (diff.inMinutes < 1) {
    return 'Just now';
  } else if (diff.inMinutes < 60) {
    final int mins = diff.inMinutes;
    return '$mins ${mins == 1 ? 'min' : 'mins'} ago';
  } else if (diff.inHours < 24) {
    final int hours = diff.inHours;
    return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
  } else if (date.year == now.year) {
    return DateFormat('d MMM, h:mm a').format(date);
  }
  return DateFormat('d MMM yyyy, h:mm a').format(date);
}
