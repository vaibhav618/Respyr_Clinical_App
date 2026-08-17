import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/result_appbar.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/score_card.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/score_interpretation.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/score_reference_card.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/score_summary_grid.dart';

import '../../../common/get_score_title.dart';
import '../../data/model/corporate_interpretation.dart';
import '../../data/model/result_model.dart';
import '../../data/model/result_profile_data_model.dart';
import '../../get_corporate_interpretation.dart';
import '../view_model/result_view_model.dart';
import 'bmi_bmr_card.dart';
import 'corporate_disclaimer.dart';
import 'result_score_lenebar.dart';

/// The corporate result page, mirroring the clinical one: the four scores as
/// selector chips driving ONE interpretation card, instead of all four cards
/// stacked down several screens of scroll. Tapping a capsule on the body
/// diagram also jumps to that score's card.
class CorporateResultScreen extends StatefulWidget {
  final VoidCallback navigateToDashboard;
  final NewResultModel userResultData;
  final ResultProfileDataModel userProfileData;
  final CorporateInterpretation corporateInterpretation;

  const CorporateResultScreen({
    super.key,
    required this.navigateToDashboard,
    required this.userResultData,
    required this.userProfileData,
    required this.corporateInterpretation,
  });

  @override
  State<CorporateResultScreen> createState() => _CorporateResultScreenState();
}

class _CorporateResultScreenState extends State<CorporateResultScreen> {
  String _selected = 'respiratory';

  final GlobalKey _selectorKey = GlobalKey();

  static const Map<String, ScoreType> _types = {
    'respiratory': ScoreType.respiratory,
    'sugar': ScoreType.sugar,
    'liver': ScoreType.liver,
    'gut': ScoreType.gut,
  };

  /// Corporate short names for the selector chips, matching the card titles
  /// (Breathing Efficiency, Energy Utilisation, …).
  static const Map<String, String> _chipLabels = {
    'respiratory': 'Breathing',
    'sugar': 'Energy',
    'liver': 'Metabolic',
    'gut': 'Digestive',
  };

  double _scoreFor(String category) {
    switch (category) {
      case 'sugar':
        return widget.userResultData.sugarScore;
      case 'liver':
        return widget.userResultData.liverScore;
      case 'gut':
        return widget.userResultData.gutScore;
      case 'respiratory':
      default:
        return widget.userResultData.respiratoryScore;
    }
  }

  ScoreInterpretation? _interpretationFor(String category) {
    switch (category) {
      case 'sugar':
        return getScoreInterpretationByKey(
          widget.corporateInterpretation,
          CorporateScoreKey.energyUtilization.apiKey,
        );
      case 'liver':
        return getScoreInterpretationByKey(
          widget.corporateInterpretation,
          CorporateScoreKey.metabolicLoad.apiKey,
        );
      case 'gut':
        return getScoreInterpretationByKey(
          widget.corporateInterpretation,
          CorporateScoreKey.digestiveBalance.apiKey,
        );
      case 'respiratory':
      default:
        return getScoreInterpretationByKey(
          widget.corporateInterpretation,
          CorporateScoreKey.breathingEfficiency.apiKey,
        );
    }
  }

  void _scrollToCardTop() {
    final BuildContext? anchor = _selectorKey.currentContext;
    if (anchor == null) return;
    Scrollable.ensureVisible(
      anchor,
      alignment: 0,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultViewModel = Provider.of<ResultViewModel>(context);
    final bmi = resultViewModel.bmi;
    final bmr = resultViewModel.bmr;

    final ScoreInterpretation? interpretation = _interpretationFor(_selected);

    // One PopScope. The old screen wrapped a WillPopScope around a PopScope,
    // both wired to navigateToDashboard, so a back press ran it twice.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.navigateToDashboard();
      },
      child: Scaffold(
        appBar: resultScreenAppbar(
          context: context,
          userResultData: widget.userResultData,
          userProfileData: widget.userProfileData,
          navigateToDashboard: widget.navigateToDashboard,
        ),
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                if (bmi != null && bmr != null) ...[
                  BmiBmrCard(bodyMassIndex: bmi, basalMetabolicRate: bmr),
                  const SizedBox(height: 20),
                ],

                const ScoreReferenceCard(isCorporate: true),

                const SizedBox(height: 10),

                resultScoreLineBar(
                  isCorporate: true,
                  context: context,
                  userResultData: widget.userResultData,
                  onScoreTap: (category) {
                    setState(() => _selected = category);
                    _scrollToCardTop();
                  },
                ),

                const SizedBox(height: 30),

                scoreInterpretation(),

                const SizedBox(height: 16),

                KeyedSubtree(
                  key: _selectorKey,
                  child: ScoreSummaryGrid(
                    userResultData: widget.userResultData,
                    selected: _selected,
                    onSelect: (category) =>
                        setState(() => _selected = category),
                    labels: _chipLabels,
                  ),
                ),

                const SizedBox(height: 14),

                if (interpretation != null)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_selected),
                      child: buildScoreCard(
                        isCorporate: true,
                        scoreTitle: getScoreTitle(
                          isCorporate: true,
                          score: _types[_selected] ?? ScoreType.respiratory,
                        ),
                        scoreVal: _scoreFor(_selected),
                        category: _selected,
                        userResultData: widget.userResultData,
                        corporateInterpretation: interpretation,
                        onBackToTop: _scrollToCardTop,
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                const CorporateDisclaimerCard(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
