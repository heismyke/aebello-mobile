import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_client.dart';
import '../api/models.dart';

/// The signed-in user. The token lives in the platform keychain/keystore so
/// the app stays signed in between launches.
class Session extends ChangeNotifier {
  Session(this.api) {
    api.onUnauthorized = _forget;
  }

  final ApiClient api;
  static const _storage = FlutterSecureStorage();
  static const _key = 'aebello.session';

  User? user;
  bool get signedIn => user != null;

  /// Restores a saved session. Call once at start-up.
  Future<void> restore() async {
    try {
      final saved = await _storage.read(key: _key);
      if (saved == null) return;
      final j = jsonDecode(saved) as Map<String, dynamic>;
      api.token = j['token'] as String;
      user = User.fromJson(j['user'] as Map<String, dynamic>);
      notifyListeners();
    } catch (_) {
      // Unreadable storage: start signed out.
    }
  }

  Future<void> signIn(String email, String password) async => _save(await api.signIn(email, password));

  Future<void> signUp(String name, String email, String password) async =>
      _save(await api.signUp(name, email, password));

  Future<void> signOut() async {
    try {
      await api.signOut();
    } catch (_) {
      // Signing out locally is what matters.
    }
    await _forget();
  }

  Future<void> _save((String, User) result) async {
    final (token, u) = result;
    api.token = token;
    user = u;
    notifyListeners();
    await _storage.write(key: _key, value: jsonEncode({'token': token, 'user': u.toJson()}));
  }

  Future<void> _forget() async {
    api.token = null;
    user = null;
    notifyListeners();
    await _storage.delete(key: _key);
  }
}
