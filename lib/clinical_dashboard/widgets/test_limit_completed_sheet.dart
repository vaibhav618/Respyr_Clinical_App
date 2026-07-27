import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TestLimitReached {
  static void showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // if you want it full screen
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(height: 30),
              Text(
                "You’ve reached your test limit",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF252525),
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.justify,
                softWrap: true,
              ),

              SizedBox(height: 30),
              Text(
                "For further assistance, contact our support team at help@respyr.com or call 99025 52385.",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF535359),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF308BF9),
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    "Contact support",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.10,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
