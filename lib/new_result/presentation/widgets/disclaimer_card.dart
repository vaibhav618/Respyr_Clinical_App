import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/report_texts.dart';

/// Disclaimer and regulatory status, collapsed to their titles.
///
/// Both blocks are must-carry text, but fully expanded they were several
/// screens of dense justified paragraphs sitting at the end of every result —
/// the reader scrolled through them without reading. The text is all still
/// here, word for word; a tap unfolds the section for whoever needs it.
class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CollapsibleSection(
            title: "Disclaimer",
            child: _disclaimerBody(),
          ),
          const SizedBox(height: 10),
          CollapsibleSection(
            title: "Regulatory Status",
            child: _regulatoryBody(),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // Text comes from report_texts.dart — shared with the PDF report, so the
  // wording cannot drift between screen and paper.
  Widget _disclaimerBody() {
    return Text(
            kDisclaimerText,
            style: GoogleFonts.poppins(
              color: const Color(0xFF535359),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.30,
              letterSpacing: -0.24,
            ),
            textAlign: TextAlign.justify,
    );
  }

  Widget _regulatoryBody() {
    return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kRegulatoryIntro,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF535359),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.30,
                  letterSpacing: -0.24,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 10),
              for (final String bullet in kRegulatoryBullets)
                bulletItem(bullet),
            ],
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

/// A titled card that keeps its body folded until tapped.
class CollapsibleSection extends StatefulWidget {
  final String title;
  final Widget child;

  const CollapsibleSection({super.key, required this.title, required this.child});

  @override
  State<CollapsibleSection> createState() => CollapsibleSectionState();
}

class CollapsibleSectionState extends State<CollapsibleSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF252525),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: Color(0xFFA1A1A1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // AnimatedSize so the fold opens and closes smoothly; the child is
          // simply absent while closed, so folded sections cost no layout.
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
