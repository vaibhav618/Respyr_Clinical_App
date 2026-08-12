import 'dart:async'; // ✅ added
import 'package:flutter/material.dart';
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

  /// The device needs its cool-down before another test, whether the last one
  /// finished or was abandoned part-way — starting early leaves the user in a
  /// calibration screen that cannot progress.
  ///
  /// An aborted test gets the cooling-down sheet; a completed one just gets a
  /// message, matching how the Take Test button behaves on the dashboard.
  Future<void> _startTestWhenReady(
    BuildContext context,
    VoidCallback proceed,
  ) async {
    if (await AbortDeviceManager.getAbortStatus()) {
      if (context.mounted) {
        CheckAbortSheet.show(context: context, onTakeTextClick: proceed);
      }
      return;
    }

    final remaining = await AbortDeviceManager.completedRemainingSeconds();
    if (remaining > 0) {
      if (context.mounted) await showCooldownToast(context, remaining);
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            _initialAvatar(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.profileName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF252525),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "${profile.age} yrs  •  ${profile.gender}",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF535359),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _subjectIdPill(),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFA1A1A1),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  /// Initial in a tinted circle — same treatment as the subject profile header,
  /// so a subject looks the same wherever they appear.
  Widget _initialAvatar() {
    final String name = profile.profileName.trim();
    return Container(
      height: 46,
      width: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF308BF9).withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "?",
        style: GoogleFonts.poppins(
          color: const Color(0xFF308BF9),
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// The subject id is a reference, not a headline — give it the quiet
  /// treatment so the name leads.
  Widget _subjectIdPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        profile.subjectId,
        style: GoogleFonts.poppins(
          color: const Color(0xFF535359),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
