class HealthScoreData {
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

  HealthScoreData({
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

  factory HealthScoreData.fromJson(Map<String, dynamic> json) {
    return HealthScoreData(
      scoreId: int.parse(json['score_id'].toString()),
      loginId: json['login_id'],
      profileId: json['profile_id'],
      dbScore: json['Db_Score'],
      gutScorePer: json['Gut_Score_per'],
      liverScore: json['liver_score'],
      blowScore: json['Blow_Score'],
      scoreDttm: json['score_dttm'],
      timestamp: json['timestamp'],
      hwd: json['hwd'],
      name: json['name'],
      gender: json['gender'],
      age: json['age'],
      height: json['height'],
      weight: json['weight'],
    );
  }
}
