import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exceptions.dart';
import 'access_policy.dart';
import 'app_user.dart';

const inactivityLimit = Duration(minutes: 3);
const inactivityWarning = Duration(seconds: 30);
const sessionLimit = Duration(minutes: 10);

enum SessionEnd { inactive, absolute, refresh }

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._prefs);

  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kProfile = 'auth_profile';
  static const _kStarted = 'auth_session_started';
  static const _kActivity = 'auth_last_activity';

  final SharedPreferences _prefs;
  Dio? _dio;
  AppUser? _user;
  String? _accessToken;
  String? _refreshToken;
  int? _sessionStartedMs;
  int? _lastActivityMs;
  SessionEnd? signedOutReason;
  Future<bool>? _refreshing;
  Timer? _absolute;

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null;
  AppRole? get role => _user?.role;

  bool allows(AppAction action) {
    final current = _user?.role;
    if (current == null) return false;
    return allowsAction(current, action);
  }

  String? get signedOutMessage {
    return switch (signedOutReason) {
      SessionEnd.inactive => 'Сессия завершена: 3 минуты не было действий.',
      SessionEnd.absolute =>
        'Сессия завершена: превышено общее время работы (10 минут).',
      SessionEnd.refresh => 'Сессия завершена: не удалось обновить вход.',
      null => null,
    };
  }

  void bind(Dio dio) {
    _dio = dio;
  }

  Future<void> restore() async {
    final access = _prefs.getString(_kAccess);
    final profile = AppUser.decode(_prefs.getString(_kProfile));
    final started = _prefs.getInt(_kStarted);
    if (access == null || profile == null || started == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - started >= sessionLimit.inMilliseconds) {
      await logout(reason: SessionEnd.absolute, remote: true);
      return;
    }
    final activity = _prefs.getInt(_kActivity);
    if (activity != null && now - activity >= inactivityLimit.inMilliseconds) {
      await logout(reason: SessionEnd.inactive, remote: true);
      return;
    }
    _accessToken = access;
    _refreshToken = _prefs.getString(_kRefresh);
    _user = profile;
    _sessionStartedMs = started;
    _lastActivityMs = activity ?? now;
    try {
      await _dio!.post('/collections/users/auth-refresh');
    } on DioException catch (error) {
      final mapped = mapDioError(error);
      if (mapped is UnauthorizedException) {
        final ok = await refreshTokens();
        if (!ok) {
          await logout(reason: SessionEnd.refresh, remote: false);
          return;
        }
      }
    }
    _armAbsolute();
    notifyListeners();
  }

  Future<void> login(String username, String password) {
    return _open(
      () => _dio!.post(
        '/collections/users/auth-with-password',
        data: {'identity': username.trim(), 'password': password},
      ),
    );
  }

  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) async {
    await guard(
      () => _dio!.post(
        '/collections/users/records',
        data: {
          'username': username.trim(),
          'password': password,
          'passwordConfirm': password,
          'email': email.trim(),
          'fullName': fullName.trim(),
          'role': 'buyer',
        },
      ),
    );
    await login(email, password);
  }

  Future<bool> refreshTokens() {
    final running = _refreshing;
    if (running != null) return running;
    final run = _refresh();
    _refreshing = run;
    return run.whenComplete(() {
      if (identical(_refreshing, run)) _refreshing = null;
    });
  }

  void markActivity() {
    if (_user == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastActivityMs = now;
    _prefs.setInt(_kActivity, now);
  }

  int? get lastActivityMs => _lastActivityMs;

  Duration get inactivityLeft {
    final last = _lastActivityMs;
    if (last == null) return inactivityLimit;
    final left =
        inactivityLimit -
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(last));
    if (left.isNegative) return Duration.zero;
    return left;
  }

  Future<void> logout({SessionEnd? reason, bool remote = true}) async {
    _absolute?.cancel();
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _sessionStartedMs = null;
    _lastActivityMs = null;
    signedOutReason = reason;
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kProfile);
    await _prefs.remove(_kStarted);
    await _prefs.remove(_kActivity);
    notifyListeners();
  }

  ({String accessToken, String? refreshToken, Map<String, dynamic> user})?
  _sessionFrom(dynamic data) {
    if (data is! Map) return null;
    if (data['token'] is String && data['record'] is Map) {
      final record = Map<String, dynamic>.from(data['record'] as Map);
      final code = record['code'];
      return (
        accessToken: data['token'] as String,
        refreshToken: data['token'] as String,
        user: {
          'id': code is num ? code.toInt() : 0,
          'pbId': '${record['id'] ?? ''}',
          'username': '${record['email'] ?? record['username'] ?? ''}',
          'fullName': '${record['fullName'] ?? ''}',
          'email': '${record['email'] ?? ''}',
          'role': record['role'],
        },
      );
    }
    if (data['accessToken'] is String && data['user'] is Map) {
      return (
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String?,
        user: Map<String, dynamic>.from(data['user'] as Map),
      );
    }
    return null;
  }

  Future<void> _open(Future<Response<dynamic>> Function() request) async {
    final response = await guard(request);
    await _accept(response.data);
  }

  Future<void> _accept(dynamic data) async {
    final session = _sessionFrom(data);
    if (session == null) {
      throw const ServerException('Сервер не выдал токен доступа.');
    }
    final user = AppUser.fromJson(session.user);
    if (user == null) throw const ServerException('Сервер не сообщил роль.');
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    _user = user;
    final now = DateTime.now().millisecondsSinceEpoch;
    _sessionStartedMs = now;
    _lastActivityMs = now;
    signedOutReason = null;
    await _prefs.setString(_kAccess, _accessToken!);
    if (_refreshToken != null) {
      await _prefs.setString(_kRefresh, _refreshToken!);
    }
    await _prefs.setString(_kProfile, jsonEncode(user.toJson()));
    await _prefs.setInt(_kStarted, now);
    await _prefs.setInt(_kActivity, now);
    _armAbsolute();
    notifyListeners();
  }

  Future<bool> _refresh() async {
    final refresh = _refreshToken ?? _prefs.getString(_kRefresh);
    if (refresh == null || refresh.isEmpty || _dio == null) return false;
    try {
      final response = await guard(
        () => _dio!.post('/collections/users/auth-refresh'),
      );
      final session = _sessionFrom(response.data);
      if (session == null) return false;
      _accessToken = session.accessToken;
      _refreshToken = session.refreshToken;
      await _prefs.setString(_kAccess, _accessToken!);
      if (_refreshToken != null) {
        await _prefs.setString(_kRefresh, _refreshToken!);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _absolute?.cancel();
    super.dispose();
  }

  void _armAbsolute() {
    _absolute?.cancel();
    final started = _sessionStartedMs;
    if (started == null || _user == null) return;
    final left =
        sessionLimit -
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(started));
    if (left <= Duration.zero) {
      logout(reason: SessionEnd.absolute);
      return;
    }
    _absolute = Timer(left, () => logout(reason: SessionEnd.absolute));
  }
}
