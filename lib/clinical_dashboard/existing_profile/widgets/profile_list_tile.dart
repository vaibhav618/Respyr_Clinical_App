import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/device_connectivity/presentation/pages/device_connectivity_screen.dart';
import 'package:respyr_clinical/shared/colors.dart';

import '../../../clinical_app_respyr/screens/bluetooth_test/screens/bluetooth_clinical_device_connectivity.dart';
import '../../../new_result/data/model/result_profile_data_model.dart';
import '../../views/subject_profile.dart';
import '../../widgets/connection_option_sheet.dart';
import '../../widgets/update_region_sheet.dart';
import '../models/profile_model.dart';

class ProfileListTile extends StatelessWidget {
  final ProfileModel profile;
  final bool isCreateAccountButtonShow;

  final VoidCallback? onRegionUpdated;

  const ProfileListTile({
    required this.profile,
    this.onRegionUpdated,
    required this.isCreateAccountButtonShow,
    super.key,
  });

  void _showConnectionOption(
    ResultProfileDataModel profileModel,
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ConnectionOptionSheet(
          onBluetoothTap: () async {
            Navigator.pop(context); // ✅ Close the bottom sheet

            // ✅ Delay to make sure bottom sheet is closed
            await Future.delayed(const Duration(milliseconds: 200));

            // ✅ Show snackbar on the main screen (not from bottom sheet)
            Get.snackbar(
              "",
              "",
              snackPosition: SnackPosition.BOTTOM,
              snackStyle: SnackStyle.FLOATING,
              backgroundColor: Colors.white,
              colorText: Colors.black,
              margin: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
              padding: const EdgeInsets.only(bottom: 8, left: 10, right: 10),
              borderRadius: 10,
              boxShadows: [
                BoxShadow(
                  color: Colors.black.withAlpha(74),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: Offset(0, 4),
                ),
              ],
              titleText: const SizedBox.shrink(),
              messageText: Align(
                alignment: Alignment.center,
                child: Text(
                  "Coming soon...",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primaryBlackColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
          onUsbTap: () {
            Navigator.pop(context);
            Get.to(
              () => UsbDeviceConnectivity(
                isClinicalTest: true,
                profileDetails: profileModel,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        ResultProfileDataModel profileDetails = ResultProfileDataModel(
          subjectId: profile.subjectId,
          clinicName: profile.clinicName,
          profileName: profile.profileName,
          gender: profile.gender,
          age: profile.age,
          height: profile.height,
          weight: profile.weight,
          region: profile.region,
          dttm: profile.dttm,
        );

        if (isCreateAccountButtonShow) {
          if (profile.region == "not_available") {
            final result = await UpdateRegionSheet().show(
              context: context,
              loginId: profile.clinicName,
              profileId: profile.subjectId,
              onResponseMessage: (_) {}, // Not used here
            );

            final body = result?['body'];

            if (body != null &&
                body['success'] == true &&
                body['data'] != null &&
                body['data']['updated_region'] != null &&
                body['data']['updated_region'].toString().isNotEmpty) {
              final updatedRegion = body['data']['updated_region'];

              profileDetails = ResultProfileDataModel(
                subjectId: profile.subjectId,
                clinicName: profile.clinicName,
                profileName: profile.profileName,
                gender: profile.gender,
                age: profile.age,
                height: profile.height,
                weight: profile.weight,
                region: updatedRegion,
                dttm: profile.dttm,
              );

              Get.snackbar(
                profile.profileName,
                body['message'] ?? 'Region updated successfully',
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
                backgroundColor: Colors.black.withOpacity(0.8),
                colorText: Colors.white,
                duration: const Duration(seconds: 1),
                animationDuration: const Duration(seconds: 1),
              );

              if (onRegionUpdated != null) onRegionUpdated!();
              _showConnectionOption(profileDetails, context);
            } else {
              Get.snackbar(
                profile.profileName,
                body?['message'] ?? 'Failed to update region',
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
                backgroundColor: Colors.red.withAlpha(200),
                colorText: Colors.white,
                duration: const Duration(seconds: 1),
                animationDuration: const Duration(seconds: 1),
              );
            }
          } else {
            _showConnectionOption(profileDetails, context);
          }
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => SubjectProfileScreen(
                    clinicName: profile.clinicName,
                    profileName: profile.subjectId,
                  ),
            ),
          );
        }
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset("assets/sagar/profile41.svg", width: 32),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.subjectId,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF252525),
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            height: 1.10,
                            letterSpacing: -0.36,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          profile.profileName,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF252525),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            height: 1.10,
                            letterSpacing: -0.36,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "${profile.age} yrs, ${profile.gender}",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF252525),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.20,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const SizedBox(
                      height: 24,
                      child: Icon(Icons.chevron_right_sharp),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(
            height: 0.5,
            color: Color(0xFFF5F7FA),
            indent: 20,
            endIndent: 20,
          ),
        ],
      ),
    );
  }
}
