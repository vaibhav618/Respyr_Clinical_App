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
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
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

  /// Side tab. The icon sits in a capsule that fills in when the tab is
  /// active — colour alone was carrying the whole active state before, which
  /// is a thin signal on a bar where two of the three items are grey.
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
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: 30,
              width: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive
                    ? DashTheme.blue.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: SvgPicture.asset(
                iconPath,
                height: 20,
                // The icons carried their own colour, so an "active" tab
                // changed only its label while the icon above it stayed grey.
                colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: tint,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The primary action, and the only lit thing on the bar.
  ///
  /// It used to be a square-cornered block filling the bar's full height,
  /// which read as a slab rather than a control. Inset slightly and lifted on
  /// its own blue shadow, it sits in the bar instead of plugging a hole in it.
  Widget _buildTakeTestButton(VoidCallback onClick) {
    final bool locked = lockedForSeconds > 0;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // No lift while locked — something you cannot use should not be
            // the most raised element on screen.
            boxShadow: locked
                ? const []
                : [
                    BoxShadow(
                      color: DashTheme.blue.withValues(alpha: 0.32),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: locked ? const Color(0xFFB6BCC6) : DashTheme.blue,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onClick,
              borderRadius: BorderRadius.circular(16),
              child: SizedBox.expand(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    locked
                        ? const Icon(
                            Icons.lock_clock,
                            color: DashTheme.white,
                            size: 20,
                          )
                        : SvgPicture.asset(
                            "assets/sagar/icon-park-outline_wind.svg",
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              DashTheme.white,
                              BlendMode.srcIn,
                            ),
                          ),
                    const SizedBox(height: 4),
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
      ),
    );
  }
}
