import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

Widget dashboardHeader({required DateTime formattedDate, required int totalTestCount}){


  String day = DateFormat('dd').format(formattedDate); // "07"
  String monthName = DateFormat('MMM').format(formattedDate); // "Jul"

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Container(
      decoration: ShapeDecoration(
        color: const Color(0xFFF5F7FA),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            decoration: ShapeDecoration(
              color: const Color(0xFFE4F0FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            constraints: BoxConstraints(maxWidth: 55),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text(day,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF308BF9),
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.60,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF308BF9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 7, horizontal: 7),
                  child: Center(child: Text(monthName,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFF5F7FA),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.10,
                      letterSpacing: 3,
                    ),
                  )),
                )
              ],
            ),
          ),
          Container(
              width: 1,
              height: 100,
              color: Color(0xFFD9D9D9)
          ),
          Column(
            children: [
              Text(totalTestCount.toString(),
                style: GoogleFonts.poppins(
                  color: const Color(0xFF252525),
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.60,
                ),
              ),
              Text("test taken",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF252525),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.10,
                  letterSpacing: -0.30,
                ),
              )
            ],
          )
        ],
      ),


    ),
  );

}