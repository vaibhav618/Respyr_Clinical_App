import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/issue_item.dart';

Widget issueTagPill(IssueItem item) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: item.itemBackgroundColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      item.name,
      style: GoogleFonts.poppins(
        color: item.itemTextColor,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.10,
        letterSpacing: -0.24,
      ),
    ),
  );
}


Widget issuePillContainer(List<IssueItem> selectedItems, bool showDivider) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (showDivider && selectedItems.isNotEmpty) Divider(),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: selectedItems.map((item) => issueTagPill(item)).toList(),
      ),
    ],
  );
}






