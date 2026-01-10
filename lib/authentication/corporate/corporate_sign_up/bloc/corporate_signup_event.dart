abstract class CorporateSignUpEvent {
  const CorporateSignUpEvent();
}

class CorporateEmailChanged extends CorporateSignUpEvent {
  final String email;
  const CorporateEmailChanged(this.email);
}

class CorporateNameChanged extends CorporateSignUpEvent {
  final String name;
  const CorporateNameChanged(this.name);
}

class CorporateGenderChanged extends CorporateSignUpEvent {
  final String gender;
  const CorporateGenderChanged(this.gender);
}

class CorporateHeightChanged extends CorporateSignUpEvent {
  final String height;
  const CorporateHeightChanged(this.height);
}

class CorporateWeightChanged extends CorporateSignUpEvent {
  final String weight;
  const CorporateWeightChanged(this.weight);
}

class CorporateAgeChanged extends CorporateSignUpEvent {
  final String age;
  const CorporateAgeChanged(this.age);
}

class CorporateRegionChanged extends CorporateSignUpEvent {
  final String region;
  const CorporateRegionChanged(this.region);
}

class CorporateClinicNameChanged extends CorporateSignUpEvent {
  final String clinicName;
  const CorporateClinicNameChanged(this.clinicName);
}

class CorporatePasswordChanged extends CorporateSignUpEvent {
  final String password;
  const CorporatePasswordChanged(this.password);
}

class CorporateSignUpSubmitted extends CorporateSignUpEvent {
  const CorporateSignUpSubmitted();
}
