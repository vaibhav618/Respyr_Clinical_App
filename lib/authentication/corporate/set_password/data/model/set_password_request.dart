class SetPasswordRequest {
  final String subjectId;
  final String password;

  const SetPasswordRequest({
    required this.subjectId,
    required this.password,
  });

  Map<String, String> toFormData() => {
    "subject_id": subjectId,
    "password": password,
  };
}
