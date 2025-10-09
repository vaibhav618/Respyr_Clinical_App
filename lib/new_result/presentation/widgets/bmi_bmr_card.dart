import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class BmiBmrCard extends StatelessWidget {
  final double bodyMassIndex;
  final double basalMetabolicRate;

  const BmiBmrCard({
    super.key,
    required this.bodyMassIndex,
    required this.basalMetabolicRate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        decoration: ShapeDecoration(
          color: const Color(0xFFF5F7FA),
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: const Color(0xFFC7C6CE)),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 19),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  "Current BMI",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF535359),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.10,
                    letterSpacing: -0.24,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  bodyMassIndex.toStringAsFixed(2),
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF535359),
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    height: 1.10,
                  ),
                ),
              ],
            ),
            Container(width: 2, height: 33, color: Color(0xFFC7C6CE)),
            Column(
              children: [
                Text(
                  "Current BMR",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF535359),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.10,
                    letterSpacing: -0.24,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  basalMetabolicRate.toStringAsFixed(2),
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF535359),
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    height: 1.10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
