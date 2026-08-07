import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
import 'package:respyr_clinical/widgets/shimmer_placeholders.dart';
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

  // Collapsing title: the patient's name fades into the app bar as the details
  // card scrolls away. Driven by a ValueNotifier so ONLY the app-bar title
  // rebuilds on scroll — never the page body (a full setState per scroll frame
  // rebuilds every card and visibly janks the scroll).
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _titleT = ValueNotifier<double>(0);
  String _loadedProfileName = "";

  static const double _fadeStart = 20;
  static const double _fadeEnd = 70;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final double offset =
        _scrollController.hasClients ? _scrollController.offset : 0;
    _titleT.value = ((offset - _fadeStart) / (_fadeEnd - _fadeStart)).clamp(
      0.0,
      1.0,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleT.dispose();

    super.dispose();
  }

  String _calculateBMI(double weight, double height) {
    return (weight / ((height / 100) * (height / 100))).toStringAsFixed(1);
  }

  String _calculateBMR(double weight, double height, int age, String gender) {
    final bmr =
        (gender.toLowerCase() == "male")
            ? 10 * weight + 6.25 * height - 5 * age + 5
            : 10 * weight + 6.25 * height - 5 * age - 161;
    return bmr.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => SubjectProfileBloc(repository: SubjectProfileRepository())
            ..add(LoadSubjectProfile(widget.clinicName, widget.profileName)),
      child: Scaffold(
        // Light background so the white cards read as cards.
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: ValueListenableBuilder<double>(
            valueListenable: _titleT,
            builder: (context, t, _) {
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 6),
                  child: Text(
                    _loadedProfileName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF252525),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        body: InternetConnectivityHandler(
          onConnectivityChanged: (hasInternet) {
            setState(() => _hasInternet = hasInternet);
          },
          child: BlocConsumer<SubjectProfileBloc, SubjectProfileState>(
            listener: (context, state) {
              if (state is SubjectProfileLoaded) {
                setState(() => _loadedProfileName = state.profile.profileName);
              }
            },
            builder: (context, state) {
              if (state is SubjectProfileLoading) {
                return const SubjectProfileShimmer();
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
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _patientDetailsCard(
                          name: profile.profileName,
                          age: age,
                          gender: profile.gender,
                          height: height,
                          weight: weight,
                        ),
                        const SizedBox(height: 24),
                        BlocProvider(
                          create: (_) => NewResultCubit(),
                          child: SubjectHistoryWidget(
                            scoreList: scores,
                            profileDataModel: profileDetails,
                          ),
                        ),
                        const SizedBox(height: 24),
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

  Widget _patientDetailsCard({
    required String name,
    required int age,
    required String gender,
    required double height,
    required double weight,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF308BF9).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF308BF9),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF252525),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "$age yrs  •  $gender",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF535359),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 14),
          Row(
            children: [
              _statTile("Height", "${height.toStringAsFixed(0)} cm"),
              _statDivider(),
              _statTile("Weight", "${weight.toStringAsFixed(0)} kg"),
              _statDivider(),
              _statTile("BMI", _calculateBMI(weight, height)),
              _statDivider(),
              _statTile(
                "BMR",
                "${_calculateBMR(weight, height, age, gender)} kcal",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF535359),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      height: 30,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFE5E7EB),
    );
  }
}
