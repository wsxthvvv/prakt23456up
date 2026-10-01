import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';

Future<bool> runWorkshopDelete(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } on ConflictException catch (error) {
    if (!context.mounted) return false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление невозможно'),
        content: Text(error.message),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Понятно')),
        ],
      ),
    );
    return false;
  } on ApiException catch (error) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    return false;
  }
}
