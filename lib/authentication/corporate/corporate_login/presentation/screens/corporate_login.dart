import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/shared/urls.dart';

import '../../../../../common/floating_message.dart';
import '../../../../../router/app_routers.dart';
import '../../../../../shared/colors.dart';
import '../../bloc/corporate_login_bloc.dart';
import '../../bloc/corporate_login_event.dart';
import '../../bloc/corporate_login_state.dart';
import '../../data/repository/corporate_login_repository.dart';

class CorporateLogin extends StatefulWidget {
  const CorporateLogin({super.key});

  @override
  State<CorporateLogin> createState() => _CorporateLoginState();
}

class _CorporateLoginState extends State<CorporateLogin> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _showPassword = false;

  // ✅ server-side errors
  String? _emailServerError;
  String? _passwordServerError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isInvalidCredentialMsg(String msg) {
    return msg.contains("401") || msg.toLowerCase().contains("invalid");
  }

  String? _validateEmail(String? value) {
    final v = (value ?? "").trim();
    if (v.isEmpty) return 'Please enter your email address';

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(v)) return 'Please enter a valid email address';

    if ((_emailServerError ?? '').isNotEmpty) return _emailServerError;
    return null;
  }

  String? _validatePassword(String? value) {
    final v = (value ?? "").trim();
    if (v.isEmpty) return 'Enter password';
    if (v.length < 6) return 'Minimum 6 characters';

    if ((_passwordServerError ?? '').isNotEmpty) return _passwordServerError;
    return null;
  }

  // Palette-correct field styling, shared with the rest of the app: Poppins
  // (the old decoration was Roboto, found nowhere else), white fill with the
  // standard hairline, Primary Blue focus and Error Red errors — the previous
  // focus colour #809BF9 belonged to no palette.
  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      counterText: '',
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFA1A1A1),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      errorStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFEA5455),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF308BF9), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEA5455), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEA5455), width: 1.5),
      ),
      suffixIcon: suffixIcon,
    );
  }

  /// Small label above a field — the screen used a 34px "Email" as its only
  /// heading, which read as a page title rather than a form.
  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: const Color(0xFF252525),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _clearServerErrorsIfAny() {
    if (_emailServerError != null || _passwordServerError != null) {
      setState(() {
        _emailServerError = null;
        _passwordServerError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocProvider(
      create: (_) => CorporateLoginBloc(
        repo: CorporateLoginRepository(
          endpointUrl:
          Urls.corporateLogin,
        ),
      ),
      child: BlocListener<CorporateLoginBloc, CorporateLoginState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) async {
          if (state.status == CorporateLoginStatus.failure) {
            final msg = (state.errorMessage ?? "Login failed").trim();

            if (_isInvalidCredentialMsg(msg)) {
              setState(() {
                // ✅ IMPORTANT FIX: do NOT put server error on email
                // so user can correct only password and proceed.
                _emailServerError = null;
                _passwordServerError = "Invalid password";
              });
              _formKey.currentState?.validate();
            } else {
              setState(() {
                _emailServerError = null;
                _passwordServerError = null;
              });
            }

            FloatingMessage.show(
              context,
              message: msg,
              type: FloatingMessageType.error,
            );
          }

          if (state.status == CorporateLoginStatus.success) {
            final user = state.user;
            if (user == null) {
              FloatingMessage.show(
                context,
                message: "Login succeeded but user data missing",
                type: FloatingMessageType.error,
              );
              return;
            }

            setState(() {
              _emailServerError = null;
              _passwordServerError = null;
            });

            final storage = GetStorage();

            final email = (user.email ?? "").trim();
            final clinicName = (user.clinicName ?? "").trim();
            final role = (user.role).toString();

            // ✅ write
            await storage.write('corporate_email', email);
            await storage.write('clinic_name', clinicName);
            await storage.write('role', role.toLowerCase());

            // ✅ verify readback
            final savedEmail = (storage.read('corporate_email') ?? "").toString();
            final savedRole = (storage.read('role') ?? "").toString();

            final isEmailSaved = savedEmail == email;
            final isRoleSaved = savedRole == role.toLowerCase();

            if (!mounted) return;

            if (isEmailSaved && isRoleSaved) {
              FloatingMessage.show(
                context,
                message: "Login successful",
                type: FloatingMessageType.success,
              );

              Navigator.pushReplacementNamed(
                context,
                AppRoutes.corporateDashboard,
                arguments: {
                  "clinic_name": clinicName,
                  "email": email,
                  "role": role,
                },
              );
            } else {
              FloatingMessage.show(
                context,
                message: "Session storage error",
                type: FloatingMessageType.error,
              );
            }
          }
        },
        child: BlocBuilder<CorporateLoginBloc, CorporateLoginState>(
          builder: (context, state) {
            final isLoading = state.status == CorporateLoginStatus.loading;

            return Scaffold(
              backgroundColor: Colors.white,
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 0,
                // Back moved up here from the bottom bar, where it sat as an
                // unlabelled arrow across from the submit arrow.
                leading: IconButton(
                  onPressed:
                      isLoading ? null : () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF252525),
                  ),
                ),
                centerTitle: true,
                title: SvgPicture.asset("assets/respyr_logo.svg"),
              ),
              body: SafeArea(
                bottom: false,
                child: AbsorbPointer(
                  absorbing: isLoading,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(horizontal: 17),
                        child: ConstrainedBox(
                          constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    "Log in",
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF252525),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Use your corporate email and password.",
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF535359),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _fieldLabel("Email"),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    maxLength: 254,
                                    cursorColor: AppColor.primaryBlueColor,
                                    textInputAction: TextInputAction.next,
                                    validator: _validateEmail,
                                    onChanged: (v) {
                                      // ✅ IMPORTANT FIX: clear both errors on edit
                                      _clearServerErrorsIfAny();

                                      context
                                          .read<CorporateLoginBloc>()
                                          .add(CorporateLoginEmailChanged(v));
                                    },
                                    decoration: _inputDecoration(
                                      hint: "Enter your email address",
                                    ),
                                  ),

                                  const SizedBox(height: 18),
                                  _fieldLabel("Password"),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: !_showPassword,
                                    maxLength: 64,
                                    cursorColor: AppColor.primaryBlueColor,
                                    textInputAction: TextInputAction.done,
                                    validator: _validatePassword,
                                    onChanged: (v) {
                                      // ✅ IMPORTANT FIX: clear both errors on edit
                                      _clearServerErrorsIfAny();

                                      context
                                          .read<CorporateLoginBloc>()
                                          .add(CorporateLoginPasswordChanged(v));
                                    },
                                    decoration: _inputDecoration(
                                      hint: "Enter password",
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _showPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 20,
                                          color: const Color(0xFFA1A1A1),
                                        ),
                                        onPressed: () => setState(() {
                                          _showPassword = !_showPassword;
                                        }),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Align(
                                      alignment: Alignment.topRight,
                                      child: TextButton(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              AppRoutes.corporateForgotPassword,
                                            );
                                          },
                                          child: Text(
                                            "Forgot your password?",
                                            style: GoogleFonts.poppins(
                                              color: const Color(0xFF308BF9),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w400,
                                              letterSpacing: -0.72,
                                            ),
                                          ))),
                                  const Spacer(),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              bottomNavigationBar: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: 12 + keyboardInset,
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don’t have an account?",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF252525),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.26,
                            ),
                          ),
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.validateCorporateId,
                              );
                            },
                            child: Text(
                              "Sign up",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF308BF9),
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.30,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // A labelled full-width button instead of a bare arrow
                      // in a circle — the arrow said "next" on a screen whose
                      // action is logging in.
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  final isValid =
                                      _formKey.currentState?.validate() ??
                                          false;
                                  if (!isValid) return;

                                  _clearServerErrorsIfAny();

                                  context
                                      .read<CorporateLoginBloc>()
                                      .add(const CorporateLoginSubmitted());
                                },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColor.primaryBlueColor,
                            disabledBackgroundColor:
                                const Color(0xFF308BF9).withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  "Log in",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
