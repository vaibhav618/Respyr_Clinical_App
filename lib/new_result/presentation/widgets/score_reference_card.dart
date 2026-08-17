import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// How to read the scores: the three bands drawn as one left-to-right scale.
///
/// Was three dot-plus-text rows spread across a bordered box — a legend that
/// only named the colours. Drawing the bands as segments of a single bar also
/// shows what they are: cut points on one 0-100 scale, poor at the bottom,
/// good at the top.
class ScoreReferenceCard extends StatelessWidget {
  final bool isCorporate;
  const ScoreReferenceCard({super.key, required this.isCorporate});

  static const List<(String, String, Color)> _bands = [
    ('Poor', '0–69', Color(0xFFEA5455)),
    ('Fair', '70–79', Color(0xFFFFC412)),
    ('Good', '80–100', Color(0xFF3EAF58)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            for (int i = 0; i < _bands.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: _segment(i)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _segment(int index) {
    final (String label, String range, Color color) = _bands[index];

    // Only the outer ends of the scale are rounded, so the three segments
    // read as one bar with cut points rather than three separate chips.
    final BorderRadius radius = BorderRadius.horizontal(
      left: index == 0 ? const Radius.circular(4) : const Radius.circular(1),
      right: index == _bands.length - 1
          ? const Radius.circular(4)
          : const Radius.circular(1),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(color: color, borderRadius: radius),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              range,
              style: GoogleFonts.poppins(
                color: const Color(0xFFA1A1A1),
                fontSize: 10.5,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
