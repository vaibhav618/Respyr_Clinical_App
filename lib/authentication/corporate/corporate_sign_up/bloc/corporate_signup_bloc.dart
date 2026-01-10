import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/data/corporate_signup_request.dart';
import '../data/repository/corporate_signup_repository.dart';
import 'corporate_signup_event.dart';
import 'corporate_signup_state.dart';

class CorporateSignUpBloc extends Bloc<CorporateSignUpEvent, CorporateSignUpState> {
  final CorporateSignUpRepository repo;

  CorporateSignUpBloc({required this.repo}) : super(const CorporateSignUpState()) {
    on<CorporateEmailChanged>((e, emit) => emit(state.copyWith(email: e.email)));
    on<CorporateNameChanged>((e, emit) => emit(state.copyWith(name: e.name)));
    on<CorporateGenderChanged>((e, emit) => emit(state.copyWith(gender: e.gender)));
    on<CorporateHeightChanged>((e, emit) => emit(state.copyWith(heightCm: e.height)));
    on<CorporateWeightChanged>((e, emit) => emit(state.copyWith(weightKg: e.weight)));
    on<CorporateAgeChanged>((e, emit) => emit(state.copyWith(age: e.age)));
    on<CorporateRegionChanged>((e, emit) => emit(state.copyWith(region: e.region)));
    on<CorporateClinicNameChanged>((e, emit) => emit(state.copyWith(clinicName: e.clinicName)));
    on<CorporatePasswordChanged>((e, emit) => emit(state.copyWith(password: e.password)));

    on<CorporateSignUpSubmitted>(_onSubmit);
  }

  Future<void> _onSubmit(
      CorporateSignUpSubmitted event,
      Emitter<CorporateSignUpState> emit,
      ) async {
    emit(state.copyWith(status: CorporateSignUpStatus.loading, errorMessage: null));

    try {
      final request = CorporateSignUpRequest(
        email: state.email,
        clinicName: state.clinicName,
        profileName: state.name,
        gender: state.gender,
        age: state.age,
        height: state.heightCm,
        weight: state.weightKg,
        region: state.region,
        password: state.password,
      );

      final response = await repo.submitCorporateSignUp(request);

      emit(state.copyWith(
        status: CorporateSignUpStatus.success,
        subjectId: response['subject_id']?.toString(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CorporateSignUpStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
