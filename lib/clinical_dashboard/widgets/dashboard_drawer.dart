import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/clinical_dashboard/widgets/test_details_widget.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../help_support/screens/help_center.dart';
import '../clinic_details/model/clinical_details_model.dart';
import 'package:respyr_clinical/shared/urls.dart';
import 'clinical_logo_widget.dart';

class DashboardDrawer {
  Future<List<ClinicalDetailsModel>> fetchClinicData({
    required String clinicName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception("No token found");
    }

    final response = await http.post(
      Uri.parse(Urls.fetchClinicDetails),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'clinic_name': clinicName},
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200 && decoded['status'] == 'success') {
      return List<ClinicalDetailsModel>.from(
        (decoded['data'] as List).map((e) => ClinicalDetailsModel.fromJson(e)),
      );
    } else {
      throw Exception('Failed to load data');
    }
  }

  Drawer dashboardEndDrawer({
    required BuildContext context,
    required String clinicName,
    required VoidCallback? onLogoutClick,
    required VoidCallback? onSubjectsClicked,
    required Map<String, dynamic>? clinicalTestCountData,
    required int totalSubjectsOnboarded,
  }) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: FutureBuilder<List<ClinicalDetailsModel>>(
        future: fetchClinicData(clinicName: clinicName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColor.primaryBlueColor,
              ),
            );
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text("Failed to load clinic data"));
          }

          final clinic = snapshot.data!.first;
          final double height = MediaQuery.of(context).size.height;

          return SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: height * 0.020),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.015),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClinicLogoWidget(
                              clinicName: clinic.clinicName,
                              size: 120,
                            ),
                            SizedBox(height: height * 0.025),
                            _infoRow(
                              "assets/admin_icon.svg",
                              clinic.clinicName,
                            ),
                            SizedBox(height: height * 0.010),
                            _infoRow(
                              "assets/hugeicons_location-05.svg",
                              clinic.location,
                            ),
                            SizedBox(height: height * 0.010),
                            _infoRow(
                              "assets/hugeicons_call.svg",
                              clinic.phoneNo,
                            ),
                            SizedBox(height: height * 0.010),
                            _infoRow("assets/email_icon.svg", clinic.username),
                          ],
                        ),
                      ),
                      SizedBox(height: height * 0.015),
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(''),
                      ),
                      TestDetailsWidget(
                        clinicalTestCountData: clinicalTestCountData,
                        totalSubjectsOnboarded: totalSubjectsOnboarded,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HelpCenter(loginId: clinicName),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              "assets/svg_icons/info_icon.svg",
                              color: Color(0xFF252525),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              "Help",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF252525),
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.30,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (onLogoutClick != null) {
                            Navigator.of(context).pop();
                            onLogoutClick();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset("assets/hugeicons_logout-03.svg"),
                            const SizedBox(width: 20),
                            Text(
                              "Logout",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFEA5455),
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.30,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "App version : 1.1.0",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF535359),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String assetPath, String text) {
    return Row(
      children: [
        SvgPicture.asset(assetPath, width: 20, color: const Color(0xFFA1A1A1)),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.poppins(
            color: const Color(0xFFA1A1A1),
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.30,
          ),
        ),
      ],
    );
  }
}
