
import '../model/subject_profile_model.dart';

abstract class SubjectProfileState {}

class SubjectProfileInitial extends SubjectProfileState {}

class SubjectProfileLoading extends SubjectProfileState {}

class SubjectProfileLoaded extends SubjectProfileState {
  final SubjectProfileModel profile;
  final List<dynamic> scores;
  final bool hasMore;
  final bool isLoadingMore;

  SubjectProfileLoaded({
    required this.profile,
    required this.scores,
    this.hasMore = false,
    this.isLoadingMore = false,
  });
}

class SubjectProfileError extends SubjectProfileState {
  final String message;
  SubjectProfileError(this.message);
}
