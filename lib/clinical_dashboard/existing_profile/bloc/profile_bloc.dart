import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/profile_model.dart';
import '../recent_subjects.dart';
import '../repositories/profile_repository.dart';

// EVENTS
abstract class ProfileEvent {}

class LoadProfiles extends ProfileEvent {
  final String clinicName;
  LoadProfiles(this.clinicName);
}

class SearchProfiles extends ProfileEvent {
  final String query;
  SearchProfiles(this.query);
}

// STATES
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final List<ProfileModel> allProfiles;
  final List<ProfileModel> filteredProfiles;

  ProfileLoaded(this.allProfiles, this.filteredProfiles);
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

// BLOC
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;
  List<ProfileModel> _allProfiles = [];

  ProfileBloc(this.repository) : super(ProfileInitial()) {
    on<LoadProfiles>(_onLoadProfiles);
    on<SearchProfiles>(_onSearchProfiles);
  }

  Future<void> _onLoadProfiles(LoadProfiles event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final profiles = await repository.fetchProfiles(event.clinicName);
      _allProfiles = await _sortByMostRecentlyTested(profiles);
      emit(ProfileLoaded(_allProfiles, _allProfiles));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  /// Whoever was tested most recently comes first, so the list reflects who is
  /// actually being seen rather than the order the API happens to return.
  ///
  /// Subjects with no recorded test keep their existing relative order below
  /// those that have one — a clinic's long tail of untested subjects should not
  /// get reshuffled on every load.
  Future<List<ProfileModel>> _sortByMostRecentlyTested(
    List<ProfileModel> profiles,
  ) async {
    final Map<String, int> lastTested = await RecentSubjects.lastTestedTimes();
    if (lastTested.isEmpty) return profiles;

    final sorted = List<ProfileModel>.from(profiles);
    sorted.sort((a, b) {
      final int aTime = lastTested[a.subjectId] ?? 0;
      final int bTime = lastTested[b.subjectId] ?? 0;
      if (aTime == bTime) return 0;
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  void _onSearchProfiles(SearchProfiles event, Emitter<ProfileState> emit) {
    final filtered = _allProfiles.where((p) =>
        p.profileName.toLowerCase().contains(event.query.toLowerCase())).toList();

    emit(ProfileLoaded(_allProfiles, filtered));
  }
}
