import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/validators.dart';
import '../models/customer.dart';
import '../models/customer_query.dart';
import '../models/loyalty_card.dart';
import '../repositories/customer_repository.dart';
import '../state/catalog_notifier.dart';
import '../widgets/entity_form.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key, this.id});

  final int? id;

  bool get isEditing => id != null;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastName = TextEditingController();
  final _firstName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _cardNumber = TextEditingController();
  final _issuedOn = TextEditingController();
  final _discount = TextEditingController();
  bool _cardActive = true;
  String? _emailError;
  String _initial = '';
  bool _ready = false;
  bool _missing = false;
  bool _saving = false;

  bool get _dirty => _ready && _snapshot() != _initial;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _lastName.dispose();
    _firstName.dispose();
    _email.dispose();
    _phone.dispose();
    _cardNumber.dispose();
    _issuedOn.dispose();
    _discount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    Customer? item;
    if (widget.id != null) {
      item = await context.read<CustomerRepository>().findById(widget.id!);
      if (!mounted) return;
      if (item == null) {
        setState(() => _missing = true);
        return;
      }
    }
    _lastName.text = item?.lastName ?? '';
    _firstName.text = item?.firstName ?? '';
    _email.text = item?.email ?? '';
    _phone.text = item?.phone ?? '';
    _cardNumber.text = item?.loyaltyCard.number ?? '';
    _issuedOn.text = item?.loyaltyCard.issuedOn ?? '';
    _discount.text = item == null ? '' : '${item.loyaltyCard.discountPercent}';
    _cardActive = item?.loyaltyCard.active ?? true;
    _initial = _snapshot();
    setState(() => _ready = true);
  }

  String _snapshot() {
    return '${_lastName.text}|${_firstName.text}|${_email.text}|${_phone.text}|${_cardNumber.text}|${_issuedOn.text}|${_discount.text}|$_cardActive';
  }

  void _touchEmail(String _) {
    _emailError = null;
    setState(() {});
  }

  Future<void> _submit() async {
    setState(() => _emailError = null);
    if (!_formKey.currentState!.validate()) return;
    final repo = context.read<CustomerRepository>();
    final draft = Customer(
      id: widget.id ?? 0,
      lastName: _lastName.text.trim(),
      firstName: _firstName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      loyaltyCard: LoyaltyCard(
        number: _cardNumber.text.trim(),
        issuedOn: _issuedOn.text.trim(),
        discountPercent: int.parse(_discount.text.trim()),
        active: _cardActive,
      ),
    );
    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        await repo.update(draft);
      } else {
        await repo.create(draft);
      }
      if (!mounted) return;
      await context.read<CatalogNotifier<Customer, CustomerQuery>>().load();
      if (!mounted) return;
      _initial = _snapshot();
      context.go('/customers');
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _emailError = e.errors['email'] ?? e.message;
      });
      _formKey.currentState!.validate();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_missing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Покупатель')),
        body: Center(child: FilledButton(onPressed: () => context.go('/customers'), child: const Text('К списку'))),
      );
    }
    if (!_ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final person = [
      TextFieldSpec(
        label: 'Фамилия',
        controller: _lastName,
        onChanged: (_) => setState(() {}),
        validator: V.combine([V.required('Укажите фамилию'), V.length(min: 2, max: 60)]),
      ),
      TextFieldSpec(
        label: 'Имя',
        controller: _firstName,
        onChanged: (_) => setState(() {}),
        validator: V.combine([V.required('Укажите имя'), V.length(min: 2, max: 60)]),
      ),
      TextFieldSpec(
        label: 'Почта',
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        onChanged: _touchEmail,
        validator: (value) {
          final local = V.combine([V.required('Укажите почту'), V.email()])(value);
          return local ?? _emailError;
        },
      ),
      TextFieldSpec(
        label: 'Телефон',
        controller: _phone,
        keyboardType: TextInputType.phone,
        onChanged: (_) => setState(() {}),
        validator: V.combine([V.required('Укажите телефон'), V.phone()]),
      ),
    ];
    final card = [
      TextFieldSpec(
        label: 'Номер карты',
        controller: _cardNumber,
        onChanged: (_) => setState(() {}),
        validator: V.combine([
          V.required('Укажите номер карты'),
          V.pattern(RegExp(r'^NY-\d{6}$'), 'Формат номера: NY-000000'),
        ]),
      ),
      TextFieldSpec(
        label: 'Дата выдачи',
        controller: _issuedOn,
        onChanged: (_) => setState(() {}),
        validator: V.combine([V.required('Укажите дату'), V.date()]),
      ),
      TextFieldSpec(
        label: 'Скидка, %',
        controller: _discount,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        validator: V.combine([V.required('Укажите скидку'), V.integer(min: 0, max: 50)]),
      ),
    ];

    return FormScaffold(
      title: widget.isEditing ? 'Покупатель' : 'Новый покупатель',
      dirty: _dirty,
      child: EntityFormBody(
        formKey: _formKey,
        saving: _saving,
        submitLabel: widget.isEditing ? 'Сохранить' : 'Создать',
        onSubmit: _submit,
        children: [
          for (final field in person) labeledField(field),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Карта лояльности',
              border: OutlineInputBorder(),
            ),
            child: Column(
              children: [
                for (final field in card) ...[
                  labeledField(field),
                  const SizedBox(height: 12),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Карта активна'),
                  value: _cardActive,
                  onChanged: (value) => setState(() => _cardActive = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
