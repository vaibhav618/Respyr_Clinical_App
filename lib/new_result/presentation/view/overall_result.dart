import 'package:flutter/material.dart';
import 'package:respyr_clinical/widgets/shimmer_placeholders.dart';
import 'package:get/get.dart';
import 'package:respyr_clinical/shared/urls.dart';

import '../../../router/app_routers.dart';
import '../../data/model/result_model.dart';
import '../../data/model/result_profile_data_model.dart';
import '../../data/model/corporate_interpretation.dart';
import '../../data/services/corporate_interpretation_service.dart';
import '../widgets/corporate_result_screen.dart';
import '../widgets/non_corporate_screen.dart';

class ResultScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final role =
    (userProfileData.role ?? 'clinical').toLowerCase();
    final isCorporate = role == 'corporate';

    if (!isCorporate) {
      return NonCorporateResultScreen(
        navigateToDashboard: _navigateToDashboard,
        userResultData: userResultData,
        userProfileData: userProfileData,
      );
    }

    return FutureBuilder<CorporateInterpretation>(
      future: CorporateInterpretationService(
        apiUrl: Urls.scoreInterpretation,
      ).fetchCorporateInterpretation(
        energyUtilization: userResultData.sugarScore,
        digestiveBalance: userResultData.gutScore,
        breathingEfficiency: userResultData.respiratoryScore,
        metabolicLoad: userResultData.liverScore,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(child: ListShimmer(rows: 5, rowHeight: 110)),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Failed to load interpretation',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.success) {
          return const Scaffold(
            body: Center(child: Text('No interpretation data')),
          );
        }


        CorporateInterpretation interpretation = snapshot.data!;
        for (final score in interpretation.scores) {
          debugPrint('-------------------------');
          debugPrint('Score Name : ${score.scoreName}');
          debugPrint('Score Value: ${score.scoreValue}');
          debugPrint('Category   : ${score.category}');
          debugPrint('Range      : ${score.range}');
          debugPrint('Marker     : ${score.mainMarker.name}');
          debugPrint('Meaning    : ${score.bandDetails.meaning}');
          debugPrint('Action     : ${score.bandDetails.suggestedAction}');
          debugPrint('Action     : ${score.wellnessInsight}');
        }


        return CorporateResultScreen(
          navigateToDashboard: _navigateToDashboard,
          userResultData: userResultData,
          userProfileData: userProfileData, corporateInterpretation: snapshot.data!,
          // 👉 later you can pass interpretation data if needed
          // interpretation: snapshot.data!,
        );
      },
    );
  }

  void _navigateToDashboard() {
    if (Get.isOverlaysOpen) {
      Get.back();
    }

    Get.offAllNamed(
      AppRoutes.mainDashboard,
      arguments: {
        'profile_details': userProfileData,
      },
    );
  }
}
