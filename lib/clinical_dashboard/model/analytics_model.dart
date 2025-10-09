class Analytics {
  final Map<String, ScoreBreakdown> genderDistribution;
  final Map<String, ScoreBreakdown> ageScoreDistribution;

  Analytics({
    required this.genderDistribution,
    required this.ageScoreDistribution,
  });

  factory Analytics.fromJson(Map<String, dynamic> json) {
    return Analytics(
      genderDistribution: (json['gender_distribution'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, ScoreBreakdown.fromJson(value)),
      ),
      ageScoreDistribution: (json['age_score_distribution'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, ScoreBreakdown.fromJson(value)),
      ),
    );
  }
}

class ScoreBreakdown {
  final Map<String, ScoreDetail> scoreDetails;

  ScoreBreakdown({required this.scoreDetails});

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      scoreDetails: json.map(
            (scoreType, detail) => MapEntry(scoreType, ScoreDetail.fromJson(detail)),
      ),
    );
  }
}

class ScoreDetail {
  final int fair;
  final int poor;
  final int good;

  ScoreDetail({required this.fair, required this.poor, required this.good});

  factory ScoreDetail.fromJson(Map<String, dynamic> json) {
    return ScoreDetail(
      fair: json['Fair'] ?? 0,
      poor: json['Poor'] ?? 0,
      good: json['Good'] ?? 0,
    );
  }
}
