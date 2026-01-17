import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../authentication/corporate/corporate_login/data/response/corporate_login_response.dart';
import '../../../../common/floating_message.dart';
import '../../../../new_result/data/model/result_model.dart';
import '../../../../new_result/data/model/result_profile_data_model.dart';
import '../../../../new_result/presentation/view/overall_result.dart';
import '../../../../new_result/presentation/view_model/result_view_model.dart';
import '../../../../utils/score_color_helper.dart';
import '../../../../utils/score_status_helper.dart';
import '../../../services/corporate_result_history_service.dart';
import '../../data/model/corporate_profile_tests_response.dart';

class TimelineItem extends StatelessWidget {
  final CorporateUserData corporateUserData;
  final CorporateProfileTestItem corporateProfileTestItem;

  const TimelineItem({
    super.key,
    required this.corporateProfileTestItem,
    required this.corporateUserData,
  });

  DateTime? _parseDttm(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;

    try {
      final parts = v.split(' ');
      if (parts.isEmpty) return null;

      final datePart = parts[0]; // MM/DD/YYYY
      final timePart = parts.length > 1 ? parts[1] : "00:00:00";

      final d = datePart.split('/');
      if (d.length != 3) return null;

      final mm = int.tryParse(d[0]) ?? 0;
      final dd = int.tryParse(d[1]) ?? 0;
      final yyyy = int.tryParse(d[2]) ?? 0;

      final t = timePart.split(':');
      final hh = t.isNotEmpty ? int.tryParse(t[0]) ?? 0 : 0;
      final min = t.length > 1 ? int.tryParse(t[1]) ?? 0 : 0;
      final sec = t.length > 2 ? int.tryParse(t[2]) ?? 0 : 0;

      if (yyyy <= 0 || mm <= 0 || dd <= 0) return null;

      return DateTime(yyyy, mm, dd, hh, min, sec);
    } catch (_) {
      return null;
    }
  }

  String _formatDttmLabel(String raw) {
    final dt = _parseDttm(raw);
    if (dt == null) return raw;

    final formatted = DateFormat("dd MMM yyyy hh:mm a").format(dt);
    return formatted.replaceAll("AM", "am").replaceAll("PM", "pm");
  }

  double _safeDouble(String? v) {
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
    final dttmLabel = _formatDttmLabel(corporateProfileTestItem.dttm);
    final sugarScore = _safeDouble(corporateProfileTestItem.dbScore);

    return InkWell(
      onTap: () async{
        try {
          final result =
              await CorporateResultHistoryService().fetchSingleResult(
            id: corporateProfileTestItem.id,
            loginId: corporateProfileTestItem.loginId,
            profileId: corporateProfileTestItem.profileId,
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
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 20,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.topCenter,
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 3,
                      height: double.infinity,
                      color: const Color(0xFFE4F0FF),
                    ),
                  ),
                  const Positioned(
                    top: 20,
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFC7C6CE),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        dttmLabel,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFA1A1A1),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          height: 1.10,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            "${sugarScore.toStringAsFixed(0)}%",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF252525),
                              fontSize: 25,
                              fontWeight: FontWeight.w400,
                              height: 1.10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF535359),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${ScoreStatusHelper.getScoreTitle(sugarScore)}!",
                            style: GoogleFonts.poppins(
                              color: ScoreColorHelper.getScoreColor(sugarScore),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  IconButton(
                    onPressed: () async {
                      try {
                        final result =
                        await CorporateResultHistoryService().fetchSingleResult(
                          id: corporateProfileTestItem.id,
                          loginId: corporateProfileTestItem.loginId,
                          profileId: corporateProfileTestItem.profileId,
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
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      backgroundColor: const Color(0xFFE4F0FF),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_right_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
