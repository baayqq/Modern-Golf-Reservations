import 'package:shared_preferences/shared_preferences.dart';

/// Abstraction over SharedPreferences for session-related data.
/// Centralizes keys, adds minimal consistency handling, and keeps UI free from storage details.
class SessionStorage {
  static const String _keyUsername = 'username';
  static const String _keyIsLoggedIn = 'isLoggedIn';

  static void _log(String msg) {
    // Prefix agar mudah difilter di console
    // ignore: avoid_print
    print('[SessionStorage] $msg');
  }

  const SessionStorage();

  Future<bool> setLoginState({
    required String username,
    required bool isLoggedIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Write sequentially and keep state consistent on failure.
    final okUser = await prefs.setString(_keyUsername, username);
    if (!okUser) return false;

    final okLogin = await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
    if (!okLogin) {
      // Best-effort rollback so partial writes don't leave inconsistent state.
      await prefs.remove(_keyUsername);
      return false;
    }
    return true;
  }

  /// Clears session data and converges to a "logged-out" state.
  /// Returns true if the end state is logged-out and username removed.
  Future<bool> clearSession() async {
    _log('clearSession: start');
    final sw = Stopwatch()..start();

    final prefs = await SharedPreferences.getInstance();
    _log(
      'clearSession: got SharedPreferences instance in ${sw.elapsedMilliseconds}ms',
    );

    try {
      // Jalankan operasi utama
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

      // Verifikasi akhir
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
    return prefs.getString(_keyUsername);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }
}
