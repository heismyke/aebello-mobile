import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'models.dart';

/// An error the backend reported, with a message fit to show the user.
class ApiException implements Exception {
  const ApiException(this.status, this.code, this.message);
  final int status;
  final String code;
  final String message;

  @override
  String toString() => message;
}

/// Talks to the Go backend. One instance lives in the app (see main.dart).
class ApiClient {
  ApiClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  /// Bearer token of the signed-in user; set by Session.
  String? token;

  /// Called when the backend says the session is no longer valid.
  void Function()? onUnauthorized;

  // Catalog

  Future<List<Destination>> destinations() async {
    final j = await _get('/v1/destinations');
    return [for (final d in j['destinations']) Destination.fromJson(d)];
  }

  Future<(Destination, List<Plan>)> destination(String code) async {
    final j = await _get('/v1/destinations/$code');
    return (Destination.fromJson(j['destination']), [for (final p in j['plans']) Plan.fromJson(p)]);
  }

  // Account

  Future<(String, User)> signIn(String email, String password) async {
    final j = await _post('/v1/auth/login', {'email': email, 'password': password});
    return (j['token'] as String, User.fromJson(j['user']));
  }

  Future<(String, User)> signUp(String name, String email, String password) async {
    final j = await _post('/v1/auth/register', {'name': name, 'email': email, 'password': password});
    return (j['token'] as String, User.fromJson(j['user']));
  }

  Future<void> signOut() => _post('/v1/auth/logout', {});

  // Orders and eSIMs

  /// Starts checkout; returns the order and the page where the customer pays.
  Future<(Order, String)> createOrder(String planSlug, String country) async {
    final j = await _post('/v1/orders', {'planSlug': planSlug, 'country': country});
    return (Order.fromJson(j['order']), j['paymentUrl'] as String);
  }

  Future<List<Order>> orders() async {
    final j = await _get('/v1/orders');
    return [for (final o in j['orders']) Order.fromJson(o)];
  }

  Future<(Order, List<Esim>)> order(String id) async {
    final j = await _get('/v1/orders/$id');
    return (Order.fromJson(j['order']), [for (final e in j['esims']) Esim.fromJson(e)]);
  }

  Future<List<Esim>> esims() async {
    final j = await _get('/v1/esims');
    return [for (final e in j['esims']) Esim.fromJson(e)];
  }

  Future<Esim> esim(String id) async => Esim.fromJson((await _get('/v1/esims/$id'))['esim']);

  // Plumbing

  Future<Map<String, dynamic>> _get(String path) => _send(() => _http.get(_uri(path), headers: _headers));

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) =>
      _send(() => _http.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  Uri _uri(String path) => Uri.parse('$apiBaseUrl$path');

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    final http.Response res;
    try {
      res = await request().timeout(const Duration(seconds: 30));
    } catch (_) {
      throw const ApiException(0, 'network_error', "We couldn't reach Aebello. Check your connection and try again.");
    }
    Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      body = {};
    }
    if (res.statusCode >= 400) {
      if (res.statusCode == 401 && token != null) onUnauthorized?.call();
      throw ApiException(
        res.statusCode,
        body['error'] as String? ?? 'error',
        body['message'] as String? ?? 'Something went wrong. Please try again.',
      );
    }
    return body;
  }
}
