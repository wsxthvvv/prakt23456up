import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final _product = TextEditingController();
  final _qty = TextEditingController(text: '1');
  List<Map<String, dynamic>> _items = [];
  String? _error;
  String? _productError;
  String? _qtyError;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _product.dispose();
    _qty.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await context.read<Dio>().get('/my-orders');
      final data = response.data;
      final items = data is Map && data['items'] is List
          ? data['items'] as List
          : const [];
      if (!mounted) return;
      setState(() {
        _items = [
          for (final item in items)
            if (item is Map) Map<String, dynamic>.from(item),
        ];
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

  Future<void> _place() async {
    final qty = int.tryParse(_qty.text.trim());
    final productError = _product.text.trim().length < 2
        ? 'Укажите изделие'
        : null;
    final qtyError = qty == null || qty < 1 ? 'Укажите количество' : null;
    setState(() {
      _productError = productError;
      _qtyError = qtyError;
    });
    if (productError != null || qtyError != null) return;
    setState(() => _busy = true);
    try {
      await context.read<Dio>().post(
        '/my-orders',
        data: {'productName': _product.text.trim(), 'qty': qty},
      );
      _product.clear();
      await _load();
    } on DioException catch (error) {
      if (!mounted) return;
      final mapped = mapDioError(error);
      if (mapped is ValidationException) {
        setState(() {
          _productError = mapped.errors['productName'];
          _qtyError = mapped.errors['qty'];
        });
      } else {
        setState(() => _error = mapped.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
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
          const Text(
            'Этот экран есть только у покупателя: здесь свои заказы, чужие не видны.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _product,
            decoration: InputDecoration(
              labelText: 'Изделие',
              errorText: _productError,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qty,
            decoration: InputDecoration(
              labelText: 'Количество',
              errorText: _qtyError,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _place,
            child: const Text('Оформить заказ'),
          ),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          for (final item in _items)
            ListTile(
              title: Text('${item['productName']}'),
              subtitle: Text(
                '${item['qty']} шт. · ${item['status'] == 'closed' ? 'закрыт' : 'открыт'}',
              ),
            ),
        ],
      ),
    );
  }
}
