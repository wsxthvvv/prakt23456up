import 'package:flutter/material.dart';

import '../models/page_result.dart';

class PaginationBar extends StatelessWidget {
  final PageResult<dynamic> result;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;

  const PaginationBar({
    super.key,
    required this.result,
    required this.onPageChanged,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Записей: ${result.total}, страница ${result.page} из ${result.totalPages}'),
        IconButton(
          tooltip: 'Первая',
          onPressed: result.hasPrevious ? () => onPageChanged(1) : null,
          icon: const Icon(Icons.first_page),
        ),
        IconButton(
          tooltip: 'Предыдущая',
          onPressed: result.hasPrevious ? () => onPageChanged(result.page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: 'Следующая',
          onPressed: result.hasNext ? () => onPageChanged(result.page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
        IconButton(
          tooltip: 'Последняя',
          onPressed: result.hasNext ? () => onPageChanged(result.totalPages) : null,
          icon: const Icon(Icons.last_page),
        ),
        DropdownButton<int>(
          value: result.size,
          items: const [
            DropdownMenuItem(value: 10, child: Text('10 на странице')),
            DropdownMenuItem(value: 25, child: Text('25 на странице')),
            DropdownMenuItem(value: 50, child: Text('50 на странице')),
          ],
          onChanged: (value) {
            if (value != null) onSizeChanged(value);
          },
        ),
      ],
    );
  }
}
