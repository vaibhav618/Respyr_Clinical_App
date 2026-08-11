import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final VoidCallback onDashboardTap;
  final VoidCallback onTakeTestTap;
  final VoidCallback onProfileTap;
  final int activeIndex;
   String label3;

  /// Seconds left of the cool-down after a completed reading, or 0 when ready.
  ///
  /// While counting down the button is visibly locked and shows the time
  /// remaining. It still calls [onTakeTestTap] so the tap can be answered with
  /// the reason, rather than appearing to do nothing.
  final int lockedForSeconds;

   BottomNavigationBarWidget({
    super.key,
    required this.onDashboardTap,
    required this.onTakeTestTap,
    required this.onProfileTap,
    required this.activeIndex,
    this.lockedForSeconds = 0,
    this.label3 ="Test History"
  });

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    return SafeArea(
      top: false,
      child: Container(
        height: 80,
        padding: EdgeInsets.only(top: 5, bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0x0C000000),
              blurRadius: 10,
              offset: Offset.zero,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
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
    return Expanded(
      child: InkWell(
        onTap: onClick,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(iconPath),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color:
                    isActive
                        ? const Color(0xFF308BF9)
                        : const Color(0xFFA1A1A1),
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
      child: InkWell(
        onTap: onClick,
        child: Container(
          decoration: BoxDecoration(
            color: locked ? const Color(0xFFA1A1A1) : const Color(0xFF308BF9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              locked
                  ? const Icon(Icons.lock_clock, color: Colors.white, size: 22)
                  : SvgPicture.asset(
                      "assets/sagar/icon-park-outline_wind.svg",
                    ),
              const SizedBox(height: 4),
              Text(
                locked ? "Wait ${lockedForSeconds}s" : "Take Test",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
