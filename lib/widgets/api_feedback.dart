import 'package:flutter/material.dart';

Future<void> showFailure(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
  }
}
