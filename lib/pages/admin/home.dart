// Archivo: pages/admin/home.dart
// Ruta: D:\proyectos\salud_materna\lib\pages\admin\home.dart

// ignore_for_file: use_build_context_synchronously, unused_element, avoid_print

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

// Importa tus widgets de pantalla/sección
import '../../services/firestore_service.dart'; // Necesario para el borrado
import '../../services/test_data_loader.dart'; // *** NUEVO: Importa el loader ***
import '../../services/users_service.dart'; // *** NUEVO: Importa UsersService ***
import '../auth/login.dart';
import 'dashboard.dart'; // *** CORREGIDO: Importa Dashboard ***
import 'doctores/doctor_management_screen.dart';
import 'gestion_users.dart';
import 'notificaciones.dart';
import 'pacientes/pacientes.dart';

// --- Definición de los Widgets para cada Sección ---
final List<Widget> _widgetOptions = <Widget>[
  const AdminDashboardScreen(), // Índice 0
  const Pacientes(), // Índice 1
  const UserManagementScreen(), // Índice 2
  const DoctorManagementScreen(), // Índice 3
  const Center(child: Text('Citas (Placeholder)')), // Índice 4
  const Center(child: Text('Configuración (Placeholder)')), // Índice 5
];

// --- Widget Principal HomeAdmin ---
class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  HomeAdminState createState() => HomeAdminState();
}

class HomeAdminState extends State<HomeAdmin> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  bool _isNavigationRailExtended = false;
  final Authentication _auth = Authentication();

  // --- Estados para acciones ---
  bool _isSeeding = false; // Estado para carga de datos
  bool _isDeletingUsers = false; // Estado para borrado masivo
  bool _isDeletingFirestorePatients = false;

  // --- Instancias de servicios ---
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  late final UsersService _usersService; // Se inicializa en initState
  late final TestDataLoader _dataLoader; // Se inicializa en initState

  @override
  void initState() {
    super.initState();
    // Inicializa servicios que dependen de otros aquí
    _usersService = UsersService();
    _dataLoader = TestDataLoader(_usersService, _firestoreService);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  // --- Método para iniciar la carga de datos ---
  Future<void> _startSeedData() async {
    if (_isSeeding) return;

    final confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Confirmar Carga de Datos de Prueba'),
                content: const Text(
                  'Esto creará usuarios pacientes ficticios y cargará sus historias clínicas desde el archivo JSON. ¿Continuar?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Sí, Cargar Datos'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    setState(() {
      _isSeeding = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Iniciando carga de datos...')));

    try {
      // Llama a la función de carga usando la instancia _dataLoader
      await _dataLoader.loadClinicalDataFromJson(context);
      // El feedback final ya se maneja dentro de loadClinicalDataFromJson
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error grave durante la carga: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSeeding = false;
        });
      }
    }
  }

  // --- Método para iniciar el borrado con confirmación (EXISTENTE) ---
  Future<void> _startMassiveUserDelete() async {
    if (_isDeletingUsers) return;

    // --- Diálogo de Confirmación MUY Explícito ---
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // No permitir cerrar tocando fuera
      builder: (BuildContext ctx) {
        String confirmationText = '';
        return AlertDialog(
          title: const Text(
            '⚠️ BORRADO MASIVO IRREVERSIBLE ⚠️',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'Estás a punto de borrar TODOS los usuarios de Firestore excepto los definidos como seguros.',
                ),
                const Text(
                  '\nESTA ACCIÓN NO SE PUEDE DESHACER.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  '\nLos usuarios de Firebase Authentication NO serán eliminados por esta función.',
                ),
                const Text(
                  '\nRevisa la lista `uidsToKeepSafe` en el código para asegurar que tus admins estén allí.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.orange),
                ),
                const Text('\nPara confirmar, escribe la palabra "BORRAR" en mayúsculas:'),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (value) {
                    confirmationText = value;
                  },
                  decoration: const InputDecoration(hintText: 'Escribe BORRAR aquí'),
                  autocorrect: false,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(ctx).pop(false); // No confirmado
              },
            ),
            TextButton(
              child: const Text('PROCEDER AL BORRADO', style: TextStyle(color: Colors.red)),
              onPressed: () {
                if (confirmationText == 'BORRAR') {
                  Navigator.of(ctx).pop(true); // Confirmado
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Texto de confirmación incorrecto.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Borrado masivo cancelado.')));
      return;
    }

    setState(() {
      _isDeletingUsers = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Iniciando borrado masivo... Esto puede tardar.'),
        duration: Duration(seconds: 4),
      ),
    );

    // --- Define AQUÍ los UIDs que NO quieres borrar ---
    // ¡¡ASEGÚRATE DE QUE ESTA LISTA SEA CORRECTA!!
    final List<String> uidsToKeepSafe =
        [
              'Tmps8lzYD1aeVig4tXKCCUR2cXt1', // Ejemplo 1
              'ELFNryTZY0hsTehf6APi8X7bHt42', // Ejemplo 2
              '9SzB2XG9ifaLcq6e6PHyWJvwfQE2', // Ejemplo 3
              'r5cHUx4oB7aWC2AYKtPGFNLxT2v1', // Ejemplo 4
              '7VhgBZuYubVxSbSydhzmgO1D3SQ2',
              _auth.currentUser?.uid ?? 'NO_CURRENT_USER_ID', // Añadir el UID del admin actual
              // Añade más UIDs esenciales aquí
            ]
            .where((uid) => uid != 'NO_CURRENT_USER_ID')
            .toSet()
            .toList(); // Elimina duplicados y placeholder

    if (uidsToKeepSafe.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Error Crítico: La lista de UIDs a mantener está vacía. Operación abortada.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 10),
        ),
      );
      setState(() {
        _isDeletingUsers = false;
      });
      return;
    }
    print("UIDs a mantener: $uidsToKeepSafe");

    try {
      // *** LLAMADA AL SERVICIO DE BORRADO ***
      // Asumiendo que tienes un método en FirestoreService que hace esto.
      // Si no lo tienes, necesitarías implementarlo (borrar documentos en batch).
      // Ejemplo de llamada (necesitarás implementar deleteAllUsersExcept):
      final result = await _firestoreService.deleteAllUsersExcept(uidsToKeepSafe);

      final resultx = await _functions.httpsCallable('manageAuthUser')({
        'action': 'bulkDeleteExcept',
        'excludedUIDs': [
          'Tmps8lzYD1aeVig4tXKCCUR2cXt1', // Ejemplo 1
          'ELFNryTZY0hsTehf6APi8X7bHt42', // Ejemplo 2
          '9SzB2XG9ifaLcq6e6PHyWJvwfQE2', // Ejemplo 3
          'r5cHUx4oB7aWC2AYKtPGFNLxT2v1', // Ejemplo 4
          '7VhgBZuYubVxSbSydhzmgO1D3SQ2',
          _auth.currentUser?.uid ?? 'NO_CURRENT_USER_ID', // Añadir el UID del admin actual
        ],
      });

      final deleted = result['deleted'] ?? 0;
      final errors = result['errors'] ?? 0;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Borrado finalizado: $deleted eliminados, $errors errores.'),
          backgroundColor: errors > 0 ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      print("Error fatal durante el borrado masivo: $e");
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error grave durante el borrado: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingUsers = false;
        });
      }
    }
  }

  Future<void> _startFirestorePatientDelete() async {
    if (_isDeletingFirestorePatients) return;

    // *** CONFIRMACIÓN EXPLÍCITA *** (MUY IMPORTANTE)
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        String confirmText = '';
        return AlertDialog(
          title: const Text(
            '⚠️ BORRAR PACIENTES (FIRESTORE) ⚠️',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'Estás a punto de borrar los datos de Firestore (documento principal y historias clínicas) de TODOS los pacientes, EXCEPTO los de la lista segura.',
                ),
                const Text(
                  '\n¡LOS USUARIOS DE AUTHENTICATION NO SE VERÁN AFECTADOS!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('\nEsta acción es irreversible para los datos de Firestore.'),
                const Text('\nRevisa la lista `uidsToKeepSafe` en el código (FirestoreService).'),
                const Text('\nEscribe "BORRAR-P" para confirmar:'),
                TextField(
                  onChanged: (v) => confirmText = v,
                  decoration: const InputDecoration(hintText: 'BORRAR-P'),
                  autocorrect: false,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TextButton(
              child: const Text('PROCEDER (FIRESTORE)', style: TextStyle(color: Colors.orange)),
              onPressed: () {
                if (confirmText == 'BORRAR-P') {
                  Navigator.of(ctx).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Texto incorrecto.'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Borrado Firestore cancelado.')));
      return;
    }

    setState(() => _isDeletingFirestorePatients = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Iniciando borrado Firestore de pacientes...'),
        duration: Duration(seconds: 3),
      ),
    );

    // *** DEFINE AQUÍ LOS IDs A MANTENER ***
    final List<String> uidsToKeepSafe = [
      'Tmps8lzYD1aeVig4tXKCCUR2cXt1', // Ejemplo 1
      'ELFNryTZY0hsTehf6APi8X7bHt42', // Ejemplo 2
      '9SzB2XG9ifaLcq6e6PHyWJvwfQE2', // Ejemplo 3
      'r5cHUx4oB7aWC2AYKtPGFNLxT2v1', // Ejemplo 4
      '7VhgBZuYubVxSbSydhzmgO1D3SQ2',
      // ... otros IDs que NO quieres borrar de Firestore
    ];

    try {
      final result = await _firestoreService.deleteFirestorePatientsExcept(uidsToKeepSafe);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Borrado Firestore Pacientes: ${result['patientsDeleted']} docs, '
            '${result['clinicalRecordsDeleted']} registros clínicos. Errores: ${result['errors']}',
          ),
          duration: const Duration(seconds: 8),
          backgroundColor: (result['errors'] ?? 0) > 0 ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error grave: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isDeletingFirestorePatients = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // TextTheme textTheme = createTextTheme(context, "Montserrat", "Atkinson Hyperlegible");
    // MaterialTheme theme = MaterialTheme(textTheme);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notificaciones',
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Notificaciones()),
                ),
          ),
          // --- Botón Cargar Datos ---
          IconButton(
            icon:
                _isSeeding
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                    : const Icon(Icons.upload_file),
            tooltip: 'Cargar Datos de Prueba',
            onPressed: _isSeeding ? null : _startSeedData, // Deshabilitar mientras carga
          ),
          // --- Botón Borrado Masivo ---
          IconButton(
            icon:
                _isDeletingUsers
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                    )
                    : const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
            tooltip: 'BORRADO MASIVO (¡Cuidado!)',
            onPressed:
                _isDeletingUsers ? null : _startMassiveUserDelete, // Deshabilitar mientras borra
          ),
          IconButton(
            icon:
                _isDeletingFirestorePatients
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.orange),
                    )
                    : const Icon(
                      Icons.cleaning_services_outlined,
                      color: Colors.orangeAccent,
                    ), // Icono diferente
            tooltip: 'Borrar Pacientes (SOLO FIRESTORE)',
            onPressed:
                _isDeletingFirestorePatients
                    ? null
                    : _startFirestorePatientDelete, // Llama a la nueva función
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _auth.logout(context),
          ),
        ],
      ),
      body: ResponsiveBuilder(
        builder: (context, sizingInformation) {
          final bool isMobileLayout = sizingInformation.deviceScreenType == DeviceScreenType.mobile;
          if (isMobileLayout) {
            return _buildPageView();
          } else {
            return Row(
              children: [
                _buildNavigationRail(),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _buildPageView()),
              ],
            );
          }
        },
      ),
      bottomNavigationBar: ResponsiveBuilder(
        builder: (context, sizingInformation) {
          if (sizingInformation.deviceScreenType == DeviceScreenType.mobile) {
            return BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_alt_outlined),
                  activeIcon: Icon(Icons.people_alt),
                  label: 'Pacientes',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.manage_accounts_outlined),
                  activeIcon: Icon(Icons.manage_accounts),
                  label: 'Usuarios',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.medical_services_outlined),
                  activeIcon: Icon(Icons.medical_services),
                  label: 'Doctores',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined),
                  activeIcon: Icon(Icons.calendar_today),
                  label: 'Citas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Ajustes',
                ),
              ],
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  // --- Widget Helper: PageView (sin cambios) ---
  Widget _buildPageView() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        if (_selectedIndex != index) {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      children: _widgetOptions,
    );
  }

  // --- Widget Helper: NavigationRail (sin cambios) ---
  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      extended: _isNavigationRailExtended,
      minExtendedWidth: 180,
      labelType: NavigationRailLabelType.none,
      leading: InkWell(
        onTap: () => setState(() => _isNavigationRailExtended = !_isNavigationRailExtended),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Icon(_isNavigationRailExtended ? Icons.menu_open : Icons.menu),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_alt_outlined),
          selectedIcon: Icon(Icons.people_alt),
          label: Text('Pacientes'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.manage_accounts_outlined),
          selectedIcon: Icon(Icons.manage_accounts),
          label: Text('Gestionar Usuarios'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.medical_services_outlined),
          selectedIcon: Icon(Icons.medical_services),
          label: Text('Doctores'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: Text('Citas'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Configuración'),
        ),
      ],
    );
  }
}
