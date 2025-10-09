import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/clinical_profile/clinical_profile_screen.dart';

import 'package:respyr_clinical/clinical_app_respyr/services/custom_result_score.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:respyr_clinical/shared/images_string.dart';

import '../../new_result/data/model/result_profile_data_model.dart';

class ResultScreenClinicalApp extends StatefulWidget {
  final String lifeStyleJsonResponse;
  final ResultProfileDataModel profileDetails;
  const ResultScreenClinicalApp({
    super.key,
    required this.lifeStyleJsonResponse,
    required this.profileDetails,
  });

  @override
  State<ResultScreenClinicalApp> createState() =>
      _ResultScreenClinicalAppState();
}

class _ResultScreenClinicalAppState extends State<ResultScreenClinicalApp> {
  int selectedIndex = 1;
  String subjectId = '';
  double height = 0.0;
  double weight = 0.0;
  String profileName = '';
  int age = 0;
  String gender = '';

  double? bmi;
  double? bmr;

  int? _cmValue;
  int _weightValue = 0;
  bool _isMale = true;

  @override
  void initState() {
    super.initState();
    profileDetails();
  }

  void profileDetails() {
    subjectId = widget.profileDetails.subjectId ?? '';
    height = widget.profileDetails.height ?? 0;
    weight = widget.profileDetails.weight ?? 0;
    profileName = widget.profileDetails.profileName ?? '';
    age = widget.profileDetails.age ?? 0;
    gender = widget.profileDetails.gender ?? '';

    _cmValue = height.toInt();
    _weightValue = weight.toInt();
    _isMale = gender.toLowerCase() == 'male';

    _updateBmi();
    _updateBmr();
  }

  void _updateBmi() {
    if (_weightValue > 0 && _cmValue != null && _cmValue! > 0) {
      double heightInMeters = _cmValue! / 100;
      double calculateBMI = _weightValue / (heightInMeters * heightInMeters);

      setState(() {
        bmi = double.parse(calculateBMI.toStringAsFixed(2));
      });
    } else {
      if (kDebugMode) {
        print("Invalid height or weight for BMI calculation");
      }
    }
  }

  void _updateBmr() {
    final int? parseAge = age;
    final int weight = _weightValue;
    final int? height = _cmValue;

    if (parseAge != null &&
        parseAge > 0 &&
        weight > 0 &&
        height != null &&
        height > 0) {
      double calculateBMR;

      if (_isMale) {
        calculateBMR = (10 * weight) + (6.25 * height) - (5 * parseAge) + 5;
      } else {
        calculateBMR = (10 * weight) + (6.25 * height) - (5 * parseAge) - 161;
      }

      setState(() {
        bmr = double.tryParse(calculateBMR.toStringAsFixed(2));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFE4FFEA),
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final Map<String, dynamic> resultData = jsonDecode(
      widget.lifeStyleJsonResponse,
    );

    double sugarScore = resultData['sugarScore'] ?? 0.0;
    double blowScore = resultData['blowScore'] ?? 0.0;
    double gutScore = resultData['gutScore'] ?? 0.0;
    double liverScore = resultData['liverScore'] ?? 0.0;
    int timeStamp = resultData['timestamp'] ?? 0;

    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000);

    final resultTime =
        DateFormat("dd-MM-yyyy hh:mma").format(dateTime).toLowerCase();

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE4FFEA),
                            AppColor.whiteColor,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              onPressed: () {},
                              icon: SvgPicture.asset(
                                "assets/svg_icons/close_icon.svg",
                              ),
                            ),
                          ),
                          SvgPicture.asset('assets/clinical_reult_success.svg'),
                          const SizedBox(height: 10),
                          Text(
                            "Test Completed",
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.w400,
                              color: AppColor.primaryBlackColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            resultTime,
                            style: GoogleFonts.mulish(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColor.primaryBlackColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: AppColor.whiteColor,
                      child: Column(
                        children: [
                          resultIdRow("Subject Id", subjectId),
                          const SizedBox(height: 5),
                          resultIdRow(
                            "Details",
                            "$profileName, $age year old, $gender",
                          ),
                          const SizedBox(height: 5),
                          resultIdRow("BMI", bmi.toString()),
                          const SizedBox(height: 5),
                          resultIdRow("BMR", bmr.toString()),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 15,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.all(
                                Radius.circular(5),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  "assets/svg_icons/green_circle_icon.svg",
                                ),
                                const SizedBox(width: 10),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Good\t\t',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: AppColor.primaryBlackColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '80 - 100%',
                                        style: GoogleFonts.roboto(
                                          fontSize: 10,
                                          color: AppColor.textLightColor,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                SvgPicture.asset(
                                  "assets/svg_icons/yellow_circle_icon.svg",
                                ),
                                const SizedBox(width: 10),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Fair\t\t',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: AppColor.primaryBlackColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '61 - 79%',
                                        style: GoogleFonts.roboto(
                                          fontSize: 10,
                                          color: AppColor.textLightColor,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                SvgPicture.asset(
                                  "assets/svg_icons/red_circle_icon.svg",
                                ),
                                const SizedBox(width: 10),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Poor\t\t',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: AppColor.primaryBlackColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '0 - 60%',
                                        style: GoogleFonts.roboto(
                                          fontSize: 10,
                                          color: AppColor.textLightColor,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            width:
                                MediaQuery.of(
                                  context,
                                ).size.width, // Responsive width
                            decoration: BoxDecoration(
                              color: AppColor.whiteColor,
                            ),
                            child: Stack(
                              children: [
                                SvgPicture.asset(
                                  ResSvg.humanBody,
                                  width:
                                      MediaQuery.of(context).size.width *
                                      0.8, // Responsive width
                                  height:
                                      MediaQuery.of(context).size.height *
                                      0.35, // Responsive height
                                  fit: BoxFit.contain,
                                ),
                                Positioned(
                                  top:
                                      MediaQuery.of(context).size.height *
                                      0.05, // Dynamic positioning
                                  left:
                                      MediaQuery.of(context).size.width * 0.05,
                                  child: CustomResultScore(
                                    progress: blowScore / 100,
                                    svgPath: ResSvg.respiratory,
                                    textTitle: 'Respiratory\nScore',
                                    scoreType: 'respiratory',
                                  ),
                                ),
                                Positioned(
                                  top:
                                      MediaQuery.of(context).size.height * 0.05,
                                  right:
                                      MediaQuery.of(context).size.width * 0.05,
                                  child: CustomResultScore(
                                    progress: gutScore / 100,
                                    svgPath: ResSvg.gutVital,
                                    textTitle: 'Gut\nScore',
                                    scoreType: 'gut',
                                  ),
                                ),
                                Positioned(
                                  top:
                                      MediaQuery.of(context).size.height * 0.22,
                                  left:
                                      MediaQuery.of(context).size.width * 0.05,
                                  child: CustomResultScore(
                                    progress: liverScore / 100,
                                    svgPath: ResSvg.liver,
                                    textTitle: 'Liver\nScore',
                                    scoreType: 'liver',
                                  ),
                                ),
                                Positioned(
                                  top:
                                      MediaQuery.of(context).size.height * 0.22,
                                  right:
                                      MediaQuery.of(context).size.width * 0.05,
                                  child: CustomResultScore(
                                    progress: sugarScore / 100,
                                    svgPath: ResSvg.sugarPancreas,
                                    textTitle: 'Sugar\nScore',
                                    scoreType: 'sugar',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _diabeticScoreCard(
                            "Sugar Score",
                            sugarScore,
                            "sugar",
                          ),
                          const SizedBox(height: 10),
                          _diabeticScoreCard("Gut Score", gutScore, "gut"),
                          const SizedBox(height: 10),
                          _diabeticScoreCard(
                            "Respiratory Score",
                            blowScore,
                            "respiratory",
                          ),
                          const SizedBox(height: 10),
                          _diabeticScoreCard(
                            "Liver Score",
                            liverScore,
                            "liver",
                          ),
                          const SizedBox(height: 10),
                          _disclaimerAndRegulatoryText(),
                          const SizedBox(height: 70),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: AppColor.whiteColor,
                    boxShadow: [
                      const BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 10,
                        offset: Offset(0, 0),
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          Get.to(() => ClinicalProfileScreen());
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/profile_svg.svg',
                              colorFilter: ColorFilter.mode(
                                selectedIndex == 0
                                    ? AppColor.primaryBlueColor
                                    : const Color(0xFFA1A1A1),
                                BlendMode.srcIn,
                              ),
                            ),
                            Text(
                              "view profile",
                              style: GoogleFonts.poppins(
                                color:
                                    selectedIndex == 0
                                        ? AppColor.primaryBlueColor
                                        : const Color(0xFFA1A1A1),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SvgPicture.asset('assets/vertical_line.svg'),
                      InkWell(
                        onTap: () {
                          setState(() {
                            selectedIndex = 1;
                          });
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/dashboard_svg.svg',
                              colorFilter: ColorFilter.mode(
                                selectedIndex == 0
                                    ? const Color(0xFFA1A1A1)
                                    : AppColor.primaryBlueColor,
                                BlendMode.srcIn,
                              ),
                            ),
                            Text(
                              "Dashboard",
                              style: GoogleFonts.poppins(
                                color:
                                    selectedIndex == 1
                                        ? AppColor.primaryBlueColor
                                        : const Color(0xFFA1A1A1),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget resultIdRow(String rowId, String rowVal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          rowId,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColor.primaryBlackColor,
          ),
        ),
        Text(
          rowVal,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColor.primaryBlackColor,
          ),
        ),
      ],
    );
  }

  Widget _disclaimerAndRegulatoryText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Disclaimer : Respyr provides non-invasive screening insights based on breath analysis. The scores and interpretations presented are intended to indicate physiological trends and support lifestyle and preventive health monitoring. Accuracy claims are based on internal blinded validation using patient classification and breath samples collected in collaboration with recognized hospitals as part of a multicentric study conducted across India. Respyr does not diagnose, treat, or prevent any disease. This interpretation guide is intended for use by qualified healthcare providers to understand screening trends. Clinical judgment and confirmatory testing should be used before making any medical decisions. Respyr is not a substitute for standard clinical testing or professional medical evaluation.',
            style: GoogleFonts.mulish(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColor.primaryBlackColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Regulatory Status',
            style: GoogleFonts.mulish(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColor.primaryBlackColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Respyr is registered as a Class B In Vitro Diagnostic (IVD) device under CDSCO MD5.\n\n'
            '• The product and its manufacturing processes comply with ISO 13485:2016 and IEC 60601-1-2:2014 standards.\n\n'
            '• Distribution and sale are authorized under MD13 and MD42 licenses.\n\n'
            '• Clinical validation data is based on a multi-centric study with recognized hospitals across India, with internal blinded validation demonstrating 90% correlation accuracy.',
            style: GoogleFonts.mulish(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColor.primaryBlackColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _diabeticScoreCard(
    String scoreTitle,
    double scoreVal,
    String category,
  ) {
    final interpretation = getScoreInterpretation(category, scoreVal);
    final status = interpretation['status'];
    final titles = interpretation['titles'] as List<String>;
    final subtitles = interpretation['subtitles'] as List<String>;
    final insight = interpretation['insight'];
    final correlation = interpretation['correlation'];

    Color clinicalScoreCardColor =
        scoreVal > 80
            ? const Color(0xFFE4FFEA)
            : scoreVal >= 69
            ? const Color(0xFFFFECB1)
            : const Color(0xFFF9C7C7);

    Color clinicalStatusScoreColor =
        scoreVal > 80
            ? const Color(0xFF3FAF58)
            : scoreVal >= 69
            ? const Color(0xFFF8B10F)
            : const Color(0xFFEA5455);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        color: AppColor.whiteColor,
        boxShadow: [
          const BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 8,
            offset: Offset(0, 0),
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: clinicalScoreCardColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    scoreTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Center(
                  child: Text(
                    "${scoreVal.toStringAsFixed(1)}%",
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: clinicalStatusScoreColor,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < titles.length; i++) ...[
                  Text(
                    titles[i],
                    style: GoogleFonts.mulish(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitles.length > i ? subtitles[i] : '',
                    style: GoogleFonts.mulish(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Clinical Insight:\n$insight",
            style: GoogleFonts.mulish(
              color: const Color(0xFFA1A1A1),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          const Divider(color: Color(0xFFF0F0F0)),
          Text(
            "Correlation:\n$correlation",
            style: GoogleFonts.mulish(
              color: const Color(0xFFA1A1A1),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> getScoreInterpretation(
    String category,
    double scoreVal,
  ) {
    String level =
        scoreVal > 80
            ? 'Good'
            : scoreVal >= 69
            ? 'Fair'
            : 'Poor';

    Map<String, Map<String, List<String>>> scoreData = {
      'sugar': {
        'Good': [
          "Indicates Efficient glucose metabolism.",
          "Correlates with normal fasting glucose and HbA1c levels. No abnormal trends in glucose utilization or metabolic flexibility are observed.",
          "No further evaluation typically required unless clinically indicated.",
        ],
        'Fair': [
          "Suggests Mild impairment in glucose efficiency.",
          "Correlating with slight elevations in fasting glucose and/or HbA1c. This may reflect early-stage reduction in insulin sensitivity or changes in metabolic substrate use",
          "Periodic monitoring of metabolic markers may be considered.",
        ],
        'Poor': [
          "Indicates Significant reduction in glucose utilization efficiency.",
          "Correlating with marked elevations in fasting glucose and/or HbA1c trends. Suggests increasing reliance on alternative energy pathways (lipolysis/ketone production).",
          "Further metabolic evaluation may be suggested to explore potential contributors to impaired glucose handling.",
        ],
      },
      'gut': {
        'Good': [
          "Reflects Balancedgut fermentation activity.",
          "Hydrogen levels fall within expected physiological ranges, correlating with efficient carbohydrate absorption and stable microbial fermentation. No significant gastrointestinal concerns observed.",
          "No further evaluation typically required unless clinically indicated.",
        ],
        'Fair': [
          "Indicates Moderate elevation in fermentation activity.",
          "Correlating with slight increases in hydrogen production. This may be associated with early dysbiosis or mild inefficiencies in carbohydrate absorption. Occasional bloating or digestive discomfort may be reported.",
          "urther assessment of gut fermentation trends may be considered if symptoms persist.",
        ],
        'Poor': [
          "Suggests Significant fermentation imbalance.",
          "Correlating with markedly elevated hydrogen levels. May reflect considerable dysbiosis, potential carbohydrate absorption inefficiency, or excessive microbial fermentation. Bloating and digestive discomfort are likely.",
          "As a screening result, further gastrointestinal evaluation may be warranted.",
        ],
      },
      'respiratory': {
        'Good': [
          "Reflects Expiratory flow and lung capacity consistent with normal or expected ventilatory function.",
          "No clinically significant airflow limitation is suggested.",
          "No further evaluation typically required unless clinically indicated.",
        ],
        'Fair': [
          "Indicates Mild decrease in expiratory flow efficiency.",
          "May correspond to early changes in airway resistance or subtle reductions in ventilatory performance. These trends are generally observed before clinically significant airflow limitation develops.",
          "Periodic monitoring of ventilatory function may be considered depending on clinical context.",
        ],
        'Poor': [
          "Suggests Marked reduction in expiratory flow capacity.",
          "Consistent with patterns typically observed in early to moderate airflow limitation.",
          "Further clinical evaluation of pulmonary function may be considered.",
        ],
      },
      'liver': {
        'Good': [
          "Indicates Minimal hepatic stress.",
          "Liver metabolic function appears consistent with healthy trends and no significant evidence of gut-liver axis imbalance.",
          "No further evaluation typically required unless clinically indicated.",
        ],
        'Fair': [
          "Suggests Mild hepatic stress.",
          "Potentially reflecting early-stage metabolic strain, subtle alterations in liver fat metabolism or minor gut-liver axis interaction effects.",
          "Further evaluation may be considered depending on clinical context.",
        ],
        'Poor': [
          "Indicates Significant hepatic stress.",
          "Potentially reflecting liver overload or compromised metabolic processing, or patterns commonly associated with metabolic liver dysfunction.",
          "Comprehensive liver function evaluation is suggested based on the individual's clinical scenario.",
        ],
      },
    };

    Map<String, String> clinicalInsights = {
      'sugar':
          "The score reflects glucose utilization efficiency, insulin sensitivity, and metabolic flexibility. It provides an early indicator of trends in carbohydrate metabolism without quantifying exact glucose levels.",
      'gut':
          "The score reflects gut fermentation activity, microbial balance, and carbohydrate absorption efficiency. It serves as a non-invasive trend indicator of fermentation imbalance without identifying specific gastrointestinal conditions.",
      'respiratory':
          "The score reflects expiratory flow capacity, airway resistance, and ventilatory function trends. It serves as a non-invasive early indicator of changes in airflow dynamics.",
      'liver':
          "The score reflects trends in hepatic metabolic stress and gut-liver axis activity. It serves as a non-invasive screening indicator of potential liver stress without identifying specific hepatic conditions.",
    };

    Map<String, String> correlations = {
      'sugar':
          "Respyr Sugar Score correlates with fasting blood glucose and HbA1c trends based on internal studies benchmarking breath biomarkers against standard blood glucose markers.",
      'gut':
          "Respyr Gut Score correlates with global hydrogen breath test thresholds for fermentation and absorption patterns. Sensor calibration aligns with standard H₂ concentration benchmarks.",
      'respiratory':
          "Respyr Respiratory Score correlates with pulmonary function trends derived from expiratory pressure converted to FEV1 values. For correlation, individuals with doctor-confirmed respiratory issues and valid PFT reports were onboarded. Respyr’s FEV1 trends were compared with the known respiratory status of each individual — lower FEV1 corresponded with lower Respyr scores, consistent with expected airflow limitations.",
      'liver':
          "Respyr Liver Score correlates with liver function trends and imaging findings observed in individuals with known liver history, based on internal correlation studies.",
    };

    Map<String, List<String>> categoryTitles = {
      'sugar': [
        'Glucose Metabolism',
        'Respyr Score Meaning',
        'Clinical Considerations / Suggested Next Steps',
      ],
      'gut': [
        'Fermentation Activity',
        'Respyr Score Meaning',
        'Clinical Considerations / Suggested Next Steps',
      ],
      'respiratory': [
        'Airflow / Ventilation',
        'Respyr Score Meaning',
        'Clinical Considerations / Suggested Next Steps',
      ],
      'liver': [
        'Hepatic Stress',
        'Respyr Score Meaning',
        'Clinical Considerations / Suggested Next Steps',
      ],
    };

    return {
      'status': level,
      'titles': categoryTitles[category] ?? [],
      'subtitles': scoreData[category]?[level] ?? [],
      'insight': clinicalInsights[category] ?? '',
      'correlation': correlations[category] ?? '',
    };
  }
}
