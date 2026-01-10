enum ClinicNameCheckStatus { initial, typing, loading, success, failure }

class ClinicNameCheckState {
  final ClinicNameCheckStatus status;
  final String clinicName;

  /// exists = true means already in DB
  final bool? exists;

  final String? message;

  const ClinicNameCheckState({
    this.status = ClinicNameCheckStatus.initial,
    this.clinicName = "",
    this.exists,
    this.message,
  });

  ClinicNameCheckState copyWith({
    ClinicNameCheckStatus? status,
    String? clinicName,
    bool? exists,
    String? message,
    bool clearExists = false,
    bool clearMessage = false,
  }) {
    return ClinicNameCheckState(
      status: status ?? this.status,
      clinicName: clinicName ?? this.clinicName,
      exists: clearExists ? null : (exists ?? this.exists),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}
