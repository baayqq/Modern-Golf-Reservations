import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../main.dart' show MyAppStateBridge;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Listener agar tombol Login enable/disable dinamis saat user mengetik
    _usernameCtrl.addListener(() => setState(() {}));
    _passwordCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    // Login dummy: terima username/password apa saja
    if (_loading) return;
    setState(() => _loading = true);
    debugPrint('[LOGIN] Button pressed');

    try {
      // Validasi sederhana
      final username = _usernameCtrl.text.trim();
      final password = _passwordCtrl.text;
      debugPrint(
        '[LOGIN] Input username="$username" len(password)=${password.length}',
      );

      if (username.isEmpty || password.isEmpty) {
        debugPrint('[LOGIN] Validation failed: empty field');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Username/Password tidak boleh kosong'),
            ),
          );
        }
        return;
      }

      // Simulasi minimal kerja async
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Simpan status login dan username ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', username);
      debugPrint(
        '[LOGIN] SharedPreferences saved: isLoggedIn=true, username="$username"',
      );

      // Beritahu aplikasi bahwa status login berubah (untuk GoRouter refresh)
      // Update ValueNotifier statis milik MyApp agar GoRouter refresh redirect
      MyAppStateBridge.isLoggedInNotifier.value = true;

      if (!mounted) return;
      // Tampilkan snackbar sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login berhasil'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Pastikan MaterialApp.router rebuild dengan status login terbaru,
      // lalu gunakan rootNavigator untuk navigasi agar tidak bentrok context.
      // Navigasi setelah frame berikutnya (setelah notifier di-update)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final rootCtx = rootNavigatorKey.currentContext ?? context;
        debugPrint(
          '[LOGIN] Navigating to dashboard using root navigator '
          '(rootCtx=${rootNavigatorKey.currentContext != null}, '
          'mounted=$mounted)',
        );
        try {
          rootCtx.goNamed(AppRoute.dashboard.name);
          debugPrint('[LOGIN] rootCtx.goNamed(AppRoute.dashboard) invoked');
        } catch (e, st) {
          debugPrint('[LOGIN][NAV ERROR] goNamed failed: $e\n$st');
        }
      });
    } catch (e, st) {
      debugPrint('[LOGIN][ERROR] $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login gagal, coba lagi')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF1F5F9); // light grey-blue like screenshot
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emblem/logo placeholder
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Column(
                      children: [
                        // Gunakan ikon 192x192 agar tajam di UI
                        Image.network(
                          '/icons/Icon-192.png',
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback jika ikon belum tersedia
                            return Icon(
                              Icons.flag,
                              size: 80,
                              color: Colors.green.shade700,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Modern Golf Reservation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Username
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Username',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(hintText: 'Username'),
                  ),
                  const SizedBox(height: 16),
                  // Password
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Password',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed:
                          (_loading ||
                              _usernameCtrl.text.trim().isEmpty ||
                              _passwordCtrl.text.isEmpty)
                          ? null
                          : _onLogin,
                      // Gunakan ElevatedButtonTheme default (primary hijau & radius 8)
                       child: _loading
                           ? const SizedBox(
                               width: 18,
                               height: 18,
                               child: CircularProgressIndicator(
                                 valueColor: AlwaysStoppedAnimation(
                                   Colors.white,
                                 ),
                                 strokeWidth: 2,
                               ),
                             )
                           : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
