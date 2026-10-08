import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../repositories/order_gateway.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;
  List<({String label, int amount})> _bars = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dio = context.read<Dio>();
      final orders = await OrderGateway(dio).list();
      final products = await dio.get(
        '/collections/products/records',
        queryParameters: {'perPage': 1, 'filter': 'deleted = false'},
      );
      final users = await dio.get(
        '/collections/users/records',
        queryParameters: {'perPage': 1},
      );
      final customers = await dio.get(
        '/collections/customers/records',
        queryParameters: {'perPage': 1, 'filter': 'deleted = false'},
      );
      final bars = <String, int>{};
      for (final order in orders) {
        for (final line in order.lines) {
          bars[line.productName] =
              (bars[line.productName] ?? 0) + line.unitPriceRub * line.qty;
        }
      }
      if (!mounted) return;
      setState(() {
        _stats = {
          'products': _total(products.data),
          'orders': orders.length,
          'users': _total(users.data),
          'customers': _total(customers.data),
        };
        _bars = [
          for (final entry in bars.entries)
            (label: entry.key, amount: entry.value),
        ]..sort((a, b) => b.amount.compareTo(a.amount));
        _loading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '${mapDioError(error)}';
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  int _total(dynamic data) {
    if (data is Map && data['totalItems'] is num) {
      return (data['totalItems'] as num).toInt();
    }
    return 0;
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
            const SizedBox(height: 16),
            const Text('Сумма заказов по изделиям'),
            const SizedBox(height: 8),
            if (_bars.isEmpty) const Text('Заказов с позициями пока нет.'),
            for (final bar in _bars)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(width: 140, child: Text(bar.label)),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _bars.first.amount == 0
                            ? 0
                            : bar.amount / _bars.first.amount,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${bar.amount} ₽'),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
