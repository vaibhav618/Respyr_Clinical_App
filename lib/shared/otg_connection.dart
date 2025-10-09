import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:respyr_clinical/shared/text_string.dart';

import 'package:url_launcher/url_launcher.dart';

class OtgConnection extends StatefulWidget {
  const OtgConnection({super.key});

  @override
  State<OtgConnection> createState() => _OtgConnectionState();
}

class _OtgConnectionState extends State<OtgConnection> {
  Future<void> _openSettings() async {
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        // For Android, open the general phone settings
        const intent = AndroidIntent(action: 'android.settings.SETTINGS');
        await intent.launch();
      } else {
        // You can handle other platforms if needed, like iOS
        if (kDebugMode) {
          print('Platform not supported.');
        }
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Error opening settings: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColor.whiteColor,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColor.whiteColor,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: SvgPicture.asset("assets/svg_icons/close_icon.svg"),
                  ),
                ),
                SizedBox(height: height * 0.01),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SvgPicture.asset(
                    "assets/svg_icons/non_connected_icon.svg",
                  ),
                ),
                SizedBox(height: height * 0.01),
                Text(
                  ResString.issuewithDevice,
                  style: GoogleFonts.poppins(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primaryBlackColor,
                  ),
                ),
                SizedBox(height: height * 0.03),
                Text(
                  'Solution',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3FAF58),
                  ),
                ),
                SizedBox(height: height * 0.01),
                Text(
                  'Turn on OTG connection and try again',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textLightColor,
                  ),
                ),
                SizedBox(height: height * 0.01),
                Image.asset('assets/otg.png'),
                SizedBox(height: height * 0.01),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.mulish(
                        fontSize: 15,
                        color: AppColor.textLightColor,
                        fontWeight: FontWeight.w400,
                      ),
                      children: const [
                        TextSpan(text: '1. Go to '),
                        TextSpan(
                          text: 'Setting > Search for OTG ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: 'in phone settings\n\n'),
                        TextSpan(text: '2. '),
                        TextSpan(
                          text: 'Turn On ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: 'OTG connection\n\n'),
                        TextSpan(text: '3. '),
                        TextSpan(
                          text: 'Restart ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: 'respyr app\n\n'),
                        TextSpan(text: '4. Now '),
                        TextSpan(
                          text: 'remove and reconnect ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: 'the respyr device\n\n '),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: height * 0.05),
                if (Platform.isAndroid)
                  GestureDetector(
                    onTap: () {
                      _openSettings();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          'Go To Setting',
                          style: GoogleFonts.mulish(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColor.primaryBlueColor,
                          ),
                        ),
                        SvgPicture.asset(
                          "assets/svg_icons/right_arrow_button.svg",
                          colorFilter: ColorFilter.mode(
                            AppColor.primaryBlueColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: height * 0.15,
          padding: const EdgeInsets.only(bottom: 15),
          child: Column(
            children: [
              const Divider(color: Color(0xFFD9D9D9)),
              const Spacer(),
              Center(
                child: Text(
                  "Still having issue with connection",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mulish(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColor.textLightColor,
                  ),
                ),
              ),
              SizedBox(height: height * 0.01),
              SizedBox(
                height: height * 0.07,
                width: width * 0.9,
                child: TextButton(
                  onPressed: () {
                    ShowButton.showCustomerSupport(context);
                  },
                  style: ButtonStyle(
                    side: WidgetStateProperty.all(
                      BorderSide(color: AppColor.primaryBlueColor),
                    ),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    backgroundColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ), // Default background
                    foregroundColor: WidgetStateProperty.all(
                      AppColor.primaryBlackColor,
                    ), // Default text color
                    overlayColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.pressed)) {
                        return Colors.blue.withAlpha(
                          47,
                        ); // Background color when pressed
                      }
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.blue.withAlpha(
                          26,
                        ); // Background color on hover
                      }
                      return null; // Default transparent
                    }),
                  ),
                  child: Text(
                    'Contact Support',
                    style: GoogleFonts.mulish(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColor.primaryBlueColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Class to show the customer support modal
class ShowButton {
  // Static method to show the customer support modal
  static void showCustomerSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final height = MediaQuery.of(context).size.height;

        return Container(
          height: height * 0.32,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColor.whiteColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Contact Support Via',
                style: GoogleFonts.mulish(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColor.primaryBlueColor,
                ),
              ),
              SizedBox(height: height * 0.04),
              SupportButton(
                label: 'WhatsApp',
                iconPath: "assets/svg_icons/whatsapp_icon.svg",
                onPressed: () async {
                  if (await canLaunchUrl(SupportLinks.whatsappUrl)) {
                    await launchUrl(
                      SupportLinks.whatsappUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    // Optionally show error
                    debugPrint("Could not launch WhatsApp");
                  }
                },
              ),
              SizedBox(height: height * 0.02),
              SupportButton(
                label: 'E-mail',
                iconPath: "assets/svg_icons/mail_icon.svg",
                onPressed: () async {
                  if (await canLaunchUrl(SupportLinks.emailUrl)) {
                    await launchUrl(SupportLinks.emailUrl);
                  } else {
                    debugPrint("Could not launch email client");
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// A reusable widget for the buttons
class SupportButton extends StatefulWidget {
  final String label;
  final String iconPath;
  final VoidCallback onPressed;

  const SupportButton({
    super.key,
    required this.label,
    required this.iconPath,
    required this.onPressed,
  });

  @override
  State<SupportButton> createState() => SupportButtonState();
}

class SupportButtonState extends State<SupportButton> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return SizedBox(
      height: height * 0.075,
      width: width * 0.9,
      child: TextButton(
        onPressed: widget.onPressed,
        style: ButtonStyle(
          side: WidgetStateProperty.all(
            BorderSide(color: AppColor.primaryBlueColor),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          ),
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.all(AppColor.primaryBlackColor),
          overlayColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.blue.withAlpha(47);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.blue.withAlpha(26);
            }
            return null;
          }),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(widget.iconPath),
            SizedBox(width: width * 0.02),
            Text(
              widget.label,
              style: GoogleFonts.mulish(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColor.textLightColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SupportLinks {
  static final Uri whatsappUrl = Uri.parse(
    "https://wa.me/8296380628?text=Hi%2C%20I%20need%20some%20help",
  );

  static final Uri emailUrl = Uri.parse(
    "mailto:connect@humorstech.com?subject=Support%20Request&body=Hi%20team%2C%20I%20need%20assistance%20with...",
  );
}
