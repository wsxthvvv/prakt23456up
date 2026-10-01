import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/product_list_notifier.dart';
import 'query_codec.dart';
import 'query_equality.dart';

class ProductQuerySync extends StatefulWidget {
  const ProductQuerySync({super.key, required this.child});

  final Widget child;

  @override
  State<ProductQuerySync> createState() => _ProductQuerySyncState();
}

class _ProductQuerySyncState extends State<ProductQuerySync> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parsed = productQueryFromUri(GoRouterState.of(context).uri.queryParameters);
    final notifier = context.read<ProductListNotifier>();
    if (!productQueriesEqual(parsed, notifier.query)) {
      notifier.applyQuery(parsed);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
