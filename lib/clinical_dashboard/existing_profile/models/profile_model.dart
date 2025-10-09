class ProfileModel {
  final int id;
  final String subjectId;
  final String clinicName;
  final String profileName;
  final String gender;
  final int age;
  final double height;
  final double weight;
  final String region;
  final String dttm;

  ProfileModel({
    required this.id,
    required this.subjectId,
    required this.clinicName,
    required this.profileName,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.region,
    required this.dttm,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      subjectId: json['subject_id'],
      clinicName: json['clinic_name'],
      profileName: json['profile_name'],
      gender: json['gender'],
      age: json['age'], // already int
      height: (json['height'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      region: json['region'],
      dttm: json['dttm'],
    );
  }
}
