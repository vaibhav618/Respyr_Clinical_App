import 'package:intl/intl.dart';

class DateHelper {
  static String formatDate({
    required String inputDate,
    required String inputPattern,
  }) {
    try {
      DateTime dt = DateFormat(inputPattern).parse(inputDate);
      return DateFormat("dd MMM yyyy h:mm a").format(dt);
    } catch (e) {
      return 'Invalid date';
    }
  }

  static String formatDate1({
    required String inputDate,
    required String inputPattern,
  }) {
    try {
      DateTime dt = DateFormat(inputPattern).parse(inputDate);
      return DateFormat("dd/MM/yyyy").format(dt);
    } catch (e) {
      return 'Invalid date';
    }
  }
}
