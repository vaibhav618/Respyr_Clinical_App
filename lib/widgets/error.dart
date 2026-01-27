import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/authentication/screens/login_with_password.dart';

import '../authentication/screens/login_screen.dart';

class ErrorsWidgets{

  static Widget jwtTokenError({required String errorMessage, required BuildContext context}){
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/sagar/undraw_server-error_syuz.svg', height: 120,),
          const SizedBox(height: 10),
          Container(
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              shadows: [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 10,
                  offset: Offset(0, 0),
                  spreadRadius: 5,
                )
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Text(
                  "Error: $errorMessage",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFA1A1A1),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.24,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20,),
                ElevatedButton(
                  onPressed: (){
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginWithPassword()), (route) => false);



                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFF0F0F0),
                  ) ,
                  child: Text("Retry",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF308BF9),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.48,

                    ),
                  ),
                )
              ],
            ),
          ),

        ],
      ),
    );
  }

  static Widget otherError({required String errorMessage,required BuildContext context}){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/sagar/undraw_server-down_lxs9.svg', height: 120,),
          const SizedBox(height: 10),
          Container(
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              shadows: [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 10,
                  offset: Offset(0, 0),
                  spreadRadius: 5,
                )
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Text(
                  "Error: $errorMessage",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFA1A1A1),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.24,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20,),
                ElevatedButton(
                  onPressed: (){
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginWithPassword()), (route) => false);

                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFF0F0F0),
                  ) ,
                  child: Text("Retry",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF308BF9),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.48,

                    ),
                  ),
                )
              ],
            ),
          ),

        ],
      ),
    );
  }

  static Widget resultModelApiError({required String errorMessage}){
    return   Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Container(
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              shadows: [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 10,
                  offset: Offset(0, 0),
                  spreadRadius: 5,
                )
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                SvgPicture.asset("assets/sagar/undraw_warning_tl76.svg", height: 150,),
                SizedBox(height: 20,),
                Text(
                  "Server error",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.24,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20,),
                Text(
                  "Error: $errorMessage",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFA1A1A1),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.24,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20,),
                ElevatedButton(
                  onPressed: (){},
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFF0F0F0),
                  ) ,
                  child: Text("Start again",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF308BF9),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.48,

                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}