import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../domain/order_quote.dart';
import '../models/customer.dart';
import '../models/customer_query.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../models/workshop.dart';
import '../models/workshop_query.dart';
import '../repositories/customer_repository.dart';
import '../repositories/order_gateway.dart';
import '../repositories/product_repository.dart';
import '../repositories/workshop_repository.dart';

class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key, this.lockedCustomerId});

  final int? lockedCustomerId;

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _qty = TextEditingController(text: '1');
  DateTime _due = DateTime.now().add(const Duration(days: 1));
  int? _customerId;
  int? _productId;
  String? _error;
  bool _busy = false;
  bool _ready = false;
  List<Product> _productRows = const [];
  List<Customer> _customerRows = const [];
  List<Workshop> _workshopRows = const [];

  @override
  void initState() {
    super.initState();
    _customerId = widget.lockedCustomerId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  List<Product> get _products => _productRows;

  List<Customer> get _customers => _customerRows;

  Future<void> _prepare() async {
    final productsRepo = context.read<ProductRepository>();
    final customersRepo = context.read<CustomerRepository>();
    final workshopsRepo = context.read<WorkshopRepository>();
    try {
      final products = await productsRepo.find(const ProductQuery(size: 100));
      final customers = await customersRepo.find(
        const CustomerQuery(size: 100),
      );
      final workshops = await workshopsRepo.find(
        const WorkshopQuery(size: 100),
      );
      if (!mounted) return;
      setState(() {
        _productRows = products.items
            .where((item) => item.priceRub > 0)
            .toList();
        _customerRows = customers.items;
        _workshopRows = workshops.items;
        _ready = true;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _ready = true;
      });
    }
  }

  Customer? get _customer {
    for (final item in _customers) {
      if (item.id == _customerId) return item;
    }
    return null;
  }

  Product? get _product {
    for (final item in _products) {
      if (item.id == _productId) return item;
    }
    return null;
  }

  int get _qtyValue => int.tryParse(_qty.text.trim()) ?? 0;

  OrderTotals? get _totals {
    final product = _product;
    final customer = _customer;
    if (product == null || customer == null || _qtyValue < 1) return null;
    final discount = customer.loyaltyCard.active
        ? customer.loyaltyCard.discountPercent
        : 0;
    return priceOrder([
      PricedLine(
        unitPriceRub: product.priceRub,
        qty: _qtyValue,
        weightGrams: product.weightGrams,
        workshopCode: product.workshopId,
      ),
    ], discount);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _due = picked);
  }

  String get _dueText {
    final month = _due.month.toString().padLeft(2, '0');
    final day = _due.day.toString().padLeft(2, '0');
    return '${_due.year}-$month-$day';
  }

  Future<void> _save() async {
    final product = _product;
    final customer = _customer;
    final totals = _totals;
    if (product == null || customer == null || totals == null) {
      setState(() => _error = 'Выберите покупателя, изделие и количество.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final gateway = OrderGateway(context.read<Dio>());
    try {
      final already = await gateway.gramsOnDate(_dueText);
      final loads = workshopLoads(
        lines: [
          PricedLine(
            unitPriceRub: product.priceRub,
            qty: _qtyValue,
            weightGrams: product.weightGrams,
            workshopCode: product.workshopId,
          ),
        ],
        alreadyGrams: already,
        capacityGrams: {
          for (final workshop in _workshopRows)
            workshop.id: workshop.dailyCapacityKg,
        },
      );
      final blocked = overloadMessage(loads);
      if (blocked != null) {
        throw ConflictException(blocked);
      }
      await gateway.create(
        customerCode: customer.id,
        dueOn: _dueText,
        discountPercent: totals.discountPercent,
        totalRub: totals.totalRub,
        lines: [OrderDraftLine(productCode: product.id, qty: _qtyValue)],
        products: {
          product.id: (priceRub: product.priceRub, name: product.name),
        },
      );
      if (!mounted) return;
      context.go(widget.lockedCustomerId == null ? '/orders' : '/my-orders');
    } on ValidationException catch (error) {
      if (!mounted) return;
      final details = error.errors.values.join('\n');
      setState(() {
        _busy = false;
        _error = details.isEmpty ? error.message : details;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totals;
    final customers = _customers;
    final products = _products;
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый заказ'),
        actions: [
          IconButton(
            tooltip: 'Назад',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Стоимость считается по цене изделия. Если карта покупателя '
            'действует, из суммы вычитается её скидка. Заказ не сохранится, '
            'если цех на выбранную дату уже загружен выше суточной мощности.',
          ),
          const SizedBox(height: 16),
          if (widget.lockedCustomerId == null)
            DropdownButtonFormField<int>(
              initialValue: _customerId,
              decoration: const InputDecoration(labelText: 'Покупатель'),
              items: [
                for (final customer in customers)
                  DropdownMenuItem(
                    value: customer.id,
                    child: Text(customer.fullName),
                  ),
              ],
              onChanged: (value) => setState(() => _customerId = value),
            )
          else
            Text('Покупатель: ${_customer?.fullName ?? ''}'),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _productId,
            decoration: const InputDecoration(labelText: 'Изделие'),
            items: [
              for (final product in products)
                DropdownMenuItem(
                  value: product.id,
                  child: Text('${product.name} · ${product.priceRub} ₽'),
                ),
            ],
            onChanged: (value) => setState(() => _productId = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qty,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Количество'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Дата выдачи'),
            subtitle: Text(_dueText),
            trailing: OutlinedButton(
              onPressed: _pickDate,
              child: const Text('Выбрать'),
            ),
          ),
          if (_customer != null)
            Text(
              _customer!.loyaltyCard.active
                  ? 'Карта ${_customer!.loyaltyCard.number}: скидка ${_customer!.loyaltyCard.discountPercent}%'
                  : 'Скидка по карте не действует',
            ),
          if (totals != null) ...[
            const SizedBox(height: 8),
            Text('Сумма без скидки: ${totals.subtotalRub} ₽'),
            Text('Скидка: ${totals.discountRub} ₽'),
            Text('К оплате: ${totals.totalRub} ₽'),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text('Сохранить заказ'),
          ),
        ],
      ),
    );
  }
}
