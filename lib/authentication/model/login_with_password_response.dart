

class LoginWithPasswordResponse {
  final String status;
  final String message;
  final int? count;
  final List<UserData>? data;

  LoginWithPasswordResponse({
    required this.status,
    required this.message,
    this.count,
    this.data,
  });

  factory LoginWithPasswordResponse.fromJson(Map<String, dynamic> json) {
    return LoginWithPasswordResponse(
      status: json['status'] ?? 'error',
      message: json['message'] ?? 'Unknown error',
      count: json.containsKey('count') ? json['count'] : null,
      data: json.containsKey('data') && json['data'] != null
          ? List<UserData>.from(json['data'].map((x) => UserData.fromJson(x)))
          : null,
    );
  }
}

class UserData {
  final int clinicalId;
  final String phoneNo;
  final String clinicName;
  final String location;
  final String username;
  final String logoSrc;

  UserData({
    required this.clinicalId,
    required this.phoneNo,
    required this.clinicName,
    required this.location,
    required this.username,
    required this.logoSrc,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      clinicalId: json['clinical_id'],
      phoneNo: json['phone_no'],
      clinicName: json['clinic_name'],
      location: json['location'],
      username: json['username'],
      logoSrc: json['logo_src'],
    );
  }
}
