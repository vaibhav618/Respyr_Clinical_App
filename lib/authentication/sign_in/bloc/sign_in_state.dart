import 'package:equatable/equatable.dart';

enum SignInStatus { initial, loading, success, failure }

class SignInState extends Equatable {
  final SignInStatus status;
  final String? selectedType; // "clinical" or "corporate"
  final String? errorMessage;

  const SignInState({
    this.status = SignInStatus.initial,
    this.selectedType,
    this.errorMessage,
  });

  SignInState copyWith({
    SignInStatus? status,
    String? selectedType,
    String? errorMessage,
  }) {
    return SignInState(
      status: status ?? this.status,
      selectedType: selectedType ?? this.selectedType,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, selectedType, errorMessage];
}
