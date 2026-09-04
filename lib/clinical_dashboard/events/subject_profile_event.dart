abstract class SubjectProfileEvent {}

class LoadSubjectProfile extends SubjectProfileEvent {
  final String clinicName;
  final String profileId;

  LoadSubjectProfile(this.clinicName, this.profileId);
}

/// Append the next page of the subject's test history to what's already shown.
class LoadMoreSubjectScores extends SubjectProfileEvent {}
