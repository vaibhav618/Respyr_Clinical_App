import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/shared/colors.dart';

class CustomResultScore extends StatefulWidget {
  final double progress;
  final String svgPath;
  final String scoreType;
  final String textTitle;
  final String? subStatusTitle;
  final String? addOnSubTitle;
  const CustomResultScore({
    super.key,
    required this.progress,
    required this.svgPath,
    required this.textTitle,
    this.addOnSubTitle,
    this.subStatusTitle,
    required this.scoreType,
  });

  @override
  State<CustomResultScore> createState() => _CustomResultScoreState();
}

class _CustomResultScoreState extends State<CustomResultScore> {
  late String title;
  late String? subTitle;

  List<Color> getProgressColor(double progress) {
    if (progress < 0.60) {
      return [const Color(0xFFEA5455), const Color(0xFFC1272D)];
    } else if (progress < 0.79) {
      return [const Color(0xFFFFC412), const Color(0xFFE3AC06)];
    } else {
      return [AppColor.buttonGreenColor, const Color(0xFF009245)];
    }
  }

  void getTitle() {
    if (widget.progress < 0.60) {
      subTitle = 'Attention\nRequired';

      title = 'Poor';
    } else if (widget.progress < 0.79) {
      subTitle = 'Come back\nin a week';
      title = 'Fair';
    } else {
      subTitle = 'Everything\nlooks good!';
      title = 'Good';
    }
  }

  @override
  void initState() {
    super.initState();
    getProgressColor(widget.progress);
    getTitle();
  }

  @override
  Widget build(BuildContext context) {
    String subtitleToShow =
        widget.addOnSubTitle ?? widget.subStatusTitle ?? subTitle ?? '';
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
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
                child: SvgPicture.asset(widget.svgPath, height: 24, width: 24),
              ),
            ),
            SizedBox(width: width * 0.03),
            Text(
              widget.textTitle,
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
                        colors: getProgressColor(widget.progress),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                  child: Text(
                    '${(widget.progress * 100).toStringAsFixed(0)}%',
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
                      width: 35 * widget.progress,
                      height: 5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: getProgressColor(widget.progress),
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
                        colors: getProgressColor(widget.progress),
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
