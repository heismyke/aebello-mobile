import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../format.dart';
import '../state/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';
import 'order_screen.dart';

/// Plans for one country, and the start of checkout.
class DestinationScreen extends StatefulWidget {
  const DestinationScreen({super.key, required this.destination});
  final Destination destination;

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  late Future<(Destination, List<Plan>)> _load;
  bool _countryOnly = true;
  String? _buying;

  Destination get d => widget.destination;

  @override
  void initState() {
    super.initState();
    _load = context.read<ApiClient>().destination(d.code);
  }

  Future<void> _buy(Plan plan) async {
    final session = context.read<Session>();
    if (!session.signedIn) {
      final ok = await Navigator.of(context)
          .push<bool>(MaterialPageRoute(builder: (_) => const AuthScreen(signUp: true), fullscreenDialog: true));
      if (ok != true || !mounted) return;
    }
    setState(() => _buying = plan.slug);
    try {
      final (order, paymentUrl) = await context.read<ApiClient>().createOrder(plan.slug, d.code);
      // Pay in the browser; the order screen notices when the payment lands.
      await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderScreen(orderId: order.id)));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _buying = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${d.name} eSIM')),
    body: FutureBuilder(
      future: _load,
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: ErrorPanel(
              message: '${snap.error}',
              onRetry: () => setState(() => _load = context.read<ApiClient>().destination(d.code)),
            ),
          );
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
        final (dest, plans) = snap.data!;
        final countryPlans = plans.where((p) => p.isCountry).toList();
        final widerPlans = plans.where((p) => !p.isCountry).toList();
        final showCountry = _countryOnly && countryPlans.isNotEmpty;
        final shown = showCountry ? countryPlans : widerPlans;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Row(
              children: [
                Flag(d.code, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'From ${money(dest.fromPrice)} · Works on ${dest.networks.map((n) => n.name).join(', ')}',
                    style: const TextStyle(color: AppColors.body, fontSize: 15, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (countryPlans.isNotEmpty && widerPlans.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: PillTabs<bool>(
                  value: showCountry,
                  options: [(true, '${d.name} only'), (false, 'Multi-country')],
                  onChanged: (v) => setState(() => _countryOnly = v),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (!showCountry)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'One eSIM for several countries. Handy if your trip crosses borders, and sometimes on a different local network.',
                  style: TextStyle(color: AppColors.body, fontSize: 14, height: 1.5),
                ),
              ),
            for (final plan in shown) ...[
              PlanCard(plan: plan, busy: _buying == plan.slug, onBuy: _buying == null ? () => _buy(plan) : null),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            Panel(
              color: Colors.black,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (title, text) in [
                    ('Data only', 'Keep your usual number for WhatsApp and calls; the eSIM handles data.'),
                    ('Install before you fly', 'The plan only starts when you connect in ${d.name}.'),
                    ('Unlocked phone needed', 'Works on eSIM-ready phones not locked to one carrier.'),
                  ]) ...[
                    Text(title, style: display(18, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(text, style: const TextStyle(color: AppColors.vibrant, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan, required this.busy, required this.onBuy});
  final Plan plan;
  final bool busy;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.data, style: display(32)),
                  Text('for ${days(plan.days)}', style: const TextStyle(color: AppColors.muted, fontSize: 15)),
                ],
              ),
            ),
            if (!plan.isCountry)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.tile, borderRadius: BorderRadius.circular(99)),
                child: Text(
                  '${plan.region} · ${plan.countryCount} countries',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.subtle),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _line(Icons.signal_cellular_alt, networksLabel(plan.networks)),
        const SizedBox(height: 6),
        _line(Icons.schedule, 'Starts when you connect abroad'),
        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(money(plan.price), style: display(24)),
                if (plan.charge case (final amount, final currency))
                  Text(
                    '≈ ${money(amount, currency)} at checkout',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
              ],
            ),
            const Spacer(),
            FilledButton(
              onPressed: onBuy,
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Buy now', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _line(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: AppColors.muted),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, style: const TextStyle(color: AppColors.body, fontSize: 14)),
      ),
    ],
  );
}
