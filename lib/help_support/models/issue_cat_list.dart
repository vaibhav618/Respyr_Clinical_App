import 'dart:ui';

import 'issue_item.dart';

List<IssueItem> issueCatList = [
  IssueItem('App not starting', Color(0xFFFFF3E0), Color(0xFFFFA000)),
  IssueItem('Device connection', Color(0xFFE1F5FE), Color(0xFF0288D1)),
  IssueItem('Test taking', Color(0xFFE8F5E9), Color(0xFF2E7D32)),
  IssueItem('App issue', Color(0xFFFFEBEE), Color(0xFFD32F2F)),
  IssueItem('Hardware issue', Color(0xFFF3E5F5), Color(0xFF7B1FA2)),
  IssueItem('Other', Color(0xFFFFFDE7), Color(0xFFFBC02D)),
];

Color? getIssueBackgroundColor(String issueName) {
  return issueCatList
      .firstWhere((item) => item.name == issueName, orElse: () => IssueItem('', Color(0x00000000), Color(0x00000000)))
      .itemBackgroundColor;
}

// Returns text color for the given issue name
Color? getIssueTextColor(String issueName) {
  return issueCatList
      .firstWhere((item) => item.name == issueName, orElse: () => IssueItem('', Color(0x00000000), Color(0x00000000)))
      .itemTextColor;
}


List<IssueItem> getMatchingIssues(String input) {
  // Split and trim each string
  List<String> names = input.split(',').map((e) => e.trim()).toList();

  // Return matching items from issueCatList
  return issueCatList
      .where((item) => names.contains(item.name))
      .toList();
}