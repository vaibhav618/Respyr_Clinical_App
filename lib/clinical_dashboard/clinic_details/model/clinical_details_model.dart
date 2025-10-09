class ClinicalDetailsModel {
  final int clinicalId;
  final String phoneNo;
  final String clinicName;
  final String location;
  final String password;
  final String username;
  final int totalProfiles;

  ClinicalDetailsModel({
    required this.clinicalId,
    required this.phoneNo,
    required this.clinicName,
    required this.location,
    required this.password,
    required this.username,
    required this.totalProfiles,
  });

  factory ClinicalDetailsModel.fromJson(Map<String, dynamic> json) {
    return ClinicalDetailsModel(
      clinicalId: json['clinical_id'] ?? 0,
      phoneNo: json['phone_no'] ?? '',
      clinicName: json['clinic_name'] ?? '',
      location: json['location'] ?? '',
      password: json['password'] ?? '',
      username: json['username'] ?? '',
      totalProfiles: json['total_profiles'] ?? 0,
    );
  }
}
