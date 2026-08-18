import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/authentication/screens/terms_privacy_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../clinical_dashboard/bloc/health_score_bloc.dart';
import '../../clinical_dashboard/service/overall_data_by_date_service.dart';
import '../../clinical_dashboard/views/clinical_dashboard.dart';
import '../../shared/colors.dart';
import '../repository/login_with_password_repository.dart';
import '../services/clinical_name_getx_controller.dart';
import '../services/clinical_token_generating_api.dart';
import 'login_form.dart';

class LoginWithPassword extends StatefulWidget {
  const LoginWithPassword({super.key});

  @override
  State<LoginWithPassword> createState() => _LoginWithPasswordState();
}

class _LoginWithPasswordState extends State<LoginWithPassword> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final LoginWithPasswordRepository _loginRepo = LoginWithPasswordRepository();

  String? _adminIdError;
  String? _passwordError;
  bool isLoading = false;

  final storage = GetStorage();
  final clinicController = Get.put(ClinicalController());

  void _handleLogin() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      _adminIdError = null;
      _passwordError = null;
    });

    try {
      final response = await _loginRepo.login(
        nameController.text.trim(),
        passwordController.text,
      );

      if (response.status == "success" && response.data?.isNotEmpty == true) {
        final user = response.data!.first;
        generateJwt(user.clinicName, user.phoneNo);
      } else {
        setState(() {
          isLoading = false;
          _adminIdError = response.message;
          _passwordError = response.message;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint("Unexpected error: $e");

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => AlertDialog(
              contentPadding: const EdgeInsets.all(30),
              backgroundColor: AppColor.whiteColor,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    "assets/sagar/undraw_server-down_lxs9.svg",
                    height: 100,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Something went wrong",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "No internet connection detected. Please check your connection and try again.",
                    style: GoogleFonts.poppins(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: () async {
                      clinicController.clearData();
                      Get.offAll(() => const LoginWithPassword());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF308BF9),
                    ),
                    child: Text(
                      "Try Again",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      );
    }
  }

  void _showDialog({required String title, required String message}) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _buildCustomDialog(
            title: title,
            message: message,
            buttonText: "OK",
            onPressed: () {
              clinicController.clearData();
              Get.offAll(() => const LoginWithPassword());
            },
          ),
    );
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
            const SizedBox(height: 15),
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
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future generateJwt(String clinicName, String phoneNo) async {
    isLoading = true;
    // Fetch and save JWT token
    final jwtResult = await JwtApiHelper.fetchAndStoreJwtToken(
      loginId: clinicName,
    );

    if (!jwtResult.success || jwtResult.data['token'] == null) {
      _showDialog(
        title: "Authentication Failed",
        message: jwtResult.message ?? "Could not fetch JWT token.",
      );
      return;
    }

    // Check if token is saved
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('jwt_token');

    if (savedToken == null || savedToken.isEmpty) {
      _showDialog(
        title: "Token Storage Error",
        message: "Failed to save JWT token. Please try again.",
      );
      return;
    }

    // Save isOtpVerified and loginClinicalName
    final storage = GetStorage();
    await storage.write('isOtpVerified', true);
    await storage.write('loginClinicalName', clinicName);
    await storage.write('role', "clinical");

    final isOtpSaved = storage.read('isOtpVerified') == true;
    final isNameSaved = storage.read('loginClinicalName') == clinicName;
    final isRoleSaved = storage.read('role') == "clinical";

    if (isOtpSaved && isNameSaved && isRoleSaved) {
      final clinicController = Get.put(ClinicalController());
      clinicController.setClinicData(name: clinicName, number: phoneNo);

      Navigator.pushAndRemoveUntil(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder:
              (_) => BlocProvider(
                create: (_) => HealthScoreBloc(OverallDataByDateService()),
                child: ClinicalDashboardMain(loginId: clinicName),
              ),
        ),
        (Route<dynamic> route) => false,
      );
    } else {
      _showDialog(
        title: "Session Storage Error",
        message: "Something went wrong while saving session data.",
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Reached two ways: pushed from the sign-in chooser (back must work,
    // by button and by gesture) or directly from splash for a returning
    // clinical session (nothing to pop to — the arrow hides itself).
    final bool canGoBack = Navigator.of(context).canPop();

    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      // Same canvas as the splash underlay and the rest of the app, so the
      // curtain-lift handoff lands on identical ground. The form area eases
      // its own bottom inset (animated), so the Scaffold must not also
      // resize — that double-resize was the patchy jump.
      backgroundColor: const Color(0xFFF5F7FA),
      resizeToAvoidBottomInset: false,
      // The app bar sits on the page's own canvas — no white band cutting
      // across the top of a grey page.
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        surfaceTintColor: const Color(0xFFF5F7FA),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading:
            canGoBack
                ? IconButton(
                  onPressed:
                      isLoading ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF252525),
                  ),
                )
                : null,
        centerTitle: true,
        title: SvgPicture.asset("assets/respyr_logo.svg"),
      ),
      // Tap anywhere outside a field to put the keyboard away; scrolling
      // deliberately does NOT dismiss it. No dock: the button and the terms
      // line sit directly on the page canvas.
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                // The scroll area eases its own bottom inset so the card —
                // Log in button included — always sits reachable above the
                // keys, without the Scaffold's un-animated snap.
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(bottom: keyboardInset),
                  child: LoginForm(
                    formKey: formKey,
                    nameController: nameController,
                    passwordController: passwordController,
                    onLoginPressed: _handleLogin,
                    adminIdError: _adminIdError,
                    passwordError: _passwordError,
                    isLoading: isLoading,
                  ),
                ),
              ),
            ),
            // The terms line holds the very bottom and never rides the
            // keyboard — the keys just cover it while they're up.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 26),
                  child: buildPrivacyText(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
