import 'package:flutter/material.dart';
import '../../services/session_storage.dart';
import '../../router.dart' show AppRoute, rootNavigatorKey;
import '../../main.dart' show MyAppStateBridge;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Halaman profil pengguna yang menampilkan informasi username
/// dan menyediakan tombol untuk logout
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _username;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      debugPrint('Username dari SharedPreferences langsung: $username');
      
      setState(() {
        _username = username;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading username: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Profile page UI similar to screenshot: title, username field, and Update Profile button.
    return Scaffold(
      // Hindari menu/leading default yang mungkin men-trigger rebuild saat navigasi.
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your Profile',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Username',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : TextFormField(
                          initialValue: _username ?? 'User',
                          decoration: const InputDecoration(hintText: 'Username'),
                          readOnly: true,
                        ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        FilledButton(
                          onPressed: () {},
                          child: const Text('Update Profile'),
                        ),
                        const SizedBox(width: 12),
                        // Tambah tombol Logout juga di Profile agar jelas dan aman
                        OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              // Tambah delay kecil untuk memastikan UI stabil
                              await Future.delayed(
                                const Duration(milliseconds: 50),
                              );

                              // Jangan akses context dulu sebelum operasi async selesai
                              final ok = await SessionStorage().clearSession();
                              if (!ok) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  final ctx = rootNavigatorKey.currentContext;
                                  if (ctx != null && ctx.mounted) {
                                    try {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Gagal logout. Coba lagi.',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      debugPrint('Error showing snackbar: $e');
                                    }
                                  }
                                });
                                return;
                              }
                              MyAppStateBridge.isLoggedInNotifier.value = false;
                              // Navigasi pada frame berikutnya menggunakan root context
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final rc = rootNavigatorKey.currentContext;
                                if (rc != null && rc.mounted) {
                                  try {
                                    GoRouter.of(
                                      rc,
                                    ).goNamed(AppRoute.login.name);
                                  } catch (e) {
                                    debugPrint('Error navigating to login: $e');
                                  }
                                }
                              });
                            } catch (e) {
                              debugPrint('Error during logout: $e');
                            }
                          },
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Logout'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
