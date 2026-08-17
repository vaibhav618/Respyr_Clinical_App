import 'package:flutter/material.dart';
import 'package:respyr_clinical/widgets/shimmer_placeholders.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/model/result_model.dart';

/// MODEL: Lung Performance Calculator
class LungPerformanceChart {
  Map<double, double> calculateLungFlows({
    required List<double> allPressures,
    double chamberVolume = 39.509211,
    double deltaT = 0.125,
    double calibrationConstant = 0.25,
  }) {
    if (allPressures.length < 2) {
      throw ArgumentError("At least two pressure readings are required.");
    }

    double basePressure = allPressures[0];
    List<double> pressures = allPressures.sublist(1);
    Map<double, double> timeFlowMap = {};

    for (int i = 0; i < pressures.length; i++) {
      double time = (i + 1) * deltaT;
      double rawFlow =
          (chamberVolume * (1 - (basePressure / pressures[i]))) / deltaT;
      double calibratedFlow = rawFlow * calibrationConstant;
      timeFlowMap[time] = calibratedFlow;
    }

    return timeFlowMap;
  }
}

/// STATE
abstract class LungChartState {}

class LungChartLoading extends LungChartState {}

class LungChartLoaded extends LungChartState {
  final List<FlSpot> spots;
  final double minY;
  final double maxY;

  LungChartLoaded({
    required this.spots,
    required this.minY,
    required this.maxY,
  });
}

/// CUBIT
class LungChartCubit extends Cubit<LungChartState> {
  LungChartCubit() : super(LungChartLoading());

  void loadLungChart(List<double> allPressures) {
    final flowMap = LungPerformanceChart().calculateLungFlows(
      allPressures: allPressures,
    );

    final spots =
        flowMap.entries.map((entry) => FlSpot(entry.key, entry.value)).toList();

    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    emit(LungChartLoaded(spots: spots, minY: minY, maxY: maxY));
  }
}

/// ✅ MAIN CHART SCREEN (FIXED WITH StatefulWidget)
class LungChartScreen extends StatefulWidget {
  final NewResultModel userResultData;
  const LungChartScreen({super.key, required this.userResultData});

  @override
  State<LungChartScreen> createState() => _LungChartScreenState();
}

class _LungChartScreenState extends State<LungChartScreen> {
  List<double> allPressures = [];

  late final LungChartCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = LungChartCubit();
    allPressures = parseRawBlowValue(widget.userResultData.blowRawValues ?? '');
    // ✅ Delay the Cubit data loading until after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cubit.loadLungChart(allPressures);
    });
  }

  List<double> parseRawBlowValue(String rawValue) {
    return rawValue
        .split(",")
        .map((e) => double.tryParse(e.trim()))
        .whereType<double>()
        .toList();
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: Center(
        child: BlocBuilder<LungChartCubit, LungChartState>(
          builder: (context, state) {
            if (state is LungChartLoaded) {
              return LungPerformanceChartWidget(
                spots: state.spots,
                minY: state.minY,
                maxY: state.maxY,
              );
            } else {
              return const BlockShimmer(height: 160);
            }
          },
        ),
      ),
    );
  }
}

/// CHART WIDGET
class LungPerformanceChartWidget extends StatefulWidget {
  final List<FlSpot> spots;
  final double minY;
  final double maxY;

  const LungPerformanceChartWidget({
    super.key,
    required this.spots,
    required this.minY,
    required this.maxY,
  });

  @override
  State<LungPerformanceChartWidget> createState() =>
      _LungPerformanceChartWidgetState();
}

class _LungPerformanceChartWidgetState extends State<LungPerformanceChartWidget>
    with SingleTickerProviderStateMixin {
  /// Traces the curve left to right, as if the breath were being recorded
  /// live — this is a plot OF a breath, so appearing fully drawn was a missed
  /// opportunity.
  late final AnimationController _controller;
  late final Animation<double> _draw;

  /// The trace waits for the chart to scroll into view. Started from
  /// initState it played immediately — but the chart sits below the
  /// interpretation text, so it usually finished off-screen and the reader
  /// arrived to a chart that had already "always been there".
  bool _started = false;
  ScrollPosition? _scrollPosition;

  /// How much of the chart must be on screen before the trace starts.
  static const double _revealMargin = 80;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _draw = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ScrollPosition? position = Scrollable.maybeOf(context)?.position;
    if (!identical(position, _scrollPosition)) {
      _scrollPosition?.removeListener(_startIfVisible);
      _scrollPosition = position;
      _scrollPosition?.addListener(_startIfVisible);
    }
    // Covers the chart being in view from the first frame (no scroll needed),
    // and the no-Scrollable-ancestor case, where it just plays.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startIfVisible());
  }

  void _startIfVisible() {
    if (_started || !mounted) return;

    final RenderObject? ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return;

    if (_scrollPosition != null) {
      final RenderObject? viewportRO =
          Scrollable.maybeOf(context)?.context.findRenderObject();
      if (viewportRO is RenderBox && viewportRO.hasSize) {
        final double chartTop = ro.localToGlobal(Offset.zero).dy;
        final double chartBottom = chartTop + ro.size.height;
        final double viewTop = viewportRO.localToGlobal(Offset.zero).dy;
        final double viewBottom = viewTop + viewportRO.size.height;

        final bool inView = chartTop < viewBottom - _revealMargin &&
            chartBottom > viewTop + _revealMargin;
        if (!inView) return;
      }
    }

    _started = true;
    _scrollPosition?.removeListener(_startIfVisible);
    _controller.forward();
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_startIfVisible);
    _controller.dispose();
    super.dispose();
  }

  /// The spots up to the drawn fraction, with the tip interpolated between
  /// samples so it advances smoothly instead of snapping point to point.
  List<FlSpot> _visibleSpots(double t) {
    final List<FlSpot> all = widget.spots;
    if (t >= 1 || all.length < 2) return all;

    final double exact = (all.length - 1) * t;
    final int index = exact.floor();
    final double frac = exact - index;

    final List<FlSpot> shown = all.sublist(0, index + 1);
    if (index + 1 < all.length && frac > 0) {
      final FlSpot a = all[index];
      final FlSpot b = all[index + 1];
      shown.add(FlSpot(a.x + (b.x - a.x) * frac, a.y + (b.y - a.y) * frac));
    }
    return shown;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _draw,
      builder: (context, _) => _chart(_visibleSpots(_draw.value)),
    );
  }

  Widget _chart(List<FlSpot> visible) {
    final spots = widget.spots;
    final minY = widget.minY;
    final maxY = widget.maxY;

    final yInterval = ((maxY - minY) / 4).clamp(0.5, 2.0);
    final minX = spots.first.x;
    final maxX = spots.last.x;
    const int minLabels = 6;
    final double xInterval =
        (maxX - minX) < minLabels
            ? 1
            : ((maxX - minX) / minLabels).floorToDouble();

    return Container(
      width: double.infinity,
      height: 270,
      constraints: const BoxConstraints(maxWidth: 300),
      child: LineChart(
        // Axes are computed from the FULL data, so the frame stays fixed
        // while the trace grows into it instead of rescaling every frame.
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: visible,
              isCurved: true,
              curveSmoothness: 0.09,
              color: const Color(0xFF308BF9),
              barWidth: 3,
              dotData: FlDotData(show: false),
              // A soft wash under the curve — the bare 3px line read as thin
              // against a full-width card.
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF308BF9).withValues(alpha: 0.20),
                    const Color(0xFF308BF9).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              axisNameWidget: Text(
                'Seconds',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF959595),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  height: 1.30,
                  letterSpacing: -0.20,
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                interval: xInterval,
                reservedSize: 28,
                getTitlesWidget:
                    (value, _) => Text(
                      value.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF959595),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        height: 1.30,
                        letterSpacing: -0.20,
                      ),
                    ),
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: RotatedBox(
                quarterTurns: 0,
                child: Text(
                  'Flow (L/s)',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF959595),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    height: 1.30,
                    letterSpacing: -0.20,
                  ),
                ),
              ),
              axisNameSize: 20,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: yInterval,
                getTitlesWidget:
                    (value, _) => Text(
                      value >= 0 ? value.toStringAsFixed(1) : '',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF959595),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        height: 1.30,
                        letterSpacing: -0.20,
                      ),
                    ),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
          ),
          lineTouchData: LineTouchData(enabled: false),
          borderData: FlBorderData(show: false),
          minX: minX,
          maxX: maxX,
          minY: minY - 0.5,
          maxY: maxY + 0.5,
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 1.9,
                color: const Color(0xFF959595),
                strokeWidth: 0.7,
                dashArray: [7, 5],
              ),
            ],
          ),
        ),
        // The trace advances a frame at a time; the chart's own lerp between
        // successive data sets would lag behind it and smear the tip.
        duration: Duration.zero,
      ),
    );
  }
}
