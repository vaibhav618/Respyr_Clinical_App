import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../clinical_dashboard/widgets/clinical_logo_widget.dart';
import '../../../../router/app_routers.dart';
import '../../bloc/corporate_profile_state.dart';

/// Corporate dashboard header: greeting on the left, the profile badge on the
/// right — the same elevated badge the clinical app bar uses, in place of a
/// flat grey circle around a generic glyph.
class AppBar extends StatelessWidget {
  final CorporateProfileState state;
  const AppBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final user = state.user!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome!",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.profileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF535359),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            button: true,
            label: 'Profile',
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.corporateProfile,
                  arguments: user,
                );
              },
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: ClinicLogoWidget(
                  clinicName: user.profileName,
                  size: 38,
                  elevated: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
