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

    if (_loading) return;
    setState(() => _loading = true);
    debugPrint('[LOGIN] Button pressed');

    try {

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

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', username);
      debugPrint(
        '[LOGIN] SharedPreferences saved: isLoggedIn=true, username="$username"',
      );

      MyAppStateBridge.isLoggedInNotifier.value = true;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login berhasil'),
          behavior: SnackBarBehavior.floating,
        ),
      );

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
    final bg = const Color(0xFFF1F5F9);
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

                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Column(
                      children: [

                        Image.network(
                          '/icons/Icon-192.png',
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {

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
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(hintText: 'Username'),
                    onSubmitted: (_) {

                      if (_loading) return;
                      _onLogin();
                    },
                  ),
                  const SizedBox(height: 16),

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
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    onSubmitted: (_) {

                      final uOk = _usernameCtrl.text.trim().isNotEmpty;
                      final pOk = _passwordCtrl.text.isNotEmpty;
                      if (_loading) return;
                      if (uOk && pOk) {
                        _onLogin();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Username/Password tidak boleh kosong'),
                          ),
                        );
                      }
                    },
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