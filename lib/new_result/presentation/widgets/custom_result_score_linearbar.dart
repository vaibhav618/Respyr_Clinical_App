import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/score_color_helper.dart';
import '../../../utils/score_status_helper.dart';

/// One organ's score on the body diagram: icon, name, counted-up percentage,
/// a filling bar, and the status line.
///
/// Restyled from the original, which painted the number and status through
/// gradient ShaderMasks in three different typefaces (Poppins, Roboto,
/// Mulish) over a 35px bar. One face, solid band colours, and a bar that
/// spans the block — and the whole capsule animates in: it fades up, then
/// the number counts and the bar fills together.
class CustomResultScoreLinearbar extends StatefulWidget {
  final double progress;
  final String svgPath;
  final String scoreType;
  final String textTitle;
  final String? subStatusTitle;
  final String? addOnSubTitle;

  /// Stagger offset — the diagram brings its four capsules in one after
  /// another rather than all at once.
  final Duration delay;

  /// Breaks the title one word per line. On for the gut capsule only, whose
  /// three-word title should stack "Gut / Fermentation / Score"; the short
  /// titles read better wrapping naturally.
  final bool breakWords;

  /// Opens this score's interpretation. Null leaves the capsule inert.
  final VoidCallback? onTap;

  const CustomResultScoreLinearbar({
    super.key,
    required this.progress,
    required this.svgPath,
    required this.textTitle,
    this.addOnSubTitle,
    this.subStatusTitle,
    required this.scoreType,
    this.delay = Duration.zero,
    this.breakWords = false,
    this.onTap,
  });

  @override
  State<CustomResultScoreLinearbar> createState() =>
      _CustomResultScoreLinearbarState();
}

class _CustomResultScoreLinearbarState
    extends State<CustomResultScoreLinearbar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _appear;
  late final Animation<double> _fill;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _appear = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.25, curve: Curves.easeOut),
    );
    _fill = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 1, curve: Curves.easeOutCubic),
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double scorePct = widget.progress * 100;
    final Color band = ScoreColorHelper.getScoreColor(scorePct);
    final List<Color> barGradient =
        ScoreColorHelper.getLinearScoreColor(scorePct);

    final String statusWord = ScoreStatusHelper.getScoreTitle(scorePct);
    final String subtitle = (widget.addOnSubTitle ??
            widget.subStatusTitle ??
            ScoreStatusHelper.getScoreSubTitle(scorePct))
        .replaceAll("\n", " ");

    final String cleaned = widget.textTitle.replaceAll("\n", " ");
    final String title =
        widget.breakWords ? cleaned.replaceAll(" ", "\n") : cleaned;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double shown = widget.progress * _fill.value;

        return Opacity(
          opacity: _appear.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - _appear.value)),
            // 116 rather than 108: the title column must hold "Fermentation"
            // unbroken — at the narrower width the word sat exactly at the
            // line limit and wrapped mid-word.
            child: GestureDetector(
              onTap: widget.onTap,
              // The capsule is mostly whitespace between small elements; an
              // opaque hit test makes the whole 116px block one target.
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
              width: 116,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          color: band.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            widget.svgPath,
                            height: 18,
                            width: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        // Word-per-line titles must never re-wrap: if the
                        // longest word runs a hair over the column (a larger
                        // device font scale is enough), its tail character
                        // drops to a line of its own. The FittedBox shrinks
                        // the whole block that hair instead, keeping each
                        // word intact on its line.
                        child: widget.breakWords
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  title,
                                  softWrap: false,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF252525),
                                    height: 1.15,
                                  ),
                                ),
                              )
                            : Text(
                                title,
                                maxLines: 4,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF252525),
                                  height: 1.15,
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${(shown * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: band,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusWord,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: band,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 4,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Container(color: const Color(0xFFE5E7EB)),
                          FractionallySizedBox(
                            widthFactor: shown.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: barGradient),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFA1A1A1),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        );
      },
    );
  }
}
