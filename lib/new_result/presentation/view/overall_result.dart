import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
import '../../../clinical_dashboard/bloc/health_score_bloc.dart';
import '../../../clinical_dashboard/service/overall_data_by_date_service.dart';
import '../../../clinical_dashboard/views/clinical_dashboard.dart';
import '../../../shared/colors.dart';
import '../../../shared/images_string.dart';
import '../../data/model/result_model.dart';
import '../../data/model/result_profile_data_model.dart';
import '../view_model/result_view_model.dart';
import '../widgets/bmi_bmr_card.dart';
import '../widgets/custom_result_score_linearbar.dart';
import '../widgets/custom_result_scorecard.dart';
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

    final dummyTimeStamp = DateTime.fromMillisecondsSinceEpoch(
      widget.userResultData.timestamp * 1000,
    );

    final resultTime = DateFormat(
      "dd MMMM yyyy • hh:mm a",
    ).format(dummyTimeStamp);

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
              padding: EdgeInsets.only(right: 30),
              child: IconButton(
                onPressed: () {
                  _navigateToDashboard();
                },
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
                  ScoreReferenceCard(),
                  SizedBox(height: 10),
                  _resultScoreLineBar(),
                  const SizedBox(height: 20),
                  QuickSummary(userResultData: widget.userResultData),
                  const SizedBox(height: 30),
                  _scoreInterpretation(),
                  const SizedBox(height: 20),
                  SizedBox(height: 20),
                  CustomResultScorecard(
                    scoreTitle: "Respiratory Score",
                    scoreVal: widget.userResultData.respiratoryScore,
                    category: "respiratory",
                    timeStamp: widget.userResultData.timestamp.toString(),
                    userResultData: widget.userResultData,
                  ),
                  SizedBox(height: 20),
                  CustomResultScorecard(
                    scoreTitle: "Sugar Score",
                    scoreVal: widget.userResultData.sugarScore,
                    category: "sugar",
                    timeStamp: widget.userResultData.timestamp.toString(),
                    userResultData: widget.userResultData,
                  ),
                  SizedBox(height: 20),
                  CustomResultScorecard(
                    scoreTitle: "Liver Stress Score",
                    scoreVal: widget.userResultData.liverScore,
                    category: "liver",
                    timeStamp: widget.userResultData.timestamp.toString(),
                    userResultData: widget.userResultData,
                  ),
                  SizedBox(height: 20),
                  CustomResultScorecard(
                    scoreTitle: "Gut Fermentation Score",
                    scoreVal: widget.userResultData.gutScore,
                    category: "gut",
                    timeStamp: widget.userResultData.timestamp.toString(),
                    userResultData: widget.userResultData,
                  ),
                  const SizedBox(height: 50),
                  DisclaimerCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultScoreLineBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      width: MediaQuery.of(context).size.width, // Responsive width
      child: Stack(
        children: [
          SvgPicture.asset(
            ResSvg.humanBody,
            width: MediaQuery.of(context).size.width * 0.8, // Responsive width
            height:
                MediaQuery.of(context).size.height * 0.35, // Responsive height
            fit: BoxFit.contain,
          ),
          Positioned(
            top:
                MediaQuery.of(context).size.height *
                0.05, // Dynamic positioning
            left: MediaQuery.of(context).size.width * 0.05,
            child: CustomResultScoreLinearbar(
              progress: widget.userResultData.respiratoryScore / 100,
              svgPath: ResSvg.respiratory,
              textTitle: 'Respiratory\nScore',
              scoreType: 'respiratory',
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.05,
            right: MediaQuery.of(context).size.width * 0.03,
            child: CustomResultScoreLinearbar(
              progress: widget.userResultData.gutScore / 100,
              svgPath: ResSvg.gutVital,
              textTitle: 'Gut\nFermentation\nScore',
              scoreType: 'gut',
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.22,
            left: MediaQuery.of(context).size.width * 0.05,
            child: CustomResultScoreLinearbar(
              progress: widget.userResultData.liverScore / 100,
              svgPath: ResSvg.liver,
              textTitle: 'Liver\nStress\nScore',
              scoreType: 'liver',
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.22,
            right: MediaQuery.of(context).size.width * 0.05,
            child: CustomResultScoreLinearbar(
              progress: widget.userResultData.sugarScore / 100,
              svgPath: ResSvg.sugarPancreas,
              textTitle: 'Sugar\nScore',
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
                TextSpan(
                  text:
                      'Scores interpretations are based on the values recorded by Respyr device. Please refer to the reference ',
                  style: TextStyle(
                    color: const Color(0xFF252525),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.26,
                    letterSpacing: -0.24,
                  ),
                ),
                TextSpan(
                  text: 'link',
                  style: TextStyle(
                    color: const Color(0xFF308BF9),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.underline,
                    height: 1.26,
                    letterSpacing: -0.24,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
                TextSpan(
                  text: ' for more details.',
                  style: TextStyle(
                    color: const Color(0xFF252525),
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => BlocProvider(
              create: (_) => HealthScoreBloc(OverallDataByDateService()),
              child: ClinicalDashboardMain(
                loginId: widget.userProfileData.clinicName!,
              ),
            ),
      ),
    );
  }
}
