import '../data/response/corporate_login_response.dart';

enum CorporateLoginStatus { initial, loading, success, failure }

class CorporateLoginState {
  final String email;
  final String password;
  final CorporateLoginStatus status;
  final String? errorMessage;
  final CorporateUserData? user;

  const CorporateLoginState({
    required this.email,
    required this.password,
    required this.status,
    this.errorMessage,
    this.user,
  });

  factory CorporateLoginState.initial() => const CorporateLoginState(
    email: '',
    password: '',
    status: CorporateLoginStatus.initial,
    errorMessage: null,
    user: null,
  );

  CorporateLoginState copyWith({
    String? email,
    String? password,
    CorporateLoginStatus? status,
    String? errorMessage,
    CorporateUserData? user,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return CorporateLoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      user: clearUser ? null : (user ?? this.user),
    );
  }
}
