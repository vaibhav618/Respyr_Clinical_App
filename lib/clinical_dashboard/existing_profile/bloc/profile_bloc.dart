import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/profile_model.dart';
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
      _allProfiles = await repository.fetchProfiles(event.clinicName);
      emit(ProfileLoaded(_allProfiles, _allProfiles));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  void _onSearchProfiles(SearchProfiles event, Emitter<ProfileState> emit) {
    final filtered = _allProfiles.where((p) =>
        p.profileName.toLowerCase().contains(event.query.toLowerCase())).toList();

    emit(ProfileLoaded(_allProfiles, filtered));
  }
}
