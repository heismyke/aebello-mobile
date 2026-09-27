import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'esim_screen.dart';

/// Shown after checkout. Polls until the order is delivered, and checks again
/// whenever the customer comes back from the payment page.
class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with WidgetsBindingObserver {
  Order? _order;
  List<Esim> _esims = [];
  String? _error;
  Timer? _timer;
  int _polls = 0;

  static const _steps = ['Payment confirmed', 'Preparing your eSIM', 'Ready to install'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _polls = 0;
      _poll();
    }
  }

  Future<void> _poll() async {
    _timer?.cancel();
    try {
      final (order, esims) = await context.read<ApiClient>().order(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _esims = esims;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
    final settled = _order?.status == 'completed' || _order?.status == 'failed';
    // Every 3s for 3 minutes; returning to the app starts another round.
    if (!settled && _polls++ < 60 && mounted) _timer = Timer(const Duration(seconds: 3), _poll);
  }

  int get _step => switch (_order?.status) {
    'paid' || 'processing' => 1,
    'completed' => 3,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      appBar: AppBar(title: const Text('Your order')),
      body: order == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: ErrorPanel(message: _error!, onRetry: _poll),
                    ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order from ${date(order.createdAt)}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ),
                          StatusBadge(order.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(order.planName, style: display(26)),
                      Text(money(order.amount, order.currency), style: display(18, color: AppColors.body)),
                      const SizedBox(height: 24),
                      if (order.status == 'failed')
                        ErrorPanel(
                          message:
                              'Something went wrong preparing this eSIM. Your payment is safe. Contact Aebello '
                              'support with order number ${order.id.substring(0, 8)} and we will deliver it or refund you.',
                        )
                      else
                        for (final (i, label) in _steps.indexed) _stepRow(i, label, order),
                      if (order.status == 'pending') ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Finish paying in your browser, then come back here. We check automatically.',
                          style: TextStyle(color: AppColors.body, fontSize: 13),
                        ),
                      ],
                      if (_esims.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pushReplacement(MaterialPageRoute(builder: (_) => EsimScreen(esimId: _esims.first.id))),
                            child: const Text('Install your eSIM'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _stepRow(int i, String label, Order order) {
    final done = i < _step;
    final current = i == _step;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: done ? Colors.black : (current ? AppColors.tangerine : AppColors.surface),
            child: done
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: current ? Colors.black : AppColors.muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: label,
                style: TextStyle(
                  fontWeight: done || current ? FontWeight.w800 : FontWeight.w400,
                  color: done || current ? AppColors.ink : AppColors.muted,
                ),
                children: [
                  if (current)
                    TextSpan(
                      text: order.status == 'pending' ? '  Waiting for your bank…' : '  Usually under a minute…',
                      style: const TextStyle(fontWeight: FontWeight.w400, color: AppColors.muted, fontSize: 13),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
