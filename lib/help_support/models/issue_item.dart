import 'dart:ui';

class IssueItem {
  final String name;
  final Color itemBackgroundColor;
  final Color itemTextColor;

  IssueItem(this.name, this.itemBackgroundColor, this.itemTextColor);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is IssueItem &&
              runtimeType == other.runtimeType &&
              name == other.name;

  @override
  int get hashCode => name.hashCode;
}
