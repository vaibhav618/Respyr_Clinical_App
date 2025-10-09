class ScoreResponseModel {
  final double diabeticScore;
  final double overallVitalScore;
  final double blowScore;
  final double gutScore;
  final double liverScore;

  ScoreResponseModel({
    required this.diabeticScore,
    required this.overallVitalScore,
    required this.blowScore,
    required this.gutScore,
    required this.liverScore,
  });

  factory ScoreResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['score_data'];
    return ScoreResponseModel(
      diabeticScore: (data['Dibetic_Score'] ?? 0).toDouble(),
      overallVitalScore: (data['Overall_Vital_Score'] ?? 0).toDouble(),
      blowScore: double.tryParse(data['Blow_Score'].toString()) ?? 0,
      gutScore: double.tryParse(data['Gut_Score_per'].toString()) ?? 0,
      liverScore: double.tryParse(data['score_liver'].toString()) ?? 0,
    );
  }
}
