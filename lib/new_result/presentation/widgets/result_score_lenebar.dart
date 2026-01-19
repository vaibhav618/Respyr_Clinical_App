import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';

import '../../../common/get_score_title.dart';
import '../../../shared/images_string.dart';
import '../../data/model/result_model.dart';
import 'custom_result_score_linearbar.dart';

Widget resultScoreLineBar({required bool isCorporate, required BuildContext context,

  required NewResultModel userResultData
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 15),
    width: MediaQuery.of(context).size.width,
    child: Stack(
      children: [
        SvgPicture.asset(
          ResSvg.humanBody,
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.35,
          fit: BoxFit.contain,
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.05,
          left: MediaQuery.of(context).size.width * 0.05,
          child: CustomResultScoreLinearbar(
            progress: userResultData.respiratoryScore / 100,
            svgPath: ResSvg.respiratory,
            textTitle: getScoreTitle(isCorporate: isCorporate, score: ScoreType.respiratory)
                .replaceAll(" ", "\n"),
            scoreType: 'respiratory',
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.05,
          right: MediaQuery.of(context).size.width * 0.03,
          child: CustomResultScoreLinearbar(
            progress: userResultData.gutScore / 100,
            svgPath: ResSvg.gutVital,
            textTitle: getScoreTitle(isCorporate: isCorporate, score: ScoreType.gut)
                .replaceAll(" ", "\n"),
            scoreType: 'gut',
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.22,
          left: MediaQuery.of(context).size.width * 0.05,
          child: CustomResultScoreLinearbar(
            progress: userResultData.liverScore / 100,
            svgPath: ResSvg.liver,
            textTitle: getScoreTitle(isCorporate: isCorporate, score: ScoreType.liver)
                .replaceAll(" ", "\n"),
            scoreType: 'liver',
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.22,
          right: MediaQuery.of(context).size.width * 0.05,
          child: CustomResultScoreLinearbar(
            progress: userResultData.sugarScore / 100,
            svgPath: ResSvg.sugarPancreas,
            textTitle: getScoreTitle(isCorporate: isCorporate, score: ScoreType.sugar)
                .replaceAll(" ", "\n"),
            scoreType: 'sugar',
          ),
        ),
      ],
    ),
  );
}