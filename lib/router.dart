import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/login_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/pos/pos_system_page.dart';
import 'screens/pos/invoice_page.dart';
import 'screens/pos/payment_history_page.dart';
import 'screens/tee_time/booking_calendar_page.dart';
import 'screens/tee_time/manage_reservation_page.dart';
import 'screens/tee_time/create_tee_time_page.dart';
import 'models/tee_time_model.dart';
import 'screens/profile/profile_page.dart' show ProfilePage;
import 'main.dart' show MyAppStateBridge;

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

enum AppRoute {
  login,
  dashboard,
  pos,
  invoice,
  payments,
  teeBooking,
  teeManage,
  teeCreate,
  profile,
}

extension AppRoutePath on AppRoute {
  String get path {
    switch (this) {
      case AppRoute.login:
        return '/login';
      case AppRoute.dashboard:
        return '/dashboard';
      case AppRoute.pos:
        return '/pos';
      case AppRoute.invoice:
        return '/pos/invoice';
      case AppRoute.payments:
        return '/pos/payments';
      case AppRoute.teeBooking:
        return '/tee-time/booking';
      case AppRoute.teeManage:
        return '/tee-time/manage';
      case AppRoute.teeCreate:
        return '/tee-time/create';
      case AppRoute.profile:
        return '/profile';
    }
  }

  String get name => toString().split('.').last;
}

CustomTransitionPage<T> _fadeTransitionPage<T>({required Widget child}) {
  return CustomTransitionPage<T>(
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    opaque: true,
    barrierDismissible: false,
    barrierColor: null,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}

CustomTransitionPage<T> _slideFromRightPage<T>({required Widget child}) {
  return CustomTransitionPage<T>(
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween<Offset>(
        begin: const Offset(0.06, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

class _AuthState extends ChangeNotifier {
  ValueNotifier<bool> get isLoggedInNotifier =>
      MyAppStateBridge.isLoggedInNotifier;

  bool get isLoggedIn => isLoggedInNotifier.value;
}

GoRouter createRouter({required bool isLoggedIn}) {
  // Sinkronkan nilai awal ke bridge agar konsisten
  MyAppStateBridge.isLoggedInNotifier.value = isLoggedIn;

  // Bungkus status login ke ValueNotifier agar GoRouter dapat refresh saat berubah
  final authState = _AuthState();

  // Force refresh ketika nilai notifier berubah untuk memastikan redirect re-evaluated
  MyAppStateBridge.isLoggedInNotifier.addListener(() {
    // ignore: avoid_print
    print(
      '[ROUTER] isLoggedInNotifier changed => ${MyAppStateBridge.isLoggedInNotifier.value}, forcing refresh',
    );
    rootNavigatorKey.currentState?.context
        .findAncestorStateOfType<State<StatefulWidget>>();
    // Tidak ada API langsung untuk force refresh selain notifyListeners pada refreshListenable,
    // tapi karena GoRouter mem-listen ValueNotifier, perubahan value sudah cukup.
  });

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: isLoggedIn ? AppRoute.dashboard.path : AppRoute.login.path,
    refreshListenable: authState.isLoggedInNotifier,
    routes: <RouteBase>[
      GoRoute(
        name: AppRoute.login.name,
        path: AppRoute.login.path,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(child: const LoginPage()),
      ),
      GoRoute(
        name: AppRoute.dashboard.name,
        path: AppRoute.dashboard.path,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(child: const DashboardPage()),
      ),
      GoRoute(
        name: AppRoute.pos.name,
        path: AppRoute.pos.path,
        pageBuilder: (context, state) {
          final from = state.uri.queryParameters['from'];
          final initialCustomer = state.uri.queryParameters['customer'];
          final qtyStr = state.uri.queryParameters['qty'];
          final initialQty = qtyStr == null ? null : int.tryParse(qtyStr);
          return _slideFromRightPage(
            child: PosSystemPage(
              from: from,
              initialCustomer: initialCustomer,
              initialQty: initialQty,
            ),
          );
        },
        routes: [
          GoRoute(
            name: AppRoute.invoice.name,
            path: 'invoice',
            pageBuilder: (context, state) =>
                _slideFromRightPage(child: const InvoicePage()),
          ),
          GoRoute(
            name: AppRoute.payments.name,
            path: 'payments',
            pageBuilder: (context, state) =>
                _slideFromRightPage(child: const PaymentHistoryPage()),
          ),
        ],
      ),
      GoRoute(
        name: AppRoute.teeBooking.name,
        path: AppRoute.teeBooking.path,
        pageBuilder: (context, state) {
          DateTime? initialDate;
          final extra = state.extra;
          if (extra is DateTime) {
            initialDate = extra;
          } else {
            final qp = state.uri.queryParameters['date'];
            if (qp != null && qp.isNotEmpty) {
              final parsed = DateTime.tryParse(qp);
              if (parsed != null) {
                initialDate = parsed;
              }
            }
          }
          return _slideFromRightPage(
            child: BookingCalendarPage(initialSelectedDate: initialDate),
          );
        },
      ),
      GoRoute(
        name: AppRoute.teeManage.name,
        path: AppRoute.teeManage.path,
        pageBuilder: (context, state) =>
            _slideFromRightPage(child: const ManageReservationPage()),
      ),
      GoRoute(
        name: AppRoute.teeCreate.name,
        path: AppRoute.teeCreate.path,
        pageBuilder: (context, state) {
          final initial = state.extra is TeeTimeModel
              ? state.extra as TeeTimeModel
              : null;
          return _slideFromRightPage(
            child: CreateTeeTimePage(initial: initial),
          );
        },
      ),
      // Profile page now uses the real ProfilePage from app_scaffold.dart
      GoRoute(
        path: AppRoute.profile.path,
        name: AppRoute.profile.name,
        pageBuilder: (context, state) =>
            _slideFromRightPage(child: const ProfilePage()),
      ),
    ],
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final atLogin = loc == AppRoute.login.path;
      final atDashboard = loc == AppRoute.dashboard.path;
      final atProfile = loc == AppRoute.profile.path;
      final atInvoice = loc == AppRoute.invoice.path;
      final atPayments = loc == AppRoute.payments.path;

      // Gunakan satu sumber kebenaran: MyAppStateBridge.isLoggedInNotifier.value
      final loggedIn = MyAppStateBridge.isLoggedInNotifier.value;

      // Debug prints
      // ignore: avoid_print
      print(
        '[ROUTER][redirect] loc="$loc" loggedIn=$loggedIn atLogin=$atLogin',
      );

      // Jika belum login dan bukan di halaman login, arahkan ke /login
      if (!loggedIn && !atLogin) {
        // ignore: avoid_print
        print('[ROUTER][redirect] -> /login');
        return AppRoute.login.path;
      }
      // Jika sudah login dan sedang di /login, arahkan ke /dashboard
      if (loggedIn && atLogin) {
        // ignore: avoid_print
        print('[ROUTER][redirect] -> /dashboard');
        return AppRoute.dashboard.path;
      }

      // Guard: sebelum membuat/melihat invoice atau riwayat pembayaran,
      // pengguna harus masuk ke menu POS terlebih dahulu pada sesi ini.
      // Jika belum, arahkan ke /pos dengan query from=invoice/payments
      if (loggedIn && (atInvoice || atPayments)) {
        final entered = MyAppStateBridge.posEnteredNotifier.value;
        if (!entered) {
          final from = atInvoice ? 'invoice' : 'payments';
          // ignore: avoid_print
          print('[ROUTER][redirect] -> /pos?from=$from (POS not entered)');
          return '${AppRoute.pos.path}?from=$from';
        }
      }
      // Jangan redirect kalau sudah di tujuan yang benar untuk menghindari flicker/error
      if (loggedIn && (atDashboard || atProfile)) {
        // ignore: avoid_print
        print('[ROUTER][redirect] stay');
        return null;
      }
      // ignore: avoid_print
      print('[ROUTER][redirect] null');
      return null;
    },
  );

  // ignore: avoid_print
  print(
    '[ROUTER] created. initial=${isLoggedIn ? AppRoute.dashboard.path : AppRoute.login.path}, refreshListenable hooked to MyAppStateBridge',
  );

  return router;
}
