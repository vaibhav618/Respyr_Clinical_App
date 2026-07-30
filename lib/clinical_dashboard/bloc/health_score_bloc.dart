import 'package:flutter_bloc/flutter_bloc.dart';

import '../service/overall_data_by_date_service.dart';
import 'overall_data_by_date_event.dart';
import 'overall_data_by_date_state.dart';

class HealthScoreBloc extends Bloc<OverallDataByDateEvent, HealthScoreState> {
  final OverallDataByDateService service;

  HealthScoreBloc(this.service) : super(HealthScoreInitial()) {
    on<FetchHealthScoreData>((event, emit) async {
      // Paint the last known data for this date immediately (if we have it) so
      // relaunching after a background kill shows content, not skeletons. The
      // network call still runs and replaces it a moment later.
      final cached = await service.readCached(
        loginId: event.loginId,
        date: event.date,
      );
      if (cached != null) {
        emit(HealthScoreLoaded(cached));
      } else {
        emit(HealthScoreLoading());
      }

      try {
        final response = await service.fetchOverallData(
          loginId: event.loginId,
          date: event.date,
        );
        emit(HealthScoreLoaded(response));
      } catch (e) {
        // Cached data is already on screen — don't replace it with an error.
        if (cached == null) {
          emit(HealthScoreError(e.toString()));
        }
      }
    });
  }
}
