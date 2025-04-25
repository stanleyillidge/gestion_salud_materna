// lib/ui/auth/login_page.dart

// ignore_for_file: use_build_context_synchronously

import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../Theme/util.dart';
import '../../Theme/theme.dart';
import '../../main.dart';
import '../../models/modelos.dart';
import '../../providers/appointment_provider.dart';

// Importa aquí tus pantallas según rol:
import '../admin/home.dart';
import '../medico/home.dart';
import '../paciente/home.dart';

class Authentication {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      if (kDebugMode) print('Error GoogleSignIn: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      if (kDebugMode) print('Error EmailSignIn: $e');
      return null;
    }
  }

  Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required void Function(String verificationId) codeSent,
    required void Function(FirebaseAuthException) verificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential cred) async {
        await _auth.signInWithCredential(cred);
      },
      verificationFailed: verificationFailed,
      codeSent: (id, _) => codeSent(id),
      codeAutoRetrievalTimeout: (id) {},
    );
  }

  Future<UserCredential?> signInWithPhoneNumber(String verificationId, String smsCode) async {
    try {
      final cred = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
      return await _auth.signInWithCredential(cred);
    } catch (e) {
      if (kDebugMode) print('Error PhoneSignIn: $e');
      return null;
    }
  }

  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MyApp()));
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

AnimationController? loginButtonController;

Future<Widget> redirectUser(User user) async {
  // Forzamos refetch de token para obtener claims actualizados
  final idToken = await user.getIdTokenResult(true);
  final claims = idToken.claims ?? {};
  String role = (claims['role'] as String?)?.toLowerCase() ?? 'paciente';
  role = (claims['superadmin'] == true) ? 'superadmin' : role;
  role = (claims['doctor'] == true) ? 'doctor' : role;
  role = (claims['admin'] == true) ? 'admin' : role;
  role = (claims['paciente'] == true) ? 'paciente' : role;
  print(['claims', role, idToken.claims]); // Debugging role

  Widget homeScreen;
  switch (role) {
    case 'superadmin':
    case 'admin':
      return const HomeAdmin();
    case 'doctor':
      return DoctorDashboardScreen();
    case 'paciente':
    default:
      return const HomePaciente();
  }
  // return homeScreen = const DoctorDashboardScreen();

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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final Authentication _auth = Authentication();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _logins = ['imagenes/logo1.png'];
  late int _img;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _img = _random.nextInt(_logins.length);
    loginButtonController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  void _showPhoneAuthDialog() {
    final phoneCtrl = TextEditingController();
    final smsCtrl = TextEditingController();
    bool codeSent = false;
    String verId = '';

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setState) => AlertDialog(
                  title: const Text('Autenticación con teléfono'),
                  content:
                      codeSent
                          ? TextField(
                            controller: smsCtrl,
                            decoration: const InputDecoration(labelText: 'Código SMS'),
                            keyboardType: TextInputType.number,
                          )
                          : TextField(
                            controller: phoneCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Número de teléfono',
                              hintText: '+123456789',
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                  actions: [
                    codeSent
                        ? TextButton(
                          onPressed: () async {
                            final cred = await _auth.signInWithPhoneNumber(
                              verId,
                              smsCtrl.text.trim(),
                            );
                            if (cred?.user != null) {
                              Navigator.of(ctx).pop();
                              await redirectUser(cred!.user!).then((value) {
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
                              });
                            }
                          },
                          child: const Text('Confirmar'),
                        )
                        : TextButton(
                          onPressed: () async {
                            await _auth.verifyPhoneNumber(
                              phoneCtrl.text.trim(),
                              codeSent: (id) {
                                setState(() {
                                  verId = id;
                                  codeSent = true;
                                });
                              },
                              verificationFailed:
                                  (e) => ScaffoldMessenger.of(
                                    ctx,
                                  ).showSnackBar(SnackBar(content: Text('Error: ${e.message}'))),
                            );
                          },
                          child: const Text('Enviar código'),
                        ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    final imagen = Image.asset(_logins[_img], fit: BoxFit.contain);
    final textTheme = createTextTheme(context, "Montserrat", "Atkinson Hyperlegible");
    final theme = MaterialTheme(textTheme);
    const btnWidth = 320.0;

    Future<void> emailLogin() async {
      final cred = await _auth.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (cred?.user != null) {
        await redirectUser(cred!.user!).then((value) {
          // Aquí puedes manejar la navegación después de iniciar sesión
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (_) => ChangeNotifierProvider(
                    create: (_) => AppointmentProvider(),
                    child: MaterialApp(title: 'Gestor de Citas Médicas', home: value),
                  ),
            ),
          );
        });
      }
    }

    Future<void> googleLogin() async {
      final cred = await _auth.signInWithGoogle();
      if (cred?.user != null) {
        await redirectUser(cred!.user!).then((value) {
          // Aquí puedes manejar la navegación después de iniciar sesión
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (_) => ChangeNotifierProvider(
                    create: (_) => AppointmentProvider(),
                    child: MaterialApp(title: 'Gestor de Citas Médicas', home: value),
                  ),
            ),
          );
        });
      }
    }

    final botones = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Inicia sesión', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        Row(children: [Checkbox(value: false, onChanged: (_) {}), const Text('Remember me')]),
        SizedBox(
          width: btnWidth,
          child: ElevatedButton.icon(
            icon: Icon(Icons.mail, size: 24, color: theme.light().colorScheme.onPrimary),
            label: Text(
              'Iniciar sesión',
              style: TextStyle(fontSize: 18, color: theme.light().colorScheme.onPrimary),
            ),
            onPressed: emailLogin,
          ),
        ),
        TextButton(
          onPressed: () {
            /* navegar a register */
          },
          child: const Text('Crear cuenta'),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: btnWidth,
          child: ElevatedButton(
            onPressed: googleLogin,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('imagenes/google_logo.png', width: 24),
                const SizedBox(width: 8),
                const Text('Iniciar con Google', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: btnWidth,
          child: ElevatedButton.icon(
            icon: Icon(Icons.phone, size: 24, color: theme.light().colorScheme.onPrimary),
            label: const Text('Iniciar con teléfono'),
            onPressed: _showPhoneAuthDialog,
          ),
        ),
      ],
    );

    return Scaffold(body: LoginAdaptativo(imagen: imagen, botones: botones));
  }
}

class LoginAdaptativo extends StatelessWidget {
  final Widget imagen;
  final Widget botones;
  const LoginAdaptativo({super.key, required this.imagen, required this.botones});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (ctx, cons) {
          final tall = cons.maxHeight > cons.maxWidth;
          return tall
              ? Column(children: [imagen, const SizedBox(height: 20), botones])
              : Row(
                children: [
                  Expanded(child: imagen),
                  const SizedBox(width: 20),
                  Expanded(child: Center(child: botones)),
                ],
              );
        },
      ),
    );
  }
}
