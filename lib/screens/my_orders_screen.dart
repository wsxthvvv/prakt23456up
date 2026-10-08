import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_notifier.dart';
import '../core/api_exceptions.dart';
import '../repositories/order_gateway.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<OrderView> _items = [];
  int? _customerCode;
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
      final gateway = OrderGateway(context.read<Dio>());
      final userId = context.read<AuthNotifier>().user?.pbId ?? '';
      final customerCode = await gateway.customerCodeForUser(userId);
      final items = await gateway.list();
      if (!mounted) return;
      setState(() {
        _customerCode = customerCode;
        _items = [
          for (final item in items)
            if (customerCode == null || item.customerCode == customerCode)
              item,
        ];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
        actions: [
          IconButton(
            tooltip: 'Новый заказ',
            onPressed: _customerCode == null
                ? null
                : () => context.go('/my-orders/new?customer=$_customerCode'),
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
            'Этот экран есть только у покупателя. Цена считается со скидкой действующей карты.',
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
              title: Text('${item.dueOn} · ${item.totalRub} ₽'),
              subtitle: Text(
                item.lines
                    .map((line) => '${line.productName} × ${line.qty}')
                    .join(', '),
              ),
              trailing: Text(item.status == 'closed' ? 'закрыт' : 'открыт'),
            ),
        ],
      ),
    );
  }
}
