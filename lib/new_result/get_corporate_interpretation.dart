import 'data/model/corporate_interpretation.dart';

enum CorporateScoreKey {
  energyUtilization,
  digestiveBalance,
  breathingEfficiency,
  metabolicLoad,
}
extension CorporateScoreKeyExt on CorporateScoreKey {
  String get apiKey {
    switch (this) {
      case CorporateScoreKey.energyUtilization:
        return 'energy_utilization';
      case CorporateScoreKey.digestiveBalance:
        return 'digestive_balance';
      case CorporateScoreKey.breathingEfficiency:
        return 'breathing_efficiency';
      case CorporateScoreKey.metabolicLoad:
        return 'metabolic_load';
    }
  }
}
CorporateScoreKey? corporateScoreKeyFromApi(String key) {
  switch (key) {
    case 'energy_utilization':
      return CorporateScoreKey.energyUtilization;
    case 'digestive_balance':
      return CorporateScoreKey.digestiveBalance;
    case 'breathing_efficiency':
      return CorporateScoreKey.breathingEfficiency;
    case 'metabolic_load':
      return CorporateScoreKey.metabolicLoad;
    default:
      return null;
  }
}

ScoreInterpretation? getScoreInterpretationByKey(
    CorporateInterpretation interpretation,
    String scoreKey,
    ) {
  for (final score in interpretation.scores) {
    if (score.scoreKey == scoreKey) {
      return score;
    }
  }
  return null;
}

