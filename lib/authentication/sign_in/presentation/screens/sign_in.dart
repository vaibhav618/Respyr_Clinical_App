import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:respyr_clinical/authentication/screens/terms_privacy_widget.dart';
import 'package:respyr_clinical/authentication/sign_in/presentation/widgets/sign_in_option_button.dart';

import '../../../../router/app_routers.dart';
import '../../bloc/sign_in_bloc.dart';
import '../../bloc/sign_in_event.dart';
import '../../bloc/sign_in_state.dart';

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignInBloc(),
      child: const _SignInView(),
    );
  }
}

/// The app's front door, built as a product page: the brand-blue hero
/// carries the wordmark, the device itself stands centre-stage at full
/// presence — haloed, grounded by a shadow, gently floating — and the two
/// login CTAs close the page above the terms line. No copy anywhere; the
/// device is the message. Everything enters on a stagger, receiving the
/// splash's fade-up.
class _SignInView extends StatefulWidget {
  const _SignInView();

  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView>
    with TickerProviderStateMixin {
  late final AnimationController _enter;

  /// Idle float: the device bobs a few pixels on a slow breath-like cycle,
  /// its ground shadow easing lighter as it rises.
  late final AnimationController _float;

  /// Ripple waves: thin rings expanding out of the halo and fading — the
  /// device quietly "emitting", like a breath pulse.
  late final AnimationController _ripple;

  static const Color _blue = Color(0xFF308BF9);

  /// Corporate is parked for now — flip to true to bring its login button
  /// back. Everything behind it (routes, screens, bloc) stays intact.
  static const bool _showCorporate = false;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
  }

  @override
  void dispose() {
    _enter.dispose();
    _float.dispose();
    _ripple.dispose();
    super.dispose();
  }

  /// Fade + rise for one entrance slot; later slots start later.
  Widget _staggered(int slot, Widget child) {
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, _) {
        final double t = Curves.easeOutCubic.transform(
          ((_enter.value - slot * 0.10) / 0.55).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignInBloc, SignInState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) async {
        if (state.status == SignInStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? "Something went wrong"),
            ),
          );
          return;
        }

        if (state.status == SignInStatus.success) {
          if (!context.mounted) return;

          if (state.selectedType == "clinical") {
            Navigator.pushNamed(context, AppRoutes.clinicalLogin);
          } else if (state.selectedType == "corporate") {
            Navigator.pushNamed(context, AppRoutes.corporateLogin);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: BlocBuilder<SignInBloc, SignInState>(
          buildWhen:
              (p, c) =>
                  p.status != c.status || p.selectedType != c.selectedType,
          builder: (context, state) {
            // Bottom-only SafeArea: the hero handles the status bar itself
            // (it paints under it), while the footer must clear whatever
            // navigation the device uses — a 3-button bar's ~48px as much as
            // a gesture pill's sliver. The LayoutBuilder sits inside so the
            // min-height math uses the already-inset viewport.
            return SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double screenH = constraints.maxHeight;

                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: screenH),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _hero(context),
                            const Spacer(flex: 2),
                            _staggered(1, _deviceShowcase(screenH)),
                            const Spacer(flex: 3),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _staggered(
                                    2,
                                    SignInOptionButton(
                                      state: state,
                                      title: "Get Started",
                                      roleKey: "clinical",
                                      filled: true,
                                      onClick:
                                          () => context.read<SignInBloc>().add(
                                            const SignInClinicalPressed(),
                                          ),
                                    ),
                                  ),
                                  if (_showCorporate) ...[
                                    const SizedBox(height: 12),
                                    _staggered(
                                      3,
                                      SignInOptionButton(
                                        state: state,
                                        title: "Corporate Login",
                                        roleKey: "corporate",
                                        onClick:
                                            () => context.read<SignInBloc>().add(
                                              const SignInCorporatePressed(),
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            _staggered(
                              4,
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  30,
                                  16,
                                  30,
                                  36,
                                ),
                                child: buildPrivacyText(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// The brand hero: blue field with a soft curved base, the wordmark alone
  /// (no tagline — nothing that could read as a medical-device claim), faint
  /// oversize rings cropped by its edges as texture.
  Widget _hero(BuildContext context) {
    final double heroHeight = MediaQuery.of(context).size.height * 0.26;

    return _staggered(
      0,
      Container(
        height: heroHeight,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: _blue,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -heroHeight * 0.42,
              right: -heroHeight * 0.28,
              child: _heroCircle(heroHeight * 0.9),
            ),
            Positioned(
              bottom: -heroHeight * 0.5,
              left: -heroHeight * 0.32,
              child: _heroCircle(heroHeight * 1.0),
            ),
            SafeArea(
              child: Center(
                child: SvgPicture.asset(
                  "assets/respyr_logo_white.svg",
                  width: 210,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The device at full presence: haloed by a faint brand-tint ring, grounded
  /// by a soft shadow, bobbing gently — a product shot, not a watermark. The
  /// cutout's transparency does all the blending; no frame anywhere.
  Widget _deviceShowcase(double screenH) {
    final double h = (screenH * 0.30).clamp(160.0, 300.0);

    return SizedBox(
      height: h + 16,
      child: AnimatedBuilder(
        animation: Listenable.merge([_float, _ripple]),
        builder: (context, _) {
          final double t = Curves.easeInOut.transform(_float.value);

          return Stack(
            alignment: Alignment.topCenter,
            // The ripple box reaches past the showcase's own bounds; the
            // default clip sliced its top and bottom into a visible square
            // band. Let it breathe.
            clipBehavior: Clip.none,
            children: [
              // Sleek circular waves: thin rings born at the halo's edge,
              // expanding and thinning out until they dissolve.
              Positioned(
                top: h * 0.51 - h * 0.68,
                child: IgnorePointer(
                  child: CustomPaint(
                    size: Size(h * 1.36, h * 1.36),
                    painter: _RippleWavesPainter(
                      progress: _ripple.value,
                      color: _blue,
                    ),
                  ),
                ),
              ),
              // The halo: echoes the hero's rings on the page side.
              Positioned(
                top: h * 0.08,
                child: Container(
                  width: h * 0.86,
                  height: h * 0.86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _blue.withValues(alpha: 0.05),
                    border: Border.all(
                      color: _blue.withValues(alpha: 0.10),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              // Ground shadow: eases smaller and lighter as the device
              // rises, selling the float.
              Positioned(
                bottom: 0,
                child: Container(
                  width: h * (0.44 - 0.05 * t),
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(h * 0.22, 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.10 * (1 - 0.4 * t),
                        ),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -7 * t),
                child: Image.asset("assets/respyr_pic.png", height: h),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _heroCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1.5,
        ),
      ),
    );
  }
}

/// Three staggered rings expanding from the halo's edge to the paint box's
/// rim, each fading and thinning as it travels — a quiet, sleek pulse, not a
/// sonar blast.
class _RippleWavesPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RippleWavesPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double half = size.shortestSide / 2;
    // Rings are born just outside the halo (~63% of the box's half-width)
    // and dissolve at the rim.
    final double base = half * 0.63;
    final double span = half - base;

    for (int i = 0; i < 3; i++) {
      final double p = (progress + i / 3) % 1.0;
      final double eased = Curves.easeOut.transform(p);
      final double fade = (1 - eased);

      canvas.drawCircle(
        center,
        base + span * eased,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 * fade + 0.3
          ..color = color.withValues(alpha: 0.14 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(_RippleWavesPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
