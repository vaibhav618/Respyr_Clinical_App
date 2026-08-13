import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_theme.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final VoidCallback onDashboardTap;
  final VoidCallback onTakeTestTap;
  final VoidCallback onProfileTap;
  final int activeIndex;
  final String label3;

  /// Seconds left of the cool-down after a completed reading, or 0 when ready.
  ///
  /// While counting down the button is visibly locked and shows the time
  /// remaining. It still calls [onTakeTestTap] so the tap can be answered with
  /// the reason, rather than appearing to do nothing.
  final int lockedForSeconds;

  const BottomNavigationBarWidget({
    super.key,
    required this.onDashboardTap,
    required this.onTakeTestTap,
    required this.onProfileTap,
    required this.activeIndex,
    this.lockedForSeconds = 0,
    this.label3 = "Test History",
  });

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    return SafeArea(
      top: false,
      child: Container(
        height: 76,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: const BoxDecoration(
          color: DashTheme.white,
          // A hairline, matching the app bar. The old diffuse shadow sat on a
          // white page and mostly read as a smudge.
          border: Border(top: BorderSide(color: DashTheme.line)),
        ),
        child: Row(
          children: [
            _buildNavItem(
              label: 'Dashboard',
              iconPath: 'assets/sagar/icon-park-outline_more-app.svg',
              isActive: activeIndex == 0,
              onClick: onDashboardTap,
            ),
            _buildTakeTestButton(onTakeTestTap),
            _buildNavItem(
              label: label3,
              iconPath: 'assets/sagar/icon-park-outline_peoples-two.svg',
              isActive: activeIndex == 2,
              onClick: onProfileTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String label,
    required String iconPath,
    required bool isActive,
    required VoidCallback onClick,
  }) {
    final Color tint = isActive ? DashTheme.blue : DashTheme.faint;

    return Expanded(
      child: InkWell(
        onTap: onClick,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              height: 22,
              // The icons carried their own colour, so an "active" tab
              // changed only its label while the icon above it stayed grey.
              colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: tint,
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTakeTestButton(VoidCallback onClick) {
    final bool locked = lockedForSeconds > 0;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Material(
          color: locked ? DashTheme.faint : DashTheme.blue,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onClick,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  locked
                      ? const Icon(
                          Icons.lock_clock,
                          color: DashTheme.white,
                          size: 21,
                        )
                      : SvgPicture.asset(
                          "assets/sagar/icon-park-outline_wind.svg",
                          height: 21,
                          colorFilter: const ColorFilter.mode(
                            DashTheme.white,
                            BlendMode.srcIn,
                          ),
                        ),
                  const SizedBox(height: 5),
                  Text(
                    locked ? "Wait ${lockedForSeconds}s" : "Take Test",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: DashTheme.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
