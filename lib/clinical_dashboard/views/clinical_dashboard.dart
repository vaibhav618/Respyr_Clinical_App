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
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/services/clinical_usb_communication_services.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/generation_foreground_service.dart';
import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
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

  // MUST live outside build(): a GlobalKey minted inside build() changes on
  // every rebuild, which makes Flutter discard and remount the entire Scaffold
  // subtree per setState — the whole screen visibly blinked on every calendar
  // toggle.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
    // Landing on the dashboard means no test is in flight — finished,
    // cancelled, disconnected or timed out. Single place to release the
    // foreground service so no abort path can leave it (and its notification)
    // running.
    GenerationForegroundService.stop();
    // The USB service is a singleton, so a test that paused it on the way out
    // would leave it paused for the whole app — muting the stream the next
    // test's readiness check relies on, and making it look idle when it isn't.
    ClinicalUsbCommunicationServices().resumeCommunication();
    // Landing here after a reading means the button may still be locked.
    _refreshTakeTestLock();
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

    // These two feed the screen, and they do not depend on each other — start
    // both now. They used to sit in a queue that ran every job strictly one
    // after another, so the dashboard waited on a notification permission
    // prompt, an FCM token and a Play Store update check before it could draw.
    fetchOverallData();
    fetchTestAllowApi().then((_) {
      // Fresh quota data was just written to storage — re-read it once.
      if (!mounted) return;
      setState(() {
        _testDataFuture = getStoredClinicalTestData();
      });
    });

    // Housekeeping. Nothing on screen waits for any of it, so it runs behind
    // the data rather than in front of it — and stays serialised, since the
    // permission prompt is better not competing with anything.
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
    _takeTestLockTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The cool-down keeps running while the app is away, so re-read it
      // rather than resuming a stale countdown.
      _refreshTakeTestLock();
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
  Future<int> getRemainingCooldownSeconds({int cooldownSeconds = 60}) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt('last_reading_time');
    if (last == null) return 0;

    final diff = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(last))
        .inSeconds;

    final remaining = cooldownSeconds - diff;
    return remaining > 0 ? remaining : 0;
  }

  /// Drives the Take Test button's locked state during the cool-down, however
  /// the previous test ended.
  ///
  /// Ticks once a second while there is time left, then unlocks itself. Kept as
  /// state rather than a dialog because someone working through a list of
  /// patients should see the wait, not have to dismiss it. What a tap does
  /// still depends on the reason — see the button's handler.
  int _takeTestLockSeconds = 0;
  Timer? _takeTestLockTimer;

  Future<void> _refreshTakeTestLock() async {
    final remaining = await AbortDeviceManager.remainingSeconds();
    if (!mounted) return;

    setState(() => _takeTestLockSeconds = remaining);

    _takeTestLockTimer?.cancel();
    if (remaining <= 0) return;

    _takeTestLockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _takeTestLockSeconds--;
        if (_takeTestLockSeconds <= 0) {
          _takeTestLockSeconds = 0;
          t.cancel();
        }
      });
    });
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

    return Scaffold(
      key: _scaffoldKey,
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

                          // NOTE: no nested SingleChildScrollView here — the
                          // page already scrolls. A nested one becomes the
                          // "nearest scrollable" for descendants and silently
                          // swallows the test-log edge handoff.
                          return Column(
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
        lockedForSeconds: _takeTestLockSeconds,
        onTakeTestTap: () async {
          if (_hasInternet) {
            // Locked during the cool-down. An aborted test gets the sheet,
            // which explains what happened; a completed one just needs the
            // time remaining.
            if (_takeTestLockSeconds > 0) {
              if (AbortDeviceManager.abortedRemainingSeconds() > 0) {
                CheckAbortSheet.show(
                  context: context,
                  onTakeTextClick: performTakeTest,
                );
              } else {
                FloatingMessage.show(
                  context,
                  message:
                      'Respyr is cooling down — please wait '
                      '$_takeTestLockSeconds seconds',
                  type: FloatingMessageType.warning,
                  fromTop: false,
                );
              }
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
              // Slides in from the left, from under the profile badge that
              // opens it — the badge sits at the left edge of the app bar.
              const begin = Offset(-1.0, 0.0);
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
      // The day the user is on. This used to return true for every day that
      // had tests, so the selected-day styling landed on all of them and the
      // actual selection was never shown.
      selectedDayPredicate: (day) => isSameDay(day, selectedDate),
      onDaySelected: _onDaySelected,
      daysOfWeekHeight: 28,
      // Column headings are labels, not data — set them back so the dates
      // themselves lead.
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFA1A1A1),
        ),
        weekendStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFA1A1A1),
        ),
      ),
      calendarStyle: CalendarStyle(
        disabledTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFFC9CDD3),
        ),
        // Selected day: filled. Today: outlined. A day with tests keeps its
        // dot underneath, so all three can show at once — before this, both
        // decorations were white circles on a white sheet, i.e. invisible.
        selectedDecoration: const BoxDecoration(
          color: Color(0xFF308BF9),
          shape: BoxShape.circle,
        ),
        selectedTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        todayDecoration: BoxDecoration(
          color: const Color(0xFF308BF9).withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF308BF9), width: 1.5),
        ),
        todayTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF308BF9),
        ),
        // Weekends were Error Red, which reads as something being wrong.
        weekendTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF535359),
        ),
        defaultTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF252525),
        ),
        outsideDaysVisible: false,
        cellMargin: const EdgeInsets.all(5),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        headerPadding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF252525),
        ),
        leftChevronIcon: const Icon(
          Icons.chevron_left_rounded,
          color: Color(0xFF535359),
          size: 24,
        ),
        rightChevronIcon: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF535359),
          size: 24,
        ),
        leftChevronMargin: EdgeInsets.zero,
        rightChevronMargin: EdgeInsets.zero,
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

    // A dot beneath the number, not a disc over it. Painting a filled circle
    // with its own day number on top of the cell meant a day with tests could
    // not also show as today or as the current selection — it simply replaced
    // them.
    final bool isSelected = isSameDay(day, selectedDate);

    return Positioned(
      bottom: 4,
      child: Container(
        height: 5,
        width: 5,
        decoration: BoxDecoration(
          // On the filled selection the dot has to sit on blue, so invert it.
          color: isSelected ? Colors.white : const Color(0xFF308BF9),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
