// blocs/subject_profile_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/subject_profile_model.dart';
import '../repositories/subject_profile_repository.dart';
import '../events/subject_profile_event.dart';
import '../state/subject_profile_state.dart';

class SubjectProfileBloc extends Bloc<SubjectProfileEvent, SubjectProfileState> {
  final SubjectProfileRepository repository;
  static const int _pageSize = 15;

  String _clinicName = '';
  String _profileId = '';
  int _page = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  SubjectProfileModel? _profile;
  List<dynamic> _scores = [];

  SubjectProfileBloc({required this.repository})
      : super(SubjectProfileInitial()) {
    on<LoadSubjectProfile>(_onLoad);
    on<LoadMoreSubjectScores>(_onLoadMore);
  }

  Future<void> _onLoad(
    LoadSubjectProfile event,
    Emitter<SubjectProfileState> emit,
  ) async {
    emit(SubjectProfileLoading());
    _clinicName = event.clinicName;
    _profileId = event.profileId;
    _page = 1;
    try {
      final result = await repository.fetchProfile(
        _clinicName,
        _profileId,
        page: 1,
        limit: _pageSize,
      );
      _profile = result['profile'];
      _scores = List<dynamic>.from(result['scores'] ?? []);
      _hasMore = result['hasMore'] == true;
      emit(SubjectProfileLoaded(
        profile: _profile!,
        scores: _scores,
        hasMore: _hasMore,
      ));
    } catch (e) {
      emit(SubjectProfileError("Something went wrong"));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreSubjectScores event,
    Emitter<SubjectProfileState> emit,
  ) async {
    if (_isLoadingMore || !_hasMore || _profile == null) return;
    _isLoadingMore = true;
    emit(SubjectProfileLoaded(
      profile: _profile!,
      scores: _scores,
      hasMore: _hasMore,
      isLoadingMore: true,
    ));
    try {
      final result = await repository.fetchProfile(
        _clinicName,
        _profileId,
        page: _page + 1,
        limit: _pageSize,
      );
      _page += 1;
      _scores = [..._scores, ...(result['scores'] as List<dynamic>)];
      _hasMore = result['hasMore'] == true;
      emit(SubjectProfileLoaded(
        profile: _profile!,
        scores: _scores,
        hasMore: _hasMore,
      ));
    } catch (e) {
      // Keep what's shown; just stop the spinner.
      emit(SubjectProfileLoaded(
        profile: _profile!,
        scores: _scores,
        hasMore: _hasMore,
      ));
    } finally {
      _isLoadingMore = false;
    }
  }
}
