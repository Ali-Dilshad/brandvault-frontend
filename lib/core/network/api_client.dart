import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'endpoints.dart';
import '../errors/app_exceptions.dart';


class AppApiClient {
  static final bool useMock = const bool.fromEnvironment('USE_MOCK', defaultValue: true);
  static const _tokenKey = 'brandvault_token';
  static const _timeout = Duration(seconds: 60);

  static String? _token;

  static void Function()? onUnauthorized;

  static bool get hasToken => _token != null && _token!.isNotEmpty;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Map<String, String> _headers({bool authenticated = true}) => {
    'Content-Type': 'application/json',
    if (authenticated && hasToken) 'Authorization': 'Bearer $_token',
  };

  static Uri _uri(String path) => Uri.parse('${Endpoints.baseUrl}$path');

  static Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = _uri(path).replace(queryParameters: query);
    final res = await http.get(uri, headers: _headers()).timeout(_timeout);
    return _decode(res);
  }

  static Future<dynamic> post(
      String path, {
        Map<String, dynamic>? body,
        bool authenticated = true,
      }) async {
    final res = await http
        .post(
      _uri(path),
      headers: _headers(authenticated: authenticated),
      body: body != null ? jsonEncode(body) : null,
    )
        .timeout(_timeout);
    return _decode(res, authenticated: authenticated);
  }

  static Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final res = await http
        .patch(
      _uri(path),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    )
        .timeout(_timeout);
    return _decode(res);
  }

  static Future<void> delete(String path) async {
    final res = await http.delete(_uri(path), headers: _headers()).timeout(_timeout);
    _decode(res);
  }

  static dynamic _decode(http.Response res, {bool authenticated = true}) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }

    if (res.statusCode == 401 && authenticated) {
      unawaited(clearToken());
      onUnauthorized?.call();
    }

    String? serverMessage;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) {
        final msg = decoded['error'] ?? decoded['message'];
        if (msg is String) serverMessage = msg;
      }
    } catch (_) {
    }
    throw AppException.fromStatusCode(res.statusCode, serverMessage: serverMessage);
  }
}