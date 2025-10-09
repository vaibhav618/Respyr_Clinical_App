import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/quick_summary_table.dart';

import '../../data/model/result_model.dart';


class QuickSummary extends StatefulWidget {
  final NewResultModel userResultData;
  const QuickSummary({super.key, required this.userResultData});

  @override
  State<QuickSummary> createState() => _QuickSummaryState();
}

class _QuickSummaryState extends State<QuickSummary> {
  final ScrollController horizontalScrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 0.50, color: const Color(0xFFC7C6CE)),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: InkWell(
                onTap: () {
                  horizontalScrollController.animateTo(
                    horizontalScrollController.position.maxScrollExtent,
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Quick Interpretation",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF308BF9),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.10,
                        letterSpacing: -0.30,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_right_rounded,
                      color: Color(0xFF308BF9),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                height: 16,
                color: Color(0xFFC7C6CE),
                thickness: 0.5,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 5, bottom: 0),
              child: QuickSummaryTable(
                userResultData: widget.userResultData,
                scrollController: horizontalScrollController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
