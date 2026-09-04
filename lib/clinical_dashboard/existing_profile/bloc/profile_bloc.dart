import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/profile_model.dart';
import '../recent_subjects.dart';
import '../repositories/profile_repository.dart';

// EVENTS
abstract class ProfileEvent {}

/// Initial / refresh load — resets to page 1 with no search.
class LoadProfiles extends ProfileEvent {
  final String clinicName;
  LoadProfiles(this.clinicName);
}

/// Append the next page to the currently shown list.
class LoadMoreProfiles extends ProfileEvent {}

/// Server-side search — resets to page 1 filtered by [query].
class SearchProfiles extends ProfileEvent {
  final String query;
  SearchProfiles(this.query);
}

// STATES
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final List<ProfileModel> profiles;
  final bool hasMore;
  final bool isLoadingMore;

  ProfileLoaded(
    this.profiles, {
    this.hasMore = false,
    this.isLoadingMore = false,
  });
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

// BLOC
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;
  static const int _pageSize = 20;

  String _clinicName = '';
  String _query = '';
  int _currentPage = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  List<ProfileModel> _profiles = [];

  ProfileBloc(this.repository) : super(ProfileInitial()) {
    on<LoadProfiles>(_onLoadProfiles);
    on<LoadMoreProfiles>(_onLoadMoreProfiles);
    on<SearchProfiles>(_onSearchProfiles);
  }

  /// Fresh load of page 1 (used on first open, reconnect, and after edits).
  Future<void> _onLoadProfiles(
    LoadProfiles event,
    Emitter<ProfileState> emit,
  ) async {
    _clinicName = event.clinicName;
    _query = '';
    await _loadFirstPage(emit);
  }

  /// Server-side search — treated like a fresh page-1 load with a query.
  Future<void> _onSearchProfiles(
    SearchProfiles event,
    Emitter<ProfileState> emit,
  ) async {
    _query = event.query.trim();
    await _loadFirstPage(emit);
  }

  Future<void> _loadFirstPage(Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    _currentPage = 1;
    try {
      final result = await repository.fetchProfiles(
        _clinicName,
        page: _currentPage,
        limit: _pageSize,
        search: _query,
      );
      _profiles = await _sortByMostRecentlyTested(result.profiles);
      _hasMore = result.hasMore;
      emit(ProfileLoaded(_profiles, hasMore: _hasMore));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  /// Fetch the next page and append it to the list already on screen.
  Future<void> _onLoadMoreProfiles(
    LoadMoreProfiles event,
    Emitter<ProfileState> emit,
  ) async {
    if (_isLoadingMore || !_hasMore) return; // nothing to do
    _isLoadingMore = true;
    emit(ProfileLoaded(_profiles, hasMore: _hasMore, isLoadingMore: true));

    try {
      final result = await repository.fetchProfiles(
        _clinicName,
        page: _currentPage + 1,
        limit: _pageSize,
        search: _query,
      );
      _currentPage += 1;
      _profiles = await _sortByMostRecentlyTested([
        ..._profiles,
        ...result.profiles,
      ]);
      _hasMore = result.hasMore;
      emit(ProfileLoaded(_profiles, hasMore: _hasMore));
    } catch (e) {
      // Keep what's already shown; just stop the spinner.
      emit(ProfileLoaded(_profiles, hasMore: _hasMore));
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Whoever was tested most recently comes first, so the list reflects who is
  /// actually being seen rather than the order the API happens to return.
  /// (With pagination this now orders the rows loaded so far.)
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
}
