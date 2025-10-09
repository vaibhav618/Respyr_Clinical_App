import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/user_region_manager.dart';

class RegionSelector {
  static Future<String?> showRegionPicker(
    BuildContext context,
    String? selectedKey,
  ) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 30,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select your region",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF252525),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children:
                            UserRegionManager().regionMap.entries.map((entry) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: RadioListTile<String>(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    entry.key,
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF535359),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  activeColor: Color(0xFF308BF9),
                                  value: entry.value,
                                  groupValue: selectedKey,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedKey = value;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            selectedKey == null
                                ? null
                                : () => Navigator.pop(context, selectedKey),
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: const Color(0xFFD9D9D9),
                          backgroundColor: const Color(0xFF308BF9),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              30,
                            ), // 👈 change radius here
                          ),
                        ),
                        child: Text(
                          "Continue",
                          style: GoogleFonts.mulish(
                            color:
                                selectedKey == null
                                    ? const Color(0xFF535359)
                                    : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
