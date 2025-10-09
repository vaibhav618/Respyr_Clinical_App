import 'dart:ui';

class ScoreColorHelper {
  static Color getScoreColor(double score) {
    if (score >= 80.0 && score <= 100.0) {
      return const Color(0xFF3EAF58); // Green - Good
    } else if (score >= 70.0 && score < 80.0) {
      return const Color(0xFFFFC412); // Yellow - Fair
    } else {
      return const Color(0xFFEA5455); // Red - Poor
    }
  }

  static List<Color> getLinearScoreColor(double score) {
    if (score >= 80.0 && score <= 100.0) {
      return [const Color(0xFF3FAF58), const Color(0xFF009245)];
    } else if (score >= 70.0 && score < 80.0) {
      return [const Color(0xFFFFC412), const Color(0xFFE3AC06)];
    } else {
      return [const Color(0xFFEA5455), const Color(0xFFC1272D)];
    }
  }
}
