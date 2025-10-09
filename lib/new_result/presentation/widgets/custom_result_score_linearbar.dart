import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/colors.dart';
import '../../../utils/score_color_helper.dart';
import '../../../utils/score_status_helper.dart';

class CustomResultScoreLinearbar extends StatelessWidget {
  final double progress;
  final String svgPath;
  final String scoreType;
  final String textTitle;
  final String? subStatusTitle;
  final String? addOnSubTitle;
  const CustomResultScoreLinearbar({
    super.key,
    required this.progress,
    required this.svgPath,
    required this.textTitle,
    this.addOnSubTitle,
    this.subStatusTitle,
    required this.scoreType,
  });

  @override
  Widget build(BuildContext context) {
    String title = ScoreStatusHelper.getScoreTitle(progress * 100);
    String subTitle = ScoreStatusHelper.getScoreSubTitle(progress * 100);
    String subtitleToShow = addOnSubTitle ?? subStatusTitle ?? subTitle;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final List<Color> gradientColors = ScoreColorHelper.getLinearScoreColor(
      progress * 100,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColor.whiteColor,
              ),
              child: Center(
                child: SvgPicture.asset(svgPath, height: 24, width: 24),
              ),
            ),
            SizedBox(width: width * 0.03),
            Text(
              textTitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColor.primaryBlackColor,
              ),
            ),
          ],
        ),
        SizedBox(height: height * 0.01),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                ShaderMask(
                  shaderCallback:
                      (bounds) => LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                  child: Text(
                    '${(progress * 100.00).toStringAsFixed(0)}%',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColor.whiteColor,
                    ),
                  ),
                ),
                Stack(
                  children: [
                    Container(
                      width: 35,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Container(
                      width: 35 * progress,
                      height: 5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(width: width * 0.03),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback:
                      (bounds) => LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                  child: Text(
                    '$title!',
                    style: GoogleFonts.mulish(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColor.whiteColor,
                    ),
                  ),
                ),
                if (subtitleToShow.isNotEmpty)
                  Text(
                    subtitleToShow,
                    softWrap: true,
                    style: GoogleFonts.mulish(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppColor.textLightColor,
                    ),
                    overflow: TextOverflow.clip,
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
