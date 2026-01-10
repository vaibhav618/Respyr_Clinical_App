import 'package:equatable/equatable.dart';

abstract class SetPasswordEvent extends Equatable {
  const SetPasswordEvent();

  @override
  List<Object?> get props => [];
}

class SubjectIdChanged extends SetPasswordEvent {
  final String subjectId;
  const SubjectIdChanged(this.subjectId);

  @override
  List<Object?> get props => [subjectId];
}

class PasswordChanged extends SetPasswordEvent {
  final String password;
  const PasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}

class ConfirmPasswordChanged extends SetPasswordEvent {
  final String confirmPassword;
  const ConfirmPasswordChanged(this.confirmPassword);

  @override
  List<Object?> get props => [confirmPassword];
}

class SubmitSetPassword extends SetPasswordEvent {
  const SubmitSetPassword();
}
