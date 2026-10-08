import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InactivityWatcher extends StatefulWidget {
  const InactivityWatcher({
    super.key,
    required this.enabled,
    required this.timeout,
    this.initialTimeout,
    required this.warning,
    required this.navigatorKey,
    required this.onActivity,
    required this.onTimeout,
    required this.child,
  });

  final bool enabled;
  final Duration timeout;
  final Duration? initialTimeout;
  final Duration warning;
  final GlobalKey<NavigatorState> navigatorKey;
  final VoidCallback onActivity;
  final VoidCallback onTimeout;
  final Widget child;

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _timer;
  Timer? _warningTimer;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    if (widget.enabled) _arm(widget.initialTimeout ?? widget.timeout);
  }

  @override
  void didUpdateWidget(InactivityWatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) _arm(widget.timeout);
    if (!widget.enabled && oldWidget.enabled) _stop();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _stop();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (widget.enabled) _arm(widget.timeout);
    return false;
  }

  void _stop() {
    _timer?.cancel();
    _warningTimer?.cancel();
    _closeDialog();
  }

  void _arm(Duration limit) {
    _timer?.cancel();
    _warningTimer?.cancel();
    _closeDialog();
    if (limit <= Duration.zero) {
      widget.onTimeout();
      return;
    }
    widget.onActivity();
    final warnAfter = limit - widget.warning;
    if (warnAfter > Duration.zero) {
      _warningTimer = Timer(warnAfter, _showWarning);
    } else {
      _showWarning();
    }
    _timer = Timer(limit, () {
      _closeDialog();
      widget.onTimeout();
    });
  }

  void _closeDialog() {
    if (!_dialogOpen) return;
    final nav = widget.navigatorKey.currentState;
    if (nav != null && nav.canPop()) nav.pop();
    _dialogOpen = false;
  }

  void _showWarning() {
    final ctx = widget.navigatorKey.currentContext;
    if (!mounted || !widget.enabled || ctx == null || _dialogOpen) return;
    _dialogOpen = true;
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Сессия скоро завершится'),
        content: const Text('Без действий выход произойдёт через 30 секунд.'),
        actions: [
          FilledButton(
            onPressed: () => _arm(widget.timeout),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    ).whenComplete(() => _dialogOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: widget.enabled ? (_) => _arm(widget.timeout) : null,
      onPointerMove: widget.enabled ? (_) => _arm(widget.timeout) : null,
      onPointerSignal: widget.enabled ? (_) => _arm(widget.timeout) : null,
      child: widget.child,
    );
  }
}
