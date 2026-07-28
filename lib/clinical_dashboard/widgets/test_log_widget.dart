import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../bloc/test_log_bloc.dart';
import '../model/OverallDataByDateModel.dart';
import '../repositories/test_log_repository.dart';
import '../views/complete_test_log.dart';
import '../views/subject_profile.dart';

class TestLogWidget extends StatefulWidget {
  final String loginId;
  final String scoreType;
  final List<ScoreData> scoreData;

  const TestLogWidget({
    super.key,
    required this.loginId,
    required this.scoreType,
    required this.scoreData,
  });

  @override
  State<TestLogWidget> createState() => _TestLogWidgetState();
}

class _TestLogWidgetState extends State<TestLogWidget> {
  /// How many entries render inline. The rest are behind "See all" — an inner
  /// scrollbox here trapped the drag gesture at its edges and made the page
  /// feel stuck.
  static const int _maxInline = 8;

  void _openFullLog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => BlocProvider(
              create: (_) => TestLogBloc()..add(FetchTestLogs(widget.loginId)),
              child: CompleteTestLog(loginId: widget.loginId),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int inlineCount =
        widget.scoreData.length > _maxInline
            ? _maxInline
            : widget.scoreData.length;
    final int hiddenCount = widget.scoreData.length - inlineCount;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Test log",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.60,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _openFullLog,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.transparent,
                ),
                child: Row(
                  children: [
                    Text(
                      "See all",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF308BF9),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.10,
                        letterSpacing: -0.30,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_right_sharp,
                      color: Color(0xFF308BF9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Inline entries — part of the page scroll, no inner scrollbox.
        for (int index = 0; index < inlineCount; index++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _testLogTile(
              context,
              widget.loginId,
              widget.scoreData[index].profileId,
              widget.scoreData[index].name,
              widget.scoreData[index].scoreDttm,
              getScoreByType(widget.scoreData[index], widget.scoreType),
            ),
          ),
        if (hiddenCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: TextButton(
              onPressed: _openFullLog,
              child: Text(
                "View $hiddenCount more ${hiddenCount == 1 ? 'test' : 'tests'}",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF308BF9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  double getScoreByType(ScoreData item, String scoreType) {
    switch (scoreType.trim()) {
      // Trim just in case
      case 'Sugar score':
        return double.tryParse(item.dbScore) ?? 0.0;
      case 'Liver stress score':
        return double.tryParse(item.liverScore) ?? 0.0;
      case 'Respiratory score':
        return double.tryParse(item.blowScore) ?? 0.0;
      case 'Gut fermentation score':
        return double.tryParse(item.gutScorePer) ?? 0.0;
      default:
        return 0.0;
    }
  }

  Widget _testLogTile(
    BuildContext context,
    String loginId,
    String subjectId,
    String name,
    String dateTime,
    double score,
  ) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => SubjectProfileScreen(
                      clinicName: loginId,
                      profileName: subjectId,
                    ),
              ),
            );
          },

          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0), // Custom shape
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF535359),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.10,
                          letterSpacing: -0.30,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        formatDate(dateTime),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF5A5A5A),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.24,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    height: 10,
                    width: 10,
                    decoration: ShapeDecoration(
                      color: getScoreColor(score),
                      shape: const OvalBorder(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "${score.toStringAsFixed(0)}%",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF535359),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.10,
                      letterSpacing: -0.30,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  String formatDate(String input) {
    try {
      final dt = DateFormat("MM/dd/yyyy HH:mm:ss").parse(input);
      return DateFormat("MMM d, hh:mma").format(dt);
    } catch (_) {
      return input; // Fallback if parsing fails
    }
  }

  Color getScoreColor(double score) {
    if (score < 70) {
      return const Color(0xFFEA5455);
    } else if (score >= 70 && score < 80) {
      return const Color(0xFFFFC412);
    } else {
      return const Color(0xFF3EAF58);
    }
  }
}
