import 'package:flutter/material.dart';

class UnsavedPopScope extends StatefulWidget {
  const UnsavedPopScope({super.key, required this.dirty, required this.child});

  final bool dirty;
  final Widget child;

  @override
  State<UnsavedPopScope> createState() => _UnsavedPopScopeState();
}

class _UnsavedPopScopeState extends State<UnsavedPopScope> {
  bool _allowPop = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.dirty || _allowPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !widget.dirty) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Есть несохранённые изменения'),
            content: const Text('Уйти с формы и потерять введённые данные?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Остаться'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Уйти'),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) {
          setState(() => _allowPop = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
        }
      },
      child: widget.child,
    );
  }
}
