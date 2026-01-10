import 'package:equatable/equatable.dart';
import '../../../authentication/corporate/corporate_login/data/response/corporate_login_response.dart';

enum CorporateProfileStatus { initial, loading, success, failure }

class CorporateProfileState extends Equatable {
  final CorporateProfileStatus status;
  final CorporateUserData? user;
  final String? errorMessage;

  const CorporateProfileState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory CorporateProfileState.initial() {
    return const CorporateProfileState(status: CorporateProfileStatus.initial);
  }

  CorporateProfileState copyWith({
    CorporateProfileStatus? status,
    CorporateUserData? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return CorporateProfileState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}
