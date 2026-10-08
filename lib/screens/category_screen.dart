import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/json_values.dart';
import '../core/pb_links.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<({int code, String name})> _items = const [];
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
        '/collections/categories/records',
        queryParameters: {
          'page': 1,
          'perPage': 50,
          'sort': 'name',
          'filter': 'deleted = false',
        },
      );
      final data = response.data;
      final rows = data is Map && data['items'] is List
          ? data['items'] as List
          : const [];
      if (!mounted) return;
      setState(() {
        _items = [
          for (final row in rows)
            if (row is Map)
              (code: jsonInt(row['code']), name: jsonString(row['name'])),
        ];
        for (final row in rows) {
          if (row is Map) {
            PbLinks.shared.remember(
              'categories',
              jsonInt(row['code']),
              jsonString(row['id']),
            );
          }
        }
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

  Future<void> _edit({int? code, String initial = ''}) async {
    final name = TextEditingController(text: initial);
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(code == null ? 'Новая категория' : 'Категория'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Название'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, name.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    name.dispose();
    if (saved == null || !mounted) return;
    if (saved.length < 2) {
      setState(() => _error = 'Название не короче 2 символов.');
      return;
    }
    try {
      final dio = context.read<Dio>();
      if (code == null) {
        await dio.post(
          '/collections/categories/records',
          data: {'name': saved},
        );
      } else {
        final pb = PbLinks.shared.pbId('categories', code);
        if (pb == null) throw const NotFoundException('Категория не найдена.');
        await dio.patch(
          '/collections/categories/records/$pb',
          data: {'name': saved},
        );
      }
      await _load();
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _error = '${mapDioError(error)}');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    }
  }

  Future<void> _hide(int code) async {
    final pb = PbLinks.shared.pbId('categories', code);
    if (pb == null) return;
    try {
      await context.read<Dio>().patch(
        '/collections/categories/records/$pb',
        data: {'deleted': true},
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
        title: const Text('Категории'),
        actions: [
          IconButton(
            tooltip: 'Новая категория',
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
          ),
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
            'Категория связана с изделиями: у изделия одна категория, в категории много изделий.',
          ),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (!_loading && _error == null && _items.isEmpty)
            const Text('Категорий пока нет.'),
          for (final item in _items)
            ListTile(
              title: Text(item.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Изменить',
                    onPressed: () => _edit(code: item.code, initial: item.name),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Скрыть',
                    onPressed: () => _hide(item.code),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
