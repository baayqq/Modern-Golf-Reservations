import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'router.dart';

void main() {

  setUrlStrategy(const HashUrlStrategy());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class MyAppStateBridge {

  static final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier<bool>(
    false,
  );

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

          final tempRouter = GoRouter(
            routes: [
              GoRoute(
                path: '/splash',
                builder: (context, state) => const _Splash(),
              ),
            ],
            initialLocation: '/splash',
          );

          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Modern Golf Reservations',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme(
                brightness: Brightness.light,
                primary: const Color(0xFF2E7D32),
                onPrimary: Colors.white,
                secondary: const Color(0xFF388E3C),
                onSecondary: Colors.white,
                error: const Color(0xFFDC3545),
                onError: Colors.white,
                surface: Colors.white,
                onSurface: const Color(0xFF212529),
                surfaceContainerHighest: const Color(
                  0xFFF1F8E9,
                ),
                outline: const Color(0xFFC7D3C0),
                tertiary: const Color(0xFF1E88E5),
                onTertiary: Colors.white,
              ),
              scaffoldBackgroundColor: const Color(0xFFF1F8E9),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1B5E20),
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

        MyAppStateBridge.isLoggedInNotifier.value = isLoggedIn;

        final router = createRouter(isLoggedIn: isLoggedIn);

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Modern Golf Reservations',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme(
              brightness: Brightness.light,
              primary: const Color(0xFF2E7D32),
              onPrimary: Colors.white,
              secondary: const Color(0xFF388E3C),
              onSecondary: Colors.white,
              error: const Color(0xFFDC3545),
              onError: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF212529),
              surfaceContainerHighest: const Color(
                0xFFF1F8E9,
              ),
              outline: const Color(0xFFC7D3C0),
              tertiary: const Color(0xFF1E88E5),
              onTertiary: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFF1F8E9),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1B5E20),
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