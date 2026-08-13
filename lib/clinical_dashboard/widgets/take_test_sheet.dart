import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Asks whether the test is for an existing subject or a new one.
///
/// Two option rows, label only. The icon carries the distinction, so a line of
/// description under each would just be reading the label back.
class BeforeTest {
  static void show({
    required BuildContext context,
    VoidCallback? onCreateNewProfileClicked,
    VoidCallback? onSelectExistingProfileClicked,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  "Who is taking the test?",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),

                // Existing first: it is the common case in a clinic.
                if (onSelectExistingProfileClicked != null)
                  _option(
                    context: context,
                    icon: Icons.person_search_rounded,
                    label: "Select existing",
                    isPrimary: true,
                    onTap: onSelectExistingProfileClicked,
                  ),
                if (onSelectExistingProfileClicked != null)
                  const SizedBox(height: 10),

                if (onCreateNewProfileClicked != null)
                  _option(
                    context: context,
                    icon: Icons.person_add_alt_1_rounded,
                    label: "Create new",
                    isPrimary: false,
                    onTap: onCreateNewProfileClicked,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _option({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    const Color blue = Color(0xFF308BF9);

    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          // The likely choice is tinted; the other stays plain, so the two are
          // distinguishable without one looking disabled.
          color: isPrimary ? blue.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary ? blue : const Color(0xFFE5E7EB),
            width: isPrimary ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: blue, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF252525),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFA1A1A1),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
