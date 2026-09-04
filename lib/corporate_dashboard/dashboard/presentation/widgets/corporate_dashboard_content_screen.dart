
import 'package:flutter/material.dart';
import 'package:respyr_clinical/widgets/shimmer_placeholders.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/corporate_dashboard/dashboard/presentation/widgets/score_trend.dart';
import 'package:respyr_clinical/corporate_dashboard/dashboard/presentation/widgets/timeline.dart';
import 'package:respyr_clinical/shared/nodeurl.dart';

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
  final VoidCallback onTrackHealthButtonClicked;
  final CorporateUserData corporateUserData;

  const CorporateDashboardContentScreen({
    super.key,
    required this.loginId,
    required this.profileId,
    this.date,
    required this.onTrackHealthButtonClicked,
    required this.corporateUserData,
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
        endpointUrl: NodeUrls.corporateProfileTests,
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
      child: BlocListener<
        CorporateProfileTestsBloc,
        CorporateProfileTestsState
      >(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {},
        child:
            BlocBuilder<CorporateProfileTestsBloc, CorporateProfileTestsState>(
              builder: (context, state) {
                if (state.status == CorporateProfileTestsStatus.loading) {
                  return const ListShimmer(
                    rows: 3,
                    rowHeight: 72,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  );
                }

                if (state.status == CorporateProfileTestsStatus.failure) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 32,
                    ),
                    child: Center(
                      child: Text(
                        state.errorMessage ?? "Failed to load data",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF535359),
                          fontSize: 13,
                        ),
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
                      if (data!.latestOfDate != null) ...[
                        Scores(
                          latestOfDate: data.latestOfDate,
                          corporateUserData: widget.corporateUserData,
                        ),
                      ] else ...[
                        noTestTaken(widget.date),
                      ],
                      SizedBox(height: 20),
                      if (data.latestPerDay.isNotEmpty)
                        ScoreTrend(
                          latestPerDay: data.latestPerDay.take(7).toList(),
                        ),
                      SizedBox(height: 20),

                      if (data.allDesc.isNotEmpty)
                        Timeline(
                          list: data.allDesc.take(5).toList(),
                          corporateUserData: widget.corporateUserData,
                        ),
                      SizedBox(height: 150),
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

    final message =
        label.isNotEmpty
            ? "You haven’t taken your reading $label."
            : "You haven’t taken your reading yet.";

    // Standard empty-state card — the old block set a 25px blue sentence on
    // a fading gradient with a 50px void before a pill button.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            Container(
              height: 56,
              width: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF308BF9).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.air_rounded,
                color: Color(0xFF308BF9),
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.35,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "A reading takes about a minute.",
              style: GoogleFonts.poppins(
                color: const Color(0xFF535359),
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  widget.onTrackHealthButtonClicked();
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF308BF9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Take Test",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }
}
