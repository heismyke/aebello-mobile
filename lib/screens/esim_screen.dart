import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// One eSIM: QR code, manual install codes, usage and install steps.
class EsimScreen extends StatefulWidget {
  const EsimScreen({super.key, required this.esimId});
  final String esimId;

  @override
  State<EsimScreen> createState() => _EsimScreenState();
}

class _EsimScreenState extends State<EsimScreen> {
  late Future<Esim> _load = context.read<ApiClient>().esim(widget.esimId);
  bool _iphone = true;

  static const _steps = {
    true: [
      'Open Settings and tap Cellular (or Mobile Data).',
      'Tap Add eSIM, then Use QR Code, and scan the code from another screen.',
      'Label the new line “Aebello”. Keep your usual line for calls and texts.',
      'When you land, set Aebello as your Cellular Data line and turn on Data Roaming for it.',
    ],
    false: [
      'Open Settings, then Network & internet (Connections on Samsung).',
      'Tap SIMs or SIM manager, then Add eSIM, and choose Scan QR code.',
      'Scan the code from another screen and confirm.',
      'When you land, select the Aebello eSIM for mobile data and turn on roaming for it.',
    ],
  };

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your eSIM')),
    body: FutureBuilder(
      future: _load,
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: ErrorPanel(
              message: '${snap.error}',
              onRetry: () => setState(() => _load = context.read<ApiClient>().esim(widget.esimId)),
            ),
          );
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
        final e = snap.data!;
        final codes = e.manualCodes;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Row(
              children: [
                Flag(e.countryCode, size: 40),
                const SizedBox(width: 12),
                Expanded(child: Text(e.planName, style: display(22))),
                StatusBadge(e.status),
              ],
            ),
            const SizedBox(height: 20),
            Panel(
              child: Column(
                children: [
                  Text('Scan to install', style: display(18)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    // Drawn from the activation code on the device, so it
                    // shows even offline (e.g. just after landing).
                    child: Semantics(
                      label: 'QR code to install this eSIM',
                      child: QrImageView(data: e.activationCode, size: 220, padding: EdgeInsets.zero),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Scan it from another screen with the phone you're travelling with. Each QR code works only once, so don't delete the eSIM after installing.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.body, fontSize: 13, height: 1.5),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Installing on this phone? Enter it manually",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _code('SM-DP+ address', codes.smdp),
                  const SizedBox(height: 10),
                  _code('Activation code', codes.matchingId),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UsageBar(used: e.usedBytes, total: e.totalBytes),
                  const SizedBox(height: 16),
                  _detail('Valid until', e.expiresAt == null ? 'Starts on first use' : date(e.expiresAt!)),
                  _detail('ICCID', e.iccid),
                  _detail('Usage updated', date(e.syncedAt)),
                  const SizedBox(height: 6),
                  const Text(
                    'Networks report usage every few hours, so recent data may not show yet.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Panel(
              color: Colors.black,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('How to install', style: display(18, color: Colors.white)),
                      ),
                      PillTabs<bool>(
                        value: _iphone,
                        options: const [(true, 'iPhone'), (false, 'Android')],
                        onChanged: (v) => setState(() => _iphone = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final (i, step) in _steps[_iphone]!.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: AppColors.tangerine,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              step,
                              style: const TextStyle(color: AppColors.vibrant, fontSize: 14, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _code(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.tile, borderRadius: BorderRadius.circular(10)),
              child: SelectableText(value, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: 'Copy $label',
            onPressed: () => _copy(label, value),
            icon: const Icon(Icons.copy, size: 18),
          ),
        ],
      ),
    ],
  );

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      ],
    ),
  );
}
