import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:respyr_clinical/clinical_dashboard/clinic_details/model/clinical_details_model.dart';
import '../repository/clinic_details_repository.dart';


abstract class ClinicEvent {}

class FetchClinicEvent extends ClinicEvent {
  final String token;
  final String clinicName;

  FetchClinicEvent({required this.token, required this.clinicName});
}

abstract class ClinicState {}

class ClinicInitial extends ClinicState {}

class ClinicLoading extends ClinicState {}

class ClinicLoaded extends ClinicState {
  final List<ClinicalDetailsModel> clinics;

  ClinicLoaded(this.clinics);
}

class ClinicError extends ClinicState {
  final String message;

  ClinicError(this.message);
}

class ClinicBloc extends Bloc<ClinicEvent, ClinicState> {
  final ClinicDetailsRepository repository;

  ClinicBloc(this.repository) : super(ClinicInitial()) {
    on<FetchClinicEvent>((event, emit) async {
      emit(ClinicLoading());
      try {
        final clinics = await repository.fetchClinics(
          token: event.token,
          clinicName: event.clinicName,
        );
        emit(ClinicLoaded(clinics));
      } catch (e) {
        emit(ClinicError(e.toString()));
      }
    });
  }
}
