import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/model/set_password_request.dart';
import '../data/repository/set_password_repository.dart';
import 'set_password_event.dart';
import 'set_password_state.dart';


class SetPasswordBloc extends Bloc<SetPasswordEvent, SetPasswordState> {
  final SetPasswordRepository repo;

  SetPasswordBloc({required this.repo}) : super(const SetPasswordState()) {
    on<SubjectIdChanged>((e, emit) => emit(state.copyWith(subjectId: e.subjectId)));
    on<PasswordChanged>((e, emit) => emit(state.copyWith(password: e.password)));
    on<ConfirmPasswordChanged>((e, emit) => emit(state.copyWith(confirmPassword: e.confirmPassword)));

    on<SubmitSetPassword>(_onSubmit);
  }

  Future<void> _onSubmit(
      SubmitSetPassword event,
      Emitter<SetPasswordState> emit,
      ) async {
    emit(state.copyWith(status: SetPasswordStatus.loading, errorMessage: null));

    try {
      final subjectId = state.subjectId.trim();
      final pass = state.password;
      final cpass = state.confirmPassword;

      if (subjectId.isEmpty) throw Exception("Subject ID is required");
      if (pass.isEmpty) throw Exception("Password is required");
      if (pass.length < 6) throw Exception("Password must be at least 6 characters");
      if (pass != cpass) throw Exception("Password and confirm password must match");

      final req = SetPasswordRequest(subjectId: subjectId, password: pass);

      final resp = await repo.setPassword(req);
      // optional: print server message
      // print("✅ set password response: $resp");

      emit(state.copyWith(status: SetPasswordStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: SetPasswordStatus.failure,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      ));
    }
  }
}
