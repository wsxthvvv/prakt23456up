import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await context.read<Dio>().get('/stats');
      final data = response.data;
      if (!mounted) return;
      setState(() {
        _stats = data is Map ? Map<String, dynamic>.from(data) : {};
        _loading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '${mapDioError(error)}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        actions: [
          IconButton(
            tooltip: 'На главную',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Этот экран есть только у администратора.'),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (stats != null) ...[
            ListTile(
              title: const Text('Изделия'),
              trailing: Text('${stats['products'] ?? 0}'),
            ),
            ListTile(
              title: const Text('Заказы'),
              trailing: Text('${stats['orders'] ?? 0}'),
            ),
            ListTile(
              title: const Text('Пользователи'),
              trailing: Text('${stats['users'] ?? 0}'),
            ),
            ListTile(
              title: const Text('Покупатели в картотеке'),
              trailing: Text('${stats['customers'] ?? 0}'),
            ),
          ],
        ],
      ),
    );
  }
}
