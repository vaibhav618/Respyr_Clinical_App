// usb_device_connectivity.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/disconnected_error.dart';
import 'package:respyr_clinical/device_connectivity/presentation/cubit/usb_connection_cubit.dart';
import 'package:respyr_clinical/device_connectivity/presentation/cubit/usb_connection_state.dart';
import 'package:respyr_clinical/new_result/data/model/result_profile_data_model.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:respyr_clinical/shared/otg_connection.dart';
import 'package:respyr_clinical/shared/text_string.dart';

import '../../../router/app_routers.dart';

class UsbDeviceConnectivity extends StatefulWidget {
  final int stepCompleted;
  final bool isClinicalTest;
  final ResultProfileDataModel profileDetails;
  final bool isDeveloping;
  const UsbDeviceConnectivity({
    super.key,
    this.stepCompleted = 1,
    this.isDeveloping = false,
    required this.isClinicalTest,
    required this.profileDetails,
  });

  @override
  State<UsbDeviceConnectivity> createState() => _UsbDeviceConnectivityState();
}

class _UsbDeviceConnectivityState extends State<UsbDeviceConnectivity> {
  final int totalStep = 5;
  bool _isUiReady = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start USB listener
      context.read<UsbCubit>().reinitializeListener();

      // Delay UI readiness for 1.5 seconds to prevent premature button press
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isUiReady = true;
          });
        }
      });
    });
  }

  Future<bool> _handleCancelTest(BuildContext context) async {
    bool didCancel = false;

    showCancelTestBox(
      context: context,
      cancelTestButtonPressed: () async {
        debugPrint("🛑 Cancel button pressed");

        didCancel = true;

        if (mounted) {
          Navigator.pop(context);
        }

        await Future.delayed(const Duration(milliseconds: 300));

        if (Get.isOverlaysOpen) {
          Get.back();
        }

        Get.offAllNamed(
          AppRoutes.mainDashboard,
          arguments: {
            'profile_details':
                widget.profileDetails, // full ResultProfileDataModel
          },
        );
      },
    );

    return didCancel;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Handle cancel confirmation
          final shouldExit = await _handleCancelTest(context);

          if (shouldExit) {
            // ✅ Do NOT pop here. Directly navigate to dashboard (handled inside _handleCancelTest)
            // Keeps the flow clean, without popping twice
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(
            'Connect Device',
            style: GoogleFonts.poppins(
              fontSize: 34,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<UsbCubit, UsbState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress bar
                    if (widget.isDeveloping)
                      Row(
                        children: List.generate(totalStep, (index) {
                          final isFilled = index < widget.stepCompleted;
                          return Expanded(
                            child: Container(
                              height: 5,
                              margin: EdgeInsets.only(
                                right: index < totalStep - 1 ? 4.0 : 0,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isFilled ? Colors.black : Colors.grey[300],
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          );
                        }),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Connect the device to mobile phone using C-type cable.',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height:
                          300, // Set this to the height of your image or container
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Centered SVG Image
                          Center(
                            child: SvgPicture.asset(
                              state.isConnected
                                  ? "assets/device_connection/connected.svg"
                                  : "assets/device_connection/not_connected.svg",
                            ),
                          ),

                          if (state.isConnected)
                            Positioned(
                              bottom: 30,
                              child: Container(
                                width:
                                    MediaQuery.of(context).size.width *
                                    0.5, // responsive width
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0xFFD9D9D9),
                                  border: Border.all(color: Color(0xFFB9B9B9)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/device_connection/device_id.svg',
                                    ),

                                    Text(
                                      'Device Id:',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF535359),

                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        height: 1.10,
                                        letterSpacing: -0.24,
                                      ),
                                    ),

                                    Text(
                                      "RESPYR${state.deviceId}", // ← this should be dynamic if you're using Cubit
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF535359),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        height: 1.10,
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const Spacer(),
                    Center(
                      child: Text(
                        state.isConnected
                            ? 'Device Connected'
                            : 'Device Not Connected',
                        style: GoogleFonts.poppins(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),

                    Center(
                      child: SizedBox(
                        width: 200,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OtgConnection(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            side: const BorderSide(color: Colors.blue),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                "Issue With Connection?",
                                style: GoogleFonts.mulish(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_outlined,
                                size: 16,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 30, left: 26, right: 26),
            child: BlocBuilder<UsbCubit, UsbState>(
              builder: (context, state) {
                if (!state.isConnected) return const SizedBox.shrink();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left_outlined,
                        size: 26,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        // Navigatoa

                        if (Get.isOverlaysOpen) {
                          Get.back();
                        }

                        Get.offAllNamed(
                          AppRoutes.mainDashboard,
                          arguments: {
                            'profile_details':
                                widget
                                    .profileDetails, // full ResultProfileDataModel
                          },
                        );
                      },
                    ),
                    SizedBox(
                      width: 180,
                      child: AnimatedOpacity(
                        opacity: state.isChecking ? 0.6 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton(
                          onPressed:
                              (!_isUiReady ||
                                      state.isChecking ||
                                      !state.isConnected)
                                  ? null
                                  : () {
                                    context.read<UsbCubit>().checkAndProceed(
                                      isClinicalTest: widget.isClinicalTest,
                                      context: context,
                                      profileDetails: widget.profileDetails,
                                    );
                                  },

                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                state.isChecking
                                    ? AppColor.textLightColor.withAlpha(74)
                                    : AppColor.primaryBlueColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 13,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(),
                              Text(
                                ResString.next,
                                style: GoogleFonts.mulish(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.whiteColor,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right_outlined,
                                size: 24,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
