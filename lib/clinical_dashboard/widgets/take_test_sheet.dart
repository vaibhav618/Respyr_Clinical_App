import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BeforeTest {
  static void show({
    required BuildContext context,
    VoidCallback? onCreateNewProfileClicked,
    VoidCallback? onSelectExistingProfileClicked,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // 💡 This makes height wrap content
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.close, size: 24, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Choose Profile Option",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "Do you want to take the test from an existing profile, or create a new profile?",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF535359),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 50),

                if (onCreateNewProfileClicked != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCreateNewProfileClicked();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2500),
                          side: BorderSide(width: 1, color: Color(0xFF308BF9)),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        "Create new",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF308BF9),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.10,
                          letterSpacing: -0.90,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                if (onSelectExistingProfileClicked != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onSelectExistingProfileClicked();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF308BF9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            2500,
                          ), // 🎯 Rounded corner
                        ),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        "Select existing",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.10,
                          letterSpacing: -0.90,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
