import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repository/clinic_name_check_repository.dart';
import 'clinic_name_check_event.dart';
import 'clinic_name_check_state.dart';

class ClinicNameCheckBloc extends Bloc<ClinicNameCheckEvent, ClinicNameCheckState> {
  final ClinicNameCheckRepository repo;

  Timer? _debounce;

  ClinicNameCheckBloc({required this.repo}) : super(const ClinicNameCheckState()) {
    on<ClinicNameChanged>(_onChanged);
    on<ClinicNameCheckSubmitted>(_onSubmitted);
    on<ClinicNameCheckReset>(_onReset);
  }

  void _onReset(ClinicNameCheckReset event, Emitter<ClinicNameCheckState> emit) {
    _debounce?.cancel();
    emit(const ClinicNameCheckState());
  }

  void _onChanged(ClinicNameChanged event, Emitter<ClinicNameCheckState> emit) {
    final name = event.clinicName.trim();

    // Show typing state and clear old results
    emit(state.copyWith(
      status: ClinicNameCheckStatus.typing,
      clinicName: name,
      clearExists: true,
      clearMessage: true,
    ));

    _debounce?.cancel();

    // Don’t call API for very short names
    if (name.length < 3) return;

    _debounce = Timer(const Duration(milliseconds: 500), () {
      add(ClinicNameCheckSubmitted(name));
    });
  }

  Future<void> _onSubmitted(
      ClinicNameCheckSubmitted event,
      Emitter<ClinicNameCheckState> emit,
      ) async {
    final name = event.clinicName.trim();
    if (name.isEmpty) return;

    emit(state.copyWith(
      status: ClinicNameCheckStatus.loading,
      clearMessage: true,
      clearExists: true,
    ));

    try {
      final res = await repo.checkClinicName(name);

      emit(state.copyWith(
        status: ClinicNameCheckStatus.success,
        exists: res.exists,
        message: res.message,
        clinicName: res.clinicName,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ClinicNameCheckStatus.failure,
        message: e.toString().replaceFirst("Exception: ", ""),
        clearExists: true,
      ));
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
