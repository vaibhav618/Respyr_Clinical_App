import 'package:flutter/material.dart';

import 'calender_item.dart';

class HorizontalCalender extends StatefulWidget {
  final ValueChanged<DateTime> onDateChanged;

  const HorizontalCalender({super.key, required this.onDateChanged});

  @override
  State<HorizontalCalender> createState() => _HorizontalCalenderState();
}

class _HorizontalCalenderState extends State<HorizontalCalender> {
  final ScrollController _scrollController = ScrollController();

  late final List<DateTime> _dates;
  late final List<GlobalKey> _itemKeys;

  DateTime? _selectedDate;

  static const double _listHorizontalPadding = 20;
  static const double _separatorWidth = 10;

  double? _measuredItemWidth;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isFuture(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.isAfter(_today);
  }

  @override
  void initState() {
    super.initState();

    _dates = _generateDates();
    _itemKeys = List.generate(_dates.length, (_) => GlobalKey());

    final today = _today;

    final todayIndex = _dates.indexWhere(
          (d) => d.year == today.year && d.month == today.month && d.day == today.day,
    );

    final initialIndex = todayIndex != -1 ? todayIndex : 0;

    // ✅ make sure default selected is not a future date
    final defaultDate = _dates.isNotEmpty ? _dates[initialIndex] : null;
    _selectedDate = (defaultDate != null && !_isFuture(defaultDate))
        ? defaultDate
        : _dates.firstWhere(
          (d) => !_isFuture(d),
      orElse: () => _dates.isNotEmpty ? _dates.first : today,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final idx = _dates.indexOf(_selectedDate!);
      if (idx >= 0) _measureAndCenter(idx);
      widget.onDateChanged(_selectedDate!);
    });
  }

  List<DateTime> _generateDates() {
    final startDate = DateTime(2025, 12, 1);

    final today = _today;

    // ✅ keep your future dates logic SAME
    final endDate = today.add(const Duration(days: 4));

    return List.generate(
      endDate.difference(startDate).inDays + 1,
          (index) => startDate.add(Duration(days: index)),
    );
  }

  void _measureAndCenter(int index, {int retries = 8}) {
    if (!_scrollController.hasClients) return;

    final ctx = _itemKeys.isNotEmpty ? _itemKeys[0].currentContext : null;
    final box = ctx?.findRenderObject() as RenderBox?;

    if (box != null) {
      _measuredItemWidth = box.size.width;
      _scrollToCenter(index);
      return;
    }

    if (retries <= 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureAndCenter(index, retries: retries - 1);
    });
  }

  void _scrollToCenter(int index) {
    if (_measuredItemWidth == null || !_scrollController.hasClients) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = _measuredItemWidth!;

    final targetOffset = _listHorizontalPadding +
        (index * (itemWidth + _separatorWidth)) +
        (itemWidth / 2) -
        (screenWidth / 2);

    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onDateTap(int index) {
    final tapped = _dates[index];

    // ✅ disable future selection
    if (_isFuture(tapped)) {
      return;
    }

    setState(() {
      _selectedDate = tapped;
    });

    widget.onDateChanged(tapped);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_measuredItemWidth == null) {
        _measureAndCenter(index);
      } else {
        _scrollToCenter(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isFuture = _isFuture(date);

          // ✅ show future dates, but disable tap
          return GestureDetector(
            onTap: isFuture ? null : () => _onDateTap(index),
            child: Opacity(
              opacity: isFuture ? 0.45 : 1, // optional "disabled" look
              child: Container(
                key: _itemKeys[index],
                child: CalenderItem(
                  dateTime: date,
                  isSelected: date == _selectedDate,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: _separatorWidth),
      ),
    );
  }
}
