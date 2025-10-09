class UserInfoModel {
  final String profileId;
  final String phone;
  final String name;
  final String email;
  final String gender;
  final String dob;
  final int age;
  final double height;
  final double weight;

  UserInfoModel({
    required this.profileId,
    required this.phone,
    required this.name,
    required this.email,
    required this.gender,
    required this.dob,
    required this.age,
    required this.height,
    required this.weight,
  });

  factory UserInfoModel.fromJson(Map<String, dynamic> json) {
    return UserInfoModel(
      profileId: json['profile_id'],
      phone: json['phone'],
      name: json['name'],
      email: json['email'],
      gender: json['gender'],
      dob: json['dob'],
      age: int.parse(json['age'].toString()),
      height: double.parse(json['height'].toString()),
      weight: double.parse(json['weight'].toString()),
    );
  }
}
