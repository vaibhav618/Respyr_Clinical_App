import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/result_screen_clinical_app.dart';
import 'package:respyr_clinical/device_connectivity/presentation/pages/device_connectivity_screen.dart';

import 'package:respyr_clinical/shared/colors.dart';

import '../../../new_result/data/model/result_profile_data_model.dart';

class ClinicalProfileView extends StatefulWidget {
  final bool isClinicalTest;
  final ResultProfileDataModel profileDetails;

  const ClinicalProfileView({
    super.key,
    this.isClinicalTest = false,
    required this.profileDetails,
  });

  @override
  State<ClinicalProfileView> createState() => _ClinicalProfileViewState();
}

class _ClinicalProfileViewState extends State<ClinicalProfileView> {
  String subjectId = '';
  double height = 0.0;
  double weight = 0.0;
  String profileName = '';
  int age = 0;
  String gender = '';

  double? bmi;
  double? bmr;

  int? _cmValue;
  int _weightValue = 0;
  bool _isMale = true;

  @override
  void initState() {
    super.initState();
    profileDetails();
  }

  void profileDetails() {
    subjectId = widget.profileDetails.subjectId ?? '';
    height = widget.profileDetails.height ?? 0;
    weight = widget.profileDetails.weight ?? 0;
    profileName = widget.profileDetails.profileName ?? '';
    age = widget.profileDetails.age ?? 0;
    gender = widget.profileDetails.gender ?? '';

    _cmValue = height.toInt();
    _weightValue = weight.toInt();
    _isMale = gender.toLowerCase() == 'male';

    _updateBmi();
    _updateBmr();
  }

  void _updateBmi() {
    if (_weightValue > 0 && _cmValue != null && _cmValue! > 0) {
      double heightInMeters = _cmValue! / 100;
      double calculateBMI = _weightValue / (heightInMeters * heightInMeters);

      setState(() {
        bmi = double.parse(calculateBMI.toStringAsFixed(2));
      });
    } else {
      if (kDebugMode) {
        print("Invalid height or weight for BMI calculation");
      }
    }
  }

  void _updateBmr() {
    final int parseAge = age;
    final int weight = _weightValue;
    final int? height = _cmValue;

    if (parseAge > 0 &&
        weight > 0 &&
        height != null &&
        height > 0) {
      double calculateBMR;

      if (_isMale) {
        calculateBMR = (10 * weight) + (6.25 * height) - (5 * parseAge) + 5;
      } else {
        calculateBMR = (10 * weight) + (6.25 * height) - (5 * parseAge) - 161;
      }

      setState(() {
        bmr = double.tryParse(calculateBMR.toStringAsFixed(2));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> lifestyleMap = {
      'sugarScore': 45.0,
      'blowScore': 75.3,
      'gutScore': 83.45,
      'liverScore': 12.4,
      'profileName': profileName,
      'subjectId': subjectId,
      'gender': gender,
      'age': age,
      'bmi': bmi,
      'bmr': bmr,
    };
    String lifestyleJson = jsonEncode(lifestyleMap);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColor.primaryBlackColor,
          ),
        ),
        backgroundColor: AppColor.whiteColor,
        surfaceTintColor: AppColor.whiteColor,
      ),
      backgroundColor: AppColor.whiteColor,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset('assets/profile_list.svg', height: 60, width: 60),
            Text(
              profileName,
              style: GoogleFonts.poppins(
                fontSize: 25,
                fontWeight: FontWeight.w600,
                color: AppColor.primaryBlackColor,
              ),
            ),
            Text(
              "$age year old, $gender",
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColor.primaryBlackColor,
              ),
            ),
            SizedBox(height: 30),
            resultIdRow("Subject Id / Employee Id", subjectId),
            const SizedBox(height: 5),
            resultIdRow("Height (cm)", "$height cm"),
            const SizedBox(height: 5),
            resultIdRow("Weight (kg)", "$weight kg"),
            const SizedBox(height: 5),
            resultIdRow("BMI", bmi!.toString()),
            const SizedBox(height: 5),
            resultIdRow("BMR", bmr!.toString()),
            const SizedBox(height: 10),
            Text(
              "Test History",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColor.primaryBlackColor,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                Get.to(
                  () => ResultScreenClinicalApp(
                    lifeStyleJsonResponse: lifestyleJson,
                    profileDetails: widget.profileDetails,
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    '17/06/2025 03:38 pm',
                    style: GoogleFonts.poppins(
                      color: AppColor.primaryBlackColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        '65.26%',
                        style: GoogleFonts.poppins(
                          color: AppColor.primaryBlackColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'Poor',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFEA5455),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          widget.isClinicalTest
              ? GestureDetector(
                onTap: () {
                  Get.to(
                    () => UsbDeviceConnectivity(
                      isClinicalTest: true,
                      profileDetails: widget.profileDetails,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FloatingActionButton.extended(
                    onPressed: null, // Disable default onPressed
                    label: Row(
                      children: [
                        SvgPicture.asset('assets/blow_air.svg'),
                        const SizedBox(width: 8),
                        Text(
                          "Take Test",
                          style: GoogleFonts.poppins(
                            color: AppColor.whiteColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColor.primaryBlueColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              )
              : null,
    );
  }

  Widget resultIdRow(String rowId, String rowVal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          rowId,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColor.primaryBlackColor,
          ),
        ),
        Text(
          rowVal,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColor.primaryBlackColor,
          ),
        ),
      ],
    );
  }
}
