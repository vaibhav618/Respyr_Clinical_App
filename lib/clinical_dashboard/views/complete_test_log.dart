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

  // Incremental rendering: only this many cards are built at first; scrolling
  // near the bottom appends another page. Building the full list at once
  // (shrinkWrap) laid out every card in one frame and froze the page open.
  static const int _pageSize = 15;
  int _visibleCount = _pageSize;
  int _totalCount = 0;
  final ScrollController _scrollController = ScrollController();

  // Collapsing search: the body search bar cross-fades into the app bar as it
  // scrolls under. Driven by a ValueNotifier so only the two fading widgets
  // rebuild on scroll, never the card list.
  final ValueNotifier<double> _searchT = ValueNotifier<double>(0);
  static const double _fadeStart = 8;
  static const double _fadeEnd = 56;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    //context.read<TestLogBloc>().add(FetchTestLogs(widget.loginId));
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;

    _searchT.value = ((position.pixels - _fadeStart) / (_fadeEnd - _fadeStart))
        .clamp(0.0, 1.0);

    if (position.pixels >= position.maxScrollExtent - 400 &&
        _visibleCount < _totalCount) {
      setState(() => _visibleCount += _pageSize);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchT.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// The search field, styled for either location. Shares [_controller] with
  /// its twin so the query carries over as the bar docks into the app bar.
  Widget _searchField({required bool compact}) {
    return Container(
      height: compact ? 40 : null,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: TextField(
        controller: _controller,
        style: GoogleFonts.poppins(
          color: const Color(0xFF86BDFF),
          fontSize: compact ? 13 : 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.60,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search,
            color: const Color(0xFF86BDFF),
            size: compact ? 20 : 24,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(Icons.close, size: compact ? 18 : 24),
                onPressed: () {
                  _controller.clear();
                  _visibleCount = _pageSize;
                  context.read<TestLogBloc>().add(FilterTestLogs(''));
                  FocusScope.of(context).unfocus();
                },
              );
            },
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 20,
            vertical: compact ? 8 : 16,
          ),
          border: InputBorder.none,
          hintText: 'Search ‘Sagar’',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF86BDFF),
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.60,
          ),
        ),
        onChanged: (value) {
          // New filter → start again from the first page.
          _visibleCount = _pageSize;
          context.read<TestLogBloc>().add(FilterTestLogs(value));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Light background so the white patient cards read as cards.
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        // Cross-fade: "Test Log" title at the top; the search bar docks in as
        // its body twin scrolls under the app bar.
        title: ValueListenableBuilder<double>(
          valueListenable: _searchT,
          builder: (context, t, _) {
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                IgnorePointer(
                  ignoring: t > 0.5,
                  child: Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0),
                    child: Text(
                      "Test Log",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF5A5A5A),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.80,
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  ignoring: t <= 0.5,
                  child: Opacity(
                    opacity: t,
                    child: _searchField(compact: true),
                  ),
                ),
              ],
            );
          },
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
                _totalCount = filteredList.length;
                final int builtCount =
                    _visibleCount < filteredList.length
                        ? _visibleCount
                        : filteredList.length;

                return SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Fades out in lock-step with the app-bar search fading
                      // in, so the bar reads as docking into the app bar.
                      ValueListenableBuilder<double>(
                        valueListenable: _searchT,
                        builder: (context, t, child) {
                          return IgnorePointer(
                            ignoring: t > 0.5,
                            child: Opacity(
                              opacity: (1 - t).clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _searchField(compact: false),
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
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFFA1A1A1),
                                  BlendMode.srcIn,
                                ),
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
                            itemCount: builtCount,
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
                // ── Header: name + tests pill, then id • time ───────────────
                //
                // No avatar. It was a circle holding the first letter of the
                // name printed beside it — no information of its own — and it
                // cost 52px of a 288px card, which is what left the name and
                // the pill fighting over the rest on a 360dp phone. It also
                // indented the header text to a second left edge while the
                // score rows below started at the card's, so one card had two
                // margins. Everything lines up now, and the name has ~218px
                // instead of ~166px.
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF252525),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
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
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Full card width now — nothing to its right, and no indent.
                Text(
                  "$profileId  •  $dateTime",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFA1A1A1),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 12),

                // ── Scores: one per line ────────────────────────────────────
                _scoreRow("Sugar Score", diabeticScore),
                const SizedBox(height: 9),
                _scoreRow("Liver Stress Score", liverScore),
                const SizedBox(height: 9),
                _scoreRow("Respiratory Score", respiratoryScore),
                const SizedBox(height: 9),
                _scoreRow("Gut Fermentation Score", gutScore),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One score: name on the left, value on the right in its band's colour.
  ///
  /// Each score used to carry a progress bar, and later a tinted pill. Both
  /// were extra encodings of a number that is already printed and already
  /// coloured — four of either per card turned the list into a texture. The
  /// colour alone says good, fair or poor.
  Widget _scoreRow(String label, double score) {
    final Color scoreColor = ScoreColorHelper.getScoreColor(score);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: const Color(0xFF535359),
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          "${score.toStringAsFixed(0)}%",
          style: GoogleFonts.poppins(
            color: scoreColor,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}
