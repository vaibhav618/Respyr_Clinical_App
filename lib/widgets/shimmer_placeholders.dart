import 'package:flutter/material.dart';

/// Pulsing skeletons shown while a page loads, shaped like the real content
/// so the layout doesn't jump when data arrives.
///
/// Uses an opacity pulse instead of a gradient sweep: the skeleton is painted
/// once into a cached layer ([RepaintBoundary]) and only its opacity animates,
/// which stays smooth even on low-end devices where a full-screen animated
/// shader visibly stutters.
///
/// Wrap any skeleton layout in [AppShimmer]; use the prebuilt page skeletons
/// ([TestLogShimmer], [SubjectProfileShimmer]) for the dashboard pages.
class AppShimmer extends StatefulWidget {
  final Widget child;
  const AppShimmer({super.key, required this.child});

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 1.0,
    end: 0.45,
  ).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: RepaintBoundary(child: widget.child),
    );
  }
}

/// A single gray placeholder block.
class ShimmerBox extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;
  final bool circle;

  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.radius = 6,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: circle ? height : width,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// Card-shaped shell matching the app's white cards.
class _ShimmerCardShell extends StatelessWidget {
  final Widget child;
  const _ShimmerCardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: child,
    );
  }
}

/// Skeleton for the Test Log page: search bar + patient cards.
class TestLogShimmer extends StatelessWidget {
  const TestLogShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AppShimmer(
          child: Column(
            children: [
              const SizedBox(height: 16),
              const ShimmerBox(height: 52, radius: 10),
              const SizedBox(height: 20),
              for (int i = 0; i < 4; i++) ...[
                _ShimmerCardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const ShimmerBox(height: 40, circle: true),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                ShimmerBox(height: 13, width: 120),
                                SizedBox(height: 6),
                                ShimmerBox(height: 10, width: 170),
                              ],
                            ),
                          ),
                          const ShimmerBox(height: 22, width: 56, radius: 20),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: const [
                          Expanded(child: ShimmerBox(height: 34)),
                          SizedBox(width: 12),
                          Expanded(child: ShimmerBox(height: 34)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Expanded(child: ShimmerBox(height: 34)),
                          SizedBox(width: 12),
                          Expanded(child: ShimmerBox(height: 34)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for the Subject Profile page: details card + history rows.
class SubjectProfileShimmer extends StatelessWidget {
  const SubjectProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AppShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _ShimmerCardShell(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const ShimmerBox(height: 52, circle: true),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              ShimmerBox(height: 16, width: 140),
                              SizedBox(height: 6),
                              ShimmerBox(height: 11, width: 90),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Expanded(child: ShimmerBox(height: 34)),
                        SizedBox(width: 10),
                        Expanded(child: ShimmerBox(height: 34)),
                        SizedBox(width: 10),
                        Expanded(child: ShimmerBox(height: 34)),
                        SizedBox(width: 10),
                        Expanded(child: ShimmerBox(height: 34)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const ShimmerBox(height: 18, width: 110),
              const SizedBox(height: 16),
              for (int i = 0; i < 5; i++) ...[
                const ShimmerBox(height: 48, radius: 12),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
