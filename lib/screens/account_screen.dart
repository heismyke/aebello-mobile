import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final user = session.user;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Account', style: display(32)),
          const SizedBox(height: 20),
          if (user == null)
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Not signed in', style: display(20)),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to buy eSIMs and keep your QR codes in one place.',
                    style: TextStyle(color: AppColors.body),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const AuthScreen(), fullscreenDialog: true)),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            )
          else ...[
            Panel(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.black,
                    child: Text(user.name.characters.first.toUpperCase(), style: display(22, color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: display(18)),
                        Text(user.email, style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.read<Session>().signOut(),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign out'),
            ),
          ],
          const SizedBox(height: 32),
          const Panel(
            color: AppColors.tile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good to know', style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 8),
                Text(
                  'Aebello eSIMs are data only, so your usual number keeps working for WhatsApp and calls. '
                  'Your phone must support eSIM and not be locked to one carrier.',
                  style: TextStyle(color: AppColors.body, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Center(child: LogoMark(size: 28)),
        ],
      ),
    );
  }
}
