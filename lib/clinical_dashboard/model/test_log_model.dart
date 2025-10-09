class TestLogModel {
  final String profileId;
  final String profileName;
  final double diabeticScore;
  final double liverScore;
  final double gutScore;
  final double respiratoryScore;
  final int recordCount;
  final int timestamp;

  TestLogModel({
    required this.profileId,
    required this.profileName,
    required this.diabeticScore,
    required this.liverScore,
    required this.gutScore,
    required this.respiratoryScore,
    required this.recordCount,
    required this.timestamp,
  });

  factory TestLogModel.fromJson(Map<String, dynamic> json) {
    return TestLogModel(
      profileId: json['profile_id'] ?? '',
      profileName: json['profile_name'] ?? 'Unknown',
      diabeticScore: (json['Db_Score'] as num?)?.toDouble() ?? 0.0,
      liverScore: (json['liver_score'] as num?)?.toDouble() ?? 0.0,
      gutScore: (json['Gut_Score_per'] as num?)?.toDouble() ?? 0.0,
      respiratoryScore: (json['Blow_Score'] as num?)?.toDouble() ?? 0.0,
      recordCount: (json['record_count'] as num?)?.toInt() ?? 0,
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
    );
  }
}