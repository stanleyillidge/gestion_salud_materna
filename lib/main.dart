import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:gestion_salud_materna/Theme/theme.dart';
import 'package:gestion_salud_materna/Theme/util.dart';
import 'package:gestion_salud_materna/firebase_options.dart';

import 'models/modelos.dart';
import 'pages/auth/login.dart';
import 'providers/appointment_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    // You can also use a `ReCaptchaEnterpriseProvider` provider instance as an
    // argument for `webProvider`
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    // Default provider for Android is the Play Integrity provider. You can use the "AndroidProvider" enum to choose
    // your preferred provider. Choose from:
    // 1. Debug provider
    // 2. Safety Net provider
    // 3. Play Integrity provider
    androidProvider: AndroidProvider.debug,
    // Default provider for iOS/macOS is the Device Check provider. You can use the "AppleProvider" enum to choose
    // your preferred provider. Choose from:
    // 1. Debug provider
    // 2. Device Check provider
    // 3. App Attest provider
    // 4. App Attest provider with fallback to Device Check provider (App Attest provider is only available on iOS 14.0+, macOS 14.0+)
    appleProvider: AppleProvider.appAttest,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Determinar brillo para tema claro/oscuro
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    TextTheme textTheme = createTextTheme(context, "Montserrat", "Atkinson Hyperlegible");
    final theme = MaterialTheme(textTheme);

    // Obtener tamaño de pantalla
    getSizeView(context);
    if (kDebugMode) {
      print(['Main', 'size.width', size.width, 'size.height', size.height]);
    }

    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras carga el estado de auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Si NO está logueado, mostrar login
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        // Si está logueado, resolver la pantalla según el role
        return FutureBuilder<Widget>(
          future: redirectUser(snapshot.data!),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (roleSnap.hasError) {
              return Center(child: Text('Error: ${roleSnap.error}'));
            }
            // Envolvemos la pantalla final con el provider
            return ChangeNotifierProvider(
              create: (_) => AppointmentProvider(),
              child: roleSnap.data!,
            );
          },
        );
      },
    );
  }
}
