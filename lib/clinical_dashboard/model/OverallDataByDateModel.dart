class OverallDataByDateModel {
  final String loginId;
  final String date;
  final int count;
  final int personalInfoCount;
  final int totalScoreCount;
  final int totalPersonalInfoCount;
  final int missingProfilesCount;
  final List<ScoreData> data;
  final Analytics analytics;

  OverallDataByDateModel({
    required this.loginId,
    required this.date,
    required this.count,
    required this.personalInfoCount,
    required this.totalScoreCount,
    required this.totalPersonalInfoCount,
    required this.missingProfilesCount,
    required this.data,
    required this.analytics,
  });

  factory OverallDataByDateModel.fromJson(Map<String, dynamic> json) {
    return OverallDataByDateModel(
      loginId: json['login_id'] ?? '',
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
      personalInfoCount: json['personal_info_count'] ?? 0,
      totalScoreCount: json['total_score_count'] ?? 0,
      totalPersonalInfoCount: json['total_personal_info_count'] ?? 0,
      missingProfilesCount: json['missing_profiles_count'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => ScoreData.fromJson(e))
          .toList() ??
          [],
      analytics: json['analytics'] != null
          ? Analytics.fromJson(json['analytics'])
          : Analytics.empty(),
    );
  }
}

class ScoreData {
  final int scoreId;
  final String loginId;
  final String profileId;
  final String dbScore;
  final String gutScorePer;
  final String liverScore;
  final String blowScore;
  final String scoreDttm;
  final int timestamp;
  final int hwd;
  final String name;
  final String gender;
  final String age;
  final String height;
  final String weight;

  ScoreData({
    required this.scoreId,
    required this.loginId,
    required this.profileId,
    required this.dbScore,
    required this.gutScorePer,
    required this.liverScore,
    required this.blowScore,
    required this.scoreDttm,
    required this.timestamp,
    required this.hwd,
    required this.name,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
  });

  factory ScoreData.fromJson(Map<String, dynamic> json) {
    return ScoreData(
      scoreId: json['score_id'] ?? 0,
      loginId: json['login_id'] ?? 'not available',
      profileId: json['profile_id'] ?? 'not available',
      dbScore: json['Db_Score']?.toString() ?? '0',
      gutScorePer: json['Gut_Score_per']?.toString() ?? '0',
      liverScore: json['liver_score']?.toString() ?? '0',
      blowScore: json['Blow_Score']?.toString() ?? '0',
      scoreDttm: json['score_dttm'] ?? 'not available',
      timestamp: json['timestamp'] ?? 0,
      hwd: json['hwd'] ?? 0,
      name: json['name'] ?? 'not available',
      gender: json['gender'] ?? 'not available',
      age: json['age'] ?? 'not available',
      height: json['height'] ?? 'not available',
      weight: json['weight'] ?? 'not available',
    );
  }
}

class Analytics {
  final Map<String, GenderDistribution> genderDistribution;
  final Map<String, Map<String, ScoreCategory>> ageScoreDistribution;

  Analytics({
    required this.genderDistribution,
    required this.ageScoreDistribution,
  });

  factory Analytics.fromJson(Map<String, dynamic> json) {
    final genderDistJson =
        json['gender_distribution'] as Map<String, dynamic>? ?? {};
    final ageDistJson =
        json['age_score_distribution'] as Map<String, dynamic>? ?? {};

    return Analytics(
      genderDistribution: genderDistJson.map((gender, value) {
        return MapEntry(
            gender, GenderDistribution.fromJson(value ?? <String, dynamic>{}));
      }),
      ageScoreDistribution: ageDistJson.map((scoreType, ageGroups) {
        final ageMap = (ageGroups as Map<String, dynamic>? ?? {}).map(
              (ageGroup, category) => MapEntry(
            ageGroup,
            ScoreCategory.fromJson(category ?? <String, dynamic>{}),
          ),
        );
        return MapEntry(scoreType, ageMap);
      }),
    );
  }

  factory Analytics.empty() {
    return Analytics(genderDistribution: {}, ageScoreDistribution: {});
  }
}

class GenderDistribution {
  final ScoreCategory dbScore;
  final ScoreCategory liverScore;
  final ScoreCategory gutScorePer;
  final ScoreCategory blowScore;

  GenderDistribution({
    required this.dbScore,
    required this.liverScore,
    required this.gutScorePer,
    required this.blowScore,
  });

  factory GenderDistribution.fromJson(Map<String, dynamic> json) {
    return GenderDistribution(
      dbScore:
      ScoreCategory.fromJson(json['Db_Score'] ?? <String, dynamic>{}),
      liverScore:
      ScoreCategory.fromJson(json['liver_score'] ?? <String, dynamic>{}),
      gutScorePer:
      ScoreCategory.fromJson(json['Gut_Score_per'] ?? <String, dynamic>{}),
      blowScore:
      ScoreCategory.fromJson(json['Blow_Score'] ?? <String, dynamic>{}),
    );
  }
}

class ScoreCategory {
  final int good;
  final int fair;
  final int poor;

  ScoreCategory({
    required this.good,
    required this.fair,
    required this.poor,
  });

  factory ScoreCategory.fromJson(Map<String, dynamic> json) {
    return ScoreCategory(
      good: json['Good'] ?? 0,
      fair: json['Fair'] ?? 0,
      poor: json['Poor'] ?? 0,
    );
  }
}
