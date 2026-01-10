import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/sign_in_state.dart';

Widget signInOptionButton({
  required SignInState state,
  required String title,            // "Clinical" / "Corporate"
  required VoidCallback onClick,    // pass event dispatcher from screen
}) {
  final isLoading = state.status == SignInStatus.loading;

  // match selectedType based on title (so your UI stays simple)
  final typeKey = title.toLowerCase(); // clinical / corporate
  final isThisButtonLoading = isLoading && state.selectedType == typeKey;

  return OutlinedButton(
    onPressed: isLoading ? null : onClick,
    style: OutlinedButton.styleFrom(
      side: const BorderSide(width: 1, color: Color(0xFFC7C6CE)),
    ),
    child: Text(
      isThisButtonLoading ? "Please wait..." : title,
      style: GoogleFonts.poppins(
        color: const Color(0xFF252525),
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.10,
        letterSpacing: 0.30,
      ),
    ),
  );
}
