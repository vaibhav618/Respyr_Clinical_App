import 'dart:async';

import 'package:respyr_clinical/widgets/shimmer_placeholders.dart';

import 'package:flutter/material.dart' hide AppBar;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:respyr_clinical/shared/urls.dart';

import '../../../../clinical_app_respyr/screens/bluetooth_test/screens/bluetooth_clinical_device_connectivity.dart';
import '../../../../clinical_dashboard/helper/abort_device_manager.dart';
import '../../../../clinical_dashboard/views/subject_profile.dart';
import '../../../../clinical_dashboard/widgets/bottom_navigation.dart';
import '../../../../clinical_dashboard/widgets/check_abort_sheet.dart'
    show CheckAbortSheet;
import '../../../../clinical_dashboard/widgets/connection_option_sheet.dart';
import '../../../../common/floating_message.dart';
import '../../../../device_connectivity/presentation/pages/device_connectivity_screen.dart';
import '../../../../new_result/data/model/result_profile_data_model.dart';
import '../../../../widgets/internet_connectivity_check.dart';

import '../../bloc/corporate_profile_bloc.dart';
import '../../bloc/corporate_profile_event.dart';
import '../../bloc/corporate_profile_state.dart';
import '../../data/repository/corporate_profile_repository.dart';

import '../widgets/appbar.dart';
import '../widgets/corporate_dashboard_content_screen.dart';
import '../widgets/horizontal_calender.dart';

class CorporateDashboard extends StatefulWidget {
  final String email;
  final String corporateId;

  const CorporateDashboard({
    super.key,
    required this.email,
    required this.corporateId,
  });

  @override
  State<CorporateDashboard> createState() => _CorporateDashboardState();
}

class _CorporateDashboardState extends State<CorporateDashboard>
    with WidgetsBindingObserver {
  static const double _calendarHeight = 72;
  static const double _contentTopGapAfterCalendar = 24;
  static const double _bottomBarExtraGap = 16;

  static const double _scrollThresholdPx = 200;
  static const Duration _slideDuration = Duration(milliseconds: 260);
  static const Duration _fadeDuration = Duration(milliseconds: 180);
  static const Curve _animCurve = Curves.easeOutCubic;

  final ScrollController _scrollController = ScrollController();

  bool _showBottomBar = true;
  double _lastOffset = 0;

  DateTime _selectedDate = DateTime.now();

  // ✅ Cooldown toast timer
  Timer? _cooldownToastTimer;

  // ✅ Internet state
  bool _hasInternet = true;
  bool _internetToastShown = false;

  // ✅ Keep a context that is INSIDE BlocProvider scope (fix ProviderNotFound on resume)
  BuildContext? _blocScopeContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();

    _cooldownToastTimer?.cancel();
    _cooldownToastTimer = null;

    super.dispose();
  }

  void _handleConnectivityChanged(bool hasInternet) {
    _hasInternet = hasInternet;

    if (!hasInternet) {
      if (_internetToastShown) return;
      _internetToastShown = true;

      if (!mounted) return;
      FloatingMessage.show(
        context,
        message: "No internet connection",
        type: FloatingMessageType.warning,
        duration: const Duration(seconds: 3),
        fromTop: false,
      );
    } else {
      _internetToastShown = false;
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final currentOffset = _scrollController.offset;
    final delta = currentOffset - _lastOffset;

    if (delta > _scrollThresholdPx && _showBottomBar) {
      setState(() => _showBottomBar = false);
    } else if (delta < -_scrollThresholdPx && !_showBottomBar) {
      setState(() => _showBottomBar = true);
    }

    _lastOffset = currentOffset;
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return "$mm/$dd/$yyyy";
  }

  void _refreshProfile(BuildContext blocContext) {
    if (!_hasInternet) {
      FloatingMessage.show(
        context,
        message: "Please turn ON internet and tap Retry.",
        type: FloatingMessageType.warning,
        duration: const Duration(seconds: 3),
        fromTop: false,
      );
      return;
    }

    blocContext.read<CorporateProfileBloc>().add(
      CorporateProfileFetchRequested(widget.email),
    );
  }

  void _onDateChanged(DateTime value) {
    setState(() => _selectedDate = value);
    debugPrint("📅 Selected Date: ${_formatDate(value)}");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ✅ Fix: use bloc-scoped context instead of widget context
    if (state == AppLifecycleState.resumed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _blocScopeContext;
        if (ctx == null) return;
        _refreshProfile(ctx);
      });
    }
  }

  void _printProfileData(CorporateProfileState profileState) {
    final u = profileState.user;
    if (u == null) return;
  }

  @override
  Widget build(BuildContext context) {
    return InternetConnectivityHandler(
      onConnectivityChanged: _handleConnectivityChanged,
      onRetry: () async {
        // Just close overlay; user can retry.
        if (mounted) {
          FloatingMessage.show(
            context,
            message: "Please turn ON internet and tap Retry.",
            type: FloatingMessageType.warning,
            duration: const Duration(seconds: 3),
            fromTop: false,
          );
        }
      },
      child: BlocProvider<CorporateProfileBloc>(
        create:
            (_) => CorporateProfileBloc(
              repo: CorporateProfileRepository(
                endpointUrl: Urls.fetchCorporateProfile,
              ),
            )..add(CorporateProfileFetchRequested(widget.email)),
        child: Builder(
          builder: (blocContext) {
            // ✅ store bloc-scoped context
            _blocScopeContext = blocContext;

            return BlocListener<CorporateProfileBloc, CorporateProfileState>(
              listenWhen: (p, c) => p.status != c.status,
              listener: (context, profileState) {
                if (profileState.status == CorporateProfileStatus.success &&
                    profileState.user != null) {
                  _printProfileData(profileState);
                }

                if (profileState.status == CorporateProfileStatus.failure) {
                  debugPrint(
                    "❌ [CorporateProfileBloc] FAILED: ${profileState.errorMessage ?? '-'}",
                  );

                  if (!_hasInternet) {
                    FloatingMessage.show(
                      context,
                      message:
                          "No internet connection. Please turn it ON and tap Retry.",
                      type: FloatingMessageType.warning,
                      duration: const Duration(seconds: 3),
                      fromTop: false,
                    );
                  }
                }
              },
              child: BlocBuilder<CorporateProfileBloc, CorporateProfileState>(
                builder: (blocContext, profileState) {
                  final bottomBarHeight = kBottomNavigationBarHeight;
                  final bottomPadding =
                      (_showBottomBar
                          ? bottomBarHeight + _bottomBarExtraGap
                          : _bottomBarExtraGap);

                  return Scaffold(
                    backgroundColor: const Color(0xFFF5F7FA),
                    body: SafeArea(
                      bottom: true,
                      child: Stack(
                        children: [
                          _buildScrollableContent(
                            blocContext: blocContext,
                            bottomPadding: bottomPadding,
                            profileState: profileState,
                          ),
                          if (profileState.user != null)
                            _FloatingBottomNav(
                              visible: _showBottomBar,
                              slideDuration: _slideDuration,
                              fadeDuration: _fadeDuration,
                              curve: _animCurve,
                              child: BottomNavigationBarWidget(
                                activeIndex: 0,
                                onDashboardTap:
                                    () => _refreshProfile(blocContext),
                                // History, like the clinical app: the
                                // person's past tests, each opening its
                                // result. Profile stays reachable from the
                                // badge in the header.
                                label3: "History",
                                onTakeTestTap: () {
                                  if (!_hasInternet) {
                                    FloatingMessage.show(
                                      context,
                                      message:
                                          "Please turn ON internet and try again.",
                                      type: FloatingMessageType.warning,
                                      duration: const Duration(seconds: 3),
                                      fromTop: false,
                                    );
                                    return;
                                  }

                                  final u = profileState.user!;
                                  final profileDetails = ResultProfileDataModel(
                                    email: u.email,
                                    subjectId: u.subjectId,
                                    clinicName: u.clinicName,
                                    profileName: u.profileName,
                                    gender: u.gender,
                                    age: int.parse(u.age),
                                    height: double.parse(u.height),
                                    weight: double.parse(u.weight),
                                    region: u.region,
                                    dttm: u.dttm,
                                    role: "corporate",
                                  );

                                  if (!mounted) return;
                                  checkDeviceAbortStatus(
                                    profileDetails,
                                    context,
                                  );
                                },
                                onProfileTap: () {
                                  final u = profileState.user!;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SubjectProfileScreen(
                                        clinicName: u.clinicName,
                                        profileName: u.subjectId,
                                        role: 'corporate',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> checkDeviceAbortStatus(
    ResultProfileDataModel profileModel,
    BuildContext context,
  ) async {
    final isDeviceAborted = await AbortDeviceManager.getAbortStatus();
    if (!mounted) return;

    if (isDeviceAborted) {
      CheckAbortSheet.show(
        context: context,
        onTakeTextClick: () {
          performTest(profileModel, context);
        },
      );
    } else {
      performTest(profileModel, context);
    }
  }

  void performTest(ResultProfileDataModel profileModel, BuildContext context) {
    _showConnectionOption(profileModel, context);
  }

  void _showConnectionOption(
    ResultProfileDataModel profileModel,
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return ConnectionOptionSheet(
          onBluetoothTap: () async {
            Navigator.pop(sheetCtx);
            await Future.delayed(const Duration(milliseconds: 200));

            if (!_hasInternet) {
              FloatingMessage.show(
                context,
                message: "Please turn ON internet and try again.",
                type: FloatingMessageType.warning,
                duration: const Duration(seconds: 3),
                fromTop: false,
              );
              return;
            }

            // Cool-down before another test: the sheet for an aborted one, a
            // message for a completed one.
            final aborted = await AbortDeviceManager.getAbortStatus();
            final remaining =
                await AbortDeviceManager.completedRemainingSeconds();

            if (!context.mounted) return;

            if (aborted) {
              CheckAbortSheet.show(context: context);
              return;
            }

            if (remaining > 0) {
              await showCooldownToast(context, remaining);
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => BluetoothClinicalDeviceConnectivity(
                      profileDetails: profileModel,
                    ),
              ),
            );
          },
          onUsbTap: () {
            Navigator.pop(sheetCtx);

            if (!_hasInternet) {
              FloatingMessage.show(
                context,
                message: "Please turn ON internet and try again.",
                type: FloatingMessageType.warning,
                duration: const Duration(seconds: 3),
                fromTop: false,
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => UsbDeviceConnectivity(
                      isClinicalTest: true,
                      profileDetails: profileModel,
                    ),
              ),
            );
          },
        );
      },
    );
  }

  Future<int> getRemainingCooldownSeconds({int cooldownSeconds = 60}) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt('last_reading_time');

    if (last == null) return 0;

    final diff =
        DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(last))
            .inSeconds;

    final remaining = cooldownSeconds - diff;
    return remaining > 0 ? remaining : 0;
  }

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

  Widget _buildScrollableContent({
    required BuildContext blocContext,
    required double bottomPadding,
    required CorporateProfileState profileState,
  }) {
    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder:
          (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  if (profileState.user != null)
                    AppBar(state: profileState)
                  else
                    const SizedBox(height: 56),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeaderDelegate(
                height: _calendarHeight,
                child: HorizontalCalender(onDateChanged: _onDateChanged),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: _contentTopGapAfterCalendar),
            ),
          ],
      body: Builder(
        builder: (_) {
          if (profileState.status == CorporateProfileStatus.loading) {
            return const ListShimmer(rows: 5, rowHeight: 96);
          }

          if (profileState.status == CorporateProfileStatus.failure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 64,
                      width: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF308BF9).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _hasInternet
                            ? Icons.error_outline_rounded
                            : Icons.cloud_off_rounded,
                        color: const Color(0xFF308BF9),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _hasInternet
                          ? "Couldn't load your profile"
                          : "No internet connection",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF252525),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hasInternet
                          ? "Try again — if this keeps happening, contact support."
                          : "Turn it on and tap Retry.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF535359),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton(
                      onPressed: () => _refreshProfile(blocContext),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF308BF9),
                        side: const BorderSide(color: Color(0xFF308BF9)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        "Retry",
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (profileState.status == CorporateProfileStatus.success &&
              profileState.user != null) {
            final u = profileState.user!;

            return CorporateDashboardContentScreen(
              loginId: u.clinicName,
              profileId: u.subjectId,
              date: _formatDate(_selectedDate),
              onTrackHealthButtonClicked: () {
                if (!_hasInternet) {
                  FloatingMessage.show(
                    context,
                    message: "Please turn ON internet and try again.",
                    type: FloatingMessageType.warning,
                    duration: const Duration(seconds: 3),
                    fromTop: false,
                  );
                  return;
                }

                final profileDetails = ResultProfileDataModel(
                  email: u.email,
                  subjectId: u.subjectId,
                  clinicName: u.clinicName,
                  profileName: u.profileName,
                  gender: u.gender,
                  age: int.tryParse(u.age) ?? 0,
                  height: double.tryParse(u.height) ?? 0,
                  weight: double.tryParse(u.weight) ?? 0,
                  region: u.region,
                  dttm: u.dttm,
                  role: "corporate",
                );

                checkDeviceAbortStatus(profileDetails, context);
              },
              corporateUserData: profileState.user!,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _FloatingBottomNav extends StatelessWidget {
  final bool visible;
  final Duration slideDuration;
  final Duration fadeDuration;
  final Curve curve;
  final Widget child;

  const _FloatingBottomNav({
    required this.visible,
    required this.slideDuration,
    required this.fadeDuration,
    required this.curve,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        bottom: true,
        child: AnimatedSlide(
          duration: slideDuration,
          curve: curve,
          offset: visible ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: fadeDuration,
            curve: curve,
            opacity: visible ? 1 : 0,
            child: IgnorePointer(ignoring: !visible, child: child),
          ),
        ),
      ),
    );
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const _PinnedHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: const Color(0xFFF5F7FA),
      elevation: overlapsContent ? 2 : 0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
