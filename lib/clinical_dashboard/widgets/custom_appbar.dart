import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                loginName,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF252525),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.72,
                ),
              ),
            ],
          )
        ],
      ),
      actions: [
        IconButton(
          icon: ClinicLogoWidget(clinicName: loginName,),
          onPressed: onProfileTap,
        ),
      ],
    );
  }
}




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
    required this.calendarVisible, required this.loginName, required this.onProfileTap,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

// Implementing the preferredSize method here as CustomAppBar is a PreferredSizeWidget
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {

    return AppBar(
      automaticallyImplyLeading: false,
      title: IconButton(
        onPressed: () => widget.onDateTap(),
        icon: LayoutBuilder(
          builder: (context, constraints) {
            double fontSize = constraints.maxWidth * 0.08;
            return Row(
              children: [
                Text(
                  _formatDate(widget.selectedDate),
                  style: GoogleFonts.roboto(
                    color: AppColor.primaryBlackColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SvgPicture.asset(
                  widget.calendarVisible
                      ? "assets/svg_icons/down_arrow_icon.svg"
                      : 'assets/svg_icons/right_arrow_button.svg',
                  height: 20,
                  width: 20,
                ),
              ],
            );
          },
        ),
      ),
      actions: [

        IconButton(
          icon: ClinicLogoWidget(clinicName: widget.loginName,),
          onPressed: widget.onProfileTap,
        ),
      ],
      elevation: 0.5,
      surfaceTintColor: AppColor.whiteColor,
      backgroundColor: AppColor.whiteColor,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today, ${DateFormat('dd MMM').format(date)}';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday, ${DateFormat('dd MMM').format(date)}';
    } else {
      return DateFormat('MMMM dd, yyyy').format(date);
    }
  }
}
