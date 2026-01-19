import 'package:equatable/equatable.dart';

abstract class CorporateInterpretationEvent extends Equatable {
  const CorporateInterpretationEvent();

  @override
  List<Object?> get props => [];
}

class FetchCorporateInterpretation extends CorporateInterpretationEvent {
  final double energyUtilization;
  final double digestiveBalance;
  final double breathingEfficiency;
  final double metabolicLoad;

  const FetchCorporateInterpretation({
    required this.energyUtilization,
    required this.digestiveBalance,
    required this.breathingEfficiency,
    required this.metabolicLoad,
  });

  @override
  List<Object?> get props => [
    energyUtilization,
    digestiveBalance,
    breathingEfficiency,
    metabolicLoad,
  ];
}
