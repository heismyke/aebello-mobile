import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/models.dart';
import '../format.dart';
import '../theme.dart';

/// The Orbit "a" mark (see src/components/AppLogo.vue on the web).
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 24, this.color = Colors.black});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size * 80 / 103, size), painter: _MarkPainter(color));
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color, {this.letter = false});
  final Color color;

  /// Crops to the letter itself (viewBox "19.5 6 70.5 94.5"): the bottom edge
  /// is the baseline, for use inside the wordmark.
  final bool letter;

  @override
  void paint(Canvas canvas, Size size) {
    // Same geometry as the SVG, whose viewBox is "15 2 80 103".
    final s = size.height / (letter ? 94.5 : 103);
    canvas.translate((letter ? -19.5 : -15) * s, (letter ? -6 : -2) * s);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(54 * s, 66 * s), 28 * s, stroke);
    canvas.drawLine(Offset(82 * s, 38 * s), Offset(82 * s, 94 * s), stroke);
    canvas.drawCircle(Offset(82 * s, 14 * s), 8 * s, Paint()..color = AppColors.tangerine);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color || old.letter != letter;
}

/// The wordmark: the Orbit mark stands in for the "a" of aebello.
class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 22, this.color = Colors.black});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Sized so the bowl matches the x-height of "ebello", as on the website.
    final h = size * 0.72;
    return Semantics(
      label: 'Aebello',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.aboveBaseline,
              baseline: TextBaseline.alphabetic,
              child: Padding(
                padding: EdgeInsets.only(right: size * 0.03),
                child: CustomPaint(size: Size(h * 70.5 / 94.5, h), painter: _MarkPainter(color, letter: true)),
              ),
            ),
            const TextSpan(text: 'ebello'),
          ],
        ),
        style: display(size, color: color, weight: FontWeight.w700).copyWith(height: 1),
      ),
    );
  }
}

class Flag extends StatelessWidget {
  const Flag(this.code, {super.key, this.size = 36});
  final String code;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.surface,
      border: Border.all(color: Colors.black12),
      image: code.isEmpty ? null : DecorationImage(image: NetworkImage(flagUrl(code)), fit: BoxFit.cover),
    ),
  );
}

/// eSIM and order statuses, same labels and colours as the website.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;

  static const _styles = {
    'ready': ('Ready to install', AppColors.tangerineSoft, AppColors.tangerineInk),
    'installed': ('Installed', AppColors.goSoft, AppColors.go),
    'active': ('Active', AppColors.goSoft, AppColors.go),
    'depleted': ('Data used up', AppColors.tile, AppColors.subtle),
    'expired': ('Expired', AppColors.tile, AppColors.subtle),
    'deleted': ('Removed', AppColors.tile, AppColors.subtle),
    'cancelled': ('Cancelled', AppColors.tile, AppColors.subtle),
    'revoked': ('Revoked', AppColors.tile, AppColors.subtle),
    'suspended': ('Suspended', AppColors.stopSoft, AppColors.stop),
    'pending': ('Awaiting payment', AppColors.tile, AppColors.subtle),
    'paid': ('Paid', AppColors.tangerineSoft, AppColors.tangerineInk),
    'processing': ('Preparing eSIM', AppColors.tangerineSoft, AppColors.tangerineInk),
    'completed': ('Delivered', AppColors.goSoft, AppColors.go),
    'failed': ('Needs attention', AppColors.stopSoft, AppColors.stop),
  };

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _styles[status] ?? (status, AppColors.tile, AppColors.subtle);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class UsageBar extends StatelessWidget {
  const UsageBar({super.key, required this.used, required this.total});
  final int used;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : (used / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${bytes((total - used).clamp(0, total))} left',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const Spacer(),
            Text(
              '${bytes(used)} of ${bytes(total)} used',
              style: const TextStyle(color: AppColors.subtle, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: AppColors.surface,
            color: Colors.black,
            semanticsLabel: 'Data used',
          ),
        ),
      ],
    );
  }
}

/// Pill-shaped segmented tabs used across the apps.
class PillTabs<T> extends StatelessWidget {
  const PillTabs({super.key, required this.value, required this.options, required this.onChanged});
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (id, label) in options)
          Semantics(
            selected: id == value,
            button: true,
            child: GestureDetector(
              onTap: () => onChanged(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: id == value ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: id == value ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.stopSoft, borderRadius: BorderRadius.circular(16)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: AppColors.stop)),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ],
    ),
  );
}

/// A rounded white card with a hairline border.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.color = Colors.white});
  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: color == Colors.white ? Border.all(color: AppColors.line) : null,
    ),
    child: child,
  );
}

String networksLabel(List<Network> networks) =>
    networks.isEmpty ? 'Local networks' : networks.map((n) => '${n.name} ${n.type}').join(', ');
