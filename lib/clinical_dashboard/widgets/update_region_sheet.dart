import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_dashboard/widgets/region_selector.dart';

import '../existing_profile/services/user_update_region_service.dart';
import '../utils/user_region_manager.dart';

class UpdateRegionSheet {
  String? selectedKey;


  Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required String loginId,
    required String profileId,
    required Function(Map<String, dynamic> response) onResponseMessage,
  }) async {
    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SvgPicture.asset("assets/sagar/region.svg"),
                  Text(
                    "Update your region",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF252525),
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "To provide you with more accurate health insights, Respyr now requires your birth region. Please update your region to continue.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mulish(
                      color: const Color(0xFF535359),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 50),
                  Container(
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(width: 2, color: Color(0xFFF0F0F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: () async {
                        final result = await RegionSelector.showRegionPicker(context, selectedKey);
                        if (result != null) {
                          setState(() {
                            selectedKey = result;
                          });
                        }
                      },
                      child: Text(
                        selectedKey == null
                            ? "Select Region"
                            : getRegionLabelFromValue(selectedKey) ?? "Select Region",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF252525),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.19,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: selectedKey == null
                          ? null
                          : () async {
                        final response = await UserUpdateRegionService().updateRegion(
                          loginId: loginId,
                          profileId: profileId,
                          region: selectedKey!,
                        );

                        onResponseMessage(response); // ✅ callback
                        Navigator.pop(context, response); // ✅ return from show()
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        disabledBackgroundColor: const Color(0xFFD9D9D9),
                        backgroundColor: const Color(0xFF308BF9),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        "Update your region",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String? getRegionLabelFromValue(String? value) {
    final match = UserRegionManager().regionMap.entries.firstWhere(
          (entry) => entry.value == value,
      orElse: () => const MapEntry('', ''),
    );
    return match.key.isNotEmpty ? match.key : null;
  }
}
