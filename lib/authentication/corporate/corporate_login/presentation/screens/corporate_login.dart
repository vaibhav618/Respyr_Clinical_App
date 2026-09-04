import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/shared/nodeurl.dart';

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

class _CorporateLoginState extends State<CorporateLogin>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ScrollController _scroll = ScrollController();
  double _lastInset = 0;

  /// Extra scroll room granted only while the keyboard is up. Tall screens
  /// don't naturally overflow enough for the full heading push — the scroll
  /// hits its end partway and half the heading stays visible — so the push
  /// distance is provisioned explicitly and reclaimed on close.
  double _kbExtra = 0;

  /// Drives the keyboard-open push frame by frame. A plain animateTo gets
  /// cancelled the moment the viewport resizes under it (which the keyboard
  /// does continuously), so instead each tick jumps the scroll toward the
  /// target, clamped to whatever extent exists that frame — riding the
  /// keyboard up instead of fighting it.
  late final AnimationController _push;

  bool _showPassword = false;

  // ✅ server-side errors
  String? _emailServerError;
  String? _passwordServerError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _push = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(() {
      if (!_scroll.hasClients) return;
      final double target =
          _pushTarget * Curves.easeOutCubic.transform(_push.value);
      final double max = _scroll.position.maxScrollExtent;
      _scroll.jumpTo(target < max ? target : max);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _push.dispose();
    _scroll.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Fallback push distance if the card can't be measured; normally the
  /// real distance is measured from the card's actual position, so the push
  /// lands exactly at the card's top on every screen and text scale.
  static const double _headingScroll = 116;

  /// Marks the card so the keyboard push can measure its true offset.
  final GlobalKey _cardKey = GlobalKey();

  /// The measured scroll offset that puts the card's top at the viewport's
  /// top (minus a small breath), refreshed on every keyboard open.
  double _pushTarget = _headingScroll;

  /// Reads where the card really is inside the scroll content — device-,
  /// screen- and font-scale-independent.
  void _measurePushTarget() {
    final BuildContext? ctx = _cardKey.currentContext;
    final RenderObject? ro = ctx?.findRenderObject();
    if (ro == null) return;
    final RenderAbstractViewport? viewport = RenderAbstractViewport.maybeOf(ro);
    if (viewport == null) return;
    final double reveal = viewport.getOffsetToReveal(ro, 0.0).offset;
    _pushTarget = (reveal - 10).clamp(0.0, double.infinity);
  }

  // When the keyboard opens, nudge the form so the heading slides behind the
  // app bar and the whole card stands in view — not all the way to the end.
  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final double inset = MediaQuery.of(context).viewInsets.bottom;
      final bool opened = inset > 0 && _lastInset == 0;
      final bool closed = inset == 0 && _lastInset > 0;
      _lastInset = inset;
      if (opened) {
        _measurePushTarget();
        setState(() => _kbExtra = _pushTarget + 8);
        _push.forward(from: 0);
      } else if (closed) {
        setState(() => _kbExtra = 0);
      }
    });
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
  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon}) {
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocProvider(
      create:
          (_) => CorporateLoginBloc(
            repo: CorporateLoginRepository(endpointUrl: NodeUrls.corporateLogin),
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
            final savedEmail =
                (storage.read('corporate_email') ?? "").toString();
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
              // Same canvas as the rest of the entry flow.
              backgroundColor: const Color(0xFFF5F7FA),
              resizeToAvoidBottomInset: false,
              // The app bar sits on the page's own canvas — no white band
              // cutting across the top of a grey page.
              appBar: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: const Color(0xFFF5F7FA),
                surfaceTintColor: const Color(0xFFF5F7FA),
                elevation: 0,
                // Back moved up here from the bottom bar, where it sat as an
                // unlabelled arrow across from the submit arrow.
                leading: IconButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF252525),
                  ),
                ),
                centerTitle: true,
                title: SvgPicture.asset("assets/respyr_logo.svg"),
              ),
              // Tap anywhere outside a field to put the keyboard away;
              // scrolling deliberately does NOT dismiss it (default manual
              // behavior — the old onDrag did). No dock: the button and the
              // sign-up line sit directly on the page canvas.
              body: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SafeArea(
                        bottom: false,
                        // The scroll area eases its own bottom inset so the
                        // card — Log in button included — always sits
                        // reachable above the keys, without the Scaffold's
                        // un-animated snap.
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.only(bottom: keyboardInset),
                          child: AbsorbPointer(
                            absorbing: isLoading,
                            child: SingleChildScrollView(
                              controller: _scroll,
                              // Bottom padding keeps the card scrollable clear
                              // of the fixed sign-up line at the screen's
                              // bottom edge.
                              padding: EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                80 + _kbExtra,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20),
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
                                      "Use your corporate email address and password.",
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF535359),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // One white card holds the fields, so the page
                                    // reads as heading → form → action, matching the
                                    // clinical login exactly.
                                    Container(
                                      key: _cardKey,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _fieldLabel("Email"),
                                          TextFormField(
                                            controller: _emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            maxLength: 254,
                                            cursorColor:
                                                AppColor.primaryBlueColor,
                                            textInputAction:
                                                TextInputAction.next,
                                            validator: _validateEmail,
                                            onChanged: (v) {
                                              // ✅ IMPORTANT FIX: clear both errors on edit
                                              _clearServerErrorsIfAny();

                                              context
                                                  .read<CorporateLoginBloc>()
                                                  .add(
                                                    CorporateLoginEmailChanged(
                                                      v,
                                                    ),
                                                  );
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
                                            cursorColor:
                                                AppColor.primaryBlueColor,
                                            textInputAction:
                                                TextInputAction.done,
                                            validator: _validatePassword,
                                            onChanged: (v) {
                                              // ✅ IMPORTANT FIX: clear both errors on edit
                                              _clearServerErrorsIfAny();

                                              context
                                                  .read<CorporateLoginBloc>()
                                                  .add(
                                                    CorporateLoginPasswordChanged(
                                                      v,
                                                    ),
                                                  );
                                            },
                                            decoration: _inputDecoration(
                                              hint: "Enter password",
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _showPassword
                                                      ? Icons
                                                          .visibility_outlined
                                                      : Icons
                                                          .visibility_off_outlined,
                                                  size: 20,
                                                  color: const Color(
                                                    0xFFA1A1A1,
                                                  ),
                                                ),
                                                onPressed:
                                                    () => setState(() {
                                                      _showPassword =
                                                          !_showPassword;
                                                    }),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 50,
                                            child: ElevatedButton(
                                              onPressed:
                                                  isLoading
                                                      ? null
                                                      : () {
                                                        final isValid =
                                                            _formKey
                                                                .currentState
                                                                ?.validate() ??
                                                            false;
                                                        if (!isValid) return;

                                                        _clearServerErrorsIfAny();

                                                        context
                                                            .read<
                                                              CorporateLoginBloc
                                                            >()
                                                            .add(
                                                              const CorporateLoginSubmitted(),
                                                            );
                                                      },
                                              style: ElevatedButton.styleFrom(
                                                elevation: 0,
                                                backgroundColor:
                                                    AppColor.primaryBlueColor,
                                                disabledBackgroundColor:
                                                    const Color(
                                                      0xFF308BF9,
                                                    ).withValues(alpha: 0.5),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child:
                                                  isLoading
                                                      ? const SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2.2,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      )
                                                      : Text(
                                                        "Log in",
                                                        style:
                                                            GoogleFonts.poppins(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              letterSpacing:
                                                                  -0.2,
                                                            ),
                                                      ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.corporateForgotPassword,
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          "Forgot password?",
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF308BF9),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // The sign-up line holds the very bottom and never rides
                    // the keyboard — the keys just cover it while they're up.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don’t have an account?",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF535359),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(width: 2),
                              TextButton(
                                onPressed:
                                    isLoading
                                        ? null
                                        : () {
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.validateCorporateId,
                                          );
                                        },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  "Sign up",
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF308BF9),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
