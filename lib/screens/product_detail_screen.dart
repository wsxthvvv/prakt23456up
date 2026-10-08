import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/access_policy.dart';
import '../auth/auth_notifier.dart';
import '../models/product.dart';
import '../widgets/api_feedback.dart';
import '../repositories/confectioner_repository.dart';
import '../repositories/flavor_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/reference_repository.dart';
import '../repositories/workshop_repository.dart';
import '../routing/query_codec.dart';
import '../state/product_list_notifier.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Изделие #$productId'),
        leading: IconButton(
          tooltip: 'Назад',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<Product?>(
        future: context.read<ProductRepository>().findById(productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final product = snapshot.data;
          if (product == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Изделие не найдено'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.go('/products'),
                    child: const Text('К каталогу'),
                  ),
                ],
              ),
            );
          }

          final references = context.read<ReferenceRepository>();
          final confectioners = context.read<ConfectionerRepository>().all;
          final flavors = context.read<FlavorRepository>().all;
          final workshops = context.read<WorkshopRepository>().all;
          final confectionerNames = product.confectionerIds
              .map((id) {
                for (final confectioner in confectioners) {
                  if (confectioner.id == id) return confectioner.fullName;
                }
                return '?';
              })
              .join(', ');
          final flavorLabel = product.flavorTagIds
              .map((id) {
                for (final flavor in flavors) {
                  if (flavor.id == id) return flavor.name;
                }
                return '?';
              })
              .join(', ');
          var workshopLabel = '—';
          for (final workshop in workshops) {
            if (workshop.id == product.workshopId) {
              workshopLabel = workshop.name;
            }
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _row('Артикул', product.sku),
                  _row(
                    'Категория',
                    references.categoryName(product.categoryId),
                  ),
                  _row('Цех', workshopLabel),
                  _row('Вкусы', flavorLabel.isEmpty ? '—' : flavorLabel),
                  _row('Год в ассортименте', '${product.year}'),
                  _row('Масса', '${product.weightGrams} г'),
                  _row('Кондитеры', confectionerNames),
                  _row(
                    'Остаток',
                    '${product.stockAvailable} из ${product.stockTotal}',
                  ),
                  if (product.isDeleted)
                    _row('Статус', 'Удалено ${product.deletedAt}'),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (context.watch<AuthNotifier>().allows(
                        AppAction.manageCatalog,
                      ))
                        FilledButton(
                          onPressed: () =>
                              context.push('/products/${product.id}/edit'),
                          child: const Text('Изменить'),
                        ),
                      FilledButton(
                        onPressed: () => context.go('/products'),
                        child: const Text('К каталогу'),
                      ),
                      if (product.isDeleted &&
                          context.watch<AuthNotifier>().allows(
                            AppAction.restore,
                          ))
                        FilledButton.tonal(
                          onPressed: () => _restore(context, product.id),
                          child: const Text('Восстановить'),
                        )
                      else if (!product.isDeleted) ...[
                        if (context.watch<AuthNotifier>().allows(
                          AppAction.manageCatalog,
                        ))
                          FilledButton.tonal(
                            onPressed: () => _softDelete(context, product.id),
                            child: const Text('Скрыть (логически)'),
                          ),
                        if (context.watch<AuthNotifier>().allows(
                          AppAction.hardDelete,
                        ))
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .error,
                            ),
                            onPressed: () => _hardDelete(context, product.id),
                            child: const Text('Удалить навсегда'),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _softDelete(BuildContext context, int id) async {
    final notifier = context.read<ProductListNotifier>();
    await showFailure(context, () async {
      await notifier.softDeleteOne(id);
      if (context.mounted) context.go(productQueryToLocation(notifier.query));
    });
  }

  Future<void> _hardDelete(BuildContext context, int id) async {
    final notifier = context.read<ProductListNotifier>();
    await showFailure(context, () async {
      await notifier.hardDeleteOne(id);
      if (context.mounted) context.go('/products');
    });
  }

  Future<void> _restore(BuildContext context, int id) async {
    final notifier = context.read<ProductListNotifier>();
    await showFailure(context, () async {
      await notifier.restoreOne(id);
      if (context.mounted) context.go(productQueryToLocation(notifier.query));
    });
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
