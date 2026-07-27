import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/appbar.dart';

class AccountSettings extends StatefulWidget {
  final String clinicName;
  final String clinicPhoneInfo;
  final String clinicEmailInfo;
  final String clinicLocationInfo;
  final Widget clinicalLogo;
  const AccountSettings({
    super.key,
    required this.clinicName,
    required this.clinicPhoneInfo,
    required this.clinicEmailInfo,
    required this.clinicLocationInfo,
    required this.clinicalLogo,
  });

  @override
  State<AccountSettings> createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: commonAppbar(title: 'Account Setting'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Spacer(),
            widget.clinicalLogo,
            SizedBox(height: 50),
            rowItem(widget.clinicName, "assets/admin_icon.svg"),
            SizedBox(height: 10),
            rowItem(widget.clinicPhoneInfo, "assets/hugeicons_call.svg"),
            SizedBox(height: 10),
            rowItem(widget.clinicEmailInfo, "assets/email_icon.svg"),
            SizedBox(height: 10),
            rowItem(
              widget.clinicLocationInfo,
              "assets/hugeicons_location-05.svg",
            ),
            Spacer(),
            Spacer(),
            Spacer(),
          ],
        ),
      ),
    );
  }

  Widget rowItem(String title, String svgPath) {
    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        color: const Color(0xFFF0F0F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          SvgPicture.asset(svgPath, color: const Color(0xFF959595)),
          SizedBox(width: 20),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: const Color(0xFF959595),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.30,
            ),
          ),
        ],
      ),
    );
  }
}
