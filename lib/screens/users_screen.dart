import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/access_policy.dart';
import '../core/api_exceptions.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> _items = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await context.read<Dio>().get(
        '/collections/users/records',
        queryParameters: {'page': 1, 'perPage': 50, 'sort': 'code'},
      );
      final data = response.data;
      final items = data is Map && data['items'] is List
          ? data['items'] as List
          : const [];
      if (!mounted) return;
      setState(() {
        _items = [
          for (final item in items)
            if (item is Map)
              {
                'pbId': item['id'],
                'fullName': item['fullName'] ?? '',
                'username': item['email'] ?? '',
                'role': item['role'] ?? 'buyer',
              },
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

  Future<void> _save(String id, String role) async {
    try {
      await context.read<Dio>().patch(
        '/collections/users/records/$id',
        data: {'role': role},
      );
      await _load();
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _error = '${mapDioError(error)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
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
            'Этот экран есть только у администратора: смена ролей других учётных записей.',
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
              title: Text('${item['fullName']}'),
              subtitle: Text('${item['username']}'),
              trailing: DropdownButton<String>(
                value: '${item['role']}',
                items: [
                  for (final role in AppRole.values)
                    DropdownMenuItem(
                      value: role.name,
                      child: Text(roleTitle(role)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null && value != item['role']) {
                    _save('${item['pbId']}', value);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
