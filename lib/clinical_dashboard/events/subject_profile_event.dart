abstract class SubjectProfileEvent {}

class LoadSubjectProfile extends SubjectProfileEvent {
  final String clinicName;
  final String profileId;

  LoadSubjectProfile(this.clinicName, this.profileId);
}
