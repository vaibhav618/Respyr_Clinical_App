import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../authentication/corporate/corporate_login/data/response/corporate_login_response.dart';
import '../../../../common/auth_logout.dart';
import '../../../../widgets/logout_bpx.dart';

class CorporateProfile extends StatelessWidget {
  final CorporateUserData corporateUserData;
  const CorporateProfile({super.key, required this.corporateUserData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:Color(0xFFF5F7FA),
        surfaceTintColor: Color(0xFFF5F7FA),
        title: Text("General",
          style: GoogleFonts.poppins(
            color: const Color(0xFF252525),
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.30,
          ),
        ),
      ),
      body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: Text("Profile Settings",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 34,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -2.04,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 28,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5,
                        children: [
                          Text("Name",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF252525),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 1.10,
                              letterSpacing: -0.30,
                            ),
                          ),
                          Text(corporateUserData.profileName,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF535359),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.24,
                            ),
                          )
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5,
                        children: [
                          Text("Age",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF252525),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 1.10,
                              letterSpacing: -0.30,
                            ),
                          ),
                          Text(corporateUserData.age,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF535359),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.24,
                            ),
                          )
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5,
                        children: [
                          Text("Gender",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF252525),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 1.10,
                              letterSpacing: -0.30,
                            ),
                          ),
                          Text(corporateUserData.gender,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF535359),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.24,
                            ),
                          )
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5,
                        children: [
                          Text("Height",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF252525),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 1.10,
                              letterSpacing: -0.30,
                            ),
                          ),
                          Text("${corporateUserData.height} cm",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF535359),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.24,
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 5,
                            children: [
                              Text("Weight",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF252525),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  height: 1.10,
                                  letterSpacing: -0.30,
                                ),
                              ),
                              Text("${corporateUserData.weight} Kg",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF535359),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.24,
                                ),
                              )
                            ],
                          ),
                          Visibility(
                            visible: false,
                            child: IconButton(
                              onPressed: (){},
                              icon: Icon(Icons.edit, size: 16,color: Colors.white,),
                              style:IconButton.styleFrom(
                                backgroundColor: const Color(0xFF252525),
                              ) ,
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 5,
                            children: [
                              Text("Region",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF252525),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  height: 1.10,
                                  letterSpacing: -0.30,
                                ),
                              ),
                              Text(corporateUserData.region,
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF535359),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.24,
                                ),
                              )
                            ],
                          ),
                          Visibility(
                            visible: false,
                            child: IconButton(
                              onPressed: (){},
                              icon: Icon(Icons.edit, size: 16,color: Colors.white,),
                              style:IconButton.styleFrom(
                                backgroundColor: const Color(0xFF252525),
                              ) ,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 28,
                    children: [
                      OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: const Color(0xFFEA5455),
                              ),
                              borderRadius: BorderRadius.circular(25.50),
                            ),
                          ),

                          onPressed: (){

                        LogoutBox().showDialogBox(
                            context: context,
                            clinicName: corporateUserData.profileName,
                            onLogoutClick: (){
                              AuthLogout.logout(context);
                            }
                        );


                      }, child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 10,
                        children: [
                          SvgPicture.asset("assets/svg_icons/logout_icon.svg"),
                          Text("Logout",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFEA5455),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.30,
                            ),
                          ),
                        ],
                      ))
                    ],
                  ),
                ),
              )
            ],
          )
      ),
    );
  }
}
