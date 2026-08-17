import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/quick_summary_card.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/result_appbar.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/result_score_lenebar.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/score_card.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/score_interpretation.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/score_reference_card.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/score_summary_grid.dart';

import '../../../common/get_score_title.dart';
import '../../data/model/result_model.dart';
import '../../data/model/result_profile_data_model.dart';
import '../../services/result_pdf_service.dart';
import '../view_model/result_view_model.dart';
import 'bmi_bmr_card.dart';
import 'disclaimer_card.dart';

/// The result page: a grid of the four scores up top, and ONE interpretation
/// card below it, switched by tapping a tile.
///
/// It used to stack all four interpretation cards down the page — several
/// screens of scroll, most of it unread. And the summary up top was a body
/// diagram with four score blocks absolute-positioned over it, which
/// overlapped on narrow phones. The grid solves both: it cannot collide, and
/// as the selector it means only the score being read costs any height.
/// Because the tap happens at the grid, the reader is at the top of the card
/// when it swaps — content below can be any length without stranding anyone.
class NonCorporateResultScreen extends StatefulWidget {
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
  State<NonCorporateResultScreen> createState() =>
      _NonCorporateResultScreenState();
}

class _NonCorporateResultScreenState extends State<NonCorporateResultScreen> {
  String _selected = 'respiratory';

  /// Anchor for the back-to-top arrow under the card: the selector row, so
  /// landing there shows the chips (ready for the next score) with the card's
  /// top right below them.
  final GlobalKey _selectorKey = GlobalKey();

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

  /// Builds the PDF report, writes it to a file and hands it to the system
  /// PDF viewer — from there the reader saves or shares it wherever they
  /// want, with no storage permissions involved.
  bool _exportingPdf = false;

  Future<void> _downloadPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);

    try {
      final vm = Provider.of<ResultViewModel>(context, listen: false);
      final bytes = await ResultPdfService.build(
        result: widget.userResultData,
        profile: widget.userProfileData,
        bmi: vm.bmi,
        bmr: vm.bmr,
      );

      final dir = await getTemporaryDirectory();
      final String subject = (widget.userProfileData.profileName ?? 'subject')
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
      // Suffixed with the export moment, not just the test's timestamp — a
      // constant name meant every re-export overwrote the same path and a
      // viewer showing the old file was indistinguishable from a fresh one.
      final file = File(
        '${dir.path}/Respyr_Report_${subject}_'
        '${widget.userResultData.timestamp}_'
        '${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);

      final openResult = await OpenFile.open(file.path);
      if (openResult.type != ResultType.done && mounted) {
        // No PDF viewer on the device — the file still exists; say where.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report saved to ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create the PDF report')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  static const Map<String, ScoreType> _types = {
    'respiratory': ScoreType.respiratory,
    'sugar': ScoreType.sugar,
    'liver': ScoreType.liver,
    'gut': ScoreType.gut,
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

  @override
  Widget build(BuildContext context) {
    final resultViewModel = Provider.of<ResultViewModel>(context);
    final bmi = resultViewModel.bmi;
    final bmr = resultViewModel.bmr;

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
          onDownload: _downloadPdf,
          downloadBusy: _exportingPdf,
        ),
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Everything the page has always carried, in its original
                // order — the redesign only swaps HOW the four score cards
                // are reached (the tile grid below), it removes nothing.
                const SizedBox(height: 20),

                if (bmi != null && bmr != null) ...[
                  BmiBmrCard(bodyMassIndex: bmi, basalMetabolicRate: bmr),
                  const SizedBox(height: 20),
                ],

                const ScoreReferenceCard(isCorporate: false),

                const SizedBox(height: 10),

                resultScoreLineBar(
                  isCorporate: false,
                  context: context,
                  userResultData: widget.userResultData,
                  // Tapping a capsule selects that score and lands on the
                  // selector with the card's top right below it — the same
                  // spot the card's own "Back to top" footer returns to.
                  onScoreTap: (category) {
                    setState(() => _selected = category);
                    _scrollToCardTop();
                  },
                ),

                const SizedBox(height: 20),

                QuickSummary(userResultData: widget.userResultData),

                const SizedBox(height: 30),

                scoreInterpretation(),

                const SizedBox(height: 16),

                // The selector: tap a score to load its card below.
                KeyedSubtree(
                  key: _selectorKey,
                  child: ScoreSummaryGrid(
                    userResultData: widget.userResultData,
                    selected: _selected,
                    onSelect: (category) =>
                        setState(() => _selected = category),
                  ),
                ),

                const SizedBox(height: 14),

                // The selected score's card, cross-faded on switch. Sized to
                // the top so the swap does not slide the content below around
                // mid-fade.
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
                      isCorporate: false,
                      scoreTitle: getScoreTitle(
                        isCorporate: false,
                        score: _types[_selected] ?? ScoreType.respiratory,
                      ),
                      scoreVal: _scoreFor(_selected),
                      category: _selected,
                      userResultData: widget.userResultData,
                      // Reading a whole card ends far from the selector; the
                      // arrow in its corner returns there — chips in view,
                      // card top right below — so the next score is one tap
                      // away.
                      onBackToTop: _scrollToCardTop,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const DisclaimerCard(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
