import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:appnew_0/src/providers/auth_provider.dart';
import 'package:appnew_0/src/screens/login_screen.dart';
import 'package:appnew_0/main.dart';

Widget _buildTestApp({
  required String initialRoute,
  Map<String, WidgetBuilder>? routes,
}) {
  return ChangeNotifierProvider(
    create: (_) => AuthProvider(),
    child: MaterialApp(
      initialRoute: initialRoute,
      routes:
          routes ??
          {
            '/login': (c) => const LoginScreen(),
            '/home': (c) =>
                const AuthGuard(child: Scaffold(body: Text('Protected Home'))),
          },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets(
    'route guard redirects unauthenticated user from /home to /login',
    (tester) async {
      await tester.pumpWidget(_buildTestApp(initialRoute: '/home'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Iniciar sesi\u00f3n'), findsOneWidget);
      expect(find.text('Protected Home'), findsNothing);
    },
  );

  testWidgets('route guard allows authenticated user to stay on /home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'username': 'testuser'});

    await tester.pumpWidget(_buildTestApp(initialRoute: '/home'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Protected Home'), findsOneWidget);
    expect(find.text('Iniciar sesi\u00f3n'), findsNothing);
  });

  testWidgets('login flow updates auth state and navigates to /home', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestApp(initialRoute: '/login'));
    await tester.pump();

    expect(find.text('Iniciar sesi\u00f3n'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'newuser');
    await tester.enterText(find.byType(TextFormField).at(1), 'pass123');
    await tester.tap(find.text('Ingresar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Protected Home'), findsOneWidget);
    expect(find.text('Iniciar sesi\u00f3n'), findsNothing);
  });

  testWidgets('logout clears auth state and returns to /login', (tester) async {
    SharedPreferences.setMockInitialValues({'username': 'testuser'});

    await tester.pumpWidget(
      _buildTestApp(
        initialRoute: '/home',
        routes: {
          '/login': (c) => const LoginScreen(),
          '/home': (c) => AuthGuard(
            child: Scaffold(
              appBar: AppBar(
                actions: [
                  IconButton(
                    tooltip: 'Cerrar sesi\u00f3n',
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      final nav = Navigator.of(c);
                      await c.read<AuthProvider>().logout();
                      nav.pushReplacementNamed('/login');
                    },
                  ),
                ],
              ),
              body: const Text('Protected Home'),
            ),
          ),
        },
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Protected Home'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar sesi\u00f3n'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Iniciar sesi\u00f3n'), findsOneWidget);
    expect(find.text('Protected Home'), findsNothing);
  });
}
