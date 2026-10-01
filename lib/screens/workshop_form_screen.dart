import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/validators.dart';
import '../models/workshop.dart';
import '../models/workshop_query.dart';
import '../repositories/flavor_repository.dart';
import '../repositories/workshop_repository.dart';
import '../state/catalog_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/relation_fields.dart';

class WorkshopFormScreen extends StatefulWidget {
  const WorkshopFormScreen({super.key, this.id});

  final int? id;

  bool get isEditing => id != null;

  @override
  State<WorkshopFormScreen> createState() => _WorkshopFormScreenState();
}

class _WorkshopFormScreenState extends State<WorkshopFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  List<int> _flavorIds = [];
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
    _city.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    Workshop? item;
    if (widget.id != null) {
      item = await context.read<WorkshopRepository>().findById(widget.id!);
      if (!mounted) return;
      if (item == null) {
        setState(() => _missing = true);
        return;
      }
    }
    _name.text = item?.name ?? '';
    _city.text = item?.city ?? '';
    _phone.text = item?.phone ?? '';
    _flavorIds = [...?item?.flavorIds];
    _initial = _snapshot();
    setState(() => _ready = true);
  }

  String _snapshot() => '${_name.text}|${_city.text}|${_phone.text}|${_flavorIds.join(',')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final draft = Workshop(
      id: widget.id ?? 0,
      name: _name.text.trim(),
      city: _city.text.trim(),
      phone: _phone.text.trim(),
      flavorIds: _flavorIds,
    );
    setState(() => _saving = true);
    final repo = context.read<WorkshopRepository>();
    try {
      if (widget.isEditing) {
        await repo.update(draft);
      } else {
        await repo.create(draft);
      }
      if (!mounted) return;
      await context.read<CatalogNotifier<Workshop, WorkshopQuery>>().load();
      if (!mounted) return;
      _initial = _snapshot();
      context.go('/workshops');
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
        appBar: AppBar(title: const Text('Цех')),
        body: Center(child: FilledButton(onPressed: () => context.go('/workshops'), child: const Text('К списку'))),
      );
    }
    if (!_ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final flavors = context.watch<FlavorRepository>().all.where((f) => !f.isDeleted).toList();
    final fields = [
      TextFieldSpec(
        label: 'Название',
        controller: _name,
        onChanged: (_) => setState(() {}),
        validator: V.combine([V.required('Укажите название'), V.length(min: 2, max: 80)]),
      ),
      TextFieldSpec(
        label: 'Город',
        controller: _city,
        onChanged: (_) => setState(() {}),
        validator: V.combine([V.required('Укажите город'), V.length(min: 2, max: 60)]),
      ),
      TextFieldSpec(
        label: 'Телефон',
        controller: _phone,
        keyboardType: TextInputType.phone,
        onChanged: (_) => setState(() {}),
        validator: V.combine([V.required('Укажите телефон'), V.phone()]),
      ),
    ];
    return FormScaffold(
      title: widget.isEditing ? 'Цех' : 'Новый цех',
      dirty: _dirty,
      child: EntityFormBody(
        formKey: _formKey,
        saving: _saving,
        submitLabel: widget.isEditing ? 'Сохранить' : 'Создать',
        onSubmit: _submit,
        children: [
          for (final field in fields) labeledField(field),
          MultiIdField(
            label: 'Вкусы цеха',
            value: _flavorIds,
            options: [for (final flavor in flavors) (id: flavor.id, label: flavor.name)],
            onChanged: (value) => setState(() => _flavorIds = value),
            validator: (value) => (value == null || value.isEmpty) ? 'Выберите хотя бы один вкус' : null,
          ),
        ],
      ),
    );
  }
}
