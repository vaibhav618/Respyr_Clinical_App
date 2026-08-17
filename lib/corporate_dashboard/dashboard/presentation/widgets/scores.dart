import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../authentication/corporate/corporate_login/data/response/corporate_login_response.dart';
import '../../../../common/floating_message.dart';
import '../../../../common/get_score_title.dart';
import '../../../../new_result/data/model/result_model.dart';
import '../../../../new_result/data/model/result_profile_data_model.dart';
import '../../../../new_result/presentation/view/overall_result.dart';
import '../../../../new_result/presentation/view_model/result_view_model.dart';
import '../../../services/corporate_result_history_service.dart';
import '../../data/model/corporate_profile_tests_response.dart';
import 'score_card.dart';

class Scores extends StatelessWidget {
  final CorporateProfileTestItem? latestOfDate;
  final CorporateUserData corporateUserData;
  const Scores({super.key, required this.latestOfDate, required this.corporateUserData});

  double _safeToDouble(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty || s == '-' || s.toLowerCase() == 'null') return 0;
    return double.tryParse(s) ?? 0;
  }

  void _navigateToResultScreen(
      NewResultModel lifestyleJson,
      ResultProfileDataModel profileDetails,
      ) {
    if (Get.isOverlaysOpen) {
      Get.back();
    }

    Get.offAll(
          () => ChangeNotifierProvider(
        create: (_) => ResultViewModel()..initialize(profileDetails),
        child: ResultScreen(
          userResultData: lifestyleJson,
          userProfileData: profileDetails,
          blowValuesList: const [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ if latestOfDate is null, everything becomes 0
    final sugar = _safeToDouble(latestOfDate?.dbScore);
    final respiratory = _safeToDouble(latestOfDate?.blowScore);
    final liver = _safeToDouble(latestOfDate?.liverScore);
    final gut = _safeToDouble(latestOfDate?.gutScorePer);

    // Section on the page, not a grey box: heading in the standard section
    // style, the four tiles as bordered cards, tight spacing. The old block
    // put 43-50px voids between rows inside a background-coloured container.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text(
                  "Today's scores",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                Column(
                  spacing: 10,
                  children: [
                    Row(
                      spacing: 12,
                      children: [
                        ScoreCard(
                          scoreName: getScoreTitle(isCorporate: true, score: ScoreType.sugar),
                          score: sugar,
                        ),
                        ScoreCard(
                          scoreName: getScoreTitle(isCorporate: true, score: ScoreType.respiratory),
                          score: respiratory,
                        ),
                      ],
                    ),
                    Row(
                      spacing: 12,
                      children: [
                        ScoreCard(
                          scoreName: getScoreTitle(isCorporate: true, score: ScoreType.liver),
                          score: liver,
                        ),
                        ScoreCard(
                          scoreName: getScoreTitle(isCorporate: true, score: ScoreType.gut),
                          score: gut,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
            child: TextButton(
              onPressed: () async{
                try {
                  final result =
                  await CorporateResultHistoryService().fetchSingleResult(
                    id: latestOfDate!.id,
                    loginId: latestOfDate!.loginId,
                    profileId: latestOfDate!.profileId,
                  );

                  final profileDetails = ResultProfileDataModel(
                    email: corporateUserData.email,
                    subjectId: corporateUserData.subjectId,
                    clinicName: corporateUserData.clinicName,
                    profileName: corporateUserData.profileName,
                    gender: corporateUserData.gender,
                    age: int.tryParse(corporateUserData.age) ?? 0,
                    height: double.tryParse(corporateUserData.height) ?? 0,
                    weight: double.tryParse(corporateUserData.weight) ?? 0,
                    region: corporateUserData.region,
                    dttm: corporateUserData.dttm,
                    role: "corporate",
                  );

                  _navigateToResultScreen(result, profileDetails);
                } catch (e) {
                  if (context.mounted) {
                    FloatingMessage.show(context, message: "Failed to load result. Please try again.", type: FloatingMessageType.error);
                  }
                }


              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Text(
                    "View full result",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF308BF9),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF308BF9),
                    size: 20,
                  )
                ],
              ),
            ),
            ),
          ],
        ),
    );
  }
}
