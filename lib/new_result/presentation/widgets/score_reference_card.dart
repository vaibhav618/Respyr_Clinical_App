import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class ScoreReferenceCard extends StatelessWidget {
  final bool isCorporate;
  const ScoreReferenceCard({super.key, required this.isCorporate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              strokeAlign: BorderSide.strokeAlignOutside,
              color: const Color(0xFFC7C6CE),
            ),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFEA5455),
                    shape: OvalBorder(),
                  ),
                ),
                SizedBox(width: 5),
                Text(
                  "Poor",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 5),
                Text(
                  "0 - 69%",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF535359),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFFFC412),
                    shape: OvalBorder(),
                  ),
                ),
                SizedBox(width: 5),
                Text(
                  "Fair",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 5),
                Text(
                  "70 - 79%",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF535359),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF3EAF58),
                    shape: OvalBorder(),
                  ),
                ),
                SizedBox(width: 5),
                Text(
                  "Good",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 5),
                Text(
                  "80 - 100%",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF535359),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
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
