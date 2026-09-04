/// Node.js backend endpoints the app uses.
///
/// Routes are grouped by domain on the backend (auth / profiles / clinic /
/// results / corporate / support / notifications). Every endpoint is a POST
/// with a JSON body, except:
///   * support image bytes ([getIssueImage] style) — served by the backend as a
///     GET and loaded directly as an image URL, so it is not listed as a call.
///   * [raiseIssue] — uploads image files, so it stays multipart/form-data.
///
/// Nothing outside this file may hardcode an endpoint. To move a route, change
/// it HERE and every call site follows.
class NodeUrls {
  // ---------------------------------------------------------------------------
  // Base URLs
  // ---------------------------------------------------------------------------
  /// Node server root. Point this at the deployed Node backend (or a local
  /// dev instance, e.g. 'http://192.168.1.x:3000/') — every route below
  /// hangs off it.
  // Local Node dev backend (PC on same Wi-Fi). Prod Lambda value kept below.
  static const String entryPoint = 'http://192.168.1.20:3000/';
  // static const String entryPoint =
  //     'https://ruewg5tlnwxpe4k43u77aeg4ka0qiqwj.lambda-url.ap-south-1.on.aws/';

  static const String _api = '${entryPoint}api';

  /// Base for the endpoints still on the original PHP server
  /// (corporateForgotPassword). Kept here so the app references only NodeUrls.
  //   static const String _php = 'https://humorstech.com/';
  static const String _php =
      'https://ruewg5tlnwxpe4k43u77aeg4ka0qiqwj.lambda-url.ap-south-1.on.aws/';

  // ---------------------------------------------------------------------------
  // Authentication  (/api/auth)
  // ---------------------------------------------------------------------------
  static const String validateLoginWithPassword = '$_api/auth/login';
  static const String generateJwtToken = '$_api/auth/token';

  // ---------------------------------------------------------------------------
  // Profiles / subjects  (/api/profiles)
  // ---------------------------------------------------------------------------
  static const String getSubjects = '$_api/profiles/list';
  static const String fetchClinicSubjectsProfile = '$_api/profiles/clinic-subjects';
  static const String createUserProfile = '$_api/profiles/create';
  static const String updateUserRegion = '$_api/profiles/region';

  // ---------------------------------------------------------------------------
  // Clinic  (/api/clinic)
  // ---------------------------------------------------------------------------
  static const String fetchClinicDetails = '$_api/clinic/data';
  static const String checkTestCounts = '$_api/clinic/test-counts';
  static const String fetchLogo = '$_api/clinic/logo';

  // ---------------------------------------------------------------------------
  // Tests / results / scores  (/api/results)
  // ---------------------------------------------------------------------------
  static const String resultAnalysis = '$_api/results/analyze';
  static const String resultAnalysis2 = '$_api/results/analyze2';
  static const String fetchHistory = '$_api/results/history';
  static const String fetchSubjectProfile = '$_api/results/profile-log';
  static const String fetchTestLog = '$_api/results/test-log';
  static const String scoreInterpretation = '$_api/results/interpretation';
  static const String fetchOverallDataByDate = '$_api/results/overall-by-date';
  static const String allClinicScore = '$_api/results/clinic-score';
  static const String productionCalculation = '$_api/results/production';
  static const String fetchLastDataTime = '$_api/results/last-data-time';

  // ---------------------------------------------------------------------------
  // Corporate  (/api/corporate)
  // ---------------------------------------------------------------------------
  static const String corporateLogin = '$_api/corporate/login';
  static const String checkCorporateId = '$_api/corporate/check-id';
  static const String insertCorporateProfile = '$_api/corporate/register';
  static const String fetchCorporateProfile = '$_api/corporate/profile';
  static const String corporateProfileTests = '$_api/corporate/tests';
  static const String fetchCorporateHistory = '$_api/corporate/history';
  // Not on Node — original PHP (email/SMTP flow).
  static const String corporateForgotPassword =
      '${_php}humors_app/app_final/clinical/corporate_forgot_password_api.php';

  // ---------------------------------------------------------------------------
  // Help & support  (/api/support)
  // ---------------------------------------------------------------------------
  static const String raiseIssue = '$_api/support/raise-issue';
  static const String fetchIssues = '$_api/support/issues';
  static const String supportWhatsApp =
      'https://wa.me/8296380628?text=Hi%2C%20I%20need%20some%20help';

  // ---------------------------------------------------------------------------
  // Notifications  (/api/notifications)
  // ---------------------------------------------------------------------------
  static const String saveFcmToken = '$_api/notifications/fcm-token';

  // ---------------------------------------------------------------------------
  // External web pages
  // ---------------------------------------------------------------------------
  static const String termsAndConditions =
      'https://respyr.in/terms-conditions/';
  static const String privacyPolicy = 'https://respyr.in/privacy_policy/';
  static const String forgotPasswordPortal =
      'https://portal.respyr.in/clinical/login-port/forgot-password/?appshow=true';
}
