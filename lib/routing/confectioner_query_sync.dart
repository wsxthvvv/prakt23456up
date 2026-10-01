import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/confectioner_list_notifier.dart';
import 'query_codec.dart';
import 'query_equality.dart';

class ConfectionerQuerySync extends StatefulWidget {
  const ConfectionerQuerySync({super.key, required this.child});

  final Widget child;

  @override
  State<ConfectionerQuerySync> createState() => _ConfectionerQuerySyncState();
}

class _ConfectionerQuerySyncState extends State<ConfectionerQuerySync> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parsed = confectionerQueryFromUri(GoRouterState.of(context).uri.queryParameters);
    final notifier = context.read<ConfectionerListNotifier>();
    if (!confectionerQueriesEqual(parsed, notifier.query)) {
      notifier.applyQuery(parsed);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
