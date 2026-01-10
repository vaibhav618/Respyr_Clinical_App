import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'sign_in_event.dart';
import 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc() : super(const SignInState()) {
    on<SignInClinicalPressed>(_onClinical);
    on<SignInCorporatePressed>(_onCorporate);
  }

  Future<void> _onClinical(
      SignInClinicalPressed event,
      Emitter<SignInState> emit,
      ) async {
    emit(state.copyWith(status: SignInStatus.loading, selectedType: "clinical"));

    try {
      // ✅ CALL SOMETHING HERE
      // Example: await repo.loginClinical();
      await Future.delayed(const Duration(milliseconds: 300)); // placeholder

      emit(state.copyWith(status: SignInStatus.success, selectedType: "clinical"));
    } catch (e) {
      emit(state.copyWith(
        status: SignInStatus.failure,
        errorMessage: "Clinical sign-in failed",
      ));
    }
  }

  Future<void> _onCorporate(
      SignInCorporatePressed event,
      Emitter<SignInState> emit,
      ) async {
    emit(state.copyWith(status: SignInStatus.loading, selectedType: "corporate"));

    try {
      await Future.delayed(const Duration(milliseconds: 300)); // placeholder
      emit(state.copyWith(status: SignInStatus.success, selectedType: "corporate"));
    } catch (e) {
      emit(state.copyWith(
        status: SignInStatus.failure,
        errorMessage: "Corporate sign-in failed",
      ));
    }
  }
}
