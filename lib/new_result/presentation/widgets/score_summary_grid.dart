import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/score_color_helper.dart';
import '../../data/model/result_model.dart';

/// Selector for the interpretation card below: the four scores as one row of
/// chips, each carrying a dot in its score's band colour.
///
/// Started as a 2×2 grid of tiles with icon, percentage and band word, but
/// the percentages already appear on the body diagram directly above — the
/// tiles were repeating them at twice the size. As chips the row reads as
/// what it is, a control, and costs one line. Same idiom as the dashboard's
/// score selector, and sized the same way: one shared font size measured
/// against the longest label, so "Respiratory" fits its quarter of the row
/// on a narrow phone instead of clipping.
class ScoreSummaryGrid extends StatelessWidget {
  final NewResultModel userResultData;

  /// Which score's chip is highlighted: 'respiratory' | 'sugar' | 'liver' |
  /// 'gut'.
  final String selected;
  final ValueChanged<String> onSelect;

  const ScoreSummaryGrid({
    super.key,
    required this.userResultData,
    required this.selected,
    required this.onSelect,
  });

  static const Map<String, String> _labels = {
    'respiratory': 'Respiratory',
    'sugar': 'Sugar',
    'liver': 'Liver',
    'gut': 'Gut',
  };

  static const double _gap = 7;
  static const double _hPadding = 6;
  static const double _border = 1;
  static const double _maxFont = 13;
  static const double _minFont = 9;

  double _scoreFor(String category) {
    switch (category) {
      case 'sugar':
        return userResultData.sugarScore;
      case 'liver':
        return userResultData.liverScore;
      case 'gut':
        return userResultData.gutScore;
      case 'respiratory':
      default:
        return userResultData.respiratoryScore;
    }
  }

  /// One type size for all four chips, chosen so the longest label fits its
  /// quarter of the row. Shrinking each label independently would leave
  /// "Respiratory" a size smaller than "Gut" beside it.
  double _fontSize(BuildContext context, double rowWidth) {
    // The dot and its gap eat into the text space alongside padding/border.
    const double dotSpace = 7 + 5;
    final double chipWidth =
        (rowWidth - _gap * (_labels.length - 1)) / _labels.length;
    final double textSpace =
        chipWidth - (_hPadding + _border) * 2 - dotSpace;
    if (textSpace <= 0) return _minFont;

    final String longest =
        _labels.values.reduce((a, b) => a.length >= b.length ? a : b);

    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: longest,
        style: GoogleFonts.poppins(
          fontSize: _maxFont,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      // Without this the measurement ignores the device font-size setting.
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();

    if (painter.width <= textSpace) return _maxFont;
    return (_maxFont * textSpace / painter.width * 0.97)
        .clamp(_minFont, _maxFont);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double fontSize = _fontSize(context, constraints.maxWidth);
          final List<String> keys = _labels.keys.toList();

          return SizedBox(
            height: 36,
            child: Row(
              children: [
                for (int i = 0; i < keys.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  Expanded(child: _chip(keys[i], fontSize)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Selected chip takes its own score's band colour — tint fill, border and
  /// a soft lift, the same treatment as the Good/Fair/Poor legend cards under
  /// the dashboard chart. Which score you are reading and how it is doing are
  /// then the same signal.
  Widget _chip(String category, double fontSize) {
    final bool isSelected = category == selected;
    final Color band = ScoreColorHelper.getScoreColor(_scoreFor(category));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: band.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : const [],
      ),
      child: Material(
        color: isSelected ? band.withValues(alpha: 0.10) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => onSelect(category),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: _hPadding),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? band : const Color(0xFFE5E7EB),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The band dot keeps how the score is doing readable from
                  // the row itself, without repeating the percentage.
                  Container(
                    width: 7,
                    height: 7,
                    decoration:
                        BoxDecoration(color: band, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _labels[category]!,
                    maxLines: 1,
                    softWrap: false,
                    // Ink even when selected. Band-coloured text on the
                    // band's own tint was low-contrast — yellow on pale
                    // yellow was barely legible — and the dot, border, fill
                    // and shadow already carry the colour.
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF252525),
                      fontSize: fontSize,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
