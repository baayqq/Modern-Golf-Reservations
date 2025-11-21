import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'router.dart';

void main() {
  // Gunakan hash routing agar URL kompatibel di hosting statis (tanpa rewrite).
  // Ini memudahkan demo online pada Netlify/Vercel/GitHub Pages.
  setUrlStrategy(const HashUrlStrategy());
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
  // Flag sesi sederhana: bernilai true setelah pengguna memasuki halaman POS.
  // Dipakai untuk mewajibkan alur "masuk POS dulu" sebelum ke halaman Invoice.
  static final ValueNotifier<bool> posEnteredNotifier = ValueNotifier<bool>(
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
                primary: const Color(0xFF2E7D32), // Golf green
                onPrimary: Colors.white,
                secondary: const Color(0xFF388E3C), // Accent green
                onSecondary: Colors.white,
                error: const Color(0xFFDC3545),
                onError: Colors.white,
                surface: Colors.white,
                onSurface: const Color(0xFF212529),
                surfaceContainerHighest: const Color(
                  0xFFF1F8E9,
                ), // Light green background
                outline: const Color(0xFFC7D3C0), // Soft greenish outline
                tertiary: const Color(0xFF1E88E5), // Sky blue accent
                onTertiary: Colors.white,
              ),
              scaffoldBackgroundColor: const Color(0xFFF1F8E9),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1B5E20), // Dark forest green
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
                  borderSide: const BorderSide(color: Color(0xFFC7D3C0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFC7D3C0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFF2E7D32),
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
                color: Color(0xFFC7D3C0),
                thickness: 1,
                space: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
              primary: const Color(0xFF2E7D32), // Golf green
              onPrimary: Colors.white,
              secondary: const Color(0xFF388E3C), // Accent green
              onSecondary: Colors.white,
              error: const Color(0xFFDC3545),
              onError: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF212529),
              surfaceContainerHighest: const Color(
                0xFFF1F8E9,
              ), // Light green background
              outline: const Color(0xFFC7D3C0), // Soft greenish outline
              tertiary: const Color(0xFF1E88E5), // Sky blue accent
              onTertiary: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFF1F8E9),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1B5E20), // Dark forest green
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
                borderSide: const BorderSide(color: Color(0xFFC7D3C0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFC7D3C0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: Color(0xFF2E7D32),
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
              color: Color(0xFFC7D3C0),
              thickness: 1,
              space: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          routerConfig: router,
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
