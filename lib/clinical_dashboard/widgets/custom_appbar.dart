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

/// Dashboard app bar: clinic identity on the left, date/calendar toggle right.
///
/// Two things changed from the original. The date used to be a bare label and
/// a chevron inside an IconButton, with its font size derived from the
/// available width — so it changed size between devices and nothing suggested
/// it could be tapped; it is a pill now, which reads as a control and shows
/// its open state. And the bar led with that control while the logo floated
/// alone at the far right, leaving the middle empty — the clinic badge and
/// name now anchor the left edge, so the row reads identity → action.
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

  @override
  Widget build(BuildContext context) {
    final bool open = widget.calendarVisible;

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      // The whole row is built as the title so the badge, the name and the
      // date pill share one flex line — the name is what gives, not the pill.
      title: Padding(
        padding: const EdgeInsets.only(left: 14, right: 12),
        child: Row(
          children: [
            _profileBadge(),
            const SizedBox(width: 10),
            Expanded(child: _clinicName()),
            const SizedBox(width: 10),
            _datePill(open),
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
            size: 36,
            elevated: true,
          ),
        ),
      ),
    );
  }

  Widget _clinicName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.loginName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: const Color(0xFF252525),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: -0.2,
          ),
        ),
        Text(
          'Dashboard',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: const Color(0xFF8A8A8F),
            fontSize: 11,
            fontWeight: FontWeight.w400,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _datePill(bool open) {
    return InkWell(
      onTap: () => widget.onDateTap(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
        decoration: BoxDecoration(
          // Tinted while the calendar is open, so the bar shows the state of
          // the sheet below it.
          color: open ? _blue.withValues(alpha: 0.10) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: open ? _blue : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_rounded,
              size: 15,
              color: open ? _blue : const Color(0xFF535359),
            ),
            const SizedBox(width: 6),
            Text(
              _formatDate(widget.selectedDate),
              style: GoogleFonts.poppins(
                color: open ? _blue : const Color(0xFF252525),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
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
