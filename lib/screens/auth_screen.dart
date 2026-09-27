import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../state/session.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Sign in or create an account. Pops with true once signed in.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.signUp = false});
  final bool signUp;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _signUp = widget.signUp;
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = context.read<Session>();
    try {
      if (_signUp) {
        await session.signUp(_name.text.trim(), _email.text.trim(), _password.text);
      } else {
        await session.signIn(_email.text.trim(), _password.text);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Logo()),
    body: SafeArea(
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(_signUp ? 'Create your account' : 'Welcome back', style: display(30)),
            const SizedBox(height: 8),
            Text(
              _signUp
                  ? 'Your eSIMs and QR codes live here, ready for your trip.'
                  : 'Sign in to see your eSIMs and orders.',
              style: const TextStyle(color: AppColors.body, fontSize: 15),
            ),
            const SizedBox(height: 28),
            if (_signUp) ...[
              _label('Name'),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your name.' : null,
              ),
              const SizedBox(height: 16),
            ],
            _label('Email'),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (v) => (v ?? '').contains('@') ? null : 'Enter a valid email address.',
            ),
            const SizedBox(height: 16),
            _label('Password'),
            TextFormField(
              controller: _password,
              obscureText: true,
              autofillHints: [_signUp ? AutofillHints.newPassword : AutofillHints.password],
              validator: (v) => _signUp && (v ?? '').length < 8
                  ? 'Use at least 8 characters.'
                  : ((v ?? '').isEmpty ? 'Enter your password.' : null),
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[const SizedBox(height: 16), ErrorPanel(message: _error!)],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Please wait…' : (_signUp ? 'Create account' : 'Sign in')),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _signUp = !_signUp;
                _error = null;
              }),
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              child: Text(_signUp ? 'Already have an account? Sign in' : 'New to Aebello? Create an account'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
  );
}
