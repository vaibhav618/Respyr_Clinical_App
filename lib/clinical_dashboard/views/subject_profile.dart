import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:respyr_clinical/shared/colors.dart';

import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
import '../../new_result/bloc/new_result_cubit.dart';
import '../../new_result/data/model/result_profile_data_model.dart';
import '../bloc/subject_profile_bloc.dart';
import '../events/subject_profile_event.dart';
import '../repositories/subject_profile_repository.dart';
import '../state/subject_profile_state.dart';
import '../widgets/subject_history_widget.dart';

class SubjectProfileScreen extends StatefulWidget {
  final String clinicName;
  final String profileName;

  const SubjectProfileScreen({
    super.key,
    required this.clinicName,
    required this.profileName,
  });

  @override
  State<SubjectProfileScreen> createState() => _SubjectProfileScreenState();
}

class _SubjectProfileScreenState extends State<SubjectProfileScreen> {
  bool _hasInternet = true;

  String _calculateBMI(double weight, double height) {
    return (weight / ((height / 100) * (height / 100))).toStringAsFixed(1);
  }

  String _calculateBMR(double weight, double height, int age, String gender) {
    final bmr =
        (gender.toLowerCase() == "male")
            ? 10 * weight + 6.25 * height - 5 * age + 5
            : 10 * weight + 6.25 * height - 5 * age - 161;
    return bmr.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => SubjectProfileBloc(repository: SubjectProfileRepository())
            ..add(LoadSubjectProfile(widget.clinicName, widget.profileName)),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        body: InternetConnectivityHandler(
          onConnectivityChanged: (hasInternet) {
            setState(() => _hasInternet = hasInternet);
          },
          child: BlocBuilder<SubjectProfileBloc, SubjectProfileState>(
            builder: (context, state) {
              if (state is SubjectProfileLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColor.primaryBlueColor,
                  ),
                );
              } else if (state is SubjectProfileLoaded) {
                final profile = state.profile;
                final scores = state.scores;

                final height = double.tryParse(profile.height) ?? 0;
                final weight = double.tryParse(profile.weight) ?? 0;
                final age = int.tryParse(profile.age) ?? 0;

                final profileDetails = ResultProfileDataModel(
                  subjectId: widget.profileName,
                  clinicName: widget.clinicName,
                  profileName: profile.profileName,
                  gender: profile.gender,
                  age: age,
                  height: height,
                  weight: weight,
                  region: "not_available",
                  dttm: "not_available",
                );

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              SvgPicture.asset("assets/sagar/profile41.svg"),
                              const SizedBox(height: 20),
                              Text(
                                profile.profileName,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(fontSize: 30),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '$age yrs | ${profile.gender}',
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow("Height", "$height cm"),
                              _buildInfoRow("Weight", "$weight kg"),
                              _buildInfoRow(
                                "BMI",
                                _calculateBMI(weight, height),
                              ),
                              _buildInfoRow(
                                "BMR",
                                "${_calculateBMR(weight, height, age, profile.gender)} Kcal",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        BlocProvider(
                          create: (_) => NewResultCubit(),
                          child: SubjectHistoryWidget(
                            scoreList: scores,
                            profileDataModel: profileDetails,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (state is SubjectProfileError) {
                return Center(child: Text(state.message));
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 12)),
          Text(value, style: GoogleFonts.poppins(fontSize: 12)),
        ],
      ),
    );
  }
}
