import 'dart:async'; // ✅ added
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/device_connectivity/presentation/pages/device_connectivity_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../clinical_app_respyr/screens/bluetooth_test/screens/bluetooth_clinical_device_connectivity.dart';
import '../../../common/floating_message.dart';
import '../../../new_result/data/model/result_profile_data_model.dart';
import '../../helper/abort_device_manager.dart';
import '../../views/subject_profile.dart';
import '../../widgets/check_abort_sheet.dart';
import '../../widgets/connection_option_sheet.dart';
import '../../widgets/update_region_sheet.dart';
import '../models/profile_model.dart';

// ✅ added (update path if your FloatingMessage file is elsewhere)

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

  // ✅ added (single timer for this widget type)
  static Timer? _cooldownToastTimer;

  // ✅ added
  Future<int> getRemainingCooldownSeconds({int cooldownSeconds = 60}) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt('last_reading_time');
    if (last == null) return 0;

    final diff =
        DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(last))
            .inSeconds;

    final remaining = cooldownSeconds - diff;
    return remaining > 0 ? remaining : 0;
  }

  // ✅ added
  Future<void> showCooldownToast(BuildContext context, int seconds) async {
    _cooldownToastTimer?.cancel();

    int remaining = seconds;

    FloatingMessage.show(
      context,
      message: 'Please wait $remaining seconds before next test',
      type: FloatingMessageType.warning,
      duration: Duration(seconds: remaining + 1),
      fromTop: false,
    );

    _cooldownToastTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      remaining--;

      // StatelessWidget has no mounted, so just close when time ends
      if (remaining <= 0) {
        t.cancel();
        FloatingMessage.hide();
        return;
      }

      FloatingMessage.update(
        'Please wait $remaining seconds before next test',
        duration: Duration(seconds: remaining + 1),
      );
    });
  }

  /// Both cooldowns have to clear before a test can start: the one after a
  /// completed reading and the one after an aborted one. The device keeps
  /// working through its own cycle either way, and starting before it is done
  /// leaves the user sitting in a calibration screen that cannot progress.
  Future<void> _startTestWhenReady(
    BuildContext context,
    VoidCallback proceed,
  ) async {
    final remaining = await getRemainingCooldownSeconds();
    if (remaining > 0) {
      if (context.mounted) await showCooldownToast(context, remaining);
      return;
    }

    if (await AbortDeviceManager.getAbortStatus()) {
      if (context.mounted) {
        CheckAbortSheet.show(context: context, onTakeTextClick: proceed);
      }
      return;
    }

    if (context.mounted) proceed();
  }

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

            await _startTestWhenReady(context, () {
              Navigator.pop(context);
              Get.to(
                () => BluetoothClinicalDeviceConnectivity(
                  // isClinicalTest: true,
                  profileDetails: profileModel,
                ),
              );
            });
          },
          onUsbTap: () async {
            Navigator.pop(context);

            await _startTestWhenReady(context, () {
              Get.to(
                () => UsbDeviceConnectivity(
                  isClinicalTest: true,
                  profileDetails: profileModel,
                ),
              );
            });
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
                backgroundColor: Colors.black.withValues(alpha: 0.8),
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
