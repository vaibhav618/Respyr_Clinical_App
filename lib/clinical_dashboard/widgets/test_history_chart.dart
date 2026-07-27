import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:respyr_clinical/shared/urls.dart';

// EVENTS
abstract class TestScoreEvent {}

class LoadTestScoreData extends TestScoreEvent {
  final String loginId;
  final String profileId;
  LoadTestScoreData({required this.loginId, required this.profileId});
}

class UpdateSelectedScore extends TestScoreEvent {
  final String selectedScore;
  UpdateSelectedScore(this.selectedScore);
}

// STATES
abstract class TestScoreState {}

class TestScoreInitial extends TestScoreState {}

class TestScoreLoading extends TestScoreState {}

class TestScoreLoaded extends TestScoreState {
  final List<Map<String, dynamic>> scoreList;
  final String selectedScore;

  TestScoreLoaded({required this.scoreList, required this.selectedScore});
}

class TestScoreError extends TestScoreState {
  final String message;
  TestScoreError(this.message);
}

// BLOC
class TestScoreBloc extends Bloc<TestScoreEvent, TestScoreState> {
  TestScoreBloc() : super(TestScoreInitial()) {
    on<LoadTestScoreData>(_loadData);
    on<UpdateSelectedScore>(_updateScore);
  }

  List<String> scoreTypes = [
    "Sugar score",
    "Liver score",
    "Respiratory score",
    "Gut score",
  ];

  Future<void> _loadData(
      LoadTestScoreData event, Emitter<TestScoreState> emit) async {
    emit(TestScoreLoading());
    final uri = Uri.parse(
        '${Urls.trend7Days}?login_id=${event.loginId}&profile_id=${event.profileId}');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final reversedList =
      data.map((e) => e as Map<String, dynamic>).toList().reversed.toList();

      emit(TestScoreLoaded(scoreList: reversedList, selectedScore: scoreTypes[0]));
    } else {
      emit(TestScoreError("Failed to fetch data"));
    }
  }

  void _updateScore(UpdateSelectedScore event, Emitter<TestScoreState> emit) {
    if (state is TestScoreLoaded) {
      final current = state as TestScoreLoaded;
      emit(TestScoreLoaded(scoreList: current.scoreList, selectedScore: event.selectedScore));
    }
  }
}

// UI ENTRY
class TestScoreChart extends StatelessWidget {
  final String loginId;
  final String profileId;

  const TestScoreChart({super.key, required this.loginId, required this.profileId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TestScoreBloc()..add(LoadTestScoreData(loginId: loginId, profileId: profileId)),
      child: _ScrollableChartView(),
    );
  }
}

// STATEFUL WRAPPER
class _ScrollableChartView extends StatefulWidget {
  @override
  State<_ScrollableChartView> createState() => _ScrollableChartViewState();
}

class _ScrollableChartViewState extends State<_ScrollableChartView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<TestScoreBloc>();
      if (bloc.state is TestScoreLoaded) {
        final state = bloc.state as TestScoreLoaded;
        final dataLength = state.scoreList.length;
        if (dataLength > 7) {
          final scrollAmount = (dataLength - 7) * 60;
          _scrollController.animateTo(
            scrollAmount.toDouble(),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TestScoreBloc, TestScoreState>(
      builder: (context, state) {
        if (state is TestScoreLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TestScoreLoaded) {
          final bloc = context.read<TestScoreBloc>();
          final scoreKey = getScoreKey(state.selectedScore);

          final List<FlSpot> spots = [];
          for (int i = 0; i < state.scoreList.length; i++) {
            final item = state.scoreList[i];
            final score = item[scoreKey];
            if (score != null) {
              spots.add(FlSpot(i.toDouble(), (score as num).toDouble()));
            }
          }

          final latestScore = spots.isNotEmpty ? spots.last.y : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 35,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  itemCount: bloc.scoreTypes.length,
                  itemBuilder: (context, index) {
                    final score = bloc.scoreTypes[index];
                    final isSelected = state.selectedScore == score;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ElevatedButton(
                        onPressed: () => bloc.add(UpdateSelectedScore(score)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? const Color(0xFF308BF9) : Colors.white,
                          foregroundColor: isSelected ? Colors.white : const Color(0xFFA1A1A1),
                          side: isSelected ? BorderSide.none : const BorderSide(color: Color(0xFFA1A1A1), width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        ),
                        child: Text(score, style: GoogleFonts.poppins(fontSize: 12)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(latestScore != null ? '${latestScore.toStringAsFixed(1)}%' : '--'),
              Text(
                latestScore != null ? getScoreLabel(latestScore) : '',
                style: TextStyle(
                  color: latestScore != null ? getScoreColor(latestScore) : Colors.transparent,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 40,
                    height: 250,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        final yValue = 100 - (index * 20);
                        return Text(
                          yValue.toString(),
                          style: GoogleFonts.poppins(fontSize: 10, color: Color(0xFFA1A1A1)),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: SizedBox(
                        width: state.scoreList.length * 60,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: 100,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: false,
                                barWidth: 3,
                                color: const Color(0xFF308BF9),
                              )
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, _) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < state.scoreList.length) {
                                      final rawDate = state.scoreList[index]['dttm'];
                                      try {
                                        final date = DateTime.parse(rawDate);
                                        final formatted = DateFormat('MMM d').format(date);
                                        return Text(
                                          formatted,
                                          style: GoogleFonts.poppins(fontSize: 10),
                                        );
                                      } catch (_) {}
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: const Border(
                                bottom: BorderSide(color: Color(0xFFC7C6CE), width: 1),
                                left: BorderSide.none,
                                top: BorderSide.none,
                                right: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else if (state is TestScoreError) {
          return Center(child: Text(state.message));
        } else {
          return const SizedBox();
        }
      },
    );
  }

  String getScoreKey(String scoreType) {
    switch (scoreType) {
      case "Sugar score":
        return "Db_Score";
      case "Liver score":
        return "liver_score";
      case "Respiratory score":
        return "Blow_Score";
      case "Gut score":
        return "Gut_Score_per";
      default:
        return "Db_Score";
    }
  }

  String getScoreLabel(double score) {
    if (score < 70) return "Poor";
    if (score < 80) return "Fair";
    return "Good";
  }

  Color getScoreColor(double score) {
    if (score < 70) return const Color(0xFFEA5455);
    if (score < 80) return const Color(0xFFF8B10F);
    return const Color(0xFF28C76F);
  }
}
