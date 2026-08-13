import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_theme.dart';

/// Result distribution for the selected score, as an interactive donut.
///
/// The chart is the one thing on the dashboard that is meant to be read at a
/// glance, so it carries the weight the rest of the page deliberately avoids:
/// a recessed track so a single-band day still reads as a ring, gradient arcs
/// for depth, and a centre that answers whichever band you touch instead of
/// only ever showing the total.
class PieChartTestAnalyticsWidget extends StatefulWidget {
  final int poor;
  final int fair;
  final int good;
  final int totalTest;

  /// Which score is being charted. Not drawn anywhere — it is here so the
  /// chart can tell "the user switched score type" from "nothing happened".
  /// Two score types can produce byte-identical band counts (a day where
  /// every reading is Good on both), and without this the ring would sit
  /// perfectly still after a chip tap, as if the tap had missed.
  final String scoreType;

  const PieChartTestAnalyticsWidget({
    super.key,
    required this.poor,
    required this.fair,
    required this.good,
    required this.totalTest,
    required this.scoreType,
  });

  @override
  State<PieChartTestAnalyticsWidget> createState() =>
      _PieChartTestAnalyticsWidgetState();
}

class _Band {
  final String label;
  final int value;
  final Color color;

  const _Band(this.label, this.value, this.color);
}

class _PieChartTestAnalyticsWidgetState
    extends State<PieChartTestAnalyticsWidget>
    with SingleTickerProviderStateMixin {
  /// Index into [_bands], or null when nothing is picked and the centre shows
  /// the total. Set by the legend cards; the ring itself is not tappable.
  int? _selected;

  /// Drives the clockwise draw-in. Runs once on open, and again — faster —
  /// each time the score type changes, so switching chips always redraws the
  /// ring even when the new numbers happen to match the old ones.
  late final AnimationController _sweepController;
  late final Animation<double> _sweep;

  static const Duration _introDuration = Duration(milliseconds: 800);
  static const Duration _switchDuration = Duration(milliseconds: 520);

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: _introDuration,
    );
    _sweep = CurvedAnimation(
      parent: _sweepController,
      curve: Curves.easeOutCubic,
    );
    _sweepController.forward();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  static const double _ringSize = 176;
  static const double _centerRadius = 62;
  static const double _arcWidth = 24;
  static const double _arcWidthActive = 30;

  List<_Band> get _bands => [
        _Band('Good', widget.good, DashTheme.good),
        _Band('Fair', widget.fair, DashTheme.fair),
        _Band('Poor', widget.poor, DashTheme.poor),
      ];

  /// Lighter end of an arc's gradient. Derived from the band colour rather
  /// than hard-coded, so the three arcs stay consistent with each other and
  /// with the score dots used elsewhere.
  Color _lighten(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness + 0.14).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  void didUpdateWidget(PieChartTestAnalyticsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool switchedScore = oldWidget.scoreType != widget.scoreType;
    final bool countsChanged = oldWidget.good != widget.good ||
        oldWidget.fair != widget.fair ||
        oldWidget.poor != widget.poor;

    if (!switchedScore && !countsChanged) return;

    // The old selection referred to the old figures. Holding it could leave
    // the centre reporting a band that now has no arc at all.
    _selected = null;

    // Redraw on any switch, including one where the numbers are unchanged —
    // the answer being the same is itself worth showing, and a chip tap that
    // produced no motion read as a dead control.
    _sweepController.duration = _switchDuration;
    _sweepController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final bands = _bands;
    final bool hasData = widget.totalTest > 0;

    return Column(
      children: [
        SizedBox(
          height: _ringSize + 12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The track. A day where every reading lands in one band would
              // otherwise draw a plain circle with no sense of the whole.
              Container(
                height: _ringSize,
                width: _ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DashTheme.surface,
                    width: _arcWidth,
                  ),
                ),
              ),
              // The arcs sweep clockwise from twelve o'clock while the centre
              // and the legend count up to meet them — on open, and again on
              // every score-type switch.
              AnimatedBuilder(
                animation: _sweep,
                builder: (context, _) {
                  final double sweep = _sweep.value;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          centerSpaceRadius: _centerRadius,
                          sectionsSpace: 3,
                          startDegreeOffset: -90,
                          sections: _sections(bands, hasData, sweep),
                          // The ring is a readout, not a control. Dragging a
                          // finger across it fired a stream of touch events,
                          // so arcs grew and shrank as the finger crossed
                          // them and a tap could toggle twice — it read as a
                          // glitch rather than as a selection. The legend
                          // cards below are the only way in.
                          pieTouchData: PieTouchData(enabled: false),
                        ),
                        // While the sweep is driving every frame, the chart's
                        // own lerp would fight it and smear the motion.
                        duration: sweep < 1
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                      ),
                      _centerLabel(bands, hasData, sweep),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // The legend counts up alongside the ring, so the whole panel reacts
        // to a chip tap rather than just the part in the middle.
        AnimatedBuilder(
          animation: _sweep,
          builder: (context, _) {
            final double sweep = _sweep.value;
            return Row(
              children: [
                for (int i = 0; i < bands.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _legendCard(bands[i], i, hasData, sweep)),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  List<PieChartSectionData> _sections(
    List<_Band> bands,
    bool hasData,
    double sweep,
  ) {
    if (!hasData) {
      // Transparent placeholder: the grey track behind is the whole visual.
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.transparent,
          title: '',
          radius: _arcWidth,
        ),
      ];
    }

    final List<PieChartSectionData> sections = [];
    for (int i = 0; i < bands.length; i++) {
      final band = bands[i];
      // A zero band contributes no arc, and skipping it also drops the
      // hairline seam sectionsSpace would otherwise leave in its place.
      if (band.value == 0) continue;

      final bool isActive = _selected == i;
      sections.add(
        PieChartSectionData(
          value: band.value * sweep,
          title: '',
          radius: isActive ? _arcWidthActive : _arcWidth,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_lighten(band.color), band.color],
          ),
          // Dims the bands you are not asking about, so the answer stands out
          // without the chart changing shape.
          borderSide: BorderSide(
            color: DashTheme.white,
            width: _selected == null || isActive ? 0 : 2,
          ),
        ),
      );
    }

    // Scaling every band by the same factor would leave the proportions
    // identical and the ring looking static. The remainder is parked in a
    // transparent trailing section, so what actually moves is the boundary
    // between drawn and undrawn — a clockwise sweep.
    if (sweep < 1) {
      sections.add(
        PieChartSectionData(
          value: widget.totalTest * (1 - sweep),
          color: Colors.transparent,
          title: '',
          radius: _arcWidth,
        ),
      );
    }

    return sections;
  }

  Widget _centerLabel(List<_Band> bands, bool hasData, double sweep) {
    final int? index = _selected;
    final _Band? band =
        (index != null && index >= 0 && index < bands.length)
            ? bands[index]
            : null;

    final int value = ((band?.value ?? widget.totalTest) * sweep).round();
    final String caption = band != null
        ? band.label
        : (widget.totalTest == 1 ? "test" : "tests");
    final Color valueColor = band?.color ?? DashTheme.ink;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Column(
        key: ValueKey(_selected),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString(),
            style: GoogleFonts.poppins(
              color: valueColor,
              fontSize: 32,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: GoogleFonts.poppins(
              color: band != null ? band.color : DashTheme.faint,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (band != null && hasData) ...[
            const SizedBox(height: 2),
            Text(
              "${_percent(band.value)}%",
              style: GoogleFonts.poppins(
                color: DashTheme.faint,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _percent(int value) {
    if (widget.totalTest == 0) return 0;
    return ((value / widget.totalTest) * 100).round();
  }

  /// Legend entries are controls, not captions — tapping one selects its band,
  /// which is easier than hitting a thin arc.
  Widget _legendCard(_Band band, int index, bool hasData, double sweep) {
    final bool isActive = _selected == index;
    final bool enabled = hasData && band.value > 0;
    final int shown = (band.value * sweep).round();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // Only the card you picked lifts, and it lifts in its own colour.
        // A shadow under all three would just be noise on a flat page.
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: band.color.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : const [],
      ),
      child: Material(
        color: isActive ? band.color.withValues(alpha: 0.10) : DashTheme.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled
              ? () => setState(() => _selected = isActive ? null : index)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? band.color : DashTheme.line,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: band.value == 0 ? DashTheme.line : band.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        band.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: DashTheme.muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      shown.toString(),
                      style: GoogleFonts.poppins(
                        color:
                            band.value == 0 ? DashTheme.faint : DashTheme.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    if (hasData) ...[
                      const SizedBox(width: 4),
                      Text(
                        "${_percent(band.value)}%",
                        style: GoogleFonts.poppins(
                          color: DashTheme.faint,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
