import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/access_policy.dart';
import '../auth/auth_notifier.dart';
import '../core/api_exceptions.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _username = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _usernameError;
  String? _fullNameError;
  String? _emailError;
  String? _passwordError;
  Map<String, String> _serverErrors = {};
  String? _formError;
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onPassword(String value) {
    setState(() => _passwordError = passwordIssue(value));
  }

  Future<void> _submit() async {
    final usernameError = _username.text.trim().length < 3
        ? 'Укажите логин не короче 3 символов'
        : null;
    final fullNameError = _fullName.text.trim().length < 3
        ? 'Укажите имя и фамилию'
        : null;
    final email = _email.text.trim();
    final emailError = !RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)
        ? 'Некорректный адрес почты'
        : null;
    final passwordError = passwordIssue(_password.text);
    setState(() {
      _usernameError = usernameError;
      _fullNameError = fullNameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _serverErrors = {};
      _formError = null;
    });
    if (usernameError != null ||
        fullNameError != null ||
        emailError != null ||
        passwordError != null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<AuthNotifier>().register(
        username: _username.text,
        password: _password.text,
        email: email,
        fullName: _fullName.text,
      );
    } on ValidationException catch (error) {
      if (mounted) setState(() => _serverErrors = error.errors);
    } on ApiException catch (error) {
      if (mounted) setState(() => _formError = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? field(String key, String? local) => local ?? _serverErrors[key];
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 32),
              Text(
                'Регистрация',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Новая учётная запись получает роль покупателя. Пароль: не короче 8 символов, цифра и специальный символ.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _fullName,
                decoration: InputDecoration(
                  labelText: 'Имя и фамилия',
                  errorText: field('fullName', _fullNameError),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _username,
                decoration: InputDecoration(
                  labelText: 'Логин',
                  errorText: field('username', _usernameError),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                decoration: InputDecoration(
                  labelText: 'Почта',
                  errorText: field('email', _emailError),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                onChanged: _onPassword,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  errorText: field('password', _passwordError),
                ),
              ),
              if (_formError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _formError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Регистрация...' : 'Зарегистрироваться'),
              ),
              TextButton(
                onPressed: _busy ? null : () => context.go('/login'),
                child: const Text('Уже есть учётная запись'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
