import 'package:intl/intl.dart';

String formatDateTimeOrRelative(int timestamp) {
  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  DateTime now = DateTime.now();
  Duration diff = now.difference(date);

  if (diff.inMinutes < 1) {
    return 'Just now';
  } else if (diff.inMinutes < 60) {
    return '${diff.inMinutes} mins ago';
  } else if (diff.inHours < 24) {
    return '${diff.inHours} hours ago';
  } else {
    // If more than 24 hours ago, show full date
    return DateFormat('d MMMM yyyy h:mm a').format(date);
  }
}
