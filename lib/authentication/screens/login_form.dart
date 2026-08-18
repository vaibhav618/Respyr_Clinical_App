import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/forgot_password.dart';

/// The clinical login form, on the app's design language: a real heading
/// with a subtitle instead of a 34px thin line, and one white card holding
/// the labelled fields and the Log in button.
class LoginForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController passwordController;
  final VoidCallback onLoginPressed;
  final String? adminIdError;
  final String? passwordError;
  final bool isLoading;

  const LoginForm({
    required this.formKey,
    required this.nameController,
    required this.passwordController,
    required this.onLoginPressed,
    required this.adminIdError,
    required this.passwordError,
    required this.isLoading,
    super.key,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _obscureText = true;

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

  @override
  Widget build(BuildContext context) {
    // One white card holds the fields and the Log in button, so the page
    // reads as heading → card → links instead of loose elements floating on
    // the canvas. Default (manual) dismiss behavior — scrolling never takes
    // the keyboard down; tapping outside or system back does. Bottom padding
    // keeps the card scrollable clear of the fixed terms line at the
    // screen's bottom edge.
    return SingleChildScrollView(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(20, 0, 20, 80 + _kbExtra),
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
            "Use your clinic's admin ID or phone number.",
            style: GoogleFonts.poppins(
              color: const Color(0xFF535359),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            key: _cardKey,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Form(
              key: widget.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel("Admin ID or phone"),
                  TextFormField(
                    controller: widget.nameController,
                    textInputAction: TextInputAction.next,
                    cursorColor: const Color(0xFF308BF9),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF252525),
                    ),
                    decoration: _inputDecoration(
                      "Enter admin ID or phone number",
                      widget.adminIdError,
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Admin ID is required'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel("Password"),
                  TextFormField(
                    controller: widget.passwordController,
                    obscureText: _obscureText,
                    textInputAction: TextInputAction.done,
                    cursorColor: const Color(0xFF308BF9),
                    onFieldSubmitted: (_) {
                      if (!widget.isLoading) widget.onLoginPressed();
                    },
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF252525),
                    ),
                    decoration: _inputDecoration(
                      "Enter password",
                      widget.passwordError,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: const Color(0xFFA1A1A1),
                        ),
                        onPressed:
                            () => setState(() => _obscureText = !_obscureText),
                      ),
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Password is required'
                                : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          widget.isLoading ? null : widget.onLoginPressed,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF308BF9),
                        disabledBackgroundColor: const Color(
                          0xFF308BF9,
                        ).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          widget.isLoading
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Get.to(() => ForgotPassword())?.then((_) => ());
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    );
  }

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

  // Palette-correct fields: white fill with the standard hairline, Primary
  // Blue focus, Error Red errors. No prefix icons — inside the card they
  // added a second visual system the corporate form doesn't have, and the
  // labels already say what each field is.
  InputDecoration _inputDecoration(String hint, String? errorText) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
      hintStyle: GoogleFonts.poppins(
        color: const Color(0xFFA1A1A1),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      errorStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFEA5455),
      ),
    );
  }
}
