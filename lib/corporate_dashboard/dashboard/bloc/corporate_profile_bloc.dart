import 'package:flutter_bloc/flutter_bloc.dart';
import 'corporate_profile_event.dart';
import 'corporate_profile_state.dart';
import '../data/repository/corporate_profile_repository.dart';

class CorporateProfileBloc extends Bloc<CorporateProfileEvent, CorporateProfileState> {
  final CorporateProfileRepository repo;

  CorporateProfileBloc({required this.repo}) : super(CorporateProfileState.initial()) {
    on<CorporateProfileFetchRequested>(_onFetch);
    on<CorporateProfileReset>(_onReset);
  }

  Future<void> _onFetch(
      CorporateProfileFetchRequested event,
      Emitter<CorporateProfileState> emit,
      ) async {
    final email = event.email.trim();
    if (email.isEmpty) {
      emit(state.copyWith(
        status: CorporateProfileStatus.failure,
        errorMessage: "Email is required",
        clearUser: true,
      ));
      return;
    }

    emit(state.copyWith(
      status: CorporateProfileStatus.loading,
      clearError: true,
    ));

    try {
      final res = await repo.fetchProfileByEmail(email);
      emit(state.copyWith(
        status: CorporateProfileStatus.success,
        user: res.data,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CorporateProfileStatus.failure,
        errorMessage: e.toString().replaceFirst("Exception: ", ""),
        clearUser: true,
      ));
    }
  }

  void _onReset(CorporateProfileReset event, Emitter<CorporateProfileState> emit) {
    emit(CorporateProfileState.initial());
  }

  @override
  Future<void> close() {
    repo.dispose();
    return super.close();
  }
}
