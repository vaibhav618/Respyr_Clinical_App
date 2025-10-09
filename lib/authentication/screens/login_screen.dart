import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/authentication/screens/login_with_password.dart';
import 'package:respyr_clinical/authentication/screens/otp_screen.dart';

import 'package:respyr_clinical/authentication/screens/terms_privacy_widget.dart';
import 'package:respyr_clinical/authentication/services/otp_generating_services.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:respyr_clinical/shared/get_stored_data_text.dart';
import 'package:respyr_clinical/shared/images_string.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isLoading = false;

  final OtpGeneratingServices _otpService = OtpGeneratingServices();
  final storage = GetStorage();

  @override
  void initState() {
    super.initState();
    _phoneController.text = '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_phoneFocusNode.hasFocus) {
        _phoneFocusNode.unfocus();
      }
    });

    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _loginWithOtp() async {
    setState(() {
      _isLoading = true;
    });
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      final String mobileNumber = _phoneController.text;

      storage.write(
        GetStoredDataText.profileCreationMobileNumber,
        mobileNumber,
      );
      // Ensure the mobile number is not empty
      if (mobileNumber.isNotEmpty) {
        // Generate a random 4-digit OTP
        String otp = _otpService.generateOtp();

        // Set OTP expiration time (3 minutes from now)
        DateTime expirationTime = DateTime.now().add(
          const Duration(seconds: 180),
        );

        // Request OTP from the server
        bool isSuccess = await _otpService.requestOtp(mobileNumber, otp);

        if (isSuccess) {
          setState(() {});

          // Navigate using GetX
          Get.to(
                () => OTPScreen(
              mobileNumber: mobileNumber,
              generatedOtp: otp,
              expirationTime: expirationTime,
            ),
          )?.then((_) => _phoneFocusNode.unfocus());


        } else {
          Get.snackbar(
            'Error',
            'Failed to send OTP',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        Get.snackbar(
          'Error',
          'Please enter a mobile number',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
    setState(() {
      _isLoading = false;
    });
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
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColor.whiteColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Mobile Number",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF252525),
                      fontSize: 34,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -2.04,
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: height * 0.025),
            Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: height * 0.082,
                          width: width * 0.17,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFF0F0F0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: SvgPicture.asset(ResSvg.indiaLogo),
                              ),
                              Expanded(
                                child: Text(
                                  "+91",
                                  style: GoogleFonts.roboto(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF053742),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: width * 0.03),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              } // Check if the value contains only numbers and starts with 6-9
                              else if (!RegExp(
                                r'^[6-9][0-9]{9}$',
                              ).hasMatch(value)) {
                                return 'Please enter a valid phone number';
                              } else if (value.length < 10) {
                                return 'Phone number must be at least 10 digits';
                              }
                              return null;
                            },
                            cursorColor: AppColor.primaryBlueColor,
                            maxLength: 10,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: "Enter your mobile number",
                              hintStyle: GoogleFonts.roboto(
                                fontSize: 15,
                                fontWeight: FontWeight.w300,
                                color: const Color(0xFF737373),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8F8F8),
                              errorStyle: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.red,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFFF0F0F0), width: 1),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFFF0F0F0), width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF809BF9), width: 1),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: width * 0.048,
                                vertical: height * 0.025,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: height * 0.025),
            Text("OR",
              style: GoogleFonts.poppins(
                color: const Color(0xFF5A5A5A),
                fontSize: 15,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.30,
              ),
            ),
            SizedBox(height: height * 0.025),
            GestureDetector(
                onTap: (){
                  // Navigate using GetX
                  Get.to(
                        () => LoginWithPassword(
                    ),
                  )?.then((_) => _phoneFocusNode.unfocus());
                },

                child: Text("Login using password instead",

                  style: GoogleFonts.poppins(
                    color: const Color(0xFF308BF9),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.30,
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFF308BF9)
                  ),
                )
            ),
            const Spacer(),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: buildPrivacyText(context),
                ),
                SizedBox(height: height * 0.030),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: ElevatedButton(
                            onPressed: (){},
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                backgroundColor: Colors.white,
                                shadowColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.all(9)),
                            child: Icon(
                              Icons.keyboard_arrow_left_sharp,
                              size: 24,
                              color: Color(0xFF535359),
                            )),
                      ),
                      Spacer(),
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: ElevatedButton(
                            onPressed: () {
                              if (!_isLoading) {
                                _loginWithOtp();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                backgroundColor: AppColor.primaryBlueColor,
                                padding: const EdgeInsets.all(9),
                                elevation: 0),
                            child: _isLoading
                                ? CircularProgressIndicator(
                              color: Colors.white,
                            )
                                : Icon(
                              Icons.keyboard_arrow_right_sharp,
                              size: 24,
                              color: Colors.white,
                            )),
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

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
