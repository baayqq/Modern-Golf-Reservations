import 'package:flutter/material.dart';
import 'services/session_storage.dart' show SessionStorage;
import 'screens/dashboard_page.dart';
import 'screens/tee_time/booking_calendar_page.dart';
import 'screens/tee_time/manage_reservation_page.dart';
import 'screens/tee_time/create_tee_time_page.dart';
import 'screens/pos/pos_system_page.dart';
import 'screens/pos/invoice_page.dart';
import 'screens/login_page.dart';
import 'package:go_router/go_router.dart';
import 'router.dart';
import 'router.dart' show rootNavigatorKey;
import 'screens/profile/profile_page.dart';
import 'main.dart' show MyAppStateBridge;

/// Scaffold sederhana untuk header dengan dua dropdown dan body fleksibel.
/// Dipisah dari main.dart agar main.dart hanya sebagai pemanggil.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  const AppScaffold({super.key, required this.body, this.title = 'Dashboard'});

  Future<void> _handleLogout(BuildContext context) async {
    // Hindari akses context selama operasi async: tidak menyentuh UI hingga await selesai.
    final storage = const SessionStorage();
    final success = await storage.clearSession();

    // Setelah operasi selesai, baru boleh gunakan context untuk navigasi/UX.
    if (!context.mounted) return;

    // TODO: sesuaikan rute login Anda jika berbeda.
    if (success) {
      // Contoh: arahkan ke halaman login dan hapus stack.
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } else {
      // Beri umpan balik kegagalan.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal logout. Coba lagi.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Contoh penempatan action Logout pada AppBar/Overflow menu:
    // Jika file Anda sudah memiliki AppBar/menus, Anda bisa memindahkan IconButton ini ke sana.
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            // Logo placeholder
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Icon(Icons.park, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text(
              'Modern Golf Reservations',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 24),
            if (isWide)
              Text(title, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          _TopLink(
            icon: Icons.dashboard,
            label: 'Dashboard',
            onTap: () {
              // Hindari memakai context dari AppBar langsung; gunakan root context
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final rc = rootNavigatorKey.currentContext;
                if (rc != null && rc.mounted) {
                  try {
                    GoRouter.of(rc).goNamed(AppRoute.dashboard.name);
                  } catch (e) {
                    debugPrint('Error navigating to dashboard: $e');
                  }
                }
              });
            },
          ),
          // Membership & Register Player removed; keep working menus below.
          _TopMenu(
            icon: Icons.calendar_month,
            label: 'Tee Time Reservation',
            onSelect: (ctx, key) {
              // Navigasi selalu lewat root context dan dijalankan pada frame berikutnya
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final rc = rootNavigatorKey.currentContext;
                if (rc == null || !rc.mounted) return;
                try {
                  switch (key) {
                    case 'booking':
                      GoRouter.of(rc).goNamed(AppRoute.teeBooking.name);
                      break;
                    case 'manage':
                      GoRouter.of(rc).goNamed(AppRoute.teeManage.name);
                      break;
                    case 'create':
                      GoRouter.of(rc).goNamed(AppRoute.teeCreate.name);
                      break;
                  }
                } catch (e) {
                  debugPrint('Error navigating to tee time: $e');
                }
              });
            },
            items: const [
              _MenuItem(
                'booking',
                'Tee Time Booking Calendar',
                Icons.event_available,
              ),
              _MenuItem('manage', 'Manage Reservation', Icons.list_alt),
              _MenuItem('create', 'Create Tee Time', Icons.add_alarm),
            ],
          ),
          _TopMenu(
            icon: Icons.point_of_sale,
            label: 'Manage POS',
            onSelect: (ctx, key) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final rc = rootNavigatorKey.currentContext;
                if (rc == null || !rc.mounted) return;
                try {
                  switch (key) {
                    case 'pos':
                      GoRouter.of(rc).goNamed(AppRoute.pos.name);
                      break;
                    case 'invoice':
                      GoRouter.of(rc).goNamed(AppRoute.invoice.name);
                      break;
                  }
                } catch (e) {
                  debugPrint('Error navigating to POS: $e');
                }
              });
            },
            items: const [
              _MenuItem('pos', 'POS System', Icons.store),
              _MenuItem('invoice', 'Invoice', Icons.receipt_long),
            ],
          ),
          const SizedBox(width: 8),
          // User dropdown: Profile & Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Builder(
                  builder: (btnContext) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) async {
                        // Hitung posisi tepat untuk dropdown
                        final RenderBox btnBox =
                            btnContext.findRenderObject() as RenderBox;
                        final Offset btnTopLeft = btnBox.localToGlobal(
                          Offset.zero,
                        );
                        final Size btnSize = btnBox.size;
                        final double left = btnTopLeft.dx;
                        final double top = btnTopLeft.dy + btnSize.height;
                        final RelativeRect position = RelativeRect.fromLTRB(
                          left,
                          top,
                          left,
                          0,
                        );

                        final key = await showMenu<String>(
                          context: btnContext,
                          position: position,
                          items: const [
                            PopupMenuItem<String>(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 18,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Profile'),
                                ],
                              ),
                            ),
                            PopupMenuDivider(),
                            PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.logout,
                                    size: 18,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Logout'),
                                ],
                              ),
                            ),
                          ],
                        );

                        if (key != null) {
                          // Pastikan menu benar-benar tertutup sebelum navigasi
                          await Future.microtask(() async {
                            // Tambah delay kecil untuk memastikan menu benar-benar tertutup
                            await Future.delayed(
                              const Duration(milliseconds: 100),
                            );

                            switch (key) {
                              case 'profile':
                                {
                                  // Gunakan post frame callback untuk navigasi yang aman
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    final ctx = rootNavigatorKey.currentContext;
                                    if (ctx != null && ctx.mounted) {
                                      try {
                                        GoRouter.of(
                                          ctx,
                                        ).goNamed(AppRoute.profile.name);
                                      } catch (e) {
                                        debugPrint(
                                          'Error navigating to profile: $e',
                                        );
                                      }
                                    }
                                  });
                                  break;
                                }
                              case 'logout':
                                {
                                  try {
                                    // Jangan sentuh UI/context sampai operasi async selesai
                                    final success = await SessionStorage()
                                        .clearSession();
                                    if (success) {
                                      // Update state global
                                      MyAppStateBridge
                                              .isLoggedInNotifier
                                              .value =
                                          false;

                                      // Navigasi di frame berikutnya menggunakan root context
                                      WidgetsBinding.instance.addPostFrameCallback((
                                        _,
                                      ) {
                                        final ctx =
                                            rootNavigatorKey.currentContext;
                                        if (ctx != null && ctx.mounted) {
                                          try {
                                            GoRouter.of(
                                              ctx,
                                            ).goNamed(AppRoute.login.name);
                                          } catch (e) {
                                            debugPrint(
                                              'Error navigating to login: $e',
                                            );
                                          }
                                        } else {
                                          debugPrint(
                                            'Context is null or not mounted on logout navigation',
                                          );
                                        }
                                      });
                                    } else {
                                      // Gunakan root context untuk snackbar
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            final ctx =
                                                rootNavigatorKey.currentContext;
                                            if (ctx != null && ctx.mounted) {
                                              try {
                                                ScaffoldMessenger.of(
                                                  ctx,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Gagal logout. Coba lagi.',
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                debugPrint(
                                                  'Error showing snackbar: $e',
                                                );
                                              }
                                            }
                                          });
                                    }
                                  } catch (e) {
                                    debugPrint('Error during logout: $e');
                                  }
                                  break;
                                }
                            }
                          });
                        }
                      },
                      child: FutureBuilder<String?>(
                        future: SessionStorage().getUsername(),
                        builder: (context, snapshot) {
                          String username = snapshot.data?.isNotEmpty == true ? snapshot.data! : "User";
                          return Text(
                            'Welcome, $username ▾',
                            style: const TextStyle(color: Colors.white70),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(padding: const EdgeInsets.all(16), child: body),
        ),
      ),
    );
  }
}

class _TopLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _TopLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white70),
      label: Text(label, style: const TextStyle(color: Colors.white70)),
      style: TextButton.styleFrom(foregroundColor: Colors.white),
    );
  }
}

class _TopMenu extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<_MenuItem> items;
  final void Function(BuildContext context, String key) onSelect;
  const _TopMenu({
    required this.label,
    required this.icon,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // Gunakan onTapDown + showMenu manual agar kita bisa menutup menu terlebih dulu
    // sebelum melakukan navigasi. Ini mencegah penggunaan context yang ter-deactivated.
    return Builder(
      builder: (btnContext) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) async {
            // Hitung posisi tepat berdasarkan ukuran tombol header yang ditekan
            final RenderBox btnBox = btnContext.findRenderObject() as RenderBox;
            final Offset btnTopLeft = btnBox.localToGlobal(Offset.zero);
            final Size btnSize = btnBox.size;
            final double left = btnTopLeft.dx;
            final double top = btnTopLeft.dy + btnSize.height;
            final RelativeRect position = RelativeRect.fromLTRB(
              left,
              top,
              left, // gunakan left juga sebagai right agar dropdown sejajar kiri tombol
              0,
            );
            final key = await showMenu<String>(
              context: btnContext,
              position: position,
              items: items
                  .map(
                    (e) => PopupMenuItem<String>(
                      value: e.key,
                      child: Row(
                        children: [
                          Icon(e.icon, size: 18),
                          const SizedBox(width: 8),
                          Flexible(child: Text(e.title)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            );
            if (key != null) {
              // Pastikan menu benar-benar tertutup sebelum navigasi
              await Future.microtask(() {
                onSelect(btnContext, key);
              });
            }
          },
          child: TextButton.icon(
            onPressed: null,
            icon: Icon(icon, size: 18, color: Colors.white70),
            label: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
        );
      },
    );
  }
}

class _MenuItem {
  final String key;
  final String title;
  final IconData icon;
  const _MenuItem(this.key, this.title, this.icon);
}
