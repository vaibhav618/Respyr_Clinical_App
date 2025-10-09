import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Disclaimer",
            style: GoogleFonts.poppins(
              color: const Color(0xFF535359),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.30,
              letterSpacing: -0.24,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Respyr provides non-invasive, preliminary screening insights through breath analysis, helping identify early physiological trends in sugar, liver, gut, and respiratory health. The scores and interpretations presented are intended to reflect physiological trends and support lifestyle and preventive health monitoring. Accuracy claims are based on internal blinded validation using breath samples and classification protocols in collaboration with recognized hospitals across India. Respyr does not diagnose, treat, or prevent any disease.\n\nThis interpretation guide is intended for use by qualified healthcare providers to understand trend patterns and support pre-screening decisions. Clinical judgment and confirmatory testing must be used before making any medical decisions. Respyr is not a substitute for standard clinical testing or professional medical evaluation.\n\nRespyr is not intended to diagnose, treat, or prevent any disease. It is not a replacement for standard clinical testing or professional medical evaluation. All medical decisions should be made by qualified healthcare professionals based on clinical judgment and, when necessary, confirmatory diagnostic testing",
            style: GoogleFonts.poppins(
              color: const Color(0xFF535359),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.30,
              letterSpacing: -0.24,
            ),
            textAlign: TextAlign.justify,
          ),
          SizedBox(height: 30),
          Text(
            "Regulatory Status",
            style: GoogleFonts.poppins(
              color: const Color(0xFF535359),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.30,
              letterSpacing: -0.24,
            ),
          ),
          SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Respyr 1.0 is a non-invasive breath analysis device developed for pre-screening and preventive health monitoring. It has undergone rigorous certification and validation to ensure clinical reliability, regulatory compliance, and suitability for population-scale deployment.",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF535359),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.30,
                  letterSpacing: -0.24,
                ),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 10),
              bulletItem(
                "Respyr 1.0 is registered as a Class B In Vitro Diagnostic (IVD) device under the MD5 license issued by the Central Drugs Standard Control Organization (CDSCO), Ministry of Health & Family Welfare, Government of India.",
              ),
              bulletItem(
                "The following modules are covered under this certification:",
              ),
              bulletItem(
                "Sugar Score – Based on exhaled acetone (VOC), reflecting trends in glucose metabolism.",
              ),
              bulletItem(
                "Liver Stress Score – Based on exhaled ethanol (VOC), indicating hepatic metabolic function and stress.",
              ),
              bulletItem(
                "The Respyr 1.0 device and its manufacturing processes fully comply with international medical device standards:",
              ),
              bulletItem(
                "ISO 13485:2016 – Quality Management Systems for Medical Devices",
              ),
              bulletItem(
                "IEC 60601-1-2:2014 – Electromagnetic Compatibility for Medical Electrical Equipment",
              ),
              bulletItem(
                "Respyr 1.0 is authorized for manufacturing, sale, and distribution under valid MD13 and MD42 licenses in India.",
              ),
              bulletItem(
                "Respiratory Score:\n\nThis module is based on pressure-derived estimations of FEV1, calibrated against the AveloAir Digital Spirometer, a globally certified pulmonary function testing device. It has been internally validated through a clinical study involving participants with doctor-confirmed respiratory conditions and Pulmonary Function Test (PFT) data.\n\nThis module is not currently included under the IVD certification and is offered as a non-invasive physiological screening feature for respiratory trend assessment in preventive health contexts.",
              ),
              bulletItem(
                "Gut Fermentation Score:\n\nDerived from exhaled Hydrogen (H₂) levels, this module is calibrated using certified gas standards and aligned with international clinical reference thresholds for hydrogen breath testing.\n\nThis module is not included under the current IVD certification and is provided as a scientifically validated, non-invasive screening feature to support the assessment of digestive fermentation trends.",
              ),
              bulletItem(
                "Clinical Validation:\n\nA multi-centric clinical study was conducted by Respyr in collaboration with government-recognized medical institutions to collect breath and clinical reference data across diverse populations. All participating institutions obtained Ethics Committee (EC) approvals prior to initiating clinical data collection. Internal, blinded validation analysis conducted by Respyr demonstrated a 90% correlation accuracy between Respyr Scores and conventional clinical markers across all assessed domains — including metabolic, hepatic, respiratory, and gut health.",
              ),
            ],
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: 2,
            ), // small vertical nudge for alignment
            child: Text(
              "•",
              style: TextStyle(
                fontSize: 14,
                height: 1.3,
                color: Color(0xFF535359),
              ),
            ),
          ),
          const SizedBox(width: 6), // spacing between bullet and text
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: const Color(0xFF535359),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.30,
                letterSpacing: -0.24,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }
}
