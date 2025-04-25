import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../Theme/theme.dart';
import '../../Theme/util.dart';
import '../admin/notificaciones.dart';
import '../auth/login.dart';

class HomePaciente extends StatefulWidget {
  const HomePaciente({super.key});

  @override
  HomePacienteState createState() => HomePacienteState();
}

class HomePacienteState extends State<HomePaciente> {
  final Authentication _auth = Authentication();
  @override
  Widget build(BuildContext context) {
    // Use with Google Fonts package to use downloadable fonts
    TextTheme textTheme = createTextTheme(context, "Montserrat", "Atkinson Hyperlegible");
    MaterialTheme theme = MaterialTheme(textTheme);
    return MaterialApp(
      theme: Theme.of(context).brightness == Brightness.light ? theme.light() : theme.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'), // Spanish, no country code
      ],
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        final scale = mediaQueryData.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.09);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Panel de Paciente'), // Título más descriptivo
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined), // Icono outline
                  tooltip: 'Notificaciones',
                  onPressed: () {
                    // Navegar a pantalla de notificaciones (Push es correcto aquí)
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Notificaciones()),
                    );
                  },
                ),
                // Puedes añadir más acciones como Logout aquí
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Cerrar Sesión',
                  onPressed: () {
                    // Implementar lógica de logout (ej. llamar a FirebaseAuth.instance.signOut())
                    // y navegar a la pantalla de login.
                    print("Logout presionado"); // Placeholder
                    _auth.logout(context);
                  },
                ),
              ],
            ),
            body: const SizedBox(child: Text('HomePaciente')),
          ),
        );
      },
    );
  }
}
