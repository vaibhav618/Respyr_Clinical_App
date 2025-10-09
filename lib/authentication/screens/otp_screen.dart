import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:respyr_clinical/authentication/screens/login_screen.dart';
import 'package:respyr_clinical/authentication/screens/terms_privacy_widget.dart';
import 'package:respyr_clinical/authentication/services/clinical_name_getx_controller.dart';
import 'package:respyr_clinical/authentication/services/clinical_id_generating_api.dart';
import 'package:respyr_clinical/authentication/services/clinical_token_generating_api.dart';
import 'package:respyr_clinical/authentication/services/otp_generating_services.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:respyr_clinical/shared/permission.dart';
import 'package:respyr_clinical/shared/text_string.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../clinical_dashboard/bloc/health_score_bloc.dart';
import '../../clinical_dashboard/service/overall_data_by_date_service.dart';
import '../../clinical_dashboard/views/clinical_dashboard.dart';

class OTPScreen extends StatefulWidget {
  final String mobileNumber;
  final String generatedOtp;
  final DateTime expirationTime;

  const OTPScreen({
    super.key,
    required this.mobileNumber,
    required this.generatedOtp,
    required this.expirationTime,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final ClinicalIdGeneratingApi _clinicalIdGeneratingApi =
      ClinicalIdGeneratingApi();
  late DateTime _expirationTime;
  late Timer _timer;
  int _start = 60;
  String loginId = '';
  String? _otpError;
  late String _generatedOtp;
  bool _isLoading = false;
  bool _isButtonEnabled = false;
  final FocusNode _otpFocusNode = FocusNode();
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final storage = GetStorage();

  @override
  void initState() {
    super.initState();
    startTimer();
    _generatedOtp = widget.generatedOtp;
    _expirationTime = widget.expirationTime;
    // Schedule the SMS permission request after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestSmsPermissions(context);
    });

    _otpController.addListener(() {
      if (_otpController.text.trim().length == 4) {
        _verifyOtp(context);
      }
    });
  }

  void startTimer() {
    setState(() {
      _isButtonEnabled = false;
      _start = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_start == 0) {
        setState(() {
          _isButtonEnabled = true;
          timer.cancel();
        });
      } else {
        setState(() => _start--);
      }
    });
  }

  void _resendOtp() async {
    setState(() {
      _isButtonEnabled = false; // Disable button to prevent multiple requests
      _otpController.clear();
    });

    final otpService = OtpGeneratingServices();
    final newOtp = otpService.generateOtp(); // Generate a new OTP
    bool isSuccess = await otpService.requestOtp(widget.mobileNumber, newOtp);

    if (isSuccess) {
      // Update the expiration time to 3 minutes from now
      setState(() {
        _generatedOtp = newOtp; // Update the OTP with the new one
        _expirationTime = DateTime.now().add(
          const Duration(minutes: 3),
        ); // New expiration time
      });

      // Restart the countdown timer
      startTimer();
    } else {
      Get.snackbar(
        'Error',
        'Failed to resend OTP',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _verifyOtp(BuildContext context) async {
    setState(() => _isLoading = true);

    final enteredOtp = _otpController.text.trim();

    if (enteredOtp.isEmpty || enteredOtp.length < 4) {
      setState(() {
        _otpError = 'Please enter a valid 4-digit OTP';
        _isLoading = false;
      });
      return;
    }

    if (DateTime.now().isAfter(_expirationTime)) {
      setState(() {
        _otpError = 'OTP has expired. Please request a new one.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _otpError = null;
    });

    final isValidOtp = await OtpGeneratingServices().verifyOtp(enteredOtp, _generatedOtp);
    if (!mounted) return;

    if (!isValidOtp) {
      setState(() {
        _otpError = 'OTP is invalid';
        _isLoading = false;
      });
      return;
    }

    _otpController.clear();
    _generatedOtp = "";

    final phoneNumber = widget.mobileNumber;
    final idResponse = await _clinicalIdGeneratingApi.fetchClinicalIdApi(phoneNumber);
    if (!mounted) return;

    if (idResponse["status"] == "error") {
      _showDialog(
        context,
        title: "No Clinical ID found",
        message: "${idResponse["message"]}\nCheck this number: $phoneNumber.\n\nIf this issue persists, please contact the admin team.",
      );
      setState(() => _isLoading = false);
      return;
    }

    final clinic = idResponse["data"][0];
    final clinicName = clinic["clinic_name"] ?? "";

    if (clinicName.isEmpty) {
      _showDialog(
        context,
        title: "Something went wrong",
        message: "Unable to retrieve Clinical ID.",
      );
      setState(() => _isLoading = false);
      return;
    }

    final jwtResult = await JwtApiHelper.fetchAndStoreJwtToken(loginId: clinicName);
    if (!mounted) return;

    if (!jwtResult.success || jwtResult.data['token'] == null) {
      _showDialog(
        context,
        title: "Authentication Failed",
        message: jwtResult.message ?? "Could not fetch JWT token.",
      );
      setState(() => _isLoading = false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('jwt_token');
    if (!mounted) return;

    if (savedToken == null || savedToken.isEmpty) {
      _showDialog(
        context,
        title: "Token Storage Error",
        message: "Failed to save JWT token. Please try again.",
      );
      setState(() => _isLoading = false);
      return;
    }

    final storage = GetStorage();
    await storage.write('isOtpVerified', true);
    await storage.write('loginClinicalName', clinicName);

    final isOtpSaved = storage.read('isOtpVerified') == true;
    final isNameSaved = storage.read('loginClinicalName') == clinicName;

    if (!mounted) return;

    if (isOtpSaved && isNameSaved) {
      final clinicController = Get.put(ClinicalController());
      clinicController.setClinicData(name: clinicName, number: phoneNumber);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => HealthScoreBloc(OverallDataByDateService()),
            child: ClinicalDashboardMain(loginId: clinicName),
          ),
        ),
            (Route<dynamic> route) => false,
      );
    } else {
      _showDialog(
        context,
        title: "Session Storage Error",
        message: "Something went wrong while saving session data.",
      );
    }

    setState(() => _isLoading = false);
  }


  void _showDialog(BuildContext context, {
    required String title,
    required String message,
  }) {
    setState(() => _isLoading = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildCustomDialog(
        title: title,
        message: message,
        buttonText: "OK",
        onPressed: () {
          final clinicController = Get.find<ClinicalController>();
          clinicController.clearData();
          Get.offAll(() => LoginScreen());
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF9FCFF),
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    final height = MediaQuery.of(context).size.height;


    return Scaffold(
      backgroundColor: AppColor.whiteColor,

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Text(
                "OTP",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF252525),
                  fontSize: 34,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -2.04,
                ),
              ),
            ),
            SizedBox(height: height * 0.025),
            Padding(
              padding:  EdgeInsets.symmetric(horizontal: 16),
              child: _buildOtpInputForm(),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.04),
            Padding(
              padding:  EdgeInsets.symmetric(horizontal: 16),
              child: _buildOtpSentText(),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.050),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildResendOtpRow(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height,
              ),
            ),
            Spacer(),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: buildPrivacyText(context),
                ),
                SizedBox(height: height * 0.030),
                Padding(
                  padding:      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(9),
                          ),
                          child:  Icon(CupertinoIcons.chevron_back, color: Color(0xFF252525),),
                        ),
                      ),
                      Spacer(),
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: ElevatedButton(
                          onPressed: () => _verifyOtp(context),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                            backgroundColor: AppColor.primaryBlueColor,
                            padding: const EdgeInsets.all(9),
                          ),
                          child: _isLoading ? CircularProgressIndicator(color: Colors.white,) : Icon(
                            Icons.keyboard_arrow_right_sharp,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildOtpSentText() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: ResString.otpSent,
            style: GoogleFonts.poppins(
              color: const Color(0xFF535359),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.30,
            ),
          ),
          TextSpan(
            text: '+91 ${widget.mobileNumber}',
            style: GoogleFonts.poppins(
              color: const Color(0xFF535359),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.30,)
          ),
        ],
      ),
    );
  }

  Widget _buildOtpInputForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pinput(
            length: 4,
            focusNode: _otpFocusNode,
            controller: _otpController,
            keyboardType: TextInputType.number,
            mainAxisAlignment: MainAxisAlignment.start,
            pinAnimationType: PinAnimationType.none,
            onChanged: (val) {

              if(val.length ==4){
                FocusScope.of(context).unfocus();
              }
              if (_otpError != null && val.length < 4) {
                setState(() {
                  _otpError = null; 
                });
              }
            },
            defaultPinTheme: PinTheme(
              width: 52,
              height: 52,
              textStyle: GoogleFonts.roboto(
                color: _otpError != null ? Colors.red : const Color(0xFF2365B5),
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Color(0xFFF7F7F7),
                border: Border.all(
                  color:
                      _otpError != null
                          ? Colors.red
                          : Color(0xFFF0F0F0), // Set border color dynamically
                ),
              ),
            ),
            focusedPinTheme: PinTheme(
              width: 52,
              height: 52,
              textStyle: GoogleFonts.roboto(
                color: _otpError != null ? Colors.red : const Color(0xFF2365B5),
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Color(0xFFF7F7F7),

                border: Border.all(
                  color:
                      _otpError != null
                          ? Colors.red
                          : AppColor
                              .primaryBlueColor, // Set focused border color dynamically
                ),
              ),
            ),
            autofocus: true,
          ),
          if (_otpError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: Text(
                  _otpError ?? '',
                  style: GoogleFonts.mulish(
                    color: Colors.red,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResendOtpRow(double width, double height) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: _start<=0,
          child: GestureDetector(
            onTap:
            _isButtonEnabled
                ? _resendOtp
                : null,
            child: Text(
              'Resend OTP',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color:_isButtonEnabled ? AppColor.primaryBlueColor :  AppColor.textLightColor,
              ),
            ),
          ),
        ),
        Visibility(
          visible: _start>0,
          child: Text(
            "Resend otp after $_start seconds",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColor.textLightColor,
            ),
          ),
        ),

      ],
    );
  }



  @override
  void dispose() {
    _timer.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Widget _buildCustomDialog({
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Dialog(
      backgroundColor: AppColor.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEA5455),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColor.textLightColor,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryBlueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
