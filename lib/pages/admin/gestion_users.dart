import 'package:flutter/material.dart';

import 'admin_management_tab.dart';
import 'doctor_management_tab.dart';
import 'pacientes/paciente_management_tab.dart';
// import 'admin_management_tab.dart'; // Tab para admins (opcional)
// Asume que tienes forma de saber el rol
// import 'auth_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bool _isSuperAdmin = true; // <-- Reemplaza con tu lógica de roles real

  @override
  void initState() {
    super.initState();
    // Ajusta length según si es SuperAdmin
    _tabController = TabController(length: _isSuperAdmin ? 3 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(icon: Icon(Icons.personal_injury), text: 'Pacientes'),
            const Tab(icon: Icon(Icons.medical_services), text: 'Doctores'),
            if (_isSuperAdmin) // Mostrar solo si es SuperAdmin
              const Tab(icon: Icon(Icons.admin_panel_settings), text: 'Admins'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const pacienteManagementTab(),
          const DoctorManagementTab(),
          if (_isSuperAdmin)
            // const Center(
            //   child: Text("Gestión de Admins (Placeholder)"),
            // ), // Reemplazar con AdminManagementTab
            const AdminManagementTab(), // Descomentar cuando AdminManagementTab esté listo
          // const AdminManagementTab(),
        ],
      ),
    );
  }
}

/* import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_salud_materna/models/modelos.dart';
import 'create_user_form.dart';

// --- Breakpoints (Sin cambios) ---
const double _kTabletBreakpoint = 600.0;
// const double _kDesktopBreakpoint = 900.0;

// --- Tipos para Ordenación y Vista ---
enum UserSortCriteria { creationDateDesc, creationDateAsc, nameAsc, role }

enum UserViewType { list, grid, compactList }

// --- Modelo ManagedUser (Sin cambios) ---
class ManagedUser {
  // ... (Todo el código del modelo ManagedUser como antes) ...
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String? phoneNumber;
  final bool disabled;
  final DateTime? creationTime;
  final DateTime? lastSignInTime;
  final List<Map<String, dynamic>> providerData;
  final Map<String, dynamic>? customClaims;
  Doctor? doctorProfile;
  Paciente? pacienteProfile;
  String? profileType;
  ManagedUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.phoneNumber,
    required this.disabled,
    this.creationTime,
    this.lastSignInTime,
    required this.providerData,
    this.customClaims,
    this.doctorProfile,
    this.pacienteProfile,
    this.profileType,
  });
  factory ManagedUser.fromMap(Map<String, dynamic> map) {
    DateTime? parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return null;
      if (timestamp is String) return DateTime.tryParse(timestamp)?.toLocal();
      if (timestamp is Map && timestamp.containsKey('_seconds')) {
        return Timestamp(timestamp['_seconds'], timestamp['_nanoseconds'] ?? 0).toDate().toLocal();
      }
      if (timestamp is Timestamp) return timestamp.toDate().toLocal();
      return null;
    }

    Map<String, dynamic>? safelyCastMap(dynamic mapData) {
      if (mapData == null || mapData is! Map) {
        return null;
      }
      final Map<String, dynamic> safeMap = {};
      mapData.forEach((key, value) {
        if (key is String) {
          safeMap[key] = value;
        }
      });
      return safeMap.isNotEmpty ? safeMap : null;
    }

    List<Map<String, dynamic>> safelyCastProviderList(dynamic listData) {
      if (listData == null || listData is! List) {
        return [];
      }
      final List<Map<String, dynamic>> safeList = [];
      for (var item in listData) {
        if (item is Map) {
          final safeItemMap = safelyCastMap(item);
          if (safeItemMap != null) {
            safeList.add(safeItemMap);
          }
        }
      }
      return safeList;
    }

    return ManagedUser(
      uid: map['uid'] ?? 'missing_uid_${DateTime.now().millisecondsSinceEpoch}',
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      photoURL: map['photoURL'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      disabled: (map['disabled'] ?? false) as bool,
      creationTime: parseTimestamp(map['creationTime']),
      lastSignInTime: parseTimestamp(map['lastSignInTime']),
      providerData: safelyCastProviderList(map['providerData']),
      customClaims: safelyCastMap(map['customClaims']),
    );
  }
  ManagedUser withProfile(dynamic profile, String type) {
    if (type == 'doctor' && profile is Doctor) {
      doctorProfile = profile;
      profileType = 'doctor';
    } else if (type == 'paciente' && profile is Paciente) {
      pacienteProfile = profile;
      profileType = 'paciente';
    } else {
      profileType = 'unknown';
    }
    return this;
  }

  bool get isSuperadmin => customClaims?['superadmin'] == true;
  bool get isAdmin => customClaims?['admin'] == true && !isSuperadmin;
  bool get isDoctor => customClaims?['role'] == 'doctor';
  bool get isPaciente => customClaims?['role'] == 'paciente';
  String get roleLabel {
    if (isSuperadmin) return 'Superadmin';
    if (isAdmin) return 'Admin';
    if (isDoctor) return 'Doctor';
    if (isPaciente) return 'Paciente';
    return 'Usuario';
  }

  // Helper para obtener el nombre de perfil para ordenar/buscar
  String get profileSortName {
    String name = displayName ?? email ?? uid; // Fallback
    if (isDoctor && doctorProfile?.nombre != null)
      name = doctorProfile!.nombre!;
    else if (isPaciente && pacienteProfile?.nombre != null)
      name = pacienteProfile!.nombre!;
    return name.toLowerCase(); // Siempre en minúsculas para ordenación insensible
  }
}

class SuperAdminUserManagement extends StatefulWidget {
  const SuperAdminUserManagement({super.key});
  @override
  State<SuperAdminUserManagement> createState() => _SuperAdminUserManagementState();
}

class _SuperAdminUserManagementState extends State<SuperAdminUserManagement> {
  // --- Variables de estado ---
  bool _isLoading = true;
  String? _error;
  List<ManagedUser> _allUsers = []; // Lista original sin filtrar/ordenar
  List<ManagedUser> _filteredUsers = []; // Lista mostrada en la UI
  String? _nextPageToken;
  bool _isLoadingMore = false;
  bool _currentUserIsSuperAdmin = false;
  bool _currentUserIsAdmin = false;

  // --- Estado para controles ---
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  UserSortCriteria _sortCriteria = UserSortCriteria.creationDateDesc; // Orden por defecto
  UserViewType _viewType = UserViewType.list; // Vista por defecto
  String?
  _filterRole; // Para filtrar por rol ('doctor', 'paciente', 'admin', 'superadmin', null para todos)

  // Instancias de Firebase
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged); // Escuchar cambios en búsqueda
    _checkPermissionsAndLoadUsers();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // --- Listener de Búsqueda ---
  void _onSearchChanged() {
    if (_searchTerm != _searchController.text.trim()) {
      setState(() {
        _searchTerm = _searchController.text.trim();
        _applyFiltersAndSort(); // Aplicar filtros/orden cada vez que cambia la búsqueda
      });
    }
  }

  // --- Lógica Principal: Carga, Filtro y Ordenación ---

  Future<void> _checkPermissionsAndLoadUsers() async {
    // ... (código anterior sin cambios) ...
    setState(() {
      _isLoading = true;
      _error = null;
      _currentUserIsAdmin = false;
      _currentUserIsSuperAdmin = false;
      _allUsers = [];
      _filteredUsers = [];
    });
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("Usuario no autenticado.");
      print('Verificando permisos para UID: ${currentUser.uid}");');
      final idTokenResult = await currentUser.getIdTokenResult(true);
      final claims = idTokenResult.claims ?? {};
      print('Claims obtenidos: $claims');
      _currentUserIsSuperAdmin = claims['superadmin'] == true;
      _currentUserIsAdmin = claims['admin'] == true && !_currentUserIsSuperAdmin;
      if (_currentUserIsSuperAdmin || _currentUserIsAdmin) {
        print('Permiso Admin/Superadmin confirmado.');
        setState(() {});
        await _loadUsers(initialLoad: true);
      } else {
        print('Permiso Admin/Superadmin DENEGADO.');
        setState(() {
          _error = "Acceso denegado.";
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error verificando permisos: $e");
      setState(() {
        _error = "Error verificando permisos: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsers({bool loadMore = false, bool initialLoad = false}) async {
    if (!_currentUserIsSuperAdmin && !_currentUserIsAdmin) return;
    if (_isLoadingMore) return;

    setState(() {
      if (loadMore)
        _isLoadingMore = true;
      else if (initialLoad)
        _isLoading = true;
      _error = null;
    });

    print(loadMore ? "Cargando más..." : "Cargando usuarios...");
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("Usuario deslogueado.");
      await currentUser.getIdTokenResult(true);

      final HttpsCallable callable = _functions.httpsCallable('manageAuthUser');
      final params = <String, dynamic>{
        'action': 'list',
        'pageSize': 50,
      }; // Cargar más para reducir llamadas
      if (loadMore && _nextPageToken != null) {
        params['pageToken'] = _nextPageToken;
      }

      final HttpsCallableResult result = await callable.call(params);
      final List<dynamic> userList = result.data['users'] ?? [];
      final String? nextPageToken = result.data['nextPageToken'];
      print("Respuesta 'list': ${userList.length} usuarios, nextPageToken: $nextPageToken");

      List<ManagedUser> newUsers = [];
      for (var userData in userList) {
        // ... (Parseo y búsqueda de perfil como en la respuesta anterior) ...
        if (userData is Map) {
          try {
            final Map<String, dynamic> userDataMap = Map<String, dynamic>.from(userData);
            ManagedUser managedUser = ManagedUser.fromMap(userDataMap);
            try {
              DocumentSnapshot doctorDoc =
                  await _firestore.collection('doctores').doc(managedUser.uid).get();
              if (doctorDoc.exists) {
                managedUser = managedUser.withProfile(Doctor.fromDocument(doctorDoc), 'doctor');
              } else {
                DocumentSnapshot pacienteDoc =
                    await _firestore.collection('pacientes').doc(managedUser.uid).get();
                if (pacienteDoc.exists) {
                  managedUser = managedUser.withProfile(
                    Paciente.fromJson(pacienteDoc.data() as Map<String, dynamic>),
                    'paciente',
                  );
                } else {
                  if (managedUser.isSuperadmin) {
                    managedUser.profileType = 'superadmin';
                  } else if (managedUser.isAdmin) {
                    managedUser.profileType = 'admin';
                  } else {
                    managedUser = managedUser.withProfile(null, 'unknown');
                  }
                }
              }
            } catch (profileError) {
              print("Error buscando perfil ${managedUser.uid}: $profileError");
              if (managedUser.isSuperadmin) {
                managedUser.profileType = 'superadmin';
              } else if (managedUser.isAdmin) {
                managedUser.profileType = 'admin';
              } else {
                managedUser.profileType = 'unknown';
              }
            }
            newUsers.add(managedUser);
          } catch (e, stacktrace) {
            print("Error procesando mapa/fromMap: $userData\n$e\n$stacktrace");
          }
        } else {
          print("Elemento NO Mapa: ${userData.runtimeType}");
        }
      }

      setState(() {
        if (loadMore) {
          _allUsers.addAll(newUsers); // Añadir a la lista completa
        } else {
          _allUsers = newUsers; // Reemplazar la lista completa
        }
        _nextPageToken = nextPageToken;
        _applyFiltersAndSort(); // Aplicar filtros y orden a la nueva lista
      });
    } on FirebaseFunctionsException catch (e) {
      /* ... (manejo error) ... */
      print("Error función 'list': ${e.code} - ${e.message}");
      setState(() {
        _error = "Error cargando (${e.code}): ${e.message}";
      });
    } catch (e) {
      /* ... (manejo error) ... */
      print("Error desconocido cargando: $e");
      setState(() {
        _error = "Error inesperado: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  // --- Aplicar Filtros y Ordenación ---
  void _applyFiltersAndSort() {
    List<ManagedUser> result = List.from(_allUsers); // Copiar la lista original

    // 1. Filtrar por Rol (si hay filtro activo)
    if (_filterRole != null) {
      result =
          result.where((user) {
            switch (_filterRole) {
              case 'superadmin':
                return user.isSuperadmin;
              case 'admin':
                return user.isAdmin;
              case 'doctor':
                return user.isDoctor;
              case 'paciente':
                return user.isPaciente;
              default:
                return true; // Si el filtro es inválido, no filtrar
            }
          }).toList();
    }

    // 2. Filtrar por Término de Búsqueda
    if (_searchTerm.isNotEmpty) {
      final lowerCaseSearchTerm = _searchTerm.toLowerCase();
      result =
          result.where((user) {
            final nameMatch = user.profileSortName.contains(lowerCaseSearchTerm);
            final emailMatch = user.email?.toLowerCase().contains(lowerCaseSearchTerm) ?? false;
            final uidMatch = user.uid.toLowerCase().contains(lowerCaseSearchTerm);
            return nameMatch || emailMatch || uidMatch;
          }).toList();
    }

    // 3. Ordenar
    result.sort((a, b) {
      switch (_sortCriteria) {
        case UserSortCriteria.nameAsc:
          return a.profileSortName.compareTo(b.profileSortName);
        case UserSortCriteria.role:
          // Ordenar por rol (Superadmin > Admin > Doctor > Paciente > Otros)
          int roleValue(ManagedUser u) {
            if (u.isSuperadmin) return 0;
            if (u.isAdmin) return 1;
            if (u.isDoctor) return 2;
            if (u.isPaciente) return 3;
            return 4; // Otros roles/desconocidos al final
          }
          final roleComparison = roleValue(a).compareTo(roleValue(b));
          // Si los roles son iguales, ordenar por nombre
          if (roleComparison == 0) return a.profileSortName.compareTo(b.profileSortName);
          return roleComparison;
        case UserSortCriteria.creationDateAsc:
          final dateA = a.creationTime ?? DateTime(1970); // Fecha muy antigua si es null
          final dateB = b.creationTime ?? DateTime(1970);
          return dateA.compareTo(dateB);
        case UserSortCriteria.creationDateDesc:
          // Por defecto, fecha de creación descendente
          final dateA = a.creationTime ?? DateTime(1970);
          final dateB = b.creationTime ?? DateTime(1970);
          return dateB.compareTo(dateA); // Invertido para descendente
      }
    });

    // Actualizar la lista filtrada que se muestra en la UI
    // No necesitamos setState aquí si esta función se llama desde otros setState
    _filteredUsers = result;

    // Si estamos en un setState, no necesitamos otro. Si no, sí.
    // Para asegurar que la UI se actualice si se llama fuera de un setState:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // --- _callManageUserFunction, Acciones, Helpers UI (sin cambios estructurales) ---
  Future<void> _callManageUserFunction(
    String action, {
    String? uid,
    Map<String, dynamic>? createData,
    Map<String, dynamic>? updateData,
  }) async {
    /* ... (código anterior) ... */
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showErrorSnackBar('Error: Usuario no autenticado.');
      return;
    }
    String processingMessage = 'Ejecutando "$action"...';
    if (uid != null) processingMessage += ' para UID: $uid';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(processingMessage), duration: Duration(seconds: 2)));
    try {
      await currentUser.getIdTokenResult(true);
      final HttpsCallable callable = _functions.httpsCallable('manageAuthUser');
      final params = <String, dynamic>{'action': action};
      if (uid != null) params['uid'] = uid;
      if (createData != null) params['createData'] = createData;
      if (updateData != null) params['updateData'] = updateData;
      final HttpsCallableResult result = await callable.call(params);
      _showSuccessSnackBar(result.data['message'] ?? '$action exitoso.');
      await _loadUsers();
    } on FirebaseFunctionsException catch (e) {
      _showErrorSnackBar('Error al $action (${e.code}): ${e.message ?? "Detalles no disponibles"}');
    } catch (e) {
      _showErrorSnackBar('Error inesperado al $action: ${e.toString()}');
    }
  }

  Future<void> _toggleUserStatus(ManagedUser user) async {
    /* ... (código anterior) ... */
    final bool disable = !user.disabled;
    if (user.isSuperadmin) {
      _showErrorSnackBar("Superadmin no puede ser habilitado/deshabilitado.");
      return;
    }
    if (user.isAdmin && !_currentUserIsSuperAdmin) {
      _showErrorSnackBar("Solo Superadmins pueden habilitar/deshabilitar Admins.");
      return;
    }
    final confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text(disable ? 'Deshabilitar' : 'Habilitar'),
                content: Text('¿Seguro?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      disable ? 'Deshabilitar' : 'Habilitar',
                      style: TextStyle(color: disable ? Colors.orange : Colors.green),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
    if (confirm) {
      _callManageUserFunction('update', uid: user.uid, updateData: {'disabled': disable});
    }
  }

  Future<void> _deleteUser(ManagedUser user) async {
    /* ... (código anterior) ... */
    if (user.isSuperadmin) {
      _showErrorSnackBar("Superadmin no puede ser eliminado.");
      return;
    }
    if (user.isAdmin && !_currentUserIsSuperAdmin) {
      _showErrorSnackBar("Solo Superadmins pueden eliminar Admins.");
      return;
    }
    final confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text('Eliminar Permanentemente'),
                content: Text('¡ADVERTENCIA!\nIrreversible. ¿SEGURO?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      'Sí, Eliminar',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
    if (confirm) {
      _callManageUserFunction('delete', uid: user.uid);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(text: '$label ', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value ?? 'No disponible'),
          ],
        ),
      ),
    );
  }

  void _showUserDetailsDialog(ManagedUser user) {
    /* ... (código anterior) ... */
    bool isSelf = user.uid == _auth.currentUser?.uid;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Detalles ${isSelf ? "(Tú)" : ""}'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  _detailRow('Rol Principal:', user.roleLabel),
                  _detailRow('UID:', user.uid),
                  _detailRow('Email Auth:', user.email),
                  _detailRow('Teléfono Auth:', user.phoneNumber),
                  _detailRow('Nombre Display Auth:', user.displayName),
                  _detailRow('Deshabilitado:', user.disabled.toString()),
                  _detailRow('Creado:', user.creationTime?.toString()),
                  _detailRow('Último Login:', user.lastSignInTime?.toString()),
                  Divider(),
                  Text('Proveedores:', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (user.providerData.isEmpty) Text('  Ninguno'),
                  ...user.providerData.map(
                    (p) => Text('  - ${p['providerId']} (${p['email'] ?? 'N/A'})'),
                  ),
                  Divider(),
                  Text('Claims:', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (user.customClaims == null || user.customClaims!.isEmpty) Text('  Ninguno'),
                  ...?user.customClaims?.entries.map((e) => Text('  - ${e.key}: ${e.value}')),
                  if (!user.isAdmin &&
                      !user.isSuperadmin &&
                      user.profileType == 'doctor' &&
                      user.doctorProfile != null) ...[
                    Divider(),
                    Text('Detalles Doctor:', style: TextStyle(fontWeight: FontWeight.bold)),
                    _detailRow('Especialidad:', user.doctorProfile!.especialidades![0]),
                  ],
                  if (!user.isAdmin &&
                      !user.isSuperadmin &&
                      user.profileType == 'paciente' &&
                      user.pacienteProfile != null) ...[
                    Divider(),
                    Text('Detalles Paciente:', style: TextStyle(fontWeight: FontWeight.bold)),
                    _detailRow(
                      'Semanas Gestación:',
                      user.pacienteProfile!.semanasGestacion.toString(),
                    ),
                  ],
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cerrar'))],
          ),
    );
  }

  // --- Métodos para construir la UI (Actualizados/Nuevos) ---

  // Construye la barra de controles (Búsqueda, Filtro, Orden, Vista)
  Widget _buildControlBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Wrap(
        // Wrap se adapta mejor a diferentes anchos
        spacing: 15.0, // Espacio horizontal
        runSpacing: 10.0, // Espacio vertical si se envuelve
        alignment: WrapAlignment.spaceBetween, // Intenta espaciar uniformemente
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // --- Buscador ---
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 300), // Limitar ancho del buscador
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, email, UID...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true, // Más compacto
                suffixIcon:
                    _searchTerm.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear(); // Llama a _onSearchChanged
                          },
                        )
                        : null,
              ),
            ),
          ),

          // --- Controles de Orden, Filtro y Vista ---
          Row(
            // Agrupar los botones
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Filtrar por Rol ---
              PopupMenuButton<String?>(
                initialValue: _filterRole,
                onSelected: (String? newValue) {
                  if (_filterRole != newValue) {
                    setState(() {
                      _filterRole = newValue;
                      _applyFiltersAndSort();
                    });
                  }
                },
                icon: Icon(Icons.filter_list, semanticLabel: 'Filtrar por rol'),
                tooltip: 'Filtrar por rol',
                itemBuilder:
                    (BuildContext context) => <PopupMenuEntry<String?>>[
                      const PopupMenuItem<String?>(value: null, child: Text('Todos los roles')),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String?>(value: 'superadmin', child: Text('Superadmin')),
                      const PopupMenuItem<String?>(value: 'admin', child: Text('Admin')),
                      const PopupMenuItem<String?>(value: 'doctor', child: Text('Doctor')),
                      const PopupMenuItem<String?>(value: 'paciente', child: Text('Paciente')),
                    ],
              ),
              // Mostrar filtro activo
              if (_filterRole != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Chip(
                    label: Text(
                      _filterRole![0].toUpperCase() + _filterRole!.substring(1),
                    ), // Capitalizar
                    onDeleted: () {
                      setState(() {
                        _filterRole = null;
                        _applyFiltersAndSort();
                      });
                    },
                    deleteIconColor: Theme.of(context).colorScheme.onSecondary,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ),

              // --- Ordenar ---
              PopupMenuButton<UserSortCriteria>(
                initialValue: _sortCriteria,
                onSelected: (UserSortCriteria newValue) {
                  if (_sortCriteria != newValue) {
                    setState(() {
                      _sortCriteria = newValue;
                      _applyFiltersAndSort();
                    });
                  }
                },
                icon: Icon(Icons.sort_by_alpha, semanticLabel: 'Ordenar usuarios'),
                tooltip: 'Ordenar por...',
                itemBuilder:
                    (BuildContext context) => <PopupMenuEntry<UserSortCriteria>>[
                      const PopupMenuItem<UserSortCriteria>(
                        value: UserSortCriteria.creationDateDesc,
                        child: Text('Más recientes primero'),
                      ),
                      const PopupMenuItem<UserSortCriteria>(
                        value: UserSortCriteria.creationDateAsc,
                        child: Text('Más antiguos primero'),
                      ),
                      const PopupMenuItem<UserSortCriteria>(
                        value: UserSortCriteria.nameAsc,
                        child: Text('Nombre (A-Z)'),
                      ),
                      const PopupMenuItem<UserSortCriteria>(
                        value: UserSortCriteria.role,
                        child: Text('Rol'),
                      ),
                    ],
              ),

              // --- Cambiar Vista ---
              PopupMenuButton<UserViewType>(
                initialValue: _viewType,
                onSelected: (UserViewType newValue) {
                  if (_viewType != newValue) {
                    setState(() {
                      _viewType = newValue;
                    });
                  }
                },
                icon: Icon(
                  _viewType == UserViewType.list
                      ? Icons.view_list_outlined
                      : _viewType == UserViewType.grid
                      ? Icons.grid_view_outlined
                      : Icons.view_headline_outlined, // Icono para compacta
                  semanticLabel: 'Cambiar vista',
                ),
                tooltip: 'Cambiar tipo de vista',
                itemBuilder:
                    (BuildContext context) => <PopupMenuEntry<UserViewType>>[
                      const PopupMenuItem<UserViewType>(
                        value: UserViewType.list,
                        child: ListTile(
                          leading: Icon(Icons.view_list_outlined),
                          title: Text('Lista Detallada'),
                        ),
                      ),
                      const PopupMenuItem<UserViewType>(
                        value: UserViewType.grid,
                        child: ListTile(
                          leading: Icon(Icons.grid_view_outlined),
                          title: Text('Cuadrícula'),
                        ),
                      ),
                      const PopupMenuItem<UserViewType>(
                        value: UserViewType.compactList,
                        child: ListTile(
                          leading: Icon(Icons.view_headline_outlined),
                          title: Text('Lista Compacta'),
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Construye un item para la ListView (móvil) - Sin cambios
  Widget _buildUserListItem(ManagedUser user) {
    /* ... (código anterior) ... */
    final bool isSelf = user.uid == _auth.currentUser?.uid;
    String profileName = _getProfileName(user);
    IconData leadingIcon = _getLeadingIcon(user);
    String profileTypeLabel = user.roleLabel;
    bool canToggle = _canPerformAction(user, 'toggle');
    bool canDelete = _canPerformAction(user, 'delete');
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              user.disabled
                  ? Colors.grey.shade300
                  : Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            leadingIcon,
            color:
                user.disabled
                    ? Colors.grey.shade600
                    : Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(
          '$profileName ${isSelf ? "(Tú)" : ""} ${user.disabled ? "[Deshabilitado]" : ""}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: user.disabled ? Colors.grey.shade600 : null,
          ),
        ),
        subtitle: Text(
          '${user.email ?? 'Sin email'}\n$profileTypeLabel',
          style: TextStyle(color: user.disabled ? Colors.grey.shade500 : Colors.grey.shade700),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                user.disabled ? Icons.toggle_off_outlined : Icons.toggle_on,
                color: user.disabled ? Colors.grey : Colors.green.shade600,
              ),
              tooltip: user.disabled ? 'Habilitar' : 'Deshabilitar',
              onPressed: canToggle ? () => _toggleUserStatus(user) : null,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
              tooltip: 'Eliminar',
              onPressed: canDelete ? () => _deleteUser(user) : null,
            ),
          ],
        ),
        onTap: () => _showUserDetailsDialog(user),
      ),
    );
  }

  // Construye un item para la GridView (tablet/web) - Sin cambios
  Widget _buildUserGridItem(ManagedUser user) {
    /* ... (código anterior) ... */
    final bool isSelf = user.uid == _auth.currentUser?.uid;
    String profileName = _getProfileName(user);
    IconData leadingIcon = _getLeadingIcon(user);
    String profileTypeLabel = user.roleLabel;
    bool canToggle = _canPerformAction(user, 'toggle');
    bool canDelete = _canPerformAction(user, 'delete');
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => _showUserDetailsDialog(user),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor:
                    user.disabled
                        ? Colors.grey.shade300
                        : Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  leadingIcon,
                  size: 30,
                  color:
                      user.disabled
                          ? Colors.grey.shade600
                          : Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '$profileName ${isSelf ? "(Tú)" : ""}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: user.disabled ? Colors.grey.shade600 : null,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                profileTypeLabel + (user.disabled ? " [Desh.]" : ""),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: user.disabled ? Colors.grey.shade500 : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                user.email ?? 'Sin email',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Spacer(),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(user.disabled ? Icons.toggle_off_outlined : Icons.toggle_on),
                    color: user.disabled ? Colors.grey : Colors.green.shade600,
                    tooltip: user.disabled ? 'Habilitar' : 'Deshabilitar',
                    onPressed: canToggle ? () => _toggleUserStatus(user) : null,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline),
                    color: Colors.red.shade700,
                    tooltip: 'Eliminar',
                    onPressed: canDelete ? () => _deleteUser(user) : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- NUEVO: Construye un item para la Vista Compacta ---
  Widget _buildUserCompactItem(ManagedUser user) {
    final bool isSelf = user.uid == _auth.currentUser?.uid;
    String profileName = _getProfileName(user);
    IconData leadingIcon = _getLeadingIcon(user);
    String profileTypeLabel = user.roleLabel;
    bool canToggle = _canPerformAction(user, 'toggle');
    bool canDelete = _canPerformAction(user, 'delete');

    return ListTile(
      leading: Icon(
        leadingIcon,
        color: user.disabled ? Colors.grey.shade600 : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        '$profileName ${isSelf ? "(Tú)" : ""} ${user.disabled ? "[Deshabilitado]" : ""}',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: user.disabled ? Colors.grey.shade600 : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${user.email ?? 'Sin email'} - $profileTypeLabel',
        style: TextStyle(color: user.disabled ? Colors.grey.shade500 : Colors.grey.shade700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        // Mantener acciones pero más compactas
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(user.disabled ? Icons.toggle_off_outlined : Icons.toggle_on),
            iconSize: 20, // Icono más pequeño
            color: user.disabled ? Colors.grey : Colors.green.shade600,
            tooltip: user.disabled ? 'Habilitar' : 'Deshabilitar',
            onPressed: canToggle ? () => _toggleUserStatus(user) : null,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline),
            iconSize: 20, // Icono más pequeño
            color: Colors.red.shade700,
            tooltip: 'Eliminar',
            onPressed: canDelete ? () => _deleteUser(user) : null,
          ),
        ],
      ),
      onTap: () => _showUserDetailsDialog(user),
      dense: true, // Hacer el ListTile más compacto
    );
  }

  // --- Helpers para obtener datos del usuario (sin cambios) ---
  String _getProfileName(ManagedUser user) {
    if (user.isSuperadmin) return user.displayName ?? user.email ?? 'Superadmin';
    if (user.isAdmin) return user.displayName ?? user.email ?? 'Admin';
    if (user.isDoctor) return user.doctorProfile?.nombre ?? user.displayName ?? '(Dr)';
    if (user.isPaciente) return user.pacienteProfile?.nombre ?? user.displayName ?? '(Pcte)';
    return user.displayName ?? user.email ?? '(Desc)';
  }

  IconData _getLeadingIcon(ManagedUser user) {
    if (user.isSuperadmin) return Icons.shield;
    if (user.isAdmin) return Icons.admin_panel_settings;
    if (user.isDoctor) return Icons.medical_services_outlined;
    if (user.isPaciente) return Icons.pregnant_woman_outlined;
    return Icons.person_outline;
  }

  bool _canPerformAction(ManagedUser targetUser, String actionType) {
    final bool isSelf = targetUser.uid == _auth.currentUser?.uid;
    if (isSelf) return false;
    if (_currentUserIsSuperAdmin) {
      return !targetUser.isSuperadmin;
    } else if (_currentUserIsAdmin) {
      return !targetUser.isSuperadmin && !targetUser.isAdmin;
    }
    return false;
  }

  // --- Widget Principal Build (ACTUALIZADO) ---
  @override
  Widget build(BuildContext context) {
    // ... (Manejo inicial de loading y permisos sin cambios) ...
    if (_isLoading && _error == null && !_currentUserIsAdmin && !_currentUserIsSuperAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text('Gestión Usuarios')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [CircularProgressIndicator(), SizedBox(height: 10), Text('Verificando...')],
          ),
        ),
      );
    }
    if (!_currentUserIsAdmin && !_currentUserIsSuperAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text('Gestión Usuarios')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _error ?? 'Acceso Denegado',
              style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Determinar si mostrar FAB o botón en AppBar
    final screenWidth = MediaQuery.of(context).size.width;
    final bool showFab = screenWidth < _kTabletBreakpoint; // Mostrar FAB en pantallas pequeñas

    // Construir cuerpo principal (Lista, Grid o Compacta) basado en _viewType
    Widget mainContentBody;
    if (_isLoading) {
      mainContentBody = Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      mainContentBody = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_error!, style: TextStyle(color: Colors.red)),
        ),
      );
    } else if (_filteredUsers.isEmpty && _searchTerm.isNotEmpty) {
      mainContentBody = Center(child: Text('No se encontraron usuarios para "$_searchTerm".'));
    } else if (_filteredUsers.isEmpty) {
      mainContentBody = Center(
        child: Text(
          'No hay usuarios para mostrar${_filterRole != null ? ' con el filtro actual.' : '.'}',
        ),
      );
    } else {
      // Decidir qué vista usar
      switch (_viewType) {
        case UserViewType.grid:
          mainContentBody = _buildGridView();
          break;
        case UserViewType.compactList:
          mainContentBody = _buildCompactListView(); // Usar nuevo builder
          break;
        case UserViewType.list:
          mainContentBody = _buildListView();
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Usuarios (${_filteredUsers.length})'), // Mostrar contador
        actions: [
          // Mostrar botón de crear en AppBar si NO es pantalla pequeña
          if (!showFab)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navegar a la pantalla de creación
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateUserScreen()),
                  );
                },
                icon: Icon(Icons.add),
                label: Text('Crear'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed:
                (_isLoading || _isLoadingMore)
                    ? null
                    : () => _loadUsers(initialLoad: true), // Forzar recarga inicial
            tooltip: 'Recargar Todo',
          ),
        ],
      ),
      floatingActionButton:
          showFab
              ? FloatingActionButton(
                onPressed: () {
                  // Navegar a la pantalla de creación
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateUserScreen()),
                  );
                },
                tooltip: 'Crear Usuario',
                child: Icon(Icons.add),
              )
              : null, // Ocultar FAB en pantallas grandes
      body: Column(
        // Columna para barra de controles + lista/grid
        children: [
          _buildControlBar(), // Añadir barra de controles
          Divider(height: 1), // Separador visual
          Expanded(
            // Hacer que la lista/grid ocupe el espacio restante
            child: RefreshIndicator(
              onRefresh: () => _loadUsers(initialLoad: true), // Refrescar TODO
              child: mainContentBody,
            ),
          ),
        ],
      ),
    );
  }

  // --- Builder para ListView (sin cambios) ---
  Widget _buildListView() {
    /* ... (código anterior) ... */
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _filteredUsers.length + (_nextPageToken != null && !_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredUsers.length && _nextPageToken != null) {
          return _buildLoadMoreIndicator();
        }
        if (index >= _filteredUsers.length) return const SizedBox.shrink();
        return _buildUserListItem(_filteredUsers[index]);
      },
    );
  }

  // --- Builder para GridView (sin cambios) ---
  Widget _buildGridView() {
    /* ... (código anterior) ... */
    const double maxCrossAxisExtent = 350.0;
    return GridView.builder(
      padding: const EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        childAspectRatio: 2 / 2.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _filteredUsers.length + (_nextPageToken != null && !_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredUsers.length && _nextPageToken != null) {
          return _buildLoadMoreIndicator();
        }
        if (index >= _filteredUsers.length) return const SizedBox.shrink();
        return _buildUserGridItem(_filteredUsers[index]);
      },
    );
  }

  // --- NUEVO: Builder para Lista Compacta ---
  Widget _buildCompactListView() {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _filteredUsers.length + (_nextPageToken != null && !_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredUsers.length && _nextPageToken != null) {
          return _buildLoadMoreIndicator();
        }
        if (index >= _filteredUsers.length) return const SizedBox.shrink();
        // Item compacto
        return _buildUserCompactItem(_filteredUsers[index]);
      },
      separatorBuilder:
          (context, index) =>
              Divider(height: 1, indent: 16, endIndent: 16), // Separador entre items
    );
  }

  // --- Widget común para "Cargar más" (sin cambios) ---
  Widget _buildLoadMoreIndicator() {
    /* ... (código anterior) ... */
    return _isLoadingMore
        ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: CircularProgressIndicator(),
          ),
        )
        : Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: OutlinedButton(
              onPressed: () => _loadUsers(loadMore: true),
              child: Text('Cargar más'),
            ),
          ),
        );
  }
} */
