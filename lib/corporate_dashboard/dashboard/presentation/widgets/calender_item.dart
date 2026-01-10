import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CalenderItem extends StatelessWidget {
  final DateTime dateTime;
  final bool isSelected;
  final VoidCallback? onTap;

  const CalenderItem({
    super.key,
    required this.dateTime,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:isSelected ?  Color(0xFF308BF9) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 5,
          children: [
            Text(
              dateTime.day.toString(),
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.0,
                letterSpacing: -0.30,
              ),
            ),
            Text(
              DateFormat('EEE').format(dateTime), // Mon
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.0,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
