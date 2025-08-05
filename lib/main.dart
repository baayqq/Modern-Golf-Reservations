import 'package:flutter/material.dart';
import 'screens/dashboard_page.dart';
import 'screens/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class MyAppStateBridge {
  // Jembatan statis agar file lain bisa memicu refresh router
  static final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier<bool>(
    false,
  );
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _checkLoggedIn();
  }

  Future<bool> _checkLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Dengarkan perubahan SharedPreferences agar GoRouter bisa rebuild setelah login/logout
  // Pindahkan ValueNotifier ke MyAppStateBridge agar bisa diakses dari file lain

  Future<void> _invalidateAfterLoginLogout() async {
    // Recheck login dan update notifier + rebuild MaterialApp.router
    final logged = await _checkLoggedIn();
    MyAppStateBridge.isLoggedInNotifier.value = logged;
    if (mounted) {
      setState(() {
        _initFuture = Future<bool>.value(logged);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          // Saat masih loading, tetap gunakan MaterialApp.router dengan router minimal
          final tempRouter = GoRouter(
            routes: [
              GoRoute(
                path: '/splash',
                builder: (context, state) => const _Splash(),
              ),
            ],
            initialLocation: '/splash',
          );
          // Penting: jangan gunakan MaterialApp biasa/berbeda konfigurasi saat splash,
          // tetap gunakan MaterialApp.router dengan konfigurasi yang SAMA (tema dll)
          // untuk mencegah rebuild yang memicu popup/theme lookup pada context yang di-dispose.
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Modern Golf Reservations',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme(
                brightness: Brightness.light,
                primary: const Color(0xFF0D6EFD),
                onPrimary: Colors.white,
                secondary: const Color(0xFF6C757D),
                onSecondary: Colors.white,
                error: const Color(0xFFDC3545),
                onError: Colors.white,
                surface: Colors.white,
                onSurface: const Color(0xFF212529),
                surfaceVariant: const Color(0xFFE9ECEF),
                outline: const Color(0xFFDEE2E6),
                tertiary: const Color(0xFF198754),
                onTertiary: Colors.white,
              ),
              scaffoldBackgroundColor: const Color(0xFFF8F9FA),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF2F363D),
                elevation: 0,
                foregroundColor: Colors.white,
                centerTitle: false,
                toolbarHeight: 64,
              ),
              textTheme: Typography.blackCupertino.apply(
                displayColor: const Color(0xFF212529),
                bodyColor: const Color(0xFF212529),
              ),
              cardTheme: const CardThemeData(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFCED4DA)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFCED4DA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFF0D6EFD),
                    width: 2,
                  ),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              dividerTheme: const DividerThemeData(
                color: Color(0xFFDEE2E6),
                thickness: 1,
                space: 0,
              ),
            ),
            routerConfig: tempRouter,
          );
        }
        final isLoggedIn = snap.data == true;
        // Pastikan ValueNotifier sinkron dengan nilai awal
        MyAppStateBridge.isLoggedInNotifier.value = isLoggedIn;
        // Router dibuat setiap build agar redirect mempertimbangkan status terbaru.
        final router = createRouter(isLoggedIn: isLoggedIn);
        // Tambahkan navigatorKey global agar semua navigator konsisten (rootNavigatorKey)
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Modern Golf Reservations',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme(
              brightness: Brightness.light,
              primary: const Color(0xFF0D6EFD),
              onPrimary: Colors.white,
              secondary: const Color(0xFF6C757D),
              onSecondary: Colors.white,
              error: const Color(0xFFDC3545),
              onError: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF212529),
              surfaceVariant: const Color(0xFFE9ECEF),
              outline: const Color(0xFFDEE2E6),
              tertiary: const Color(0xFF198754),
              onTertiary: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF2F363D),
              elevation: 0,
              foregroundColor: Colors.white,
              centerTitle: false,
              toolbarHeight: 64,
            ),
            textTheme: Typography.blackCupertino.apply(
              displayColor: const Color(0xFF212529),
              bodyColor: const Color(0xFF212529),
            ),
            cardTheme: const CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCED4DA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCED4DA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: Color(0xFF0D6EFD),
                  width: 2,
                ),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            dividerTheme: const DividerThemeData(
              color: Color(0xFFDEE2E6),
              thickness: 1,
              space: 0,
            ),
          ),
          routerConfig: router,
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
