import 'package:equatable/equatable.dart';

abstract class SignInEvent extends Equatable {
  const SignInEvent();

  @override
  List<Object?> get props => [];
}

class SignInClinicalPressed extends SignInEvent {
  const SignInClinicalPressed();
}

class SignInCorporatePressed extends SignInEvent {
  const SignInCorporatePressed();
}
