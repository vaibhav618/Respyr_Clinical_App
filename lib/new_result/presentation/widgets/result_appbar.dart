import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../shared/colors.dart';
import '../../data/model/result_model.dart';
import '../../data/model/result_profile_data_model.dart';

PreferredSizeWidget resultScreenAppbar({
  required BuildContext context,
  required NewResultModel userResultData,
  required ResultProfileDataModel userProfileData,
  required VoidCallback navigateToDashboard,

  /// Downloads the report as a PDF. Shown top-right when provided; while
  /// [downloadBusy] is true the icon becomes a spinner and stops taking taps.
  VoidCallback? onDownload,
  bool downloadBusy = false,
}) {
  final dummyTimeStamp = DateTime.fromMillisecondsSinceEpoch(
    userResultData.timestamp * 1000,
  );
  final resultTime = DateFormat(
    "dd MMMM yyyy • hh:mm a",
  ).format(dummyTimeStamp);

  return AppBar(
    // The cross is the bar's only control and sits leading, where a screen's
    // exit lives everywhere else in the app. (No implied back arrow either —
    // it ran the same navigateToDashboard, offering one action twice.)
    automaticallyImplyLeading: false,
    leading: IconButton(
      onPressed: () => navigateToDashboard(),
      icon: SvgPicture.asset("assets/svg_icons/close_icon.svg"),
    ),
    title: Column(
      children: [
        Text(
          userProfileData.profileName ?? "",
          style: GoogleFonts.poppins(
            color: const Color(0xFF252525),
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          resultTime,
          style: GoogleFonts.poppins(
            color: const Color(0xFF252525),
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ),
    centerTitle: true,
    actions: [
      if (onDownload != null)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: downloadBusy
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Color(0xFF308BF9),
                    ),
                  ),
                )
              : IconButton(
                  onPressed: onDownload,
                  tooltip: 'Download report as PDF',
                  icon: const Icon(
                    Icons.download_rounded,
                    color: Color(0xFF252525),
                  ),
                ),
        ),
    ],
    backgroundColor: AppColor.whiteColor,
    surfaceTintColor: AppColor.whiteColor,
    elevation: 3.2,
  );
}
