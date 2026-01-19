import 'package:equatable/equatable.dart';

import '../data/model/corporate_interpretation.dart';

abstract class CorporateInterpretationState extends Equatable {
  const CorporateInterpretationState();

  @override
  List<Object?> get props => [];
}

class CorporateInterpretationInitial extends CorporateInterpretationState {}

class CorporateInterpretationLoading extends CorporateInterpretationState {}

class CorporateInterpretationLoaded extends CorporateInterpretationState {
  final CorporateInterpretation data;

  const CorporateInterpretationLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class CorporateInterpretationFailure extends CorporateInterpretationState {
  final String message;

  const CorporateInterpretationFailure(this.message);

  @override
  List<Object?> get props => [message];
}
