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

/* import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gestion_salud_materna/Theme/theme.dart';
import 'package:gestion_salud_materna/Theme/util.dart';
import 'package:gestion_salud_materna/firebase_options.dart';

import 'models/modelos.dart';
import 'pages/auth/login.dart';
import 'pages/medico/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;
    // Use with Google Fonts package to use downloadable fonts
    TextTheme textTheme = createTextTheme(context, "Montserrat", "Atkinson Hyperlegible");
    MaterialTheme theme = MaterialTheme(textTheme);
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
      supportedLocales: const [
        Locale('es'), // Spanish, no country code
      ],
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
      home: const AuthWrapper(),
    );
  }
}

Future<Widget> _redirectUser(User user) async {
  // Forzamos refetch de token para obtener claims actualizados
  final idToken = await user.getIdTokenResult(true);
  final claims = idToken.claims ?? {};
  final role = (claims['role'] as String?)?.toLowerCase() ?? 'paciente';

  Widget? homeScreen;
  /* switch (role) {
      case 'superadmin':
        return homeScreen = const HomeAdmin();
        break;
      case 'admin':
        return homeScreen = const HomeAdmin();
        break;
      case 'doctor':
        return homeScreen = const DoctorDashboardScreen();
        break;
      case 'paciente':
      default:
        return homeScreen = const HomePaciente();
    } */
  print(['claims', role, 'homeScreen', homeScreen]); // Debugging role
  return homeScreen = const DoctorDashboardScreen();

  /* Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider(
              create: (_) => AppointmentProvider(),
              child: MaterialApp(title: 'Gestor de Citas Médicas', home: homeScreen),
            ),
      ),
    ); */
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (kDebugMode) {
            print(['displayName', snapshot.data?.displayName]);
            print(['snapshot.hasData', snapshot.hasData]);
          }
          return snapshot.hasData
              ? (snapshot.data != null)
                  ? _redirectUser(cred!.user!).then((value) {
                                // Aquí puedes manejar la navegación después de iniciar sesión
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ChangeNotifierProvider(
                                          create: (_) => AppointmentProvider(),
                                          child: MaterialApp(
                                            title: 'Gestor de Citas Médicas',
                                            home: value,
                                          ),
                                        ),
                                  ),
                                );
                              })
                  : const LoginPage()
              : const LoginPage();
        } else {
          return const SizedBox(width: 30, height: 30, child: CircularProgressIndicator());
        }
      },
    );
  }
} */

/* class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para email y contraseña
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Método para inicio de sesión con Email/Contraseña
  Future<void> _signInWithEmailAndPassword() async {
    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inicio de sesión con Email exitoso')));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    }
  }

  // Método para inicio de sesión con Google
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inicio de sesión con Google exitoso')));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    }
  }

  // Método para mostrar el modal de autenticación con teléfono
  void _showPhoneAuthDialog() {
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController smsController = TextEditingController();
    bool isCodeSent = false;
    String verificationId = '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Autenticación con teléfono'),
              content:
                  isCodeSent
                      ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: smsController,
                            decoration: const InputDecoration(
                              labelText: 'Código SMS',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      )
                      : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Número de teléfono',
                              hintText: '+123456789',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
              actions: [
                isCodeSent
                    ? TextButton(
                      onPressed: () async {
                        try {
                          final String smsCode = smsController.text.trim();
                          final AuthCredential credential = PhoneAuthProvider.credential(
                            verificationId: verificationId,
                            smsCode: smsCode,
                          );
                          await _auth.signInWithCredential(credential);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Inicio de sesión con teléfono exitoso')),
                          );
                        } on FirebaseAuthException catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
                        }
                      },
                      child: const Text('Confirmar código'),
                    )
                    : TextButton(
                      onPressed: () async {
                        final String phone = phoneController.text.trim();
                        await _auth.verifyPhoneNumber(
                          phoneNumber: phone,
                          verificationCompleted: (PhoneAuthCredential credential) async {
                            await _auth.signInWithCredential(credential);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Autenticación completada automáticamente'),
                              ),
                            );
                          },
                          verificationFailed: (FirebaseAuthException e) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
                          },
                          codeSent: (String verId, int? resendToken) {
                            setState(() {
                              verificationId = verId;
                              isCodeSent = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Código de verificación enviado')),
                            );
                          },
                          codeAutoRetrievalTimeout: (String verId) {
                            setState(() {
                              verificationId = verId;
                            });
                          },
                        );
                      },
                      child: const Text('Enviar código'),
                    ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use with Google Fonts package to use downloadable fonts
    TextTheme textTheme = createTextTheme(context, "Montserrat", "Atkinson Hyperlegible");
    var size = MediaQuery.of(context).size;
    MaterialTheme theme = MaterialTheme(textTheme);
    return Scaffold(
      // backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: size.height * 0.68,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // LOGO PRINCIPAL
                    Image.asset('imagenes/logo1.png'),
                    const SizedBox(height: 16),

                    const Text(
                      'Iniciar sesión',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Campo de Correo
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo de Contraseña
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Botón de inicio de sesión (Email/Contraseña)
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                        ),
                        onPressed: _signInWithEmailAndPassword,
                        icon: Icon(
                          Icons.mail,
                          size: 32,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        label: Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // SizedBox(height: size.height * 0.08),
              SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Otros metodos',
                      style: TextStyle(
                        fontSize: 20,
                        // color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Botón de inicio de sesión con Google (con imagen)
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                        ),
                        onPressed: _signInWithGoogle,
                        icon: Image.asset('imagenes/google_logo.png', height: 32),
                        label: Text(
                          'Iniciar con Google',
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Botón único para autenticación con teléfono
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                        ),
                        onPressed: _showPhoneAuthDialog,
                        icon: Icon(
                          Icons.phone,
                          size: 32,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        label: Text(
                          'Iniciar con teléfono',
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        // child: const Text('Iniciar con teléfono', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 */
