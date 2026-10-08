import 'package:flutter/material.dart';

List<Widget> rowActions({
  required VoidCallback onOpen,
  required VoidCallback onEdit,
  required bool deleted,
  required VoidCallback onRestore,
  required VoidCallback onSoftDelete,
  required VoidCallback onHardDelete,
  bool canEdit = true,
  bool canSoftDelete = true,
  bool canRestore = true,
  bool canHardDelete = true,
}) {
  return [
    IconButton(
      tooltip: 'Карточка',
      onPressed: onOpen,
      icon: const Icon(Icons.open_in_new),
    ),
    if (canEdit)
      IconButton(
        tooltip: 'Изменить',
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined),
      ),
    if (deleted && canRestore)
      IconButton(
        tooltip: 'Восстановить',
        onPressed: onRestore,
        icon: const Icon(Icons.restore),
      )
    else if (!deleted) ...[
      if (canSoftDelete)
        IconButton(
          tooltip: 'Скрыть (логическое удаление)',
          onPressed: onSoftDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      if (canHardDelete)
        IconButton(
          tooltip: 'Удалить навсегда',
          onPressed: onHardDelete,
          icon: const Icon(Icons.delete_forever),
        ),
    ],
  ];
}
