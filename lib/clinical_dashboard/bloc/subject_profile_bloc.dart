// blocs/subject_profile_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/subject_profile_repository.dart';
import '../events/subject_profile_event.dart';
import '../state/subject_profile_state.dart';


class SubjectProfileBloc extends Bloc<SubjectProfileEvent, SubjectProfileState> {
  final SubjectProfileRepository repository;

  SubjectProfileBloc({required this.repository}) : super(SubjectProfileInitial()) {
    on<LoadSubjectProfile>((event, emit) async {
      emit(SubjectProfileLoading());
      try {
        final result = await repository.fetchProfile(event.clinicName, event.profileId);
        emit(SubjectProfileLoaded(
          profile: result['profile'],
          scores: result['scores'],
        ));
      } catch (e) {
        emit(SubjectProfileError("Something went wrong"));
      }
    });
  }
}
