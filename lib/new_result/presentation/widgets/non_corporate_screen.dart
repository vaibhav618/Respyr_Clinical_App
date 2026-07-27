import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/quick_summary_card.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/result_appbar.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/result_score_lenebar.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/score_card.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/score_interpretation.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/score_reference_card.dart';

import '../../../common/get_score_title.dart';
import '../../data/model/result_model.dart';
import '../../data/model/result_profile_data_model.dart';
import '../view_model/result_view_model.dart';
import 'bmi_bmr_card.dart';
import 'disclaimer_card.dart';

class NonCorporateResultScreen extends StatelessWidget {
  final VoidCallback navigateToDashboard;
  final NewResultModel userResultData;
  final ResultProfileDataModel userProfileData;

  const NonCorporateResultScreen({
    super.key,
    required this.navigateToDashboard,
    required this.userResultData,
    required this.userProfileData,
  });

  @override
  Widget build(BuildContext context) {
    final resultViewModel = Provider.of<ResultViewModel>(context);
    final bmi = resultViewModel.bmi;
    final bmr = resultViewModel.bmr;

    return WillPopScope(
      onWillPop: () async {
        navigateToDashboard();
        return false;
      },
      child: Scaffold(
        appBar: resultScreenAppbar(
          context: context,
          userResultData: userResultData,
          userProfileData: userProfileData,
          navigateToDashboard: navigateToDashboard,
        ),
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: PopScope(
            canPop: true,
            onPopInvoked: (_) async => navigateToDashboard(),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  if (bmi != null && bmr != null)
                    BmiBmrCard(bodyMassIndex: bmi, basalMetabolicRate: bmr),

                  const SizedBox(height: 20),

                  const ScoreReferenceCard(isCorporate: false),

                  const SizedBox(height: 10),

                  resultScoreLineBar(
                    isCorporate: false,
                    context: context,
                    userResultData: userResultData,
                  ),

                  const SizedBox(height: 20),

                  QuickSummary(userResultData: userResultData),

                  const SizedBox(height: 30),

                  scoreInterpretation(),

                  const SizedBox(height: 20),

                  buildScoreCard(
                    isCorporate: false,
                    scoreTitle: getScoreTitle(
                      isCorporate: false,
                      score: ScoreType.respiratory,
                    ),
                    scoreVal: userResultData.respiratoryScore,
                    category: "respiratory",
                    userResultData: userResultData,
                  ),

                  const SizedBox(height: 20),

                  buildScoreCard(
                    isCorporate: false,
                    scoreTitle: getScoreTitle(
                      isCorporate: false,
                      score: ScoreType.sugar,
                    ),
                    scoreVal: userResultData.sugarScore,
                    category: "sugar",
                    userResultData: userResultData,
                  ),

                  const SizedBox(height: 20),

                  buildScoreCard(
                    isCorporate: false,
                    scoreTitle: getScoreTitle(
                      isCorporate: false,
                      score: ScoreType.liver,
                    ),
                    scoreVal: userResultData.liverScore,
                    category: "liver",
                    userResultData: userResultData,
                  ),

                  const SizedBox(height: 20),

                  buildScoreCard(
                    isCorporate: false,
                    scoreTitle: getScoreTitle(
                      isCorporate: false,
                      score: ScoreType.gut,
                    ),
                    scoreVal: userResultData.gutScore,
                    category: "gut",
                    userResultData: userResultData,
                  ),

                  const SizedBox(height: 50),

                  const DisclaimerCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
