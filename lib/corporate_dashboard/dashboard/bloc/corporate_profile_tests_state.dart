import 'package:equatable/equatable.dart';
import '../data/model/corporate_profile_tests_response.dart';

enum CorporateProfileTestsStatus { initial, loading, success, failure }

class CorporateProfileTestsState extends Equatable {
  final CorporateProfileTestsStatus status;
  final CorporateProfileTestsResponse? response;
  final String? errorMessage;

  const CorporateProfileTestsState({
    required this.status,
    this.response,
    this.errorMessage,
  });

  factory CorporateProfileTestsState.initial() {
    return const CorporateProfileTestsState(status: CorporateProfileTestsStatus.initial);
  }

  CorporateProfileTestsState copyWith({
    CorporateProfileTestsStatus? status,
    CorporateProfileTestsResponse? response,
    String? errorMessage,
    bool clearError = false,
    bool clearResponse = false,
  }) {
    return CorporateProfileTestsState(
      status: status ?? this.status,
      response: clearResponse ? null : (response ?? this.response),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, response, errorMessage];
}
