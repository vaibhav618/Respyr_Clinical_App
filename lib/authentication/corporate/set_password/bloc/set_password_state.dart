import 'package:equatable/equatable.dart';

enum SetPasswordStatus { initial, loading, success, failure }

class SetPasswordState extends Equatable {
  final String subjectId;
  final String password;
  final String confirmPassword;

  final SetPasswordStatus status;
  final String? errorMessage;

  const SetPasswordState({
    this.subjectId = "",
    this.password = "",
    this.confirmPassword = "",
    this.status = SetPasswordStatus.initial,
    this.errorMessage,
  });

  bool get canSubmit =>
      subjectId.trim().isNotEmpty &&
          password.isNotEmpty &&
          confirmPassword.isNotEmpty &&
          password == confirmPassword &&
          password.length >= 6 &&
          status != SetPasswordStatus.loading;

  SetPasswordState copyWith({
    String? subjectId,
    String? password,
    String? confirmPassword,
    SetPasswordStatus? status,
    String? errorMessage,
  }) {
    return SetPasswordState(
      subjectId: subjectId ?? this.subjectId,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [subjectId, password, confirmPassword, status, errorMessage];
}
