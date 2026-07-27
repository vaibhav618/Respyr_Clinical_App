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
  static const String sendOtp = '$_appFinal/send_otp2.php';
  static const String checkLoginId = '$_appFinal/check_otp2.php';
  static const String getClinicalId = '$_appFinal/get_clinical_id.php';
  static const String generateJwtToken =
      '$_clinicalApi/generate/generate_jwt_token.php';
  static const String validateLoginWithPassword =
      '$_clinicalApi/fetch/validate_login_with_password.php';
  static const String checkPhoneNumberExists =
      '$_appFinal/check_phone_number.php';
  static const String checkEmailExists = '$_appFinal/check_email_exist.php';
  static const String checkUserNameExists = '$_appFinal/check_name_exist.php';
  static const String updateUserPassword = '$_appFinal/update_password.php';
  static const String createAndCheckUserPassword =
      '$_appFinal/check_password.php';

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
  static const String selectProfileNew = '$_appFinal/select_profile.php';
  static const String getLoginId = '$_appFinal/fetch_profile_counts.php';
  static const String checkProfileCount = '$_appFinal/fetch_profile_counts.php';
  static const String newProfileCreation = '$_appFinal/add_new_profile.php';
  static const String createPatientProfile =
      '$_appFinal/create_patient_profile.php';
  static const String fetchClinicSubjectsProfile =
      '$_appFinal/fetch_clinic_subjects_profile.php';
  static const String fetchUserProfileService =
      '$_appFinal/fetch_profile_data.php';
  static const String fetchSubjectProfile =
      '$_clinicalApi/fetch/fetch_profile_data_test_log2.php?';
  static const String getSubjects = '$_clinicalApi/fetch/get_subjects.php';
  static const String updateUserPersonalInfo =
      '$_appFinal/update_persnoal_info.php';
  static const String updatePersonalInfo =
      '$_appFinal/update_persnoal_info.php';
  static const String updateUserHobbies = '$_appFinal/update_hobbies_data.php';
  static const String updateLifeStyleInfo =
      '$_appFinal/update_hobbies_data.php';
  static const String updateMedicalHistoryInfo =
      '$_appFinal/update_medical_history.php';
  static const String updateUserRegion =
      '$_clinicalApi/update/update_profile_region.php';
  static const String addHobbies = '$_appFinal/add_hobbies.php';
  static const String addBloodReport = '$_appFinal/add_blood_report.php';
  static const String deleteAccountApi = '$_appFinal/delete_account.php';
  static const String profileDeletionApi = '$_appFinal/delete_profile.php';

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
  static const String trend7Days = '$_clinical/trend_7_days.php';
  static const String allClinicScore =
      '${entryPoint}humors/json_curl/all_clinic_score.php';
  static const String fetchLastDataTime =
      '$_clinicalApi/fetch/fetch_last_data_time2.php';
  static const String processRawData =
      '${entryPoint}humorscalculation/production.php?';
  static const String productionCalculation =
      '${entryPoint}humorscalculation/production.php';
  static const String fetchLifeStyleScore =
      '${entryPoint}humors/json_curl/life_style.php';
  static const String dbVital = '${entryPoint}humors/json_curl/db_vital.php?';
  static const String fetchMonthFlChartData = '$_appFinal/trends/test53.php';
  static const String fetchDayFlchartData =
      '$_appFinal/trends/dashboard_trend_by_date.php';

  // ---------------------------------------------------------------------------
  // Raphacure
  // ---------------------------------------------------------------------------
  static const String raphacureBase = '$_clinicalApi/fetch/raphacure';
  static const String fetchUserdata = '$raphacureBase/check_profile.php';
  static const String fetchOverallData = '$raphacureBase/user_overall_data.php';
  static const String fetchRaphacureResult = '$raphacureBase/fetch_result.php?';

  // ---------------------------------------------------------------------------
  // Help & support
  // ---------------------------------------------------------------------------
  static const String raiseIssue = '$_clinicalApi/insert/raise_issue.php';
  static const String fetchIssues = '$_clinicalApi/fetch/fetch_issues2.php';
  static const String supportWhatsApp =
      'https://wa.me/8296380628?text=Hi%2C%20I%20need%20some%20help';

  // ---------------------------------------------------------------------------
  // Notifications / logging / app updates
  // ---------------------------------------------------------------------------
  static const String saveFcmToken = '$_clinicalApi/insert/save_fcm_token.php';
  static const String appErrorReport =
      '${entryPoint}log_manager/app_error_report.php';
  static const String logger = '${entryPoint}log_manager/logger.php';
  static const String appVersionJson = '$_clinical/app_version.json';

  // ---------------------------------------------------------------------------
  // Food (consumer app leftovers — kept for compatibility)
  // ---------------------------------------------------------------------------
  static const String fetchFoodMenu = '$_appFinal/food/fetch_food2.php';
  static const String fetchFoodMenuById =
      '$_appFinal/food/fetch_food_data_by_id.php';
  static const String fetchFoodQuantity = '$_appFinal/food/food_amount3.php';

  // ---------------------------------------------------------------------------
  // External web pages
  // ---------------------------------------------------------------------------
  static const String termsAndConditions =
      'https://respyr.in/terms-conditions/';
  static const String privacyPolicy = 'https://respyr.in/privacy_policy/';
  static const String forgotPasswordPortal =
      'https://portal.respyr.in/clinical/login-port/forgot-password/?appshow=true';

  // ---------------------------------------------------------------------------
  // Placeholder (endpoint never implemented — kept so the code still compiles)
  // ---------------------------------------------------------------------------
  static const String clinicFetch =
      'https://yourdomain.com/api/clinic_fetch.php';
}
