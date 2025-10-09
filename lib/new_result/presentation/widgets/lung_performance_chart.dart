import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/shared/colors.dart';

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
              return CircularProgressIndicator(
                color: AppColor.primaryBlueColor,
              );
            }
          },
        ),
      ),
    );
  }
}

/// CHART WIDGET
class LungPerformanceChartWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.09,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
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
      ),
    );
  }
}
