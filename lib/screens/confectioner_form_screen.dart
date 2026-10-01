import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/validators.dart';
import '../models/confectioner.dart';
import '../repositories/confectioner_repository.dart';
import '../repositories/reference_repository.dart';
import '../repositories/workshop_repository.dart';
import '../state/confectioner_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/relation_fields.dart';

class ConfectionerFormScreen extends StatefulWidget {
  const ConfectionerFormScreen({super.key, this.id});

  final int? id;

  bool get isEditing => id != null;

  @override
  State<ConfectionerFormScreen> createState() => _ConfectionerFormScreenState();
}

class _ConfectionerFormScreenState extends State<ConfectionerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastName = TextEditingController();
  final _firstName = TextEditingController();
  String? _country;
  String? _specialty;
  int? _workshopId;
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
    super.dispose();
  }

  Future<void> _load() async {
    Confectioner? item;
    if (widget.id != null) {
      item = await context.read<ConfectionerRepository>().findById(widget.id!);
      if (!mounted) return;
      if (item == null) {
        setState(() => _missing = true);
        return;
      }
    }
    _lastName.text = item?.lastName ?? '';
    _firstName.text = item?.firstName ?? '';
    _country = item?.country;
    _specialty = item?.specialty;
    _workshopId = item?.workshopId;
    _initial = _snapshot();
    setState(() => _ready = true);
  }

  String _snapshot() => '${_lastName.text}|${_firstName.text}|$_country|$_specialty|$_workshopId';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final draft = Confectioner(
      id: widget.id ?? 0,
      lastName: _lastName.text.trim(),
      firstName: _firstName.text.trim(),
      country: _country!,
      specialty: _specialty!,
      workshopId: _workshopId!,
    );
    setState(() => _saving = true);
    final repo = context.read<ConfectionerRepository>();
    try {
      if (widget.isEditing) {
        await repo.update(draft);
      } else {
        await repo.create(draft);
      }
      if (!mounted) return;
      await context.read<ConfectionerListNotifier>().load();
      if (!mounted) return;
      _initial = _snapshot();
      context.go('/confectioners');
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
        appBar: AppBar(title: const Text('Кондитер')),
        body: Center(
          child: FilledButton(onPressed: () => context.go('/confectioners'), child: const Text('К списку')),
        ),
      );
    }
    if (!_ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final references = context.watch<ReferenceRepository>();
    final workshops = context.watch<WorkshopRepository>().all.where((w) => !w.isDeleted || w.id == _workshopId).toList();
    final fields = [
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
    ];

    return FormScaffold(
      title: widget.isEditing ? 'Кондитер' : 'Новый кондитер',
      dirty: _dirty,
      child: EntityFormBody(
        formKey: _formKey,
        saving: _saving,
        submitLabel: widget.isEditing ? 'Сохранить' : 'Создать',
        onSubmit: _submit,
        children: [
          for (final field in fields) labeledField(field),
          ChoiceDropdownField<String>(
            label: 'Страна',
            value: _country,
            options: references.countries,
            labelOf: (value) => value,
            onChanged: (value) => setState(() => _country = value),
          ),
          ChoiceDropdownField<String>(
            label: 'Специализация',
            value: _specialty,
            options: references.specialties,
            labelOf: (value) => value,
            onChanged: (value) => setState(() => _specialty = value),
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
            onChanged: (value) => setState(() => _workshopId = value),
            validator: (value) => value == null ? 'Выберите цех' : null,
          ),
        ],
      ),
    );
  }
}
