import 'dart:convert';

import 'package:respyr_clinical/widgets/shimmer_placeholders.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../clinical_dashboard/clinic_details/model/clinical_details_model.dart';
import 'package:respyr_clinical/shared/urls.dart';
import '../clinical_dashboard/widgets/clinical_logo_widget.dart';
import '../clinical_dashboard/widgets/test_details_widget.dart';
import '../common/auth_logout.dart';
import '../help_support/screens/help_center.dart';
import '../widgets/logout_bpx.dart';

class MenuScreen extends StatefulWidget {
  final String loginId;
  final Map<String, dynamic>? clinicalTestCountData;
  final int totalSubjectsOnboarded;
  const MenuScreen({
    super.key,
    required this.loginId,
    required this.clinicalTestCountData,
    required this.totalSubjectsOnboarded,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _hasInternet = true;
  bool _hasFetchedInitialData = false;
  Future<List<ClinicalDetailsModel>>? _clinicDataFuture;

  @override
  void initState() {
    super.initState();
    _startFetchIfNeeded();
  }

  void _startFetchIfNeeded() {
    if (!_hasFetchedInitialData && _hasInternet) {
      setState(() {
        _clinicDataFuture = fetchClinicData(clinicName: widget.loginId);
        _hasFetchedInitialData = true;
      });
    }
  }

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

  Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: InternetConnectivityHandler(
        isBody: true,
        onConnectivityChanged: (hasInternet) {
          _hasInternet = hasInternet;

          if (hasInternet) {
            _hasFetchedInitialData = false; // allow one more fetch
            _startFetchIfNeeded();
          }
        },

        child: FutureBuilder<List<ClinicalDetailsModel>>(
          future: _clinicDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ListShimmer(rows: 6, rowHeight: 56);
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const Center(child: Text("Failed to load clinic data"));
            }

            final clinic = snapshot.data!.first;
            final double height = MediaQuery.of(context).size.height;

            return SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClinicLogoWidget(
                                    clinicName: clinic.clinicName,
                                    size: 60,
                                  ),
                                  SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        clinic.clinicName,
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF252525),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.30,
                                        ),
                                      ),
                                      Text(
                                        clinic.phoneNo,
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF252525),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: -0.24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
                          clinicalTestCountData: widget.clinicalTestCountData,
                          totalSubjectsOnboarded: widget.totalSubjectsOnboarded,
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
                        Visibility(
                          visible: false,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => HelpCenter(
                                        loginId: clinic.clinicName,

                                        // loginId: widget.loginId,
                                      ),
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
                                  "assets/admin_icon.svg",
                                  color: Color(0xFF252525),
                                ),
                                const SizedBox(width: 20),
                                Text(
                                  "Account Setting",
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
                        ),
                        Visibility(
                          visible: false,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          HelpCenter(loginId: widget.loginId),
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
                                  "Help Center",
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
                        ),
                        Visibility(
                          visible: false,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          HelpCenter(loginId: widget.loginId),
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
                                  "assets/report_issue.svg",
                                  color: Color(0xFF252525),
                                ),
                                const SizedBox(width: 20),
                                Text(
                                  "Report an Issue",
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
                        ),

                        Divider(),
                        ElevatedButton(
                          onPressed: () async {
                            // logout

                            LogoutBox().showDialogBox(
                              context: context,
                              clinicName: widget.loginId,
                              onLogoutClick: () {
                                AuthLogout.logout(context);
                              },
                              // onLogoutClick: () async {
                              //   bool success = await clearAllAppData();
                              //   if (success && mounted) {
                              //     Navigator.pushReplacement(
                              //       context,
                              //       MaterialPageRoute(
                              //         builder: (context) => LoginScreen(),
                              //       ),
                              //     );
                              //   } else {
                              //     if (mounted) {
                              //       ScaffoldMessenger.of(context).showSnackBar(
                              //         const SnackBar(
                              //           content: Text('Failed to clear data'),
                              //         ),
                              //       );
                              //     }
                              //   }
                              // },
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
                                "assets/hugeicons_logout-03.svg",
                              ),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FutureBuilder<String>(
                              future: getAppVersion(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text(
                                    "App version: ...",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF535359),
                                    ),
                                  );
                                } else if (snapshot.hasError) {
                                  return Text(
                                    "App version: Error",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF535359),
                                    ),
                                  );
                                } else {
                                  return Text(
                                    "App version: ${snapshot.data}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF535359),
                                    ),
                                  );
                                }
                              },
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
      ),
    );
  }
}
