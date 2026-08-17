import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'disclaimer_card.dart' show CollapsibleSection;

/// The corporate wellness disclaimer and regulatory status, collapsed to
/// their titles — same treatment as the clinical result's disclaimer. All
/// text is unchanged, word for word; a tap unfolds it.
class CorporateDisclaimerCard extends StatelessWidget {
  const CorporateDisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CollapsibleSection(
            title: "Wellness Disclaimer",
            child: _disclaimerBody(),
          ),
          const SizedBox(height: 10),
          CollapsibleSection(
            title: "Regulatory Status & Quality Compliance",
            child: _regulatoryBody(),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _disclaimerBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Respyr provides non-invasive, health and wellness preliminary screening insights through breath analysis to support wellness awareness by identifying early physiological trends related to sugar metabolism, liver-related metabolic handling, digestive fermentation, and breathing patterns. The scores and interpretations presented in this report are intended to:",
          style: _body,
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 10),
        bulletItem("Support wellness awareness"),
        bulletItem("Encourage lifestyle understanding"),
        bulletItem("Enable preventive self-monitoring"),
        const SizedBox(height: 10),
        Text(
          "They are not diagnostic and do not represent medical conclusions or disease assessment.\n\n"
          "Respyr does not provide medical advice, treatment recommendations, or diagnoses.\n\n"
          "This report is designed for wellness and preventive health monitoring, not for medical decision-making or clinical care.",
          style: _body,
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }

  Widget _regulatoryBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Respyr 1.0 is a non-invasive breath analysis medical device developed for population-scale screening and preventive health monitoring.",
          style: _body,
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 10),
        bulletItem(
          "Respyr 1.0 is registered as a Class B In Vitro Diagnostic (IVD) device under the MD5 license issued by the Central Drugs Standard Control Organization (CDSCO), Ministry of Health & Family Welfare, Government of India.",
        ),
        bulletItem(
          "The device is authorized for manufacturing, sale, and distribution under valid MD13 and MD42 licenses.",
        ),
        const SizedBox(height: 10),
        Text(
          "Quality & Safety Standards",
          style: GoogleFonts.poppins(
            color: const Color(0xFF535359),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.30,
            letterSpacing: -0.24,
          ),
        ),
        const SizedBox(height: 10),
        bulletItem(
          "ISO 13485:2016 — Quality Management Systems for Medical Devices",
        ),
        bulletItem(
          "IEC 60601-1-2:2014 — Electromagnetic Compatibility for Medical Electrical Equipment",
        ),
      ],
    );
  }

  static final TextStyle _body = GoogleFonts.poppins(
    color: const Color(0xFF535359),
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.30,
    letterSpacing: -0.24,
  );

  Widget bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "•",
            style: TextStyle(
              fontSize: 14,
              height: 1.3,
              color: Color(0xFF535359),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: _body,
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }
}
