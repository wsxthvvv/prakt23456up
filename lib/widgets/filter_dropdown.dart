import 'package:flutter/material.dart';

class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = 220,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final double width;

  static Widget menuText(String text) {
    return Text(text, overflow: TextOverflow.ellipsis, maxLines: 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final fieldWidth = available.isFinite && available < width
            ? available
            : width;
        return SizedBox(
          width: fieldWidth,
          child: DropdownButtonFormField<T>(
            key: ValueKey<T?>(value),
            isExpanded: true,
            initialValue: value,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: items,
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}
