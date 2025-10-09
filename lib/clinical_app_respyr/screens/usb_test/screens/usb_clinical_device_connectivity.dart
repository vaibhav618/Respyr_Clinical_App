// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/screens/usb_clinical_breathe_tube.dart';
// import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/services/clinical_device_check_api.dart';
// import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/services/clinical_usb_communication_services.dart';
// import 'package:respyr_clinical/clinical_app_respyr/services/disconnected_error.dart';
// import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
// import 'package:respyr_clinical/shared/colors.dart';
// import 'package:respyr_clinical/shared/otg_connection.dart';
// import 'package:respyr_clinical/shared/text_string.dart';

// import 'package:shared_preferences/shared_preferences.dart';

// import '../../../../clinical_dashboard/bloc/health_score_bloc.dart';
// import '../../../../clinical_dashboard/service/overall_data_by_date_service.dart';
// import '../../../../clinical_dashboard/views/clinical_dashboard.dart';
// import '../../../../new_result/data/model/result_profile_data_model.dart';

// class UsbClinicalDeviceConnectivity extends StatefulWidget {
//   final bool isClinicalTest;
//   final ResultProfileDataModel profileDetails;
//   const UsbClinicalDeviceConnectivity({
//     super.key,
//     this.isClinicalTest = false,
//     required this.profileDetails,
//   });

//   @override
//   State<UsbClinicalDeviceConnectivity> createState() =>
//       _UsbClinicalDeviceConnectivityState();
// }

// class _UsbClinicalDeviceConnectivityState
//     extends State<UsbClinicalDeviceConnectivity> {
//   final ClinicalUsbCommunicationServices _usbService =
//       ClinicalUsbCommunicationServices();

//   bool _isConnected = false;
//   bool _isDeviceChecking = false;
//   bool _hasInternet = true;
//   String? _deviceId;

//   @override
//   void initState() {
//     super.initState();
//     _initializeUsbListener();
//     _checkInitialConnection();
//   }

//   void _initializeUsbListener() {
//     _usbService.setUsbSerialListener(
//       onConnectionStatusChanged: (status) async {
//         final connected = status.toLowerCase().trim() == "connected";
//         if (!mounted) return;
//         if (mounted) {
//           setState(() {
//             _isConnected = connected;
//           });
//         }
//       },
//       onDataReceived: (data) {
//         if (data.startsWith("H")) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (mounted) {
//               setState(() {
//                 _deviceId = data.substring(1).trim();
//               });
//             }
//           });
//         } else {
//           int? parsedValue = int.tryParse(data);

//           if (parsedValue != null) {
//             if (parsedValue < 120) {
//               setState(() {
//                 _isDeviceChecking = true;
//               });
//             } else if (parsedValue == 120) {
//               Future.delayed(Duration(milliseconds: 100), () {
//                 setState(() {
//                   _isDeviceChecking = false;
//                 });
//               });
//             }
//           }
//         }
//       },
//       onCommandSent: (command) {
//         debugPrint("Command sent: $command");
//       },
//       onError: (error) {
//         debugPrint("USB Error: $error");
//       },
//     );
//   }

//   Future<void> _checkInitialConnection() async {
//     final devices = await _usbService.listDevices();

//     if (devices.isNotEmpty) {
//       await Future.delayed(const Duration(seconds: 1));
//       await _usbService.connectToDevice(devices.first);
//     }
//   }

//   void _handlePop(BuildContext context) async {
//     bool shouldExit = await _handleCancelTest(context);
//     if (shouldExit) {
//       // Using GetX for both levels of pop if desired:
//       if (Get.isOverlaysOpen) Get.back(); // Close dialog if still open
//       Get.back(result: true); // Pop the screen
//     }
//   }

//   Future<bool> _handleCancelTest(context) async {
//     bool confirmed = await showCancelTestDialog(context);
//     if (confirmed) {
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(
//           builder:
//               (_) => BlocProvider(
//                 create: (_) => HealthScoreBloc(OverallDataByDateService()),
//                 child: ClinicalDashboardMain(
//                   loginId: widget.profileDetails.clinicName!,
//                 ),
//               ),
//         ),
//         (route) => false,
//       );
//     }
//     return confirmed;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final height = MediaQuery.of(context).size.height;
//     final width = MediaQuery.of(context).size.width;

//     SystemChrome.setSystemUIOverlayStyle(
//       SystemUiOverlayStyle(
//         statusBarColor: AppColor.whiteColor,
//         statusBarIconBrightness: Brightness.dark,
//       ),
//     );

//     return PopScope(
//       canPop: false,
//       onPopInvokedWithResult: (didPop, result) async {
//         if (!didPop) {
//           // Handle cancel confirmation
//           final shouldExit = await _handleCancelTest(context);

//           if (shouldExit) {
//             // ✅ Do NOT pop here. Directly navigate to dashboard (handled inside _handleCancelTest)
//             // Keeps the flow clean, without popping twice
//           }
//         }
//       },

//       child: Scaffold(
//         backgroundColor: AppColor.whiteColor,
//         resizeToAvoidBottomInset: false,
//         body: InternetConnectivityHandler(
//           onConnectivityChanged: (hasInternet) async {
//             if (!hasInternet) {
//               debugPrint("📴 Internet lost during USB test");
//               setState(() {
//                 _isDeviceChecking = false;
//                 _hasInternet = hasInternet;
//               });
//             } else {
//               debugPrint("📶 Internet restored during USB test");

//               await _checkInitialConnection();
//             }
//           },

//           child: SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.all(10.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   IconButton(
//                     onPressed: () => _handlePop(context),
//                     icon: SvgPicture.asset("assets/svg_icons/close_icon.svg"),
//                   ),
//                   Align(
//                     alignment: Alignment.topCenter,
//                     child: SvgPicture.asset(
//                       _isConnected
//                           ? "assets/connected_devices.svg"
//                           : "assets/not_connected.svg",
//                     ),
//                   ),
//                   SizedBox(height: height * 0.01),
//                   _buildConnectionSubtitle(),
//                   SizedBox(height: height * 0.05),
//                   _buildConnectionTitle(),
//                   SizedBox(height: height * 0.05),
//                   _buildOtgButton(width),
//                   SizedBox(height: height * 0.05),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         bottomNavigationBar: _buildBottomNavigationBar(height, width),
//       ),
//     );
//   }

//   Widget _buildConnectionSubtitle() {
//     return Center(
//       child: Text(
//         _isConnected
//             ? ResString.connectedDeviceSubTitle
//             : "Connect your Respyr device to phone via USB",
//         textAlign: TextAlign.center,
//         style: GoogleFonts.mulish(
//           fontSize: 15,
//           fontWeight: FontWeight.w400,
//           color: AppColor.textLightColor,
//         ),
//       ),
//     );
//   }

//   Widget _buildConnectionTitle() {
//     return Center(
//       child: Text(
//         _isConnected ? 'Connected' : 'Not Connected',
//         style: GoogleFonts.poppins(
//           fontSize: 25,
//           fontWeight: FontWeight.w600,
//           color: AppColor.primaryBlackColor,
//         ),
//       ),
//     );
//   }

//   Widget _buildOtgButton(double width) {
//     return !_isConnected
//         ? Center(
//           child: SizedBox(
//             width: width * 0.5,
//             child: TextButton(
//               onPressed:
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const OtgConnection()),
//                   ),
//               style: ButtonStyle(
//                 side: WidgetStateProperty.all(
//                   BorderSide(color: AppColor.primaryBlueColor),
//                 ),
//                 backgroundColor: WidgetStateProperty.all(Colors.transparent),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   Text(
//                     ResString.issuewithDevice,
//                     style: GoogleFonts.mulish(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: AppColor.primaryBlueColor,
//                     ),
//                   ),
//                   SvgPicture.asset("assets/svg_icons/right_arrow_button.svg"),
//                 ],
//               ),
//             ),
//           ),
//         )
//         : const SizedBox.shrink();
//   }

//   Widget _buildBottomNavigationBar(double height, double width) {
//     return SafeArea(
//       bottom: true,
//       top: false,
//       child: Padding(
//         padding: const EdgeInsets.only(bottom: 8),
//         child: SizedBox(
//           height: height * 0.1,
//           child: Column(
//             children: [
//               SizedBox(
//                 height: height * 0.06,
//                 width: width * 0.9,
//                 child: _buildConnectOrProceedButton(),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildConnectOrProceedButton() {
//     if (!_isConnected) return const SizedBox.shrink();

//     return ElevatedButton(
//       onPressed: _isDeviceChecking ? null : _verifyAndProceed,
//       style: ElevatedButton.styleFrom(
//         backgroundColor:
//             _isDeviceChecking
//                 ? AppColor.textLightColor.withAlpha(74)
//                 : AppColor.primaryBlueColor,
//         foregroundColor: AppColor.whiteColor,
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             _isDeviceChecking
//                 ? "Device is getting ready, please wait..."
//                 : ResString.next,
//             style: GoogleFonts.mulish(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               color: AppColor.whiteColor,
//             ),
//           ),
//           const Icon(
//             Icons.chevron_right_outlined,
//             size: 24,
//             color: Colors.white,
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _verifyAndProceed() async {
//     final devices = await _usbService.listDevices();
//     if (devices.isEmpty || !_isConnected) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("No device detected. Please connect your device."),
//           ),
//         );
//       }
//       return;
//     }

//     setState(() => _isDeviceChecking = true);

//     _deviceId = null;
//     _usbService.sendData("!");

//     int attempts = 0;
//     while (_deviceId == null && attempts < 50) {
//       await Future.delayed(const Duration(milliseconds: 100));
//       attempts++;
//     }

//     if (_deviceId == null) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Device ID not received. Please reconnect."),
//           ),
//         );
//         setState(() => _isDeviceChecking = false);
//       }
//       return;
//     }

//     await clinicalDeviceCheckApi(_deviceId!);
//     final prefs = await SharedPreferences.getInstance();
//     final isReady = prefs.getBool("is_device_ready") ?? false;

//     if (!mounted) return;

//     if (isReady) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder:
//               (_) => UsbClinicalBreatheTube(
//                 isClinicalTest: widget.isClinicalTest,
//                 profileDetails: widget.profileDetails,
//               ),
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Device not ready yet. Please try again."),
//         ),
//       );
//     }

//     if (mounted) {
//       setState(() => _isDeviceChecking = false);
//     }
//   }
// }
