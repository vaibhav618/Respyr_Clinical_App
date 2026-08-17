/// Single source of truth for every API endpoint and external link used in the app.
///
/// All backend calls go through `humorstech.com` (PHP API). Endpoints are
/// grouped by feature area. Do NOT hardcode URLs anywhere else in the app —
/// add them here and reference them as `Urls.<name>`.
class Urls {
  // ---------------------------------------------------------------------------
  // Base URLs
  // ---------------------------------------------------------------------------
  static const String entryPoint = 'https://humorstech.com/';
  static const String _appFinal = '${entryPoint}humors_app/app_final';
  static const String _clinical = '$_appFinal/clinical';
  static const String _clinicalApi = '$_clinical/api';

  /// Base for the clinical insert APIs (used by create-profile service).
  static const String clinicalInsertBase = '$_clinicalApi/insert/';

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------
  static const String generateJwtToken =
      '$_clinicalApi/generate/generate_jwt_token.php';
  static const String validateLoginWithPassword =
      '$_clinicalApi/fetch/validate_login_with_password.php';

  // ---------------------------------------------------------------------------
  // Corporate
  // ---------------------------------------------------------------------------
  static const String corporateLogin = '$_clinical/corporate_login.php';
  static const String corporateForgotPassword =
      '$_clinical/corporate_forgot_password_api.php';
  static const String checkCorporateId = '$_clinical/check_corporate_id.php';
  static const String insertCorporateProfile =
      '$_clinical/insert_corporate_profile.php';
  static const String fetchCorporateProfile =
      '$_clinical/fetch_corporate_profile.php';
  static const String corporateProfileTests =
      '$_clinical/corporate_profile_tests.php';
  static const String fetchCorporateHistory =
      '$_clinical/fetch_corporate_history.php';

  // ---------------------------------------------------------------------------
  // Profiles / subjects
  // ---------------------------------------------------------------------------
  static const String fetchClinicSubjectsProfile =
      '$_appFinal/fetch_clinic_subjects_profile.php';
  static const String fetchSubjectProfile =
      '$_clinicalApi/fetch/fetch_profile_data_test_log2.php?';
  static const String getSubjects = '$_clinicalApi/fetch/get_subjects.php';
  static const String updateUserRegion =
      '$_clinicalApi/update/update_profile_region.php';

  // ---------------------------------------------------------------------------
  // Clinic
  // ---------------------------------------------------------------------------
  static const String fetchClinicDetails =
      '$_clinicalApi/fetch/get_clinic_data.php';
  static const String checkTestCounts =
      '$_clinicalApi/fetch/check_test_counts.php';
  static const String fetchLogo = '$_clinical/fetch_logo1.php';

  // ---------------------------------------------------------------------------
  // Tests / results / scores
  // ---------------------------------------------------------------------------
  static const String resultAnalysis =
      '$_clinicalApi/fetch/result_analysis.php';
  static const String resultAnalysis2 =
      '$_clinicalApi/fetch/result_analysis2.php';
  static const String fetchHistory = '$_clinicalApi/fetch/fetch_history.php';
  static const String scoreInterpretation =
      '$_clinical/get_score_interpretation.php';
  static const String fetchTestLog = '$_clinicalApi/fetch/all_test_data.php?';
  static const String fetchOverallDataByDate =
      '$_clinicalApi/fetch/overall_data_by_date.php';
  static const String allClinicScore =
      '${entryPoint}humors/json_curl/all_clinic_score.php';
  static const String fetchLastDataTime =
      '$_clinicalApi/fetch/fetch_last_data_time2.php';
  static const String productionCalculation =
      '${entryPoint}humorscalculation/production.php';

  // ---------------------------------------------------------------------------
  // Help & support
  // ---------------------------------------------------------------------------
  static const String raiseIssue = '$_clinicalApi/insert/raise_issue.php';
  static const String fetchIssues = '$_clinicalApi/fetch/fetch_issues2.php';
  static const String supportWhatsApp =
      'https://wa.me/8296380628?text=Hi%2C%20I%20need%20some%20help';

  // ---------------------------------------------------------------------------
  // Notifications / logging
  // ---------------------------------------------------------------------------
  static const String saveFcmToken = '$_clinicalApi/insert/save_fcm_token.php';
  static const String appErrorReport =
      '${entryPoint}log_manager/app_error_report.php';
  static const String logger = '${entryPoint}log_manager/logger.php';

  // ---------------------------------------------------------------------------
  // External web pages
  // ---------------------------------------------------------------------------
  static const String termsAndConditions =
      'https://respyr.in/terms-conditions/';
  static const String privacyPolicy = 'https://respyr.in/privacy_policy/';
  static const String forgotPasswordPortal =
      'https://portal.respyr.in/clinical/login-port/forgot-password/?appshow=true';
}
