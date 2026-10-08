import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/validators.dart';
import '../models/flavor.dart';
import '../models/flavor_query.dart';
import '../repositories/flavor_repository.dart';
import '../state/catalog_notifier.dart';
import '../widgets/entity_form.dart';

class FlavorFormScreen extends StatefulWidget {
  const FlavorFormScreen({super.key, this.id});

  final int? id;

  bool get isEditing => id != null;

  @override
  State<FlavorFormScreen> createState() => _FlavorFormScreenState();
}

class _FlavorFormScreenState extends State<FlavorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _intensity = TextEditingController();
  String _initial = '';
  bool _ready = false;
  bool _missing = false;
  bool _saving = false;

  CatalogNotifier<Flavor, FlavorQuery> get _list =>
      context.read<CatalogNotifier<Flavor, FlavorQuery>>();

  bool get _dirty => _ready && _snapshot() != _initial;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _intensity.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    Flavor? item;
    if (widget.id != null) {
      item = await context.read<FlavorRepository>().findById(widget.id!);
      if (!mounted) return;
      if (item == null) {
        setState(() => _missing = true);
        return;
      }
    }
    _name.text = item?.name ?? '';
    _description.text = item?.description ?? '';
    _intensity.text = item == null ? '' : '${item.intensity}';
    _initial = _snapshot();
    setState(() => _ready = true);
  }

  String _snapshot() => '${_name.text}|${_description.text}|${_intensity.text}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final draft = Flavor(
      id: widget.id ?? 0,
      name: _name.text.trim(),
      description: _description.text.trim(),
      intensity: int.parse(_intensity.text.trim()),
    );
    setState(() => _saving = true);
    final repo = context.read<FlavorRepository>();
    try {
      if (widget.isEditing) {
        await repo.update(draft);
      } else {
        await repo.create(draft);
      }
      if (!mounted) return;
      await _list.load();
      if (!mounted) return;
      _initial = _snapshot();
      context.go('/flavors');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_missing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Вкус')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/flavors'),
            child: const Text('К списку'),
          ),
        ),
      );
    }
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final fields = [
      TextFieldSpec(
        label: 'Название',
        controller: _name,
        onChanged: (_) => setState(() {}),
        validator: V.combine([
          V.required('Укажите название'),
          V.length(min: 2, max: 40),
        ]),
      ),
      TextFieldSpec(
        label: 'Описание',
        controller: _description,
        maxLines: 3,
        onChanged: (_) => setState(() {}),
        validator: V.combine([
          V.required('Укажите описание'),
          V.length(min: 3, max: 200),
        ]),
      ),
      TextFieldSpec(
        label: 'Интенсивность (1–5)',
        controller: _intensity,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        validator: V.combine([
          V.required('Укажите интенсивность'),
          V.integer(min: 1, max: 5),
        ]),
      ),
    ];
    return FormScaffold(
      title: widget.isEditing ? 'Вкус' : 'Новый вкус',
      dirty: _dirty,
      child: EntityFormBody(
        formKey: _formKey,
        saving: _saving,
        submitLabel: widget.isEditing ? 'Сохранить' : 'Создать',
        onSubmit: _submit,
        children: [for (final field in fields) labeledField(field)],
      ),
    );
  }
}
