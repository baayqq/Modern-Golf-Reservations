import 'package:flutter/material.dart';
import 'screens/dashboard_page.dart';
import 'screens/tee_time/booking_calendar_page.dart';
import 'screens/tee_time/manage_reservation_page.dart';
import 'screens/tee_time/create_tee_time_page.dart';
import 'screens/pos/pos_system_page.dart';
import 'screens/pos/invoice_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_page.dart';

/// Scaffold sederhana untuk header dengan dua dropdown dan body fleksibel.
/// Dipisah dari main.dart agar main.dart hanya sebagai pemanggil.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  const AppScaffold({super.key, required this.body, this.title = 'Dashboard'});

  @override
  Widget build(BuildContext context) {
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
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const DashboardPage()));
            },
          ),
          // Membership & Register Player removed; keep working menus below.
          _TopMenu(
            icon: Icons.calendar_month,
            label: 'Tee Time Reservation',
            onSelect: (ctx, key) {
              switch (key) {
                case 'booking':
                  Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => const BookingCalendarPage(),
                    ),
                  );
                  break;
                case 'manage':
                  Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => const ManageReservationPage(),
                    ),
                  );
                  break;
                case 'create':
                  Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (context) => const CreateTeeTimePage(),
                    ),
                  );
                  break;
              }
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
              switch (key) {
                case 'pos':
                  Navigator.of(ctx).push(
                    MaterialPageRoute(builder: (_) => const PosSystemPage()),
                  );
                  break;
                case 'invoice':
                  Navigator.of(ctx).push(
                    MaterialPageRoute(builder: (_) => const InvoicePage()),
                  );
                  break;
              }
            },
            items: const [
              _MenuItem('pos', 'POS System', Icons.store),
              _MenuItem('invoice', 'Invoice', Icons.receipt_long),
            ],
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                PopupMenuButton<String>(
                  tooltip: 'User Menu',
                  offset: const Offset(0, 40),
                  onSelected: (key) async {
                    switch (key) {
                      case 'profile':
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const _ProfilePage(),
                          ),
                        );
                        break;
                      case 'logout':
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('isLoggedIn', false);
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 18, color: Colors.black),
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
                          Icon(Icons.logout, size: 18, color: Colors.black),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                  child: const Text(
                    'Welcome, fitri ▾',
                    style: TextStyle(color: Colors.white70),
                  ),
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
    return PopupMenuButton<String>(
      tooltip: label,
      offset: const Offset(0, 40),
      itemBuilder: (context) {
        return items
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
            .toList();
      },
      onSelected: (key) => onSelect(context, key),
      child: TextButton.icon(
        onPressed: null,
        icon: Icon(icon, size: 18, color: Colors.white70),
        label: Text(label, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}

class _MenuItem {
  final String key;
  final String title;
  final IconData icon;
  const _MenuItem(this.key, this.title, this.icon);
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Meniru tampilan sederhana profil seperti di gambar:
    // Card di tengah berisi avatar/emblem, nama pengguna, role, email (dummy), dan tombol Logout.
    return Scaffold(
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
                  Icon(
                    Icons.shield_outlined,
                    size: 84,
                    color: Colors.brown.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'fitri',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Role: Administrator',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Email: fitri@example.com',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC3545),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('isLoggedIn', false);
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                        ),
                      ),
                    ],
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
