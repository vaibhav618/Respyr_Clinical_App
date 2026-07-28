import 'dart:async'; // ✅ ADDED

import 'package:respyr_clinical/widgets/shimmer_placeholders.dart';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:respyr_clinical/account_center/menu_screen.dart';
import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:respyr_clinical/widgets/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../common/floating_message.dart';
import '../../fcm/save_fcm_token.dart';
import '../bloc/health_score_bloc.dart';
import '../bloc/overall_data_by_date_event.dart';
import '../bloc/overall_data_by_date_state.dart';
import '../bloc/test_log_bloc.dart';
import '../create_profile/create_profile.dart' show CreateProfile;
import '../existing_profile/views/profile_screen.dart';
import '../helper/abort_device_manager.dart';
import '../helper/fetch_clinic_test_counts.php.dart';
import '../helper/get_clinical_test_count.dart';
import '../repositories/test_log_repository.dart';
import '../task_manager/task_manager.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/check_abort_sheet.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/dashboard_header_detail.dart';
import '../widgets/errors.dart';
import '../widgets/overall_analytics_widget.dart';
import '../widgets/take_test_sheet.dart';
import '../widgets/test_details_widget.dart';
import '../widgets/test_limit_completed_sheet.dart';
import 'complete_test_log.dart';

// ✅ ADDED (update path if needed)

class ClinicalDashboardMain extends StatefulWidget {
  final String loginId;
  const ClinicalDashboardMain({super.key, required this.loginId});

  @override
  State<ClinicalDashboardMain> createState() => _ClinicalDashboardMainState();
}

class _ClinicalDashboardMainState extends State<ClinicalDashboardMain>
    with WidgetsBindingObserver {
  DateTime selectedDate = DateTime.now();
  bool _hasFetchedInitialData = false;
  Map<String, dynamic>? clinicalTestCountData;

  // Created once and reused across rebuilds. Building the future inline in
  // the FutureBuilder made every setState (e.g. toggling the calendar) restart
  // it, flashing the loading skeleton as if the page reloaded.
  Future<Map<String, dynamic>?>? _testDataFuture;
  int totalSubjectsOnboarded1 = 0;
  bool _hasInternet = true;
  bool _hasCheckedForUpdate = false;
  final TaskQueueManager taskManager = TaskQueueManager();

  static const String sharedPrefsKey = 'clinical_test_data';
  static const String testAllowKey = 'test_allow';
  static const String testNoKey = 'test_no';
  static const String scoreCountKey = 'clinical_score_count';
  static const String statusKey = 'status';
  static const String successValue = 'success';

  // ✅ ADDED (cooldown toast timer)
  Timer? _cooldownToastTimer;

  String get formattedDate {
    return "${selectedDate.month.toString().padLeft(2, '0')}/"
        "${selectedDate.day.toString().padLeft(2, '0')}/"
        "${selectedDate.year}";
  }

  final List<DateTime> _markedEvents = [];
  bool _isCalendarVisible = false;
  ValueNotifier<String> selectedDateNotifier = ValueNotifier<String>(
    DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initData();
    _cacheLoginId(widget.loginId);
    selectedDateNotifier.addListener(() {
      setState(() {
        selectedDate = DateTime.parse(selectedDateNotifier.value);
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    });
  }

  Future<void> _cacheLoginId(String loginId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userLoginId', loginId);
  }

  void _initData() {
    if (_hasFetchedInitialData || !_hasInternet) return;

    _hasFetchedInitialData = true;

    taskManager.add(() async => fetchOverallData());
    taskManager.add(() async {
      await fetchTestAllowApi();
      // Fresh quota data was just written to storage — re-read it once.
      if (mounted) {
        setState(() => _testDataFuture = getStoredClinicalTestData());
      }
    });
    taskManager.add(() async => requestNotificationPermission());
    taskManager.add(() async => saveFCMToken());
    if (!_hasCheckedForUpdate) {
      _hasCheckedForUpdate = true;
      taskManager.add(() async {
        try {
          checkForUpdate();
        } catch (e) {
          debugPrint("checkForUpdate failed: $e");
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownToastTimer?.cancel(); // ✅ ADDED
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initData();
    }
  }

  void fetchOverallData() async {
    context.read<HealthScoreBloc>().add(
      FetchHealthScoreData(loginId: widget.loginId, date: formattedDate),
    );
  }

  Future<void> fetchTestAllowApi() async {
    final result = await fetchClinicalDetails(loginId: widget.loginId);
    if (result.statusCode == 200 && result.data[statusKey] == successValue) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(sharedPrefsKey, jsonEncode(result.data));
    }
  }

  Future<void> saveFCMToken() async {
    await FirebaseMessaging.instance.getToken().then((token) {
      FCMManager().saveFcmToken(loginId: widget.loginId, fcmToken: token!);
    });
  }

  Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  void openRightDrawer(scaffoldKey) {
    scaffoldKey.currentState?.openEndDrawer();
  }

  // ✅ ADDED: cooldown seconds checker (uses last_reading_time from SharedPrefs)
  Future<int> getRemainingCooldownSeconds({int cooldownSeconds = 40}) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt('last_reading_time');
    if (last == null) return 0;

    final diff = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(last))
        .inSeconds;

    final remaining = cooldownSeconds - diff;
    return remaining > 0 ? remaining : 0;
  }

  // ✅ ADDED: FloatingMessage toast countdown
  Future<void> showCooldownToast(BuildContext context, int seconds) async {
    _cooldownToastTimer?.cancel();

    int remaining = seconds;

    FloatingMessage.show(
      context,
      message: 'Please wait $remaining seconds before next test',
      type: FloatingMessageType.warning,
      duration: Duration(seconds: remaining + 1),
      fromTop: false,
    );

    _cooldownToastTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      remaining--;

      if (!mounted) {
        t.cancel();
        return;
      }

      if (remaining <= 0) {
        t.cancel();
        FloatingMessage.hide();
        return;
      }

      FloatingMessage.update(
        'Please wait $remaining seconds before next test',
        duration: Duration(seconds: remaining + 1),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loginId.isEmpty) {
      return Errors().showDashboardLoadError(errorMessage: "Clinic not found");
    }

    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      // Light background so the white dashboard cards read as cards.
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildCustomAppBar(),
      body: InternetConnectivityHandler(
        isBody: true,
        onConnectivityChanged: (hasInternet) {
          _hasInternet = hasInternet;
          if (hasInternet) {
            _hasFetchedInitialData = false;
            _initData();
          }
        },
        child: Stack(
          // Fill the viewport even when the page content is short (e.g. a
          // "no test data" message) — otherwise the Stack shrinks to the text
          // and clips the calendar overlay.
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  BlocBuilder<HealthScoreBloc, HealthScoreState>(
                builder: (context, state) {
                  if (state is HealthScoreLoading) {
                    return const DashboardShimmer();
                  } else if (state is HealthScoreLoaded) {
                    final scores = state.response.data;
                    final analytics = state.response.analytics;

                    totalSubjectsOnboarded1 =
                        state.response.totalPersonalInfoCount;

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _testDataFuture ??= getStoredClinicalTestData(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const DashboardShimmer();
                        } else if (snapshot.hasError) {
                          return const Center(
                            child: Text('Error loading test data'),
                          );
                        } else if (snapshot.hasData && snapshot.data != null) {
                          if (clinicalTestCountData == null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                clinicalTestCountData = snapshot.data;
                                totalSubjectsOnboarded1 =
                                    totalSubjectsOnboarded1;
                              });
                            });
                          }

                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 20),
                                dashboardHeader(
                                  formattedDate: selectedDate,
                                  totalTestCount: scores.length,
                                ),
                                SizedBox(height: 20),
                                Visibility(
                                  visible: scores.isNotEmpty,
                                  child: OverallAnalyticsWidget(
                                    genderDistribution: analytics
                                        .genderDistribution
                                        .map(
                                          (gender, data) => MapEntry(
                                        gender,
                                        ScoreTypesForGender(
                                          dbScore: ScoreBreakdown(
                                            good: data.dbScore.good,
                                            fair: data.dbScore.fair,
                                            poor: data.dbScore.poor,
                                          ),
                                          liverScore: ScoreBreakdown(
                                            good: data.liverScore.good,
                                            fair: data.liverScore.fair,
                                            poor: data.liverScore.poor,
                                          ),
                                          gutScorePer: ScoreBreakdown(
                                            good: data.gutScorePer.good,
                                            fair: data.gutScorePer.fair,
                                            poor: data.gutScorePer.poor,
                                          ),
                                          blowScore: ScoreBreakdown(
                                            good: data.blowScore.good,
                                            fair: data.blowScore.fair,
                                            poor: data.blowScore.poor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    date: formattedDate,
                                    scoreData: scores,
                                    loginId: widget.loginId,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TestDetailsWidget(
                                  clinicalTestCountData: snapshot.data,
                                  totalSubjectsOnboarded: totalSubjectsOnboarded1,
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          );
                        } else {
                          return const Center(
                            child: Text('No test data found'),
                          );
                        }
                      },
                    );
                  } else if (state is HealthScoreError) {
                    final now = DateTime.now();
                    final isToday =
                        selectedDate.year == now.year &&
                            selectedDate.month == now.month &&
                            selectedDate.day == now.day;

                    if (isToday) {
                      return const Center(
                        child: Text(
                          "No test data found for today.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      );
                    } else {
                      // To prevent repeated triggering
                      if (selectedDate != now) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "No test data found.",
                                style: GoogleFonts.poppins(),
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );

                          setState(() {
                            selectedDate = now;
                          });
                          fetchOverallData();
                        });
                      }

                      return const Center(
                        child: Text("Loading previous date data..."),
                      );
                    }
                  }

                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),

            // Calendar dropdown overlay: floats OVER the content (fade+slide,
            // compositor-only) instead of pushing it down — animating the old
            // in-flow container re-laid-out the whole page every frame.
            if (_isCalendarVisible)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleCalendar,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_isCalendarVisible,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  opacity: _isCalendarVisible ? 1 : 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    offset:
                        _isCalendarVisible ? Offset.zero : const Offset(0, -0.04),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildCalendar(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        activeIndex: 0,
        onDashboardTap: () => _initData(),
        onTakeTestTap: () async {
          if (_hasInternet) {
            // ✅ ADDED: Bluetooth cooldown check here
            final remaining =
            await getRemainingCooldownSeconds(cooldownSeconds: 40);

            if (!mounted) return;

            if (remaining > 0) {
              await showCooldownToast(context, remaining);
              return;
            }

            checkDeviceAbortStatus();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No internet connection')),
            );
          }
        },
        onProfileTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) =>
                TestLogBloc()..add(FetchTestLogs(widget.loginId)),
                child: CompleteTestLog(loginId: widget.loginId),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> checkDeviceAbortStatus() async {
    final isDeviceAborted = await AbortDeviceManager.getAbortStatus();
    if (!mounted) return;
    if (isDeviceAborted) {
      CheckAbortSheet.show(context: context, onTakeTextClick: performTakeTest);
    } else {
      await performTakeTest();
    }
  }

  Future<void> performTakeTest() async {
    Map<String, dynamic>? data = await getStoredClinicalTestData();

    // Retry if local data is not available
    if (data == null) {
      await fetchTestAllowApi();
      data = await getStoredClinicalTestData();
    }

    if (!mounted || data == null) {
      _showBeforeTestPlaceholder();
      return;
    }

    final String isTestAllowed =
        (data[testAllowKey]?.toString().toLowerCase()) ?? "false";
    final int? testLimitCount = int.tryParse(data[testNoKey]?.toString() ?? '');
    final int? testTokenCount = int.tryParse(
      data[scoreCountKey]?.toString() ?? '',
    );

    if (isTestAllowed == "true") {
      final isLimitReached =
          testTokenCount != null &&
              testLimitCount != null &&
              testTokenCount > testLimitCount;

      if (isLimitReached) {
        TestLimitReached.showBottomSheet(context);
      } else {
        BeforeTest.show(
          context: context,
          onCreateNewProfileClicked: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateProfile(loginId: widget.loginId),
              ),
            );
          },
          onSelectExistingProfileClicked: () {
            _navigateToExistingProfiles(isCreateAccountButtonShow: true);
          },
        );
      }
    } else {
      _showBeforeTestPlaceholder();
    }
  }

  void _showBeforeTestPlaceholder() {
    BeforeTest.show(
      context: context,
      onCreateNewProfileClicked: () {},
      onSelectExistingProfileClicked: () {},
    );
  }

  void _navigateToExistingProfiles({required bool isCreateAccountButtonShow}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExistingProfilesListScreen(
          clinicName: widget.loginId,
          isCreateAccountButtonShow: isCreateAccountButtonShow,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildCustomAppBar() {
    return CustomAppBar(
      selectedDate: selectedDate,
      onDateTap: () {
        if (_hasInternet) {
          _toggleCalendar();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No internet connection')),
          );
        }
      },
      calendarVisible: _isCalendarVisible,
      loginName: widget.loginId,
      onProfileTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => MenuScreen(
              loginId: widget.loginId,
              totalSubjectsOnboarded: totalSubjectsOnboarded1,
              clinicalTestCountData: clinicalTestCountData,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0); // Start from right
              const end = Offset.zero;
              const curve = Curves.ease;

              final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              final offsetAnimation = animation.drive(tween);

              return SlideTransition(position: offsetAnimation, child: child);
            },
          ),
        );
      },
    );
  }

  void _toggleCalendar() {
    setState(() {
      _isCalendarVisible = !_isCalendarVisible;
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      selectedDateNotifier.value = formattedDate;
    });

    // Scroll to the top when the calendar is toggled
    if (_isCalendarVisible) {
      _scrollController.animateTo(
        0, // Scroll to the top
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Calendar widget using TableCalendar
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime(2020),
      lastDay: DateTime.now(),
      focusedDay: selectedDate,
      selectedDayPredicate: (day) => _markedEvents.any(
            (markedDay) =>
        markedDay.year == day.year &&
            markedDay.month == day.month &&
            markedDay.day == day.day,
      ),
      onDaySelected: _onDaySelected,
      daysOfWeekHeight: 20,
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: GoogleFonts.mulish(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColor.primaryBlackColor,
        ),
        weekendStyle: GoogleFonts.mulish(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColor.primaryBlackColor,
        ),
      ),
      calendarStyle: CalendarStyle(
        disabledTextStyle: GoogleFonts.roboto(
          fontSize: 14,
          color: Colors.grey[500],
        ),
        selectedDecoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        todayDecoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        weekendTextStyle: GoogleFonts.roboto(
          fontSize: 14,
          color: const Color(0xFFEA5455),
        ),
        defaultTextStyle: GoogleFonts.roboto(
          fontSize: 14,
          color: AppColor.primaryBlackColor,
        ),
        outsideDaysVisible: false,
        todayTextStyle: GoogleFonts.roboto(
          fontSize: 14,
          color: AppColor.primaryBlackColor,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColor.primaryBlackColor,
        ),
      ),
      calendarBuilders: CalendarBuilders(markerBuilder: _markerBuilder),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (selectedDay != selectedDate) {
      setState(() {
        selectedDate = selectedDay;
        selectedDateNotifier.value = DateFormat('yyyy-MM-dd').format(selectedDay);
        _isCalendarVisible = false;
      });
      fetchOverallData(); // 🔥 Fetch data for selected date
    }
  }

  Widget? _markerBuilder(
      BuildContext context,
      DateTime day,
      List<dynamic> events,
      ) {
    bool isMarked = _markedEvents.any(
          (markedDate) =>
      markedDate.year == day.year &&
          markedDate.month == day.month &&
          markedDate.day == day.day,
    );

    if (!isMarked) return null;

    return Center(
      child: Container(
        height: 35,
        width: 35,
        decoration: BoxDecoration(
          color: AppColor.primaryBlueColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: GoogleFonts.roboto(fontSize: 14, color: AppColor.whiteColor),
          ),
        ),
      ),
    );
  }
}
