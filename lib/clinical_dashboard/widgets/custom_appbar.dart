import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:respyr_clinical/shared/colors.dart';

import 'clinical_logo_widget.dart';

class DashboardAppBar {
  static AppBar build({
    required String loginName,
    required VoidCallback onProfileTap,
  }) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      surfaceTintColor: Colors.white,
      elevation: 2,
      title: Text(
        loginName,
        style: GoogleFonts.poppins(
          color: const Color(0xFF252525),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.72,
        ),
      ),
      actions: [
        IconButton(
          icon: ClinicLogoWidget(clinicName: loginName),
          onPressed: onProfileTap,
        ),
      ],
    );
  }
}

/// Dashboard app bar: date/calendar toggle on the left, clinic identity right.
///
/// The date leads because it is the control that gets used — it changes which
/// day the whole page is reporting on, and the left edge is the easier reach.
/// The profile is a destination you visit occasionally, so it sits out at the
/// far edge with the clinic name beside it.
///
/// The date used to be a bare label and a chevron inside an IconButton, with
/// its font size derived from the available width — so it changed size between
/// devices and nothing suggested it could be tapped. It is a pill now, which
/// reads as a control and shows its open state. Nothing sits between the two
/// ends: the clinic name was tried there and only competed with the badge,
/// which already says whose clinic this is.
class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final DateTime selectedDate;
  final Function onDateTap;
  final bool calendarVisible;
  final String loginName;
  final VoidCallback onProfileTap;

  const CustomAppBar({
    super.key,
    required this.selectedDate,
    required this.onDateTap,
    required this.calendarVisible,
    required this.loginName,
    required this.onProfileTap,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  // +1 for the hairline in `bottom` — Scaffold lays the bar out from this, so
  // leaving it at kToolbarHeight squeezes the toolbar by the divider's height.
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}

class _CustomAppBarState extends State<CustomAppBar> {
  static const Color _blue = Color(0xFF308BF9);

  /// Width the fixed sizes below were tuned against — a 360dp phone, which is
  /// the narrow end of the range this app runs on.
  static const double _baseWidth = 360;

  /// How much to grow the bar's controls on a roomier screen.
  ///
  /// A flat size looks right on a small handset and undersized on a large one;
  /// the original code scaled the date straight off the available width
  /// (`maxWidth * 0.08`), which grew without limit and made the same label a
  /// different size on every device. This keeps the proportional idea but
  /// bounds it: never smaller than the tuned size, never more than a fifth
  /// larger, so the bar reads the same everywhere it lands.
  double get _scale {
    final double shortest = MediaQuery.sizeOf(context).shortestSide;
    return (shortest / _baseWidth).clamp(1.0, 1.2);
  }

  @override
  Widget build(BuildContext context) {
    final bool open = widget.calendarVisible;

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 12, right: 10),
        child: Row(
          children: [
            _datePill(open),
            const Spacer(),
            _profileBadge(),
          ],
        ),
      ),
      elevation: 0,
      // A hairline instead of a shadow — the page below is F5F7FA, and a drop
      // shadow over it muddied the edge.
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE5E7EB)),
      ),
      surfaceTintColor: AppColor.whiteColor,
      backgroundColor: AppColor.whiteColor,
    );
  }

  /// Tappable clinic badge. It was an IconButton, which padded the avatar out
  /// to 48px and rendered the splash as a big grey square behind a circle.
  Widget _profileBadge() {
    return Semantics(
      button: true,
      label: 'Clinic profile',
      child: InkWell(
        onTap: widget.onProfileTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: ClinicLogoWidget(
            clinicName: widget.loginName,
            size: 36 * _scale,
            elevated: true,
          ),
        ),
      ),
    );
  }

  Widget _datePill(bool open) {
    final double s = _scale;

    return InkWell(
      onTap: () => widget.onDateTap(),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: EdgeInsets.fromLTRB(13 * s, 8 * s, 9 * s, 8 * s),
        decoration: BoxDecoration(
          // Tinted while the calendar is open, so the bar shows the state of
          // the sheet below it.
          color: open ? _blue.withValues(alpha: 0.10) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: open ? _blue : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_rounded,
              size: 15 * s,
              color: open ? _blue : const Color(0xFF535359),
            ),
            SizedBox(width: 6 * s),
            Text(
              _formatDate(widget.selectedDate),
              style: GoogleFonts.poppins(
                color: open ? _blue : const Color(0xFF252525),
                fontSize: 13.5 * s,
                fontWeight: FontWeight.w600,
              ),
            ),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 19 * s,
                color: open ? _blue : const Color(0xFF535359),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Deliberately short. The header card directly below spells the date out
    // in full, so repeating "Today, 12 Aug" here only crowded the clinic name.
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return DateFormat('d MMM').format(date);
    }
    return DateFormat('d MMM yy').format(date);
  }
}
