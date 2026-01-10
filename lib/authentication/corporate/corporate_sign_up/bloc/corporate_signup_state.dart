enum CorporateSignUpStatus { initial, loading, success, failure }

class CorporateSignUpState {
  final CorporateSignUpStatus status;

  final String email;
  final String name;
  final String gender;
  final String heightCm;
  final String weightKg;
  final String age;
  final String region;
  final String clinicName;
  final String password;

  final String? errorMessage;
  final String? subjectId;

  const CorporateSignUpState({
    this.status = CorporateSignUpStatus.initial,
    this.email = '',
    this.name = '',
    this.gender = 'Male',
    this.heightCm = '',
    this.weightKg = '',
    this.age = '',
    this.region = '',
    this.clinicName = '',
    this.password = '',
    this.errorMessage,
    this.subjectId,
  });

  CorporateSignUpState copyWith({
    CorporateSignUpStatus? status,
    String? email,
    String? name,
    String? gender,
    String? heightCm,
    String? weightKg,
    String? age,
    String? region,
    String? clinicName,
    String? password,
    String? errorMessage,
    String? subjectId,
  }) {
    return CorporateSignUpState(
      status: status ?? this.status,
      email: email ?? this.email,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      age: age ?? this.age,
      region: region ?? this.region,
      clinicName: clinicName ?? this.clinicName,
      password: password ?? this.password,
      errorMessage: errorMessage,
      subjectId: subjectId,
    );
  }
}
