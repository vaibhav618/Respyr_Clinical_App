import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_theme.dart';

/// Picks which of the four scores the analytics and the test log are showing.
///
/// This was a DropdownButton in a bordered box: two taps and an overlay to
/// change a four-way toggle, with the current choice the only one visible. As
/// a row of chips the options are all on screen, switching costs one tap, and
/// the selection is legible at a glance while scanning the numbers below it.
///
/// The chips divide the row evenly and share the card's margins, so the strip
/// lines up with the panel underneath on every screen. Sizing them to their
/// own text instead left the row short of the card's edge on a wide phone and
/// running past it — needing a sideways scroll — on a narrow one.
class ScoreTypeSelector extends StatelessWidget {
  /// The key used by the analytics and log widgets, e.g. 'Liver stress score'.
  final String selected;
  final ValueChanged<String> onChanged;

  const ScoreTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// Full key to chip label. The keys are the strings the score lookups
  /// already switch on, so they cannot be shortened — but "Gut fermentation
  /// score" does not need repeating on a chip inside a panel about scores.
  static const Map<String, String> options = {
    'Sugar score': 'Sugar',
    'Liver stress score': 'Liver',
    'Gut fermentation score': 'Gut',
    'Respiratory score': 'Respiratory',
  };

  static const double _gap = 7;
  static const double _hPadding = 6;
  static const double _border = 1;
  static const double _maxFont = 13;
  static const double _minFont = 9;

  /// One type size for all four chips, chosen so the longest label fits its
  /// quarter of the row.
  ///
  /// Shrinking each label independently (a FittedBox per chip) would leave
  /// "Respiratory" a size smaller than "Gut" sitting next to it. Measuring the
  /// longest one and applying the result to all of them keeps the strip even.
  double _fontSize(BuildContext context, double rowWidth) {
    final double chipWidth =
        (rowWidth - _gap * (options.length - 1)) / options.length;
    // The border is drawn inside the box, so it eats into the text area on
    // top of the padding.
    final double textSpace = chipWidth - (_hPadding + _border) * 2;
    if (textSpace <= 0) return _minFont;

    final String longest = options.values
        .reduce((a, b) => a.length >= b.length ? a : b);

    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: longest,
        style: GoogleFonts.poppins(
          fontSize: _maxFont,
          // Measure the heavier of the two weights — the selected chip is
          // w600, and sizing against w500 would let the selected one spill.
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      // Without this the measurement ignores the device's font-size setting,
      // so a phone set to larger text renders wider than what was measured
      // and the longest label is clipped.
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();

    if (painter.width <= textSpace) return _maxFont;
    // Leave a hair of slack: glyph advances do not scale perfectly linearly
    // with point size, so an exact-fit ratio can still land a pixel over.
    return (_maxFont * textSpace / painter.width * 0.97)
        .clamp(_minFont, _maxFont);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DashTheme.gutter),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double fontSize = _fontSize(context, constraints.maxWidth);
          final List<String> keys = options.keys.toList();

          return SizedBox(
            height: 36,
            child: Row(
              children: [
                for (int i = 0; i < keys.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  Expanded(
                    child: _chip(
                      keys[i],
                      options[keys[i]]!,
                      keys[i] == selected,
                      fontSize,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String key, String label, bool isSelected, double fontSize) {
    return Material(
      color: isSelected ? DashTheme.blue : DashTheme.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => onChanged(key),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: _hPadding),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? DashTheme.blue : DashTheme.line,
            ),
          ),
          // Backstop. The measurement above should already have found a size
          // that fits, but it depends on Poppins being resident — if the font
          // is still loading it is measured against the fallback's metrics.
          // This guarantees the label is never clipped, whatever happens.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: isSelected ? DashTheme.white : DashTheme.muted,
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
