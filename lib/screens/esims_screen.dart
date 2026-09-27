import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../format.dart';
import '../state/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';
import 'esim_screen.dart';
import 'order_screen.dart';

/// The dashboard: summary, eSIMs and orders.
class EsimsScreen extends StatefulWidget {
  const EsimsScreen({super.key, required this.visible});

  /// True while this tab is on screen; the data reloads each time it opens.
  final bool visible;

  @override
  State<EsimsScreen> createState() => _EsimsScreenState();
}

class _EsimsScreenState extends State<EsimsScreen> {
  Future<(List<Esim>, List<Order>)>? _load;
  bool _showOrders = false;

  @override
  void didUpdateWidget(EsimsScreen old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) _reload();
  }

  void _reload() {
    if (!context.read<Session>().signedIn) return;
    final api = context.read<ApiClient>();
    setState(() => _load = (api.esims(), api.orders()).wait);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    if (!session.signedIn) return _signedOut();
    if (_load == null) WidgetsBinding.instance.addPostFrameCallback((_) => _reload());

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: Colors.black,
        onRefresh: () async {
          _reload();
          await _load;
        },
        child: FutureBuilder(
          future: _load,
          builder: (context, snap) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(
                'My account',
                style: const TextStyle(color: AppColors.eyebrow, fontWeight: FontWeight.w600),
              ),
              Text('Hi, ${session.user!.firstName}', style: display(32)),
              const SizedBox(height: 20),
              if (snap.hasError)
                ErrorPanel(message: '${snap.error}', onRetry: _reload)
              else if (!snap.hasData)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator(color: Colors.black)),
                )
              else
                ..._content(snap.data!.$1, snap.data!.$2),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(List<Esim> esims, List<Order> orders) {
    final live = esims.where((e) => e.usable).toList();
    final left = live.fold<int>(0, (sum, e) => sum + e.leftBytes);
    final expiries = live.map((e) => e.expiresAt).whereType<DateTime>().toList()..sort();
    return [
      Row(
        children: [
          Expanded(child: _stat('Active eSIMs', '${live.length}', dark: true)),
          const SizedBox(width: 10),
          Expanded(child: _stat('Data left', bytes(left))),
        ],
      ),
      const SizedBox(height: 10),
      _stat('Next expiry', expiries.isEmpty ? 'None' : date(expiries.first)),
      for (final o in orders.where((o) => o.inProgress))
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Material(
            color: AppColors.tangerineSoft,
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                '${o.planName} is being prepared',
                style: const TextStyle(color: AppColors.tangerineInk, fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'This usually takes under a minute.',
                style: TextStyle(color: AppColors.tangerineInk),
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.tangerineInk),
              onTap: () => _open(OrderScreen(orderId: o.id)),
            ),
          ),
        ),
      const SizedBox(height: 20),
      Align(
        alignment: Alignment.centerLeft,
        child: PillTabs<bool>(
          value: _showOrders,
          options: const [(false, 'My eSIMs'), (true, 'Orders')],
          onChanged: (v) => setState(() => _showOrders = v),
        ),
      ),
      const SizedBox(height: 16),
      if (!_showOrders) ...[
        if (esims.isEmpty) _empty(),
        for (final e in esims) ...[_esimCard(e), const SizedBox(height: 12)],
      ] else if (orders.isEmpty)
        const Panel(color: AppColors.tile, child: Text('You have no orders yet.'))
      else
        Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, o) in orders.indexed) ...[
                if (i > 0) const Divider(),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(o.planName, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${date(o.createdAt)} · ${money(o.amount, o.currency)}'),
                  trailing: StatusBadge(o.status),
                  onTap: () => _open(OrderScreen(orderId: o.id)),
                ),
              ],
            ],
          ),
        ),
    ];
  }

  Widget _stat(String label, String value, {bool dark = false}) => Panel(
    color: dark ? Colors.black : Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: dark ? AppColors.vibrant : AppColors.muted, fontSize: 13)),
        const SizedBox(height: 6),
        Text(value, style: display(26, color: dark ? Colors.white : Colors.black)),
      ],
    ),
  );

  Widget _esimCard(Esim e) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.line),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _open(EsimScreen(esimId: e.id)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flag(e.countryCode, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(e.planName, style: display(18), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                StatusBadge(e.status),
              ],
            ),
            const SizedBox(height: 16),
            UsageBar(used: e.usedBytes, total: e.totalBytes),
            const SizedBox(height: 12),
            Text(
              e.status == 'ready'
                  ? 'Not installed yet. Tap to see your QR code.'
                  : e.expiresAt != null
                  ? 'Valid until ${date(e.expiresAt!)}'
                  : 'Bought ${date(e.createdAt)}',
              style: const TextStyle(color: AppColors.subtle, fontSize: 13),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _empty() => Panel(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    child: Column(
      children: [
        const LogoMark(size: 44, color: Color(0xFFD4D4D8)),
        const SizedBox(height: 16),
        Text('No eSIMs yet', style: display(22)),
        const SizedBox(height: 8),
        const Text(
          'Pick a destination in Explore and your eSIM will appear here with its QR code.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.body),
        ),
      ],
    ),
  );

  Widget _signedOut() => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LogoMark(size: 52),
          const SizedBox(height: 20),
          Text('Your eSIMs live here', style: display(26), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text(
            'Sign in to see your QR codes, data left and orders.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.body),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const AuthScreen(), fullscreenDialog: true)),
            child: const Text('Sign in'),
          ),
        ],
      ),
    ),
  );

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _reload();
  }
}
