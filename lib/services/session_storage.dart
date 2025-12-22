import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {

  static const String _keyUsername = 'username';
  static const String _keyIsLoggedIn = 'isLoggedIn';

  static void _log(String msg) {

    print('[SessionStorage] $msg');
  }

  const SessionStorage();

  Future<bool> setLoginState({
    required String username,
    required bool isLoggedIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final okUser = await prefs.setString(_keyUsername, username);
    if (!okUser) return false;

    final okLogin = await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
    if (!okLogin) {

      await prefs.remove(_keyUsername);
      return false;
    }
    return true;
  }

  Future<bool> clearSession() async {
    _log('clearSession: start');
    final sw = Stopwatch()..start();

    final prefs = await SharedPreferences.getInstance();
    _log(
      'clearSession: got SharedPreferences instance in ${sw.elapsedMilliseconds}ms',
    );

    try {

      _log('clearSession: removing username and setting isLoggedIn=false');
      final results = await Future.wait<bool>([
        prefs.remove(_keyUsername),
        prefs.setBool(_keyIsLoggedIn, false),
      ], eagerError: true);

      final okUser = results[0];
      final okLogin = results[1];
      _log(
        'clearSession: results okUser=$okUser, okLogin=$okLogin after ${sw.elapsedMilliseconds}ms',
      );

      if (!okUser || !okLogin) {
        _log('clearSession: convergence attempt');
        await Future.wait([
          prefs.setBool(_keyIsLoggedIn, false),
          prefs.remove(_keyUsername),
        ]);
      }

      final stillHasUser = prefs.getString(_keyUsername) != null;
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      final success = !stillHasUser && !isLoggedIn;
      _log(
        'clearSession: verify stillHasUser=$stillHasUser, isLoggedIn=$isLoggedIn, success=$success, total ${sw.elapsedMilliseconds}ms',
      );
      return success;
    } catch (e, st) {
      _log('clearSession: ERROR $e\n$st');
      return false;
    } finally {
      sw.stop();
      _log('clearSession: end total ${sw.elapsedMilliseconds}ms');
    }
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_keyUsername);
    debugPrint('[SessionStorage] getUsername: $username');
    return username;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }
}