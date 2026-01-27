import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:respyr_clinical/authentication/corporate/forgot_password/corporate_forgot_password.dart';
import 'package:respyr_clinical/authentication/screens/login_with_password.dart';
import 'package:upgrader/upgrader.dart';

import '../authentication/corporate/check_corporate_id/presentation/check_corporate_id_screen.dart';
import '../authentication/corporate/corporate_login/data/response/corporate_login_response.dart';
import '../authentication/corporate/corporate_login/presentation/screens/corporate_login.dart';
import 'package:respyr_clinical/authentication/corporate/corporate_sign_up/presentation/corporate_sign_up.dart';
import 'package:respyr_clinical/authentication/corporate/corporate_sign_up/presentation/account_creation_success.dart';
import 'package:respyr_clinical/authentication/corporate/set_password/presentation/screens/set_password.dart';

import '../authentication/screens/login_screen.dart';
import '../authentication/sign_in/presentation/screens/sign_in.dart';
import '../clinical_dashboard/bloc/health_score_bloc.dart';
import '../clinical_dashboard/service/overall_data_by_date_service.dart';
import '../clinical_dashboard/views/clinical_dashboard.dart';
import '../corporate_dashboard/profile/presentation/screens/corporate_profile.dart';
import '../corporate_dashboard/dashboard/presentation/screens/corporate_dashboard.dart';
import '../new_result/data/model/result_model.dart';
import '../new_result/data/model/result_profile_data_model.dart';
import '../new_result/presentation/view/overall_result.dart';
import '../new_result/presentation/view_model/result_view_model.dart';
import '../splash/corporate_splash.dart';
import '../splash/splash.dart';
import 'app_routers.dart';

class AppPages {
  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () {
        // ✅ Read at runtime (NOT as instance variable)
        final storage = GetStorage();
        final savedRole = (storage.read('role') ?? '').toString().toLowerCase();

        Widget child;


        if (savedRole == "clinical") {
          child = const Splash();
        } else if (savedRole == "corporate") {
          child = const CorporateSplash();
        } else {
          child = const SignIn();
        }

        return UpgradeAlert(
          upgrader: Upgrader(),
          child: child,
        );
      },
    ),

    GetPage(name: AppRoutes.signIn, page: () => const SignIn()),
    GetPage(name: AppRoutes.clinicalLogin, page: () => const LoginWithPassword()),
    GetPage(name: AppRoutes.corporateLogin, page: () => const CorporateLogin()),

    GetPage(
      name: AppRoutes.corporateSignUp,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final clinicName = (args?['clinic_name'] ?? '').toString();
        return CorporateSignUp(clinicName: clinicName);
      },
    ),

    GetPage(
      name: AppRoutes.setNewPassword,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final subjectId = (args?['subject_id'] ?? '').toString();
        return SetPassword(subjectId: subjectId);
      },
    ),

    GetPage(
      name: AppRoutes.corporateProfile,
      page: () {
        final CorporateUserData? data =
        Get.arguments as CorporateUserData?;
        return CorporateProfile(
          corporateUserData: data!,
        );
      },
    ),


    GetPage(
      name: AppRoutes.accountCreationSuccess,
      page: () => const AccountCreationSuccessScreen(),
    ),

    GetPage(
      name: AppRoutes.validateCorporateId,
      page: () => const CheckCorporateIdScreen(),
    ),

    GetPage(
      name: AppRoutes.corporateForgotPassword,
      page: () => const CorporateForgotPassword(),
    ),


    GetPage(
      name: AppRoutes.corporateDashboard,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;

        // ✅ allow both keys (corporate_id / clinic_name), so your earlier code won't break
        final corporateId =
        (args?['corporate_id'] ?? args?['clinic_name'] ?? '').toString();

        final email = (args?['email'] ?? '').toString();

        return CorporateDashboard(
          email: email,
          corporateId: corporateId,
        );
      },
    ),


    GetPage(
      name: AppRoutes.finalResultPage,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;

        final NewResultModel lifestyleJson = args?['lifestyle_json'] as NewResultModel;
        final ResultProfileDataModel profileDetails =
        args?['profile_details'] as ResultProfileDataModel;

        final List<double> blowValuesList =
            (args?['blow_values_list'] as List?)?.cast<double>() ?? <double>[];

        // ✅ role default + persist (so splash routing works next time)
        final storage = GetStorage();
        final role = (profileDetails.role ?? 'clinical').toLowerCase();
        storage.write('role', role);

        return ChangeNotifierProvider(
          create: (_) => ResultViewModel()..initialize(profileDetails),
          child: ResultScreen(
            userResultData: lifestyleJson,
            userProfileData: profileDetails,
            blowValuesList: blowValuesList,
          ),
        );
      },
    ),


    GetPage(
      name: AppRoutes.mainDashboard,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;

        final profileDetails = args?['profile_details'];
        if (profileDetails is! ResultProfileDataModel) {
          // Fallback screen if arguments are missing
          return const SignIn();
        }

        final storage = GetStorage();
        final role = (profileDetails.role ?? 'clinical').toString().toLowerCase();
        storage.write('role', role);
        return BlocProvider(
          create: (_) => HealthScoreBloc(OverallDataByDateService()),
          child: role == 'corporate'
              ? CorporateDashboard(
            email: (profileDetails.email ?? 'NA'),
            corporateId: (profileDetails.clinicName ?? ''),
          )
              : ClinicalDashboardMain(
            loginId: profileDetails.clinicName ?? '',
          ),
        );
      },
    ),


  ];
}
