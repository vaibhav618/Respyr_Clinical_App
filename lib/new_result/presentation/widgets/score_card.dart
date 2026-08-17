import 'package:flutter/cupertino.dart';

import '../../data/model/corporate_interpretation.dart';
import '../../data/model/result_model.dart';
import 'custom_result_scorecard.dart';
import 'custom_result_scorecard_corporate.dart';

Widget buildScoreCard({
  required bool isCorporate,
  ScoreInterpretation? corporateInterpretation,
  required String scoreTitle,
  required double scoreVal,
  required String category,
  required NewResultModel userResultData,
  VoidCallback? onBackToTop,
}) {
  final timeStamp = userResultData.timestamp.toString();

  if (isCorporate) {
    assert(
    corporateInterpretation != null,
    'corporateInterpretation must not be null for corporate users',
    );

    return CustomResultScorecardCorporate(
      scoreTitle: scoreTitle,
      scoreVal: scoreVal,
      category: category,
      timeStamp: timeStamp,
      userResultData: userResultData,
      corporateInterpretation: corporateInterpretation!,
    );
  }

  return CustomResultScorecard(
    scoreTitle: scoreTitle,
    scoreVal: scoreVal,
    category: category,
    timeStamp: timeStamp,
    userResultData: userResultData,
    onBackToTop: onBackToTop,
  );
}
