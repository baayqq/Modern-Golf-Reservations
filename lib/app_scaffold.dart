import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'router.dart' show AppRoute, rootNavigatorKey;
import 'services/session_storage.dart' show SessionStorage;
import 'main.dart' show MyAppStateBridge;

class AppScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  const AppScaffold({super.key, required this.body, this.title = 'Dashboard'});

  @override
  Widget build(BuildContext context) {

    final isWide = MediaQuery.of(context).size.width >= 900;
    final appBarFg =
        Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onPrimary;
    final appBarFgSubtle = appBarFg.withValues(alpha: 0.7);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                '/icons/Icon-192.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) =>
                    Icon(Icons.park, size: 20, color: appBarFg),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Modern Golf Reservations',
              style: TextStyle(color: appBarFg, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 24),
            if (isWide) Text(title, style: TextStyle(color: appBarFgSubtle)),
          ],
        ),
        actions: [
          _TopLink(
            icon: Icons.dashboard,
            label: 'Dashboard',
            onTap: () {

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

          _TopMenu(
            icon: Icons.calendar_month,
            label: 'Tee Time Reservation',
            onSelect: (ctx, key) {

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
                    case 'payments':
                      GoRouter.of(rc).goNamed(AppRoute.payments.name);
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
              _MenuItem('payments', 'Payment History', Icons.history),
            ],
          ),
          const SizedBox(width: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.person, color: appBarFgSubtle, size: 18),

                const SizedBox(width: 6),
                Builder(
                  builder: (btnContext) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) async {

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
                            PopupMenuItem<String>(
                              value: 'database',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.storage,
                                    size: 18,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Database Management'),
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

                          await Future.microtask(() async {

                            await Future.delayed(
                              const Duration(milliseconds: 100),
                            );

                            switch (key) {
                              case 'profile':
                                {

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
                              case 'database':
                                {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    final ctx = rootNavigatorKey.currentContext;
                                    if (ctx != null && ctx.mounted) {
                                      try {
                                        GoRouter.of(ctx).goNamed(
                                          AppRoute.databaseManagement.name,
                                        );
                                      } catch (e) {
                                        debugPrint(
                                          'Error navigating to database: $e',
                                        );
                                      }
                                    }
                                  });
                                  break;
                                }
                              case 'logout':
                                {
                                  try {

                                    final success = await SessionStorage()
                                        .clearSession();
                                    if (success) {

                                      MyAppStateBridge
                                              .isLoggedInNotifier
                                              .value =
                                          false;

                                      MyAppStateBridge
                                              .posEnteredNotifier
                                              .value =
                                          false;

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
                          String username = snapshot.data?.isNotEmpty == true
                              ? snapshot.data!
                              : "User";
                          return Text(
                            'Welcome, $username ▾',
                            style: TextStyle(color: appBarFgSubtle),
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
    final appBarFg =
        Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onPrimary;
    final appBarFgSubtle = appBarFg.withValues(alpha: 0.7);
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: appBarFgSubtle),
      label: Text(label, style: TextStyle(color: appBarFgSubtle)),
      style: TextButton.styleFrom(foregroundColor: appBarFg),
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
    final appBarFg =
        Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onPrimary;
    final appBarFgSubtle = appBarFg.withValues(alpha: 0.7);

    return Builder(
      builder: (btnContext) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) async {

            final RenderBox btnBox = btnContext.findRenderObject() as RenderBox;
            final Offset btnTopLeft = btnBox.localToGlobal(Offset.zero);
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

              await Future.microtask(() {
                if (!btnContext.mounted) return;
                onSelect(btnContext, key);
              });
            }
          },
          child: TextButton.icon(
            onPressed: null,
            icon: Icon(icon, size: 18, color: appBarFgSubtle),
            label: Text(label, style: TextStyle(color: appBarFgSubtle)),
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