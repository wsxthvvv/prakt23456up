import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuerySync<Q> extends StatefulWidget {
  const QuerySync({
    super.key,
    required this.parse,
    required this.current,
    required this.equals,
    required this.apply,
    required this.child,
  });

  final Q Function(Map<String, String> params) parse;
  final Q Function(BuildContext context) current;
  final bool Function(Q a, Q b) equals;
  final void Function(BuildContext context, Q query) apply;
  final Widget child;

  @override
  State<QuerySync<Q>> createState() => _QuerySyncState<Q>();
}

class _QuerySyncState<Q> extends State<QuerySync<Q>> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parsed = widget.parse(GoRouterState.of(context).uri.queryParameters);
    final current = widget.current(context);
    if (!widget.equals(parsed, current)) {
      widget.apply(context, parsed);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
