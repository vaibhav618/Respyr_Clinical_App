class ClinicNameCheckResponse {
  final bool success;
  final bool exists;
  final String message;
  final String clinicName;

  ClinicNameCheckResponse({
    required this.success,
    required this.exists,
    required this.message,
    required this.clinicName,
  });

  factory ClinicNameCheckResponse.fromJson(Map<String, dynamic> json) {
    return ClinicNameCheckResponse(
      success: json["success"] == true,
      exists: json["exists"] == true,
      message: (json["message"] ?? "").toString(),
      clinicName: (json["clinic_name"] ?? "").toString(),
    );
  }
}
