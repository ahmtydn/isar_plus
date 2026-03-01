import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar_plus_inspector/connection_screen.dart';

void main() async {
  runApp(DarkMode(notifier: DarkModeNotifier(), child: const App()));
}

final _router = GoRouter(
  routes: <GoRoute>[
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const Material(
          child: Center(
            child: Text(
              'Welcome to the Isar Plus Inspector!\nPlease open the link '
              'displayed when running the debug version of an Isar app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: '/:port/:secret',
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: Scaffold(
            body: Material(
              child: ConnectionScreen(
                port: state.pathParameters['port']!,
                secret: state.pathParameters['secret']!,
              ),
            ),
          ),
        );
      },
    ),
  ],
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Isar Plus Inspector',
      routeInformationProvider: _router.routeInformationProvider,
      routeInformationParser: _router.routeInformationParser,
      routerDelegate: _router.routerDelegate,
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9FC9FF),
          brightness: DarkMode.of(context).darkMode ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
    );
  }
}

class DarkMode extends InheritedNotifier<DarkModeNotifier> {
  const DarkMode({required super.child, super.key, super.notifier});

  static DarkModeNotifier of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DarkMode>()!.notifier!;
  }
}

class DarkModeNotifier extends ChangeNotifier {
  var _darkMode = true;

  bool get darkMode => _darkMode;

  // Used by UI components to toggle dark mode
  // ignore: unreachable_from_main
  void toggle() {
    _darkMode = !_darkMode;
    notifyListeners();
  }
}
