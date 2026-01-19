
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../shared/colors.dart';
import '../../data/model/result_model.dart';
import '../../data/model/result_profile_data_model.dart';

PreferredSizeWidget resultScreenAppbar(
{
  required BuildContext context,
  required NewResultModel userResultData,
  required ResultProfileDataModel userProfileData,
  required VoidCallback navigateToDashboard
}
) {
  final dummyTimeStamp = DateTime.fromMillisecondsSinceEpoch(
    userResultData.timestamp * 1000,
  );
  final resultTime = DateFormat("dd MMMM yyyy • hh:mm a").format(dummyTimeStamp);

  return AppBar(
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
      Padding(
        padding: const EdgeInsets.only(right: 30),
        child: IconButton(
          onPressed: () => navigateToDashboard(),
          icon: SvgPicture.asset("assets/svg_icons/close_icon.svg"),
        ),
      ),
    ],
    backgroundColor: AppColor.whiteColor,
    surfaceTintColor: AppColor.whiteColor,
    elevation: 3.2,
  );
}