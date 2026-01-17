import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../common/get_score_title.dart';
import '../../../router/app_routers.dart';
import '../../../shared/colors.dart';
import '../../../shared/images_string.dart';
import '../../data/model/result_model.dart';
import '../../data/model/result_profile_data_model.dart';
import '../view_model/result_view_model.dart';
import '../widgets/bmi_bmr_card.dart';
import '../widgets/corporate_disclaimer.dart';
import '../widgets/custom_result_score_linearbar.dart';
import '../widgets/custom_result_scorecard.dart';
import '../widgets/custom_result_scorecard_corporate.dart';
import '../widgets/disclaimer_card.dart';
import '../widgets/quick_summary_card.dart';
import '../widgets/score_reference_card.dart';

class ResultScreen extends StatefulWidget {
  final NewResultModel userResultData;
  final ResultProfileDataModel userProfileData;
  final List<double> blowValuesList;

  const ResultScreen({
    super.key,
    required this.userResultData,
    required this.userProfileData,
    required this.blowValuesList,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _hasInternet = true;

  @override
  Widget build(BuildContext context) {
    final resultViewModel = Provider.of<ResultViewModel>(context);
    final bmi = resultViewModel.bmi;
    final bmr = resultViewModel.bmr;


    final isCorporate =
        (widget.userProfileData.role ?? 'clinical').toLowerCase() == 'corporate';

    final dummyTimeStamp = DateTime.fromMillisecondsSinceEpoch(
      widget.userResultData.timestamp * 1000,
    );

    final resultTime = DateFormat("dd MMMM yyyy • hh:mm a").format(dummyTimeStamp);

    return WillPopScope(
      onWillPop: () async {
        _navigateToDashboard();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(
                widget.userProfileData.profileName ?? "",
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
                onPressed: () => _navigateToDashboard(),
                icon: SvgPicture.asset("assets/svg_icons/close_icon.svg"),
              ),
            ),
          ],
          backgroundColor: AppColor.whiteColor,
          surfaceTintColor: AppColor.whiteColor,
          elevation: 3.2,
        ),
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: PopScope(
            canPop: true,
            onPopInvoked: (didPop) async {
              _navigateToDashboard();
            },
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  if (bmi != null && bmr != null)
                    BmiBmrCard(bodyMassIndex: bmi, basalMetabolicRate: bmr),

                  const SizedBox(height: 20),

                  ScoreReferenceCard(isCorporate: isCorporate,),

                  const SizedBox(height: 10),

                  _resultScoreLineBar(isCorporate: isCorporate),

                  const SizedBox(height: 20),

                  if (!isCorporate) ...[
                    QuickSummary(userResultData: widget.userResultData),
                  ],

                  const SizedBox(height: 30),

                  _scoreInterpretation(),

                  const SizedBox(height: 20),

                  const SizedBox(height: 20),

                  _buildScoreCard(
                    isCorporate: isCorporate,
                    scoreTitle: getScoreTitle(isCorporate: isCorporate, score: ScoreType.respiratory),
                    scoreVal: widget.userResultData.respiratoryScore,
                    category: "respiratory",
                  ),

                  const SizedBox(height: 20),

                  _buildScoreCard(
                    isCorporate: isCorporate,
                    scoreTitle: getScoreTitle(isCorporate: isCorporate, score: ScoreType.sugar),
                    scoreVal: widget.userResultData.sugarScore,
                    category: "sugar",
                  ),

                  const SizedBox(height: 20),

                  _buildScoreCard(
                    isCorporate: isCorporate,
                    scoreTitle: getScoreTitle(isCorporate: isCorporate, score: ScoreType.liver),
                    scoreVal: widget.userResultData.liverScore,
                    category: "liver",
                  ),

                  const SizedBox(height: 20),

                  _buildScoreCard(
                    isCorporate: isCorporate,
                    scoreTitle: getScoreTitle(isCorporate: isCorporate, score: ScoreType.gut),
                    scoreVal: widget.userResultData.gutScore,
                    category: "gut",
                  ),

                  const SizedBox(height: 50),

                  isCorporate ? const CorporateDisclaimerCard() : const DisclaimerCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard({
    required bool isCorporate,
    required String scoreTitle,
    required double scoreVal,
    required String category,
  }) {
    final timeStamp = widget.userResultData.timestamp.toString();

    if (isCorporate) {
      return CustomResultScorecardCorporate(
        scoreTitle: scoreTitle,
        scoreVal: scoreVal,
        category: category,
        timeStamp: timeStamp,
        userResultData: widget.userResultData,
      );
    }

    return CustomResultScorecard(
      scoreTitle: scoreTitle,
      scoreVal: scoreVal,
      category: category,
      timeStamp: timeStamp,
      userResultData: widget.userResultData,
    );
  }

  Widget _resultScoreLineBar({required bool isCorporate}) {
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
              progress: widget.userResultData.respiratoryScore / 100,
              svgPath: ResSvg.respiratory,
              textTitle: getScoreTitle(isCorporate: isCorporate, score: ScoreType.respiratory).replaceAll(" ", "\n"),
              scoreType: 'respiratory',
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.05,
            right: MediaQuery.of(context).size.width * 0.03,
            child: CustomResultScoreLinearbar(
              progress: widget.userResultData.gutScore / 100,
              svgPath: ResSvg.gutVital,
              textTitle: getScoreTitle(isCorporate: isCorporate, score: ScoreType.gut).replaceAll(" ", "\n"),
              scoreType: 'gut',
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.22,
            left: MediaQuery.of(context).size.width * 0.05,
            child: CustomResultScoreLinearbar(
              progress: widget.userResultData.liverScore / 100,
              svgPath: ResSvg.liver,
              textTitle: getScoreTitle(isCorporate: isCorporate, score: ScoreType.liver).replaceAll(" ", "\n"),
              scoreType: 'liver',
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.22,
            right: MediaQuery.of(context).size.width * 0.05,
            child: CustomResultScoreLinearbar(
              progress: widget.userResultData.sugarScore / 100,
              svgPath: ResSvg.sugarPancreas,
              textTitle: getScoreTitle(isCorporate: isCorporate, score: ScoreType.sugar).replaceAll(" ", "\n"),
              scoreType: 'sugar',
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreInterpretation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scores Interpretation',
            style: GoogleFonts.poppins(
              color: const Color(0xFF252525),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text:
                  'Scores interpretations are based on the values recorded by Respyr device. Please refer to the reference ',
                  style: TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.26,
                    letterSpacing: -0.24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDashboard() {
    if (Get.isOverlaysOpen) {
      Get.back();
    }
    Get.offAllNamed(
      AppRoutes.mainDashboard,
      arguments: {
        'profile_details': widget.userProfileData,
      },
    );
  }


}
