import 'package:flutter/material.dart';

class DeferredPage extends StatefulWidget {
  const DeferredPage({super.key, required this.load, required this.builder});

  final Future<void> Function() load;
  final Widget Function() builder;

  @override
  State<DeferredPage> createState() => _DeferredPageState();
}

class _DeferredPageState extends State<DeferredPage> {
  late final Future<void> _ready = widget.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Раздел не удалось открыть. Обновите страницу.'),
            ),
          );
        }
        return widget.builder();
      },
    );
  }
}
