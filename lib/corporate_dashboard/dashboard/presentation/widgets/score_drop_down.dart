import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SimpleDropdown extends StatelessWidget {
  final List<String> items;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const SimpleDropdown({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    assert(items.contains(selectedValue),
    'selectedValue must exist in items');

    return DropdownButton<String>(
      value: selectedValue,
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        ),
      )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
