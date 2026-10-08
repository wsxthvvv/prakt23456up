import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';

class OrderDeskScreen extends StatefulWidget {
  const OrderDeskScreen({super.key});

  @override
  State<OrderDeskScreen> createState() => _OrderDeskScreenState();
}

class _OrderDeskScreenState extends State<OrderDeskScreen> {
  List<Map<String, dynamic>> _items = [];
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
      final response = await context.read<Dio>().get('/orders');
      final data = response.data;
      final items = data is Map && data['items'] is List ? data['items'] as List : const [];
      if (!mounted) return;
      setState(() {
        _items = [for (final item in items) if (item is Map) Map<String, dynamic>.from(item)];
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

  Future<void> _close(int id) async {
    try {
      await context.read<Dio>().post('/orders/$id/close');
      await _load();
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _error = '${mapDioError(error)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформление заказов'),
        actions: [IconButton(onPressed: () => context.go('/'), icon: const Icon(Icons.home))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Этот экран есть только у продавца: здесь все заказы покупателей, их можно закрыть.'),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          for (final item in _items)
            ListTile(
              title: Text('${item['productName']}'),
              subtitle: Text('Покупатель ${item['userId']} · ${item['qty']} шт. · ${item['status'] == 'closed' ? 'закрыт' : 'открыт'}'),
              trailing: item['status'] == 'closed'
                  ? null
                  : FilledButton(
                      onPressed: () => _close(item['id'] as int),
                      child: const Text('Закрыть'),
                    ),
            ),
        ],
      ),
    );
  }
}
