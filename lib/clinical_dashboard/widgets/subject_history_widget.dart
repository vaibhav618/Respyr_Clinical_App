import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:respyr_clinical/shared/colors.dart';

import '../../new_result/bloc/new_result_bloc.dart';
import '../../new_result/bloc/new_result_cubit.dart';
import '../../utils/score_color_helper.dart';
import '../../new_result/data/model/result_model.dart';
import '../../new_result/data/model/result_profile_data_model.dart';
import '../../new_result/presentation/view/overall_result.dart';
import '../../new_result/presentation/view_model/result_view_model.dart';

class SubjectHistoryWidget extends StatefulWidget {
  final List<dynamic> scoreList;
  final ResultProfileDataModel profileDataModel;

  const SubjectHistoryWidget({
    super.key,
    required this.scoreList,
    required this.profileDataModel,
  });

  @override
  State<SubjectHistoryWidget> createState() => _SubjectHistoryWidgetState();
}

class _SubjectHistoryWidgetState extends State<SubjectHistoryWidget> {
  String selectedValue = "Sugar score";
  String scoreType = "Db_Score";
  bool isLoading = false;

  // Incremental rendering: build only this many history cards initially and
  // append a page when the surrounding screen scrolls near its bottom.
  // Building the whole history at once froze the profile screen open for
  // subjects with hundreds of tests.
  static const int _pageSize = 15;
  int _visibleCount = _pageSize;
  ScrollPosition? _pagePosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ScrollPosition? position = Scrollable.maybeOf(context)?.position;
    if (!identical(position, _pagePosition)) {
      _pagePosition?.removeListener(_maybeLoadMore);
      _pagePosition = position;
      _pagePosition?.addListener(_maybeLoadMore);
    }
  }

  void _maybeLoadMore() {
    final ScrollPosition? position = _pagePosition;
    if (position == null || !mounted) return;
    if (position.pixels >= position.maxScrollExtent - 400 &&
        _visibleCount < widget.scoreList.length) {
      setState(() => _visibleCount += _pageSize);
    }
  }

  @override
  void didUpdateWidget(SubjectHistoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fresh subject/data → start from the first page again.
    if (oldWidget.scoreList.length != widget.scoreList.length) {
      _visibleCount = _pageSize;
    }
  }

  @override
  void dispose() {
    _pagePosition?.removeListener(_maybeLoadMore);
    super.dispose();
  }

  final List<String> items = [
    'Sugar score',
    'Liver stress score',
    'Respiratory score',
    'Gut fermentation score',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<NewResultCubit, NewResultState>(
      listener: (context, state) {
        if (state is NewResultLoading) {
          setState(() => isLoading = true);
        } else {
          setState(() => isLoading = false);
        }

        if (state is NewResultSuccess) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ResultScreen(
                    userResultData: state.result,
                    userProfileData: widget.profileDataModel,
                    blowValuesList: [],
                  ),
            ),
          );

          _navigateToResultScreen(state.result, widget.profileDataModel);
        } else if (state is NewResultFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed: ${state.error}')));
        }
      },
      child: Stack(
        children: [
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Heading & Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Test History",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF252525),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.40,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: selectedValue,
                        underline: const SizedBox(),
                        dropdownColor: AppColor.whiteColor,
                        borderRadius: BorderRadius.circular(12),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF308BF9),
                          size: 20,
                        ),
                        items:
                            items.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF535359),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.24,
                                  ),
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedValue = newValue!;
                            scoreType = _mapScoreType(selectedValue);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                /// Score List
                ListView.builder(
                  itemCount:
                      _visibleCount < widget.scoreList.length
                          ? _visibleCount
                          : widget.scoreList.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final score = widget.scoreList[index];
                    final double value = (score[scoreType] as num).toDouble();
                    final String date = score['dttm'] ?? '';

                    void openResult() {
                      context.read<NewResultCubit>().fetchHistory(
                        loginId: widget.profileDataModel.clinicName ?? '',
                        profileId: widget.profileDataModel.subjectId ?? '',
                        id: score["id"].toString(),
                      );
                    }

                    try {
                      final parsedDate = DateFormat(
                        'MM/dd/yyyy HH:mm:ss',
                      ).parse(date);
                      String formattedDate = DateFormat(
                        'd MMM y hh:mm a',
                      ).format(parsedDate);

                      return _historyCard(formattedDate, value, openResult);
                    } catch (e) {
                      return _historyCard(date, value, openResult);
                    }
                  },
                ),
              ],
            ),
          if (isLoading)
            Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColor.primaryBlueColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _mapScoreType(String selected) {
    switch (selected) {
      case "Sugar score":
        return "Db_Score";
      case "Liver stress score":
        return "liver_score";
      case "Respiratory score":
        return "Blow_Score";
      default:
        return "Gut_Score_per";
    }
  }

  /// One past test as a tappable card: date left, colored score + status
  /// pill right, chevron as the "opens the result" hint.
  Widget _historyCard(String dateTime, double value, VoidCallback onTap) {
    final Color scoreColor = ScoreColorHelper.getScoreColor(value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dateTime,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF252525),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${value.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    color: scoreColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getScoreLabel(value),
                    style: GoogleFonts.poppins(
                      color: scoreColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFA1A1A1),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToResultScreen(
    NewResultModel result,
    ResultProfileDataModel profileDetails,
  ) {
    if (Get.isOverlaysOpen) {
      Get.back(); // Close any open overlays/dialogs
    }

    Navigator.of(context).popUntil((route) => route.isFirst);

    Get.offAll(
      () => ChangeNotifierProvider(
        create: (_) => ResultViewModel()..initialize(profileDetails),
        child: ResultScreen(
          userResultData: result,
          userProfileData: profileDetails,
          blowValuesList: [],
        ),
      ),
    );
  }

  String _getScoreLabel(double score) {
    if (score < 70) return "Poor";
    if (score < 80) return "Fair";
    return "Good";
  }
}
