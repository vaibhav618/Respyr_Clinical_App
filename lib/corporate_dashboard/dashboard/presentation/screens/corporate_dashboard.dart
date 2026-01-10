import 'dart:async';

import 'package:flutter/material.dart' hide AppBar;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:respyr_clinical/common/auth_logout.dart';
import 'package:respyr_clinical/widgets/logout_bpx.dart';

import '../../../../clinical_app_respyr/screens/bluetooth_test/screens/bluetooth_clinical_device_connectivity.dart';
import '../../../../clinical_dashboard/helper/abort_device_manager.dart';
import '../../../../clinical_dashboard/widgets/bottom_navigation.dart';
import '../../../../clinical_dashboard/widgets/check_abort_sheet.dart' show CheckAbortSheet;
import '../../../../clinical_dashboard/widgets/connection_option_sheet.dart';
import '../../../../common/floating_message.dart';
import '../../../../device_connectivity/presentation/pages/device_connectivity_screen.dart';
import '../../../../new_result/data/model/result_profile_data_model.dart';
import '../../../../router/app_routers.dart';

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

  // ✅ Cooldown toast timer (NEW)
  Timer? _cooldownToastTimer;

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

    // ✅ cancel toast timer
    _cooldownToastTimer?.cancel();
    _cooldownToastTimer = null;

    super.dispose();
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
    if (state == AppLifecycleState.resumed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _refreshProfile(context);
      });
    }
  }

  void _printProfileData(CorporateProfileState profileState) {
    final u = profileState.user;
    if (u == null) return;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CorporateProfileBloc>(
      create: (_) => CorporateProfileBloc(
        repo: CorporateProfileRepository(
          endpointUrl:
          "https://humorstech.com/humors_app/app_final/clinical/fetch_corporate_profile.php",
        ),
      )..add(CorporateProfileFetchRequested(widget.email)),
      child: Builder(
        builder: (blocContext) {
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
              }
            },
            child: BlocBuilder<CorporateProfileBloc, CorporateProfileState>(
              builder: (blocContext, profileState) {
                final bottomBarHeight = kBottomNavigationBarHeight;
                final bottomPadding = (_showBottomBar
                    ? bottomBarHeight + _bottomBarExtraGap
                    : _bottomBarExtraGap);

                return Scaffold(
                  backgroundColor: Colors.white,
                  body: SafeArea(
                    bottom: false,
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
                              onDashboardTap: () => _refreshProfile(blocContext),
                              label3: "Profile",
                              onTakeTestTap: () {
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
                                checkDeviceAbortStatus(profileDetails, context);
                              },
                              onProfileTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.corporateProfile,
                                  arguments: profileState.user,
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
    );
  }

  Future<void> checkDeviceAbortStatus(
      ResultProfileDataModel profileModel, BuildContext context) async {
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
            // ✅ close the sheet first
            Navigator.pop(sheetCtx);
            await Future.delayed(const Duration(milliseconds: 200));

            final remaining =
            await getRemainingCooldownSeconds(cooldownSeconds: 40);

            if (!context.mounted) return;

            if (remaining > 0) {
              await showCooldownToast(context, remaining);
              return;
            }

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => BluetoothClinicalDeviceConnectivity(
                  profileDetails: profileModel,
                ),
              ),
                  (route) => false,
            );
          },
          onUsbTap: () {
            Navigator.pop(sheetCtx);

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => UsbDeviceConnectivity(
                  isClinicalTest: true,
                  profileDetails: profileModel,
                ),
              ),
                  (route) => false,
            );
          },
        );
      },
    );
  }

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

  // ✅ REPLACED snackbar with FloatingMessage toast countdown
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
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
            child: HorizontalCalender(
              onDateChanged: _onDateChanged,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: _contentTopGapAfterCalendar),
        ),
      ],
      body: Builder(
        builder: (_) {
          if (profileState.status == CorporateProfileStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (profileState.status == CorporateProfileStatus.failure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      "assets/sagar/undraw_not-found_6bgl.svg",
                      height: 250,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Oops! Something went wrong. Try logging in again. If you see this error again, please reach out to the admin or support team.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF252525),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.24,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(elevation: 0),
                      onPressed: () {
                        LogoutBox().showDialogBox(
                          context: context,
                          clinicName: widget.email,
                          onLogoutClick: () {
                            AuthLogout.logout(context);
                          },
                        );
                      },
                      child: const Text("Logout"),
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
        child: AnimatedSlide(
          duration: slideDuration,
          curve: curve,
          offset: visible ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: fadeDuration,
            curve: curve,
            opacity: visible ? 1 : 0,
            child: IgnorePointer(
              ignoring: !visible,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const _PinnedHeaderDelegate({
    required this.child,
    required this.height,
  });

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
      color: Colors.white,
      elevation: overlapsContent ? 3 : 0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
