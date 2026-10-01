import 'package:flutter/material.dart';

class ChoiceDropdownField<T> extends StatelessWidget {
  const ChoiceDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final T? value;
  final List<T> options;
  final String Function(T option) labelOf;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return TextFormField(
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Нет доступных значений',
          border: const OutlineInputBorder(),
        ),
        validator: (_) => 'Нет доступных значений',
      );
    }
    final safe = options.contains(value) ? value : null;
    return DropdownButtonFormField<T>(
      key: ValueKey('$label-$safe'),
      isExpanded: true,
      initialValue: safe,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(labelOf(option), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
      validator: validator ?? (selected) => selected == null ? 'Выберите значение' : null,
    );
  }
}

class MultiIdField extends StatelessWidget {
  const MultiIdField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.validator,
    this.emptyHint = 'Нет доступных значений',
  });

  final String label;
  final List<int> value;
  final List<({int id, String label})> options;
  final ValueChanged<List<int>> onChanged;
  final String? Function(List<int>?)? validator;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    return FormField<List<int>>(
      key: ValueKey('$label-${value.join(',')}'),
      initialValue: value,
      validator: validator,
      builder: (field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            errorText: field.errorText,
          ),
          child: options.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(emptyHint),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in options)
                      FilterChip(
                        label: Text(option.label),
                        selected: field.value?.contains(option.id) ?? false,
                        onSelected: (_) {
                          final next = [...?field.value];
                          if (next.contains(option.id)) {
                            next.remove(option.id);
                          } else {
                            next.add(option.id);
                          }
                          field.didChange(next);
                          onChanged(next);
                        },
                      ),
                  ],
                ),
        );
      },
    );
  }
}
