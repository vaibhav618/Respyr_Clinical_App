class ResString {
  //Onboarding Screen Titles
  static const String onboardingTitle1 = "A breath is all it takes";
  static const String onboardingTitle2 = "Track it. Better it.";
  static const String onboardingTitle3 = "Four-in-One";
  static const String onboardingSubTitle1 =
      "Breath based technology to simplify health and lifestyle tracking";
  static const String onboardingSubTitle2 =
      "Track multiple health and lifestyle parameters, receive personalized suggestions";
  static const String onboardingSubTitle3 =
      "Add upto four profiles in one account, great for you and your loved ones";

  // Respyr Titles
  static const String adRespyrTitle =
      "Take your first step toward a better health life with respyr. ";

  // Login Titles
  static const String letGetStarted = "Let's Get Started";
  static const String forgetPassword = "\t\t\tForget Password";
  static const String notificationReceived =
      "Receive notification alerts and newsletter from respyr  ";

  // Existing profile Titles
  static const String profileText = "Who’s Profile ?";
  static const String selectProfileTitle =
      "Select or add a profile that can be personalized to you ";
  static const String maxProfile =
      "You can add maximum of 4 profile to your account";

  // Show Dialog Box Title
  static const String accessGranted = "Access Granted";

  // BMI score Title
  static const String bmiText = "BMI";
  static const String bmiScoreTitle = "Your BMI score is";
  static const String bmiScoreSubTitle = "Kg/m2";
  static const String bmiDobLabel = "DD/MM/YYYY";

  // Water Level Title
  static const String waterLevelTitle = "How much water do you consume daily?";

  // Smoking Question
  static const String smokeQuestionTitle =
      "How much did you smoke in the last 24 hours?";
  static const String cigarettes = "Cigarettes";

  // Alcohol Consuming Question
  static const String alcoholQuestionTitle =
      "Did you consumed any alcohol in the last 24 hours?";

  // Exercise Question
  static const String exerciseQuestionTitle =
      "How many minutes did you exercise in the last 24 hours?";
  static const String genderTitle = "What’s your gender?";
  static const String genderMale = "Male";
  static const String genderFemale = "Female";

  // Height and Weight Title
  static const String heightTitle = "How tall are you?";
  static const String weightTitle = "How much do you weigh?";
  static const String inch = "INCHES";
  static const String feet = "FEET";
  static const String bmiUnderWeight = "Under Weight";
  static const String bmiNormal = "Normal";
  static const String bmiOverWeight = "Over Weight";
  static const String bmiObese = "Obese";

  // Date Of Birth Title
  static const String dateOfBirthTitle = "What's Your date of birth?";
  static const String profileCreationSubTitle =
      "This is used to get accurate health status";

  // Habit Question Title
  static const String habitTitle = "Other Habits";
  static const String alcoholQuestion = "Do You\nConsume Alcohol?";
  static const String nonVegQuestion = "Do You\nEat Non-Veg?";
  static const String smokeQuestion = "Do You\nSmoke?";
  static const String exerciseQuestion = "Do You\nExercise?";

  // Habit Options Title
  static const String neverOption = "Never";
  static const String occasionallyOption = "Occasionally";
  static const String regularlyOption = "Regularly";
  static const String sedentaryOption = "Sedentary (little or no exercise)";
  static const String lightlyOption = "Lightly (1-3 days/week)";
  static const String moderateOption = "Moderately (3-5 days/week)";
  static const String activelyOption = "Actively (6-7 days/week)";
  static const String veryActivelyOption = "VeryActively (daily)";

  // Nutrition Question
  static const String nutritionQuestionTitle =
      "What did you eat in the last 24 hours?";
  static const String mealsAddedContainer = "Meals Added";
  static const String addMealsContainer = "Add Meal";
  static const String addAMealsContainer = "Add a meal";
  static const String nutritionContainerSubTitle =
      "Food is essential to maintain your lifestyle.";

  // Sleep Question
  static const String sleepQuestionTitle = "How is your sleep routine?";
  static const String sleepSurveyTitle =
      "Adjust the duration that matches your sleep schedule";

  // Mental Issue Question
  static const String mentalIssueQuestionTitle =
      "Are you struggling from any of the following mental conditions ?";
  static const List<String> mentalIssueCheckBox = [
    'None',
    'Depression',
    'Anxiety/ Stress',
    'Post-Traumatic Stress Disorder (PTSD)',
    'Schizophrenia',
    'Eating Disorders',
    'Disruptive behaviour and dissocial disorders',
    'Autism spectrum',
    'Attention deficit hyperactivity disorder (ADHD)',
  ];

  static Map<String, bool> mentalIssueOptions = {
    'None': false,
    'Depression': false,
    'Anxiety/ Stress': false,
    'Post-Traumatic Stress Disorder (PTSD)': false,
    'Schizophrenia': false,
    'Eating Disorders': false,
    'Disruptive behaviour and dissocial disorders': false,
    'Autism spectrum': false,
    'Attention deficit hyperactivity disorder (ADHD)': false,
  };

  // LifeStyle Score Title
  static const String lifestyleText = "LifeStyle";
  static const String personalInfoText = "Personal Info";
  static const String lifestyleScoreTitle = "Your lifestyle score is\n";
  static const String lifestyleScoreSubTitle = "\nout of 100";
  static const String lifestyleScoreButton = "Continue To Medical History";
  static const String lifestyleScoreGreat = "Great!";
  static const List<String> alcoholConsumedOptions = [
    "Yes",
    "NO! Not for me..",
  ];

  // Medical History Title
  static const String medicalHistoryText = "Medical History";
  static const String medicalHistoryTitle =
      "Have you taken blood test recently ?";
  static const String medicalIssueTitle =
      "Are you suffering from any of the following conditions ?";
  static const String sugarLevelTitle = "What’s your fasting sugar level ?";

  // Recent Test Radio Button List
  static const List<String> recentTestOptions = [
    "Within 6 months",
    "Over 6 months",
    "I don’t remember / Never",
  ];

  // Medical Issue Check Box List
  static const List<String> medicalIssueCheckBox = [
    'None',
    'Diabetes',
    'Lung Issues',
    'Lipid issues',
    'Kidney Issues',
    'Liver Issues',
  ];
  static Map<String, bool> medicalIssueOptions = {
    'None': false,
    'Diabetes': false,
    'Lung Issues': false,
    'Lipid issues': false,
    'Kidney Issues': false,
    'Liver Issues': false,
  };

  // Sugar Level Radio Button List
  static const List<String> sugarLevelOptions = [
    "<100 mg/dl",
    "Between 100 - 126 mg/dl",
    "Between 126 - 140 mg/dl",
    "Between 140 - 200 mg/dl",
    ">200 mg/dl",
  ];

  // OTP screen Title
  static const String otpSent = "An OTP has been sent to ";
  static const String verificationSent =
      "A verification OTP has been sent to \n";

  // Profile Created Screen
  static const String profileCreatedTitle =
      "Yay! Get ready to take your first test.";
  static const String profileCreatedSubTitle =
      "Your Profile Has Been Successfully Created!";

  // Device Connectivity Screen
  static const String connectedDeviceSubTitle = "All set... Let’s go!";
  static const String notConnectedDeviceSubTitle =
      "Connect your respyr device to phone via bluetooth";
  static const String connectedDeviceTitle = "Device Connected";
  static const String notConnectedDeviceTitle = "Device Not Connected";
  static const String issuewithDevice = "issue with connection?";
  static const String respyrDeviceName = "Respyr Kiosk Device";

  // Buttons text
  static const String skip = "Skip";
  static const String back = "Back";
  static const String next = "Next";
  static const String resendOtp = "Resend OTP";
  static const String getStarted = "Get Started";
  static const String buyNow = "Buy Now";
  static const String getOtp = "Get OTP";
  static const String addProfile = "ADD PROFILE";
  static const String loginWithPassword = "Login with password";
  static const String updatePassword = "Update password";
  static const String noThanks = "No Thanks";
  static const String buildYourHealth = "Build Your Health Profile";
  static const String alreadyRespyr = "I already have a respyr device";
  static const String bmiScoreButton = "Let’s Track Your Lifestyle";
  static const String profileCreatedButton = "Take Your First Reading";
}
