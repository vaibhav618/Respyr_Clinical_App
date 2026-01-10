import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repository/corporate_login_repository.dart';
import 'corporate_login_event.dart';
import 'corporate_login_state.dart';

class CorporateLoginBloc extends Bloc<CorporateLoginEvent, CorporateLoginState> {
  final CorporateLoginRepository repo;

  CorporateLoginBloc({required this.repo}) : super(CorporateLoginState.initial()) {
    on<CorporateLoginEmailChanged>((event, emit) {
      emit(state.copyWith(email: event.email, clearError: true));
    });

    on<CorporateLoginPasswordChanged>((event, emit) {
      emit(state.copyWith(password: event.password, clearError: true));
    });

    on<CorporateLoginSubmitted>(_onSubmit);
  }

  Future<void> _onSubmit(
      CorporateLoginSubmitted event,
      Emitter<CorporateLoginState> emit,
      ) async {
    final email = state.email.trim();
    final password = state.password;

    if (email.isEmpty || password.isEmpty) {
      emit(state.copyWith(
        status: CorporateLoginStatus.failure,
        errorMessage: "Email and password are required",
      ));
      return;
    }

    emit(state.copyWith(status: CorporateLoginStatus.loading, clearError: true));

    try {
      final res = await repo.login(email: email, password: password);

      emit(state.copyWith(
        status: CorporateLoginStatus.success,
        user: res.data,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CorporateLoginStatus.failure,
        errorMessage: e.toString().replaceFirst("Exception: ", ""),
      ));
    }
  }
}
