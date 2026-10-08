import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../repositories/order_gateway.dart';

class OrderDeskScreen extends StatefulWidget {
  const OrderDeskScreen({super.key});

  @override
  State<OrderDeskScreen> createState() => _OrderDeskScreenState();
}

class _OrderDeskScreenState extends State<OrderDeskScreen> {
  List<OrderView> _items = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await OrderGateway(context.read<Dio>()).list();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _close(int code) async {
    try {
      await OrderGateway(context.read<Dio>()).close(code);
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформление заказов'),
        actions: [
          IconButton(
            tooltip: 'Новый заказ',
            onPressed: () => context.go('/orders/new'),
            icon: const Icon(Icons.add),
          ),
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
          const Text(
            'Этот экран есть только у продавца. Сумма заказа уже учитывает скидку карты.',
          ),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (!_loading && _error == null && _items.isEmpty)
            const Text('Заказов пока нет.'),
          for (final item in _items)
            ListTile(
              title: Text(
                '${item.customerName} · ${item.dueOn} · ${item.totalRub} ₽',
              ),
              subtitle: Text(
                '${item.lines.map((line) => '${line.productName} × ${line.qty}').join(', ')}'
                '${item.status == 'closed' ? ' · закрыт' : ' · открыт'}',
              ),
              trailing: item.status == 'closed'
                  ? null
                  : FilledButton(
                      onPressed: () => _close(item.code),
                      child: const Text('Закрыть'),
                    ),
            ),
        ],
      ),
    );
  }
}
