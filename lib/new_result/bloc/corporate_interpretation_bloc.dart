import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repository/corporate_interpretation_repository.dart';
import 'corporate_interpretation_event.dart';
import 'corporate_interpretation_state.dart';

class CorporateInterpretationBloc
    extends Bloc<CorporateInterpretationEvent, CorporateInterpretationState> {
  final CorporateInterpretationRepository repository;

  CorporateInterpretationBloc({required this.repository})
      : super(CorporateInterpretationInitial()) {
    on<FetchCorporateInterpretation>(_onFetch);
  }

  Future<void> _onFetch(
      FetchCorporateInterpretation event,
      Emitter<CorporateInterpretationState> emit,
      ) async {
    try {
      emit(CorporateInterpretationLoading());

      final data = await repository.fetchInterpretation(
        energyUtilization: event.energyUtilization,
        digestiveBalance: event.digestiveBalance,
        breathingEfficiency: event.breathingEfficiency,
        metabolicLoad: event.metabolicLoad,
      );

      emit(CorporateInterpretationLoaded(data));
    } catch (e) {
      emit(CorporateInterpretationFailure(e.toString()));
    }
  }
}
