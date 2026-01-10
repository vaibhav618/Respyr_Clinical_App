import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/corporate_dashboard/dashboard/presentation/widgets/score_trend.dart';
import 'package:respyr_clinical/corporate_dashboard/dashboard/presentation/widgets/timeline.dart';

import '../../../../authentication/corporate/corporate_login/data/response/corporate_login_response.dart';
import '../../bloc/corporate_profile_tests_bloc.dart';
import '../../bloc/corporate_profile_tests_event.dart';
import '../../bloc/corporate_profile_tests_state.dart';
import '../../data/repository/corporate_profile_tests_repository.dart';
import 'scores.dart';

class CorporateDashboardContentScreen extends StatefulWidget {
  final String loginId;
  final String profileId;
  final String? date;
  final VoidCallback  onTrackHealthButtonClicked;
  final CorporateUserData corporateUserData;


  const CorporateDashboardContentScreen({
    super.key,
    required this.loginId,
    required this.profileId,
    this.date,
    required this.onTrackHealthButtonClicked, required this.corporateUserData,
  });

  @override
  State<CorporateDashboardContentScreen> createState() =>
      _CorporateDashboardContentScreenState();
}

class _CorporateDashboardContentScreenState
    extends State<CorporateDashboardContentScreen> {
  late final CorporateProfileTestsBloc _bloc;

  @override
  void initState() {
    super.initState();

    _bloc = CorporateProfileTestsBloc(
      repository: CorporateProfileTestsRepository(
        endpointUrl:
        "https://humorstech.com/humors_app/app_final/clinical/corporate_profile_tests.php",
      ),
    );

    _fetch();
  }

  void _fetch() {
    debugPrint(
      "📤 Fetch tests => loginId=${widget.loginId}, profileId=${widget.profileId}, date=${widget.date}",
    );

    _bloc.add(
      CorporateProfileTestsFetchRequested(
        loginId: widget.loginId,
        profileId: widget.profileId,
        date: widget.date,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant CorporateDashboardContentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final dateChanged = oldWidget.date != widget.date;
    final loginChanged = oldWidget.loginId != widget.loginId;
    final profileChanged = oldWidget.profileId != widget.profileId;

    if (dateChanged || loginChanged || profileChanged) {
      _fetch();
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<CorporateProfileTestsBloc, CorporateProfileTestsState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {},
        child: BlocBuilder<CorporateProfileTestsBloc, CorporateProfileTestsState>(
          builder: (context, state) {
            if (state.status == CorporateProfileTestsStatus.loading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (state.status == CorporateProfileTestsStatus.failure) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    state.errorMessage ?? "Failed to load data",
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (state.status == CorporateProfileTestsStatus.success) {
              final res = state.response!;
              final data = res.data;
              return ListView(
                children: [
                  if(data!.latestOfDate!=null)...[
                    Scores(latestOfDate: data!.latestOfDate, corporateUserData: widget.corporateUserData,),
                  ]else...[
                    noTestTaken(widget.date)
                  ],
                  SizedBox(height: 20,),
                  if(data.latestPerDay.isNotEmpty)
                    ScoreTrend(latestPerDay: data.latestPerDay.take(7).toList(),),
                  SizedBox(height: 20,),

                  if(data.allDesc.isNotEmpty)
                    Timeline(list: data.allDesc.take(5).toList(), corporateUserData: widget.corporateUserData,),
                  SizedBox(height: 150,)
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }


  Widget noTestTaken(String? date) {
    String label = '';

    if (date != null && date.isNotEmpty) {
      try {
        // Expected format: MM/DD/YYYY
        final parts = date.split('/');
        if (parts.length == 3) {
          final mm = int.parse(parts[0]);
          final dd = int.parse(parts[1]);
          final yyyy = int.parse(parts[2]);

          final inputDate = DateTime(yyyy, mm, dd);
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          final yesterdayDate = todayDate.subtract(const Duration(days: 1));

          if (inputDate == todayDate) {
            label = 'today';
          } else if (inputDate == yesterdayDate) {
            label = 'yesterday';
          } else {
            label =
            "${dd.toString().padLeft(2, '0')} "
                "${_monthName(mm)} ";
          }
        }
      } catch (_) {
        label = '';
      }
    }

    final message = label.isNotEmpty
        ? "You haven’t taken your reading $label."
        : "You haven’t taken your reading yet.";




    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: ShapeDecoration(
          gradient: const LinearGradient(
            begin: Alignment(0.50, 0.00),
            end: Alignment(0.50, 1.00),
            colors: [Color(0xFFE4F0FF), Color(0x00E4F0FF)],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          spacing: 50,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFF308BF9),
                fontSize: 25,
                fontWeight: FontWeight.w600,
                height: 1.10,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onTrackHealthButtonClicked();
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF308BF9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                "Track Your Health",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }

}
