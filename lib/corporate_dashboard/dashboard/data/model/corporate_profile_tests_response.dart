class CorporateProfileTestsResponse {
  final bool success;
  final String message;
  final CorporateProfileTestsData? data;

  CorporateProfileTestsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CorporateProfileTestsResponse.fromJson(Map<String, dynamic> json) {
    return CorporateProfileTestsResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map<String, dynamic>
          ? CorporateProfileTestsData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CorporateProfileTestsData {
  final String loginId;
  final String profileId;

  /// API may return null when date not sent
  final String? requestedDate; // MM/DD/YYYY or null

  /// one record per day
  final List<CorporateProfileTestItem> latestPerDay;

  /// ✅ single latest record for requested date
  final CorporateProfileTestItem? latestOfDate;

  /// (optional) full desc data if you want later
  final List<CorporateProfileTestItem> allDesc;

  CorporateProfileTestsData({
    required this.loginId,
    required this.profileId,
    required this.requestedDate,
    required this.latestPerDay,
    required this.latestOfDate,
    required this.allDesc,
  });

  factory CorporateProfileTestsData.fromJson(Map<String, dynamic> json) {
    final latestPerDayList = json['latest_per_day'];
    final allDescList = json['all_desc'];

    return CorporateProfileTestsData(
      loginId: (json['login_id'] ?? '').toString(),
      profileId: (json['profile_id'] ?? '').toString(),
      requestedDate: json['requested_date'] == null
          ? null
          : (json['requested_date'] ?? '').toString(),

      latestPerDay: latestPerDayList is List
          ? latestPerDayList
          .whereType<Map<String, dynamic>>()
          .map((e) => CorporateProfileTestItem.fromJson(e))
          .toList()
          : <CorporateProfileTestItem>[],

      latestOfDate: json['latest_of_date'] is Map<String, dynamic>
          ? CorporateProfileTestItem.fromJson(json['latest_of_date'] as Map<String, dynamic>)
          : null,

      allDesc: allDescList is List
          ? allDescList
          .whereType<Map<String, dynamic>>()
          .map((e) => CorporateProfileTestItem.fromJson(e))
          .toList()
          : <CorporateProfileTestItem>[],
    );
  }
}

class CorporateProfileTestItem {
  final int id;
  final String loginId;
  final String profileId;

  final String dbScore;
  final String gutScorePer;
  final String liverScore;
  final String blowScore;

  final String blowRawValues;
  final String acetonePpm;
  final String ethnolPpm;
  final String h2Ppm;
  final String respiratoryFvcJson;

  final double? maxpress;
  final String dttm;
  final int? timestamp;
  final int? hwd;

  CorporateProfileTestItem({
    required this.id,
    required this.loginId,
    required this.profileId,
    required this.dbScore,
    required this.gutScorePer,
    required this.liverScore,
    required this.blowScore,
    required this.blowRawValues,
    required this.acetonePpm,
    required this.ethnolPpm,
    required this.h2Ppm,
    required this.respiratoryFvcJson,
    required this.dttm,
    this.maxpress,
    this.timestamp,
    this.hwd,
  });

  factory CorporateProfileTestItem.fromJson(Map<String, dynamic> json) {
    return CorporateProfileTestItem(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      loginId: (json['login_id'] ?? '').toString(),
      profileId: (json['profile_id'] ?? '').toString(),

      dbScore: (json['Db_Score'] ?? '').toString(),
      gutScorePer: (json['Gut_Score_per'] ?? '').toString(),
      liverScore: (json['liver_score'] ?? '').toString(),
      blowScore: (json['Blow_Score'] ?? '').toString(),

      blowRawValues: (json['blow_raw_values'] ?? '').toString(),
      acetonePpm: (json['acetone_ppm'] ?? '').toString(),
      ethnolPpm: (json['ethnol_ppm'] ?? '').toString(),
      h2Ppm: (json['h2_ppm'] ?? '').toString(),
      respiratoryFvcJson: (json['respiratory_fvc_json'] ?? '').toString(),

      maxpress: double.tryParse((json['maxpress'] ?? '').toString()),
      dttm: (json['dttm'] ?? '').toString(),
      timestamp: int.tryParse((json['timestamp'] ?? '').toString()),
      hwd: int.tryParse((json['hwd'] ?? '').toString()),
    );
  }
}
