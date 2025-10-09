class ScoreStatusHelper {
  static String getScoreTitle(double score) {
    if (score >= 80.0 && score <= 100.0) {
      return 'Good';
    } else if (score >= 70.0 && score < 80.0) {
      return 'Fair';
    } else {
      return 'Poor';
    }
  }

  static String getScoreSubTitle(double score) {
    if (score >= 80.0 && score <= 100.0) {
      return 'Everything\nlooks good!';
    } else if (score >= 70.0 && score < 80.0) {
      return 'Come back\nin a week';
    } else {
      return 'Attention\nRequired';
    }
  }
}
