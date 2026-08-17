import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../common/get_score_title.dart';
import '../../../shared/images_string.dart';
import '../../data/model/result_model.dart';
import 'custom_result_score_linearbar.dart';

/// The body diagram, in its original arrangement: the figure drawn at 80% of
/// the screen width with the four score capsules positioned over it.
///
/// The capsules themselves are the redesigned ones — one typeface, band
/// colours, staggered entrance with count-up — and their fixed compact width
/// keeps the left and right pairs clear of each other at these positions.
/// The figure still breathes (a ±1.2% scale pulse), which is the product.
Widget resultScoreLineBar({
  required bool isCorporate,
  required BuildContext context,
  required NewResultModel userResultData,
  /// Called with 'respiratory' | 'sugar' | 'liver' | 'gut' when a capsule is
  /// tapped. Omit to leave the diagram read-only.
  void Function(String category)? onScoreTap,
}) {
  return _ResultBodyDiagram(
    isCorporate: isCorporate,
    userResultData: userResultData,
    onScoreTap: onScoreTap,
  );
}

class _ResultBodyDiagram extends StatefulWidget {
  final bool isCorporate;
  final NewResultModel userResultData;
  final void Function(String category)? onScoreTap;

  const _ResultBodyDiagram({
    required this.isCorporate,
    required this.userResultData,
    this.onScoreTap,
  });

  @override
  State<_ResultBodyDiagram> createState() => _ResultBodyDiagramState();
}

class _ResultBodyDiagramState extends State<_ResultBodyDiagram>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.userResultData;
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      width: width,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _breath,
            builder: (context, child) {
              final double t = Curves.easeInOut.transform(_breath.value);
              return Transform.scale(scale: 1 + 0.012 * t, child: child);
            },
            child: SvgPicture.asset(
              ResSvg.humanBody,
              width: width * 0.8,
              height: height * 0.35,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: height * 0.05,
            left: width * 0.05,
            child: _capsule(
              isCorporate: widget.isCorporate,
              progress: data.respiratoryScore / 100,
              svgPath: ResSvg.respiratory,
              score: ScoreType.respiratory,
              scoreType: 'respiratory',
              order: 0,
              onScoreTap: widget.onScoreTap,
            ),
          ),
          // Nudged left and up relative to the other corners: the old gut
          // block was wider than the new capsule, so anchoring the narrow one
          // at the same right offset left it hugging the edge.
          Positioned(
            top: height * 0.03,
            right: width * 0.05,
            child: _capsule(
              isCorporate: widget.isCorporate,
              progress: data.gutScore / 100,
              svgPath: ResSvg.gutVital,
              score: ScoreType.gut,
              scoreType: 'gut',
              order: 1,
              breakWords: true,
              onScoreTap: widget.onScoreTap,
            ),
          ),
          Positioned(
            top: height * 0.22,
            left: width * 0.05,
            child: _capsule(
              isCorporate: widget.isCorporate,
              progress: data.liverScore / 100,
              svgPath: ResSvg.liver,
              score: ScoreType.liver,
              scoreType: 'liver',
              order: 3,
              onScoreTap: widget.onScoreTap,
            ),
          ),
          Positioned(
            top: height * 0.22,
            right: width * 0.05,
            child: _capsule(
              isCorporate: widget.isCorporate,
              progress: data.sugarScore / 100,
              svgPath: ResSvg.sugarPancreas,
              score: ScoreType.sugar,
              scoreType: 'sugar',
              order: 2,
              onScoreTap: widget.onScoreTap,
            ),
          ),
        ],
      ),
    );
  }
}

/// Builds one capsule with its title and stagger order resolved.
Widget _capsule({
  required bool isCorporate,
  required double progress,
  required String svgPath,
  required ScoreType score,
  required String scoreType,
  required int order,
  bool breakWords = false,
  void Function(String category)? onScoreTap,
}) {
  return CustomResultScoreLinearbar(
    progress: progress,
    svgPath: svgPath,
    textTitle: getScoreTitle(isCorporate: isCorporate, score: score),
    scoreType: scoreType,
    delay: Duration(milliseconds: 140 * order),
    breakWords: breakWords,
    onTap: onScoreTap == null ? null : () => onScoreTap(scoreType),
  );
}
