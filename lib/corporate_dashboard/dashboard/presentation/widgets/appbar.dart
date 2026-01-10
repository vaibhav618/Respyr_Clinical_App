import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../router/app_routers.dart';
import '../../bloc/corporate_profile_state.dart';

class AppBar extends StatelessWidget {
  final CorporateProfileState state;
  const AppBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return                 Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Welcome!",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
              Text(state.user!.profileName,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                ),
              )
            ],
          ),
          IconButton(
            onPressed: (){
              Navigator.pushNamed(context, AppRoutes.corporateProfile,  arguments: state.user, );
            },
            icon: SvgPicture.asset("assets/ic_profile.svg", width: 24,),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFDCDCDC),

            ),
          )
        ],
      ),
    );
  }
}
