import 'package:flutter/material.dart';
import '../../services/subscription_service.dart';
import 'subscription_screen.dart';

class SubscriptionGate extends StatefulWidget {
  final Widget child;
  const SubscriptionGate({super.key, required this.child});

  @override
  State<SubscriptionGate> createState() => _SubscriptionGateState();
}

class _SubscriptionGateState extends State<SubscriptionGate> {
  SubscriptionState? _state;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final state = await SubscriptionService.getState();
      if (mounted) setState(() => _state = state);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final state = _state;
    if (state == null || !state.canUsePaidFeatures) {
      return SubscriptionScreen(onActivated: _refresh);
    }
    return widget.child;
  }
}
