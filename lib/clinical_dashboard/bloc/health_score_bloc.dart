import 'package:flutter_bloc/flutter_bloc.dart';

import '../service/overall_data_by_date_service.dart';
import 'overall_data_by_date_event.dart';
import 'overall_data_by_date_state.dart';

class HealthScoreBloc extends Bloc<OverallDataByDateEvent, HealthScoreState> {
  final OverallDataByDateService service;

  HealthScoreBloc(this.service) : super(HealthScoreInitial()) {
    on<FetchHealthScoreData>((event, emit) async {
      emit(HealthScoreLoading());
      try {
        final response = await service.fetchOverallData(
          loginId: event.loginId,
          date: event.date,
        );
        emit(HealthScoreLoaded(response));
      } catch (e) {
        emit(HealthScoreError(e.toString()));
      }
    });
  }
}
