import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_notifier.dart';
import '../core/api_exceptions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  String? _usernameError;
  String? _passwordError;
  String? _formError;
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final usernameError = _username.text.trim().isEmpty ? 'Укажите логин' : null;
    final passwordError = _password.text.isEmpty ? 'Укажите пароль' : null;
    setState(() {
      _usernameError = usernameError;
      _passwordError = passwordError;
      _formError = null;
    });
    if (usernameError != null || passwordError != null) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthNotifier>().login(_username.text, _password.text);
    } on ApiException catch (error) {
      if (mounted) setState(() => _formError = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = context.watch<AuthNotifier>().signedOutMessage;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 48),
              Text('Вход', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Кондитерская «нямка»', textAlign: TextAlign.center),
              if (notice != null) ...[
                const SizedBox(height: 16),
                MaterialBanner(content: Text(notice), actions: const [SizedBox.shrink()]),
              ],
              const SizedBox(height: 24),
              TextField(
                controller: _username,
                decoration: InputDecoration(labelText: 'Логин', errorText: _usernameError),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Пароль', errorText: _passwordError),
                onSubmitted: (_) => _busy ? null : _submit(),
              ),
              if (_formError != null) ...[
                const SizedBox(height: 12),
                Text(_formError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Вход...' : 'Войти'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : () => context.go('/register'),
                child: const Text('Регистрация'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
