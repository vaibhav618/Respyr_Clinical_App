import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:respyr_clinical/shared/colors.dart';

import '../../new_result/bloc/new_result_bloc.dart';
import '../../new_result/bloc/new_result_cubit.dart';
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Heading & Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Test History",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF5A5A5A),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.80,
                      ),
                    ),
                    DropdownButton<String>(
                      value: selectedValue,
                      underline: const SizedBox(),
                      dropdownColor: AppColor.whiteColor,
                      borderRadius: BorderRadius.circular(15),
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
                  ],
                ),
                const SizedBox(height: 30),

                /// Score List
                ListView.builder(
                  itemCount: widget.scoreList.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final score = widget.scoreList[index];
                    final double value = (score[scoreType] as num).toDouble();
                    final String date = score['dttm'] ?? '';

                    try {
                      final parsedDate = DateFormat(
                        'MM/dd/yyyy HH:mm:ss',
                      ).parse(date);
                      String formattedDate = DateFormat(
                        'd MMM y hh:mm a',
                      ).format(parsedDate);

                      return InkWell(
                        onTap: () {
                          context.read<NewResultCubit>().fetchHistory(
                            loginId: widget.profileDataModel.clinicName ?? '',
                            profileId: widget.profileDataModel.subjectId ?? '',
                            id: score["id"].toString(),
                          );
                        },
                        child: _listItem(formattedDate, value),
                      );
                    } catch (e) {
                      return _listItem(date, value);
                    }
                  },
                ),
              ],
            ),
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

  Widget _listItem(String dateTime, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateTime,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF535359),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.10,
                  letterSpacing: -0.30,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${value.toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.10,
                      letterSpacing: -0.30,
                    ),
                  ),
                  Text(
                    _getScoreLabel(value),
                    style: GoogleFonts.poppins(
                      color: _getScoreColor(value),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      height: 1.10,
                      letterSpacing: -0.20,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),
        ],
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

  Color _getScoreColor(double score) {
    if (score < 70) return const Color(0xFFEA5455);
    if (score < 80) return const Color(0xFFF8B10F);
    return const Color(0xFF28C76F);
  }
}
