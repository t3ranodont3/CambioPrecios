import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/services/storage_service.dart';
import 'src/providers/establishment_provider.dart';
import 'src/providers/auth_provider.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/import_catalog_screen.dart';
import 'src/screens/import_report_screen.dart';
import 'src/screens/edit_screen.dart';
import 'src/screens/export_csv_screen.dart';
import 'src/screens/sync_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await createStartupApp());
}

Future<Widget> createStartupApp({
  Future<void> Function() initializeStorage = initStorage,
}) async {
  try {
    await initializeStorage();
    return const MyApp();
  } catch (error, stackTrace) {
    debugPrint('Storage initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    return const StorageStartupFailureApp();
  }
}

class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!auth.isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return child;
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EstablishmentProvider()),
      ],
      child: MaterialApp(
        title: 'CambioPrecios DIGEMID',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (c) => const LoginScreen(),
          '/home': (c) => const AuthGuard(child: HomeScreen()),
          '/import_catalog': (c) =>
              const AuthGuard(child: ImportCatalogScreen()),
          '/import_report': (c) => const AuthGuard(child: ImportReportScreen()),
          '/edit': (c) => const AuthGuard(child: EditScreen()),
          '/export': (c) => const AuthGuard(child: ExportCsvScreen()),
          '/sync': (c) => const AuthGuard(child: SyncScreen()),
        },
      ),
    );
  }
}

class StorageStartupFailureApp extends StatelessWidget {
  const StorageStartupFailureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CambioPrecios DIGEMID',
      home: Scaffold(
        appBar: AppBar(title: const Text('No se pudo iniciar la aplicación')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No se pudo inicializar el almacenamiento local. '
              'La aplicación no se inició y los datos existentes no se '
              'restablecieron. Reinicie la aplicación o contacte al soporte.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
