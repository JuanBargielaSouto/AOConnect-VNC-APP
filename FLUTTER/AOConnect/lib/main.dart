import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/vnc/auth/login_screen.dart';
import 'features/vnc/devices/device_screen.dart';
import 'features/vnc/providers/auth_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AOConnect',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: const ColorScheme(
          brightness: Brightness.light,

          primary: Colors.black,
          onPrimary: Colors.white,

          secondary: Colors.black,
          onSecondary: Colors.white,

          surface: Colors.white,
          onSurface: Colors.black,

          error: Colors.red,
          onError: Colors.white,

          outline: Colors.black,
          surfaceContainerHighest: Color(0xFFF2F2F2),
        ),

        scaffoldBackgroundColor: Colors.white,

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),

        iconTheme: const IconThemeData(
          color: Colors.black,
        ),

        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: const WidgetStatePropertyAll(Colors.white),
            foregroundColor: const WidgetStatePropertyAll(Colors.black),

            overlayColor: const WidgetStatePropertyAll(
              Color(0x1A000000), // hover negro suave
            ),

            side: const WidgetStatePropertyAll(
              BorderSide(color: Colors.black),
            ),
          ),
        ),

        textButtonTheme: const TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Colors.black),
            overlayColor: WidgetStatePropertyAll(Color(0x1A000000)),
          ),
        ),

        iconButtonTheme: const IconButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Colors.black),
            overlayColor: WidgetStatePropertyAll(Color(0x1A000000)),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/devices': (context) => const DeviceScreen(),
      },
    );
  }
}