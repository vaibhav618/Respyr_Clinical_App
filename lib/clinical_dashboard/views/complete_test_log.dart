import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_dashboard/views/subject_profile.dart';
import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
import 'package:respyr_clinical/widgets/shimmer_placeholders.dart';
import '../../utils/score_color_helper.dart';
import '../bloc/test_log_bloc.dart';
import '../helper/timestamp_helper.dart';
import '../repositories/test_log_repository.dart';

class CompleteTestLog extends StatefulWidget {
  final String loginId;
  const CompleteTestLog({super.key, required this.loginId});

  @override
  State<CompleteTestLog> createState() => _CompleteTestLogState();
}

class _CompleteTestLogState extends State<CompleteTestLog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    //context.read<TestLogBloc>().add(FetchTestLogs(widget.loginId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Light background so the white patient cards read as cards.
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          "Test Log",
          style: GoogleFonts.poppins(
            color: const Color(0xFF5A5A5A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.80,
          ),
        ),
      ),
      body: SafeArea(
        child: InternetConnectivityHandler(
          isBody: true,
          onConnectivityChanged: (hasInternet) {
            context.read<TestLogBloc>().add(FetchTestLogs(widget.loginId));
          },

          child: BlocBuilder<TestLogBloc, TestLogState>(
            builder: (context, state) {
              if (state is TestLogLoading) {
                return const TestLogShimmer();
              } else if (state is TestLogError) {
                return Center(child: Text(state.message));
              } else if (state is TestLogLoaded) {
                final filteredList =
                    state.filteredList
                        .where((item) => item.profileId.isNotEmpty)
                        .toList();

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF86BDFF),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.60,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFF86BDFF),
                              ),
                              suffixIcon: Visibility(
                                visible: _controller.text.isNotEmpty,
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _controller.clear();
                                    context.read<TestLogBloc>().add(
                                      FilterTestLogs(''),
                                    );
                                    FocusScope.of(context).unfocus();
                                  },
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              border: InputBorder.none,
                              hintText: 'Search ‘Sagar’',
                              hintStyle: GoogleFonts.poppins(
                                color: const Color(0xFF86BDFF),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.60,
                              ),
                            ),
                            onChanged:
                                (value) => context.read<TestLogBloc>().add(
                                  FilterTestLogs(value),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      filteredList.isEmpty
                          ? Column(
                            children: [
                              const SizedBox(height: 50),
                              SvgPicture.asset(
                                "assets/sagar/folder-error-svgrepo-com.svg",
                                width: 100,
                                height: 100,
                                color: const Color(0xFFA1A1A1),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "No test history found",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFA1A1A1),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.80,
                                ),
                              ),
                              const SizedBox(height: 50),
                            ],
                          )
                          : ListView.builder(
                            itemCount: filteredList.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final item = filteredList[index];

                              if (item.profileName == "Unknown") {
                                return SizedBox.shrink();
                              }

                              return _patientCard(
                                dateTime: formatDateTimeOrRelative(
                                  item.timestamp,
                                ),
                                profileId: item.profileId,
                                profileName: item.profileName,
                                diabeticScore: item.diabeticScore,
                                liverScore: item.liverScore,
                                respiratoryScore: item.respiratoryScore,
                                gutScore: item.gutScore,
                                recordCount: item.recordCount,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => SubjectProfileScreen(
                                            clinicName: widget.loginId,
                                            profileName: item.profileId,
                                          ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _patientCard({
    required String dateTime,
    required String profileId,
    required String profileName,
    required double diabeticScore,
    required double liverScore,
    required double respiratoryScore,
    required double gutScore,
    required int recordCount,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: avatar + name + id • date + tests pill ──────────
                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF308BF9).withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        profileName.isNotEmpty
                            ? profileName[0].toUpperCase()
                            : "?",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF308BF9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileName,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF252525),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            "$profileId  •  $dateTime",
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF535359),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF308BF9).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$recordCount ${recordCount == 1 ? 'test' : 'tests'}",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF308BF9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 12),

                // ── Scores: 2×2 grid of tiles ───────────────────────────────
                Row(
                  children: [
                    _scoreTile("Sugar Score", diabeticScore),
                    const SizedBox(width: 12),
                    _scoreTile("Liver Stress Score", liverScore),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _scoreTile("Respiratory Score", respiratoryScore),
                    const SizedBox(width: 12),
                    _scoreTile("Gut fermentation Score", gutScore),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One score cell: label, colored value, thin progress bar underneath.
  Widget _scoreTile(String label, double score) {
    final Color scoreColor = ScoreColorHelper.getScoreColor(score);
    final double fraction = (score / 100).clamp(0.0, 1.0);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: const Color(0xFF535359),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "${score.toStringAsFixed(0)}%",
            style: GoogleFonts.poppins(
              color: scoreColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 4,
              width: double.infinity,
              color: const Color(0xFFE5E7EB),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction,
                child: Container(color: scoreColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
