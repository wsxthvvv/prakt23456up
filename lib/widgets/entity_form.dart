import 'package:flutter/material.dart';

import 'unsaved_pop_scope.dart';

class TextFieldSpec {
  const TextFieldSpec({
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.onChanged,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final int maxLines;
}

class FormScaffold extends StatelessWidget {
  const FormScaffold({super.key, required this.title, required this.dirty, required this.child});

  final String title;
  final bool dirty;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return UnsavedPopScope(
      dirty: dirty,
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (dirty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('Есть несохранённые изменения'),
                  ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EntityFormBody extends StatelessWidget {
  const EntityFormBody({
    super.key,
    required this.formKey,
    required this.children,
    required this.submitLabel,
    required this.onSubmit,
    this.saving = false,
  });

  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final String submitLabel;
  final VoidCallback? onSubmit;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final child in children) ...[
            child,
            const SizedBox(height: 16),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: saving ? null : onSubmit,
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(submitLabel),
            ),
          ),
        ],
      ),
    );
  }
}

Widget labeledField(TextFieldSpec spec) {
  return TextFormField(
    controller: spec.controller,
    maxLines: spec.maxLines,
    keyboardType: spec.keyboardType,
    decoration: InputDecoration(labelText: spec.label, border: const OutlineInputBorder()),
    validator: spec.validator,
    onChanged: spec.onChanged,
  );
}
