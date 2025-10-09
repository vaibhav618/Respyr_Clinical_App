class SubjectProfileModel {
  final String profileName;
  final String age;
  final String gender;
  final String height;
  final String weight;

  SubjectProfileModel({
    required this.profileName,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
  });

  factory SubjectProfileModel.fromJson(Map<String, dynamic> json) {
    return SubjectProfileModel(
      profileName: json['profile_name'],
      age: json['age'],
      gender: json['gender'],
      height: json['height'],
      weight: json['weight'],
    );
  }
}
