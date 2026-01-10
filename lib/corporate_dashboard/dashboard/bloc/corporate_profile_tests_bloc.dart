import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repository/corporate_profile_tests_repository.dart';
import 'corporate_profile_tests_event.dart';
import 'corporate_profile_tests_state.dart';

class CorporateProfileTestsBloc
    extends Bloc<CorporateProfileTestsEvent, CorporateProfileTestsState> {
  final CorporateProfileTestsRepository repository;

  CorporateProfileTestsBloc({required this.repository})
      : super(CorporateProfileTestsState.initial()) {
    on<CorporateProfileTestsFetchRequested>(_onFetch);
    on<CorporateProfileTestsClear>(_onClear);
  }

  Future<void> _onFetch(
      CorporateProfileTestsFetchRequested event,
      Emitter<CorporateProfileTestsState> emit,
      ) async {
    emit(
      state.copyWith(
        status: CorporateProfileTestsStatus.loading,
        clearError: true,
      ),
    );

    try {
      final res = await repository.fetchTests(
        loginId: event.loginId,
        profileId: event.profileId,
        date: event.date,
      );

      emit(
        state.copyWith(
          status: CorporateProfileTestsStatus.success,
          response: res,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CorporateProfileTestsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onClear(
      CorporateProfileTestsClear event,
      Emitter<CorporateProfileTestsState> emit,
      ) {
    emit(CorporateProfileTestsState.initial());
  }
}
