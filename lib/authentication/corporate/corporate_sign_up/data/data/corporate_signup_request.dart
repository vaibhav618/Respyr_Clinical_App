class CorporateSignUpRequest {
  final String email;
  final String clinicName;
  final String profileName;
  final String gender;
  final String age;
  final String height;
  final String weight;
  final String region;
  final String password;

  CorporateSignUpRequest({
    required this.email,
    required this.clinicName,
    required this.profileName,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.region,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "clinic_name": clinicName,
      "profile_name": profileName,
      "gender": gender,
      "age": age,
      "height": height,
      "weight": weight,
      "region": region,
      "password": password,
    };
  }
}
