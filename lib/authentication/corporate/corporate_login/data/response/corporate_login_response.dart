class CorporateLoginResponse {
  final bool success;
  final String message;
  final CorporateUserData? data;

  CorporateLoginResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CorporateLoginResponse.fromJson(Map<String, dynamic> json) {
    return CorporateLoginResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map<String, dynamic>
          ? CorporateUserData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CorporateUserData {
  final int id;
  final String subjectId;
  final String email;
  final String profileName;
  final String gender;
  final String age;
  final String height;
  final String weight;
  final String region;
  final String dttm;

  // From table_clinics
  final String clinicName;
  final String role;

  CorporateUserData({
    required this.id,
    required this.subjectId,
    required this.email,
    required this.profileName,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.region,
    required this.dttm,
    required this.clinicName,
    required this.role,
  });

  factory CorporateUserData.fromJson(Map<String, dynamic> json) {
    return CorporateUserData(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      subjectId: (json['subject_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      profileName: (json['profile_name'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      age: (json['age'] ?? '').toString(),
      height: (json['height'] ?? '').toString(),
      weight: (json['weight'] ?? '').toString(),
      region: (json['region'] ?? '').toString(),
      dttm: (json['dttm'] ?? '').toString(),
      clinicName: (json['clinic_name'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
    );
  }
}
