import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// BMI and BMR side by side, as value-over-caption stats.
///
/// The old card was grey-on-grey: page-background fill inside an off-palette
/// border, every string the same muted w400 — the two numbers had no more
/// weight than their labels. It also printed "1520.00" for BMR and "22.46"
/// for BMI, precision neither figure carries in practice.
class BmiBmrCard extends StatelessWidget {
  final double bodyMassIndex;
  final double basalMetabolicRate;

  const BmiBmrCard({
    super.key,
    required this.bodyMassIndex,
    required this.basalMetabolicRate,
  });

  /// WHO adult BMI bands, coloured with the app's score-band palette so
  /// "how to read this number" matches every other number on the page.
  (String, Color) get _bmiCategory {
    if (bodyMassIndex < 18.5) return ('Underweight', const Color(0xFFFFC412));
    if (bodyMassIndex < 25) return ('Normal', const Color(0xFF3EAF58));
    if (bodyMassIndex < 30) return ('Overweight', const Color(0xFFFFC412));
    return ('Obese', const Color(0xFFEA5455));
  }

  @override
  Widget build(BuildContext context) {
    final (String bmiLabel, Color bmiColor) = _bmiCategory;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: _stat(
                value: bodyMassIndex.toStringAsFixed(1),
                trailing: bmiLabel,
                trailingColor: bmiColor,
                caption: "BODY MASS INDEX",
              ),
            ),
            Container(width: 1, height: 38, color: const Color(0xFFE5E7EB)),
            Expanded(
              child: _stat(
                value: basalMetabolicRate.toStringAsFixed(0),
                trailing: "kcal/day",
                trailingColor: const Color(0xFFA1A1A1),
                caption: "BASAL METABOLIC RATE",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat({
    required String value,
    required String trailing,
    required Color trailingColor,
    required String caption,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              trailing,
              style: GoogleFonts.poppins(
                color: trailingColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: const Color(0xFF535359),
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
