
import 'analytics_model.dart';
import 'health_score_model.dart';

class OverallDataByDateModel {
  final String status;
  final String loginId;
  final String date;
  final int count;
  final int personalInfoCount;
  final int totalScoreCount;
  final int totalPersonalInfoCount;
  final int missingProfilesCount;
  final List<HealthScoreData> data;
  final Analytics analytics;

  OverallDataByDateModel({
    required this.status,
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
      status: json['status'],
      loginId: json['login_id'],
      date: json['date'],
      count: json['count'],
      personalInfoCount: json['personal_info_count'],
      totalScoreCount: json['total_score_count'],
      totalPersonalInfoCount: json['total_personal_info_count'],
      missingProfilesCount: json['missing_profiles_count'],
      data: (json['data'] as List)
          .map((item) => HealthScoreData.fromJson(item))
          .toList(),
      analytics: Analytics.fromJson(json['analytics']),
    );
  }
}
