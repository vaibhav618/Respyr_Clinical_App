import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

AppBar commonAppbar({required String title}){
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    title: Text(title,
      style: GoogleFonts.poppins(
        color: const Color(0xFF252525),
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.30,
      ),
    ),
  );
}