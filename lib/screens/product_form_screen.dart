import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/validators.dart';
import '../models/product.dart';
import '../repositories/confectioner_repository.dart';
import '../repositories/flavor_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/reference_repository.dart';
import '../repositories/workshop_repository.dart';
import '../state/product_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/relation_fields.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.id});

  final int? id;

  bool get isEditing => id != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _year = TextEditingController();
  final _weight = TextEditingController();
  final _stockTotal = TextEditingController();
  final _stockAvailable = TextEditingController();

  int? _categoryId;
  int? _workshopId;
  List<int> _flavorIds = [];
  List<int> _confectionerIds = [];
  final Map<String, String> _serverErrors = {};
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
    _name.dispose();
    _sku.dispose();
    _year.dispose();
    _weight.dispose();
    _stockTotal.dispose();
    _stockAvailable.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    Product? product;
    if (widget.id != null) {
      product = await context.read<ProductRepository>().findById(widget.id!);
      if (!mounted) return;
      if (product == null) {
        setState(() => _missing = true);
        return;
      }
    }
    _name.text = product?.name ?? '';
    _sku.text = product?.sku ?? '';
    _year.text = product == null ? '' : '${product.year}';
    _weight.text = product == null ? '' : '${product.weightGrams}';
    _stockTotal.text = product == null ? '' : '${product.stockTotal}';
    _stockAvailable.text = product == null ? '' : '${product.stockAvailable}';
    _categoryId = product?.categoryId;
    _workshopId = product?.workshopId;
    _flavorIds = [...?product?.flavorTagIds].where(_allowedFlavorIds().contains).toList();
    _confectionerIds = [...?product?.confectionerIds].where(_allowedConfectionerIds().contains).toList();
    _initial = _snapshot();
    setState(() => _ready = true);
  }

  String _snapshot() {
    return [
      _name.text,
      _sku.text,
      _year.text,
      _weight.text,
      _stockTotal.text,
      _stockAvailable.text,
      _categoryId,
      _workshopId,
      _flavorIds.join(','),
      _confectionerIds.join(','),
    ].join('|');
  }

  void _touch([String _ = '']) {
    if (_serverErrors.isNotEmpty) _serverErrors.clear();
    setState(() {});
  }

  List<TextFieldSpec> get _fields => [
        TextFieldSpec(
          label: 'Название',
          controller: _name,
          onChanged: _touch,
          validator: (value) {
            final local = V.combine([V.required('Укажите название'), V.length(min: 2, max: 120)])(value);
            return local ?? _serverErrors['name'];
          },
        ),
        TextFieldSpec(
          label: 'Артикул',
          controller: _sku,
          onChanged: _touch,
          validator: (value) {
            final local = V.combine([
              V.required('Укажите артикул'),
              V.length(min: 3, max: 32),
            ])(value);
            return local ?? _serverErrors['sku'];
          },
        ),
        TextFieldSpec(
          label: 'Год в ассортименте',
          controller: _year,
          keyboardType: TextInputType.number,
          onChanged: _touch,
          validator: (value) {
            final local = V.combine([V.required('Укажите год'), V.integer(min: 1990, max: 2100)])(value);
            return local ?? _serverErrors['year'];
          },
        ),
        TextFieldSpec(
          label: 'Масса, г',
          controller: _weight,
          keyboardType: TextInputType.number,
          onChanged: _touch,
          validator: V.combine([V.required('Укажите массу'), V.integer(min: 1, max: 20000)]),
        ),
        TextFieldSpec(
          label: 'На складе, шт.',
          controller: _stockTotal,
          keyboardType: TextInputType.number,
          onChanged: _touch,
          validator: V.combine([V.required('Укажите количество'), V.integer(min: 1, max: 100000)]),
        ),
        TextFieldSpec(
          label: 'Доступно, шт.',
          controller: _stockAvailable,
          keyboardType: TextInputType.number,
          onChanged: _touch,
          validator: (value) {
            final local = V.combine([
              V.required('Укажите доступный остаток'),
              V.integer(min: 0, max: 100000),
            ])(value);
            if (local != null) return local;
            final total = int.tryParse(_stockTotal.text.trim());
            final available = int.tryParse(value?.trim() ?? '');
            if (total != null && available != null && available > total) {
              return 'Доступно не больше, чем на складе';
            }
            return null;
          },
        ),
      ];

  void _onWorkshopChanged(int? id) {
    setState(() {
      _workshopId = id;
      final allowedFlavors = _allowedFlavorIds();
      final allowedChefs = _allowedConfectionerIds();
      _flavorIds = _flavorIds.where(allowedFlavors.contains).toList();
      _confectionerIds = _confectionerIds.where(allowedChefs.contains).toList();
    });
  }

  Set<int> _allowedFlavorIds() {
    if (_workshopId == null) return {};
    for (final workshop in context.read<WorkshopRepository>().all) {
      if (workshop.id == _workshopId) return workshop.flavorIds.toSet();
    }
    return {};
  }

  Set<int> _allowedConfectionerIds() {
    if (_workshopId == null) return {};
    return context
        .read<ConfectionerRepository>()
        .all
        .where((c) => !c.isDeleted && c.workshopId == _workshopId)
        .map((c) => c.id)
        .toSet();
  }

  Future<void> _submit() async {
    setState(() => _serverErrors.clear());
    if (!_formKey.currentState!.validate()) return;
    final repo = context.read<ProductRepository>();
    final draft = Product(
      id: widget.id ?? 0,
      name: _name.text.trim(),
      sku: _sku.text.trim(),
      year: int.parse(_year.text.trim()),
      weightGrams: int.parse(_weight.text.trim()),
      categoryId: _categoryId!,
      workshopId: _workshopId!,
      confectionerIds: _confectionerIds,
      flavorTagIds: _flavorIds,
      stockTotal: int.parse(_stockTotal.text.trim()),
      stockAvailable: int.parse(_stockAvailable.text.trim()),
    );
    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        await repo.update(draft);
      } else {
        await repo.create(draft);
      }
      if (!mounted) return;
      await context.read<ProductListNotifier>().load();
      if (!mounted) return;
      _initial = _snapshot();
      context.go('/products');
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverErrors
          ..clear()
          ..addAll(e.errors);
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
        appBar: AppBar(title: const Text('Изделие')),
        body: Center(
          child: FilledButton(onPressed: () => context.go('/products'), child: const Text('К каталогу')),
        ),
      );
    }
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final references = context.watch<ReferenceRepository>();
    final workshops = context.watch<WorkshopRepository>().all.where((w) => !w.isDeleted || w.id == _workshopId).toList();
    final flavors = context.watch<FlavorRepository>().all;
    final confectioners = context.watch<ConfectionerRepository>().all;
    final allowedFlavors = _allowedFlavorIds();
    final allowedChefs = _allowedConfectionerIds();

    return FormScaffold(
      title: widget.isEditing ? 'Изделие' : 'Новое изделие',
      dirty: _dirty,
      child: EntityFormBody(
        formKey: _formKey,
        saving: _saving,
        submitLabel: widget.isEditing ? 'Сохранить' : 'Создать',
        onSubmit: _submit,
        children: [
          for (final field in _fields) labeledField(field),
          ChoiceDropdownField<int>(
            label: 'Категория',
            value: _categoryId,
            options: [for (final category in references.categories) category.id],
            labelOf: references.categoryName,
            onChanged: (value) => setState(() => _categoryId = value),
          ),
          ChoiceDropdownField<int>(
            label: 'Цех',
            value: _workshopId,
            options: [for (final workshop in workshops) workshop.id],
            labelOf: (id) {
              for (final workshop in workshops) {
                if (workshop.id == id) return workshop.name;
              }
              return '—';
            },
            onChanged: _onWorkshopChanged,
            validator: (value) => value == null ? 'Выберите цех' : null,
          ),
          const Text('Список вкусов и кондитеров сужается по выбранному цеху.'),
          MultiIdField(
            label: 'Вкусы',
            value: _flavorIds,
            emptyHint: _workshopId == null ? 'Сначала выберите цех' : 'У цеха нет доступных вкусов',
            options: [
              for (final flavor in flavors)
                if (!flavor.isDeleted && allowedFlavors.contains(flavor.id)) (id: flavor.id, label: flavor.name),
            ],
            onChanged: (value) => setState(() => _flavorIds = value),
            validator: (value) => (value == null || value.isEmpty) ? 'Выберите хотя бы один вкус' : null,
          ),
          MultiIdField(
            label: 'Кондитеры',
            value: _confectionerIds,
            emptyHint: _workshopId == null ? 'Сначала выберите цех' : 'В этом цехе нет кондитеров',
            options: [
              for (final confectioner in confectioners)
                if (allowedChefs.contains(confectioner.id)) (id: confectioner.id, label: confectioner.fullName),
            ],
            onChanged: (value) => setState(() => _confectionerIds = value),
            validator: (value) => (value == null || value.isEmpty) ? 'Выберите хотя бы одного кондитера' : null,
          ),
        ],
      ),
    );
  }
}
