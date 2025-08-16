// gestion_users.dart
// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/modelos.dart';
import '../../services/firestore_service.dart';

import 'admin_management_tab.dart';
import 'create_user_form.dart';
import 'doctores/doctor_management_tab.dart';
import 'pacientes/paciente_management_tab.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bool _isSuperAdmin = true; // <-- Reemplaza con tu lógica de roles real
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _searchController = TextEditingController();
  List<Usuario> _allUsers = [];
  bool _isLoadingUsers = true;
  String _searchTerm = '';
  UserViewType _currentViewType = UserViewType.grid; // Estado para vista lista/grid

  // --- NUEVO: Estado para agrupación por riesgo ---
  bool _isGroupedByRisk = false;
  // -------------------------------------------

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _isSuperAdmin ? 3 : 2, vsync: this);
    // --- NUEVO: Listener para mostrar/ocultar botón de agrupar ---
    _tabController.addListener(() {
      // Forzar actualización de UI para que el botón aparezca/desaparezca
      if (mounted) {
        setState(() {});
      }
    });
    // -----------------------------------------------------------
    _loadAllUsersForAutocomplete();
  }

  @override
  void dispose() {
    _tabController.removeListener(() {
      if (mounted) setState(() {});
    }); // Limpiar listener
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsersForAutocomplete() async {
    setState(() => _isLoadingUsers = true);
    try {
      final List<Usuario> pacientes = await _firestoreService.getAllpacientesStream().first;
      final List<Usuario> doctores = await _firestoreService.getAllDoctorsStream().first;
      List<Usuario> admins = [];
      if (_isSuperAdmin) {
        admins = await _firestoreService.getAllAdminsStream().first;
      }
      final Map<String, Usuario> userMap = {};
      for (var user in [...pacientes, ...doctores, ...admins]) {
        userMap[user.uid] = user;
      }
      setState(() {
        _allUsers = userMap.values.toList();
        _isLoadingUsers = false;
      });
    } catch (e) {
      if (kDebugMode) print("Error cargando usuarios para autocomplete: $e");
      setState(() => _isLoadingUsers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar lista de usuarios: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateSearchTerm(String term) {
    if (_searchTerm != term) {
      setState(() {
        _searchTerm = term;
      });
    }
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
            if (_isSuperAdmin) const Tab(icon: Icon(Icons.admin_panel_settings), text: 'Admins'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 8.0, 10), // Ajusta padding derecho
            child: Row(
              children: [
                Expanded(
                  child: Autocomplete<Usuario>(
                    // ... (Código del Autocomplete sin cambios) ...
                    fieldViewBuilder: (
                      BuildContext context,
                      TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted,
                    ) {
                      // Usamos nuestro controlador para poder limpiarlo desde fuera si es necesario
                      // y sincronizamos bidireccionalmente si cambia internamente
                      if (_searchController.text != fieldTextEditingController.text) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _searchController.text = fieldTextEditingController.text;
                        });
                      }

                      return TextField(
                        controller: fieldTextEditingController, // Usa el controlador interno
                        focusNode: fieldFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Buscar usuario...',
                          prefixIcon:
                              _isLoadingUsers
                                  ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                  : const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).inputDecorationTheme.fillColor ??
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ), // Ajustar padding vertical
                          isDense: true, // Hace el campo un poco más compacto
                          suffixIcon:
                              fieldTextEditingController.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      fieldTextEditingController.clear();
                                      _updateSearchTerm('');
                                      _searchController.clear(); // Limpiar también el nuestro
                                      FocusScope.of(context).unfocus(); // Quitar foco
                                    },
                                  )
                                  : null,
                        ),
                        onChanged: (value) {
                          _updateSearchTerm(value);
                          _searchController.text = value; // Actualiza el nuestro
                        },
                        onSubmitted: (value) {
                          _updateSearchTerm(value);
                          _searchController.text = value;
                          onFieldSubmitted(); // Llama al callback original si es necesario
                        },
                      );
                    },
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (_isLoadingUsers) return const Iterable<Usuario>.empty();
                      final query = textEditingValue.text.toLowerCase();
                      if (query.isEmpty) return const Iterable<Usuario>.empty();
                      return _allUsers.where((Usuario user) {
                        return user.displayName.toLowerCase().contains(query) ||
                            user.email.toLowerCase().contains(query);
                      });
                    },
                    optionsViewBuilder: (
                      BuildContext context,
                      AutocompleteOnSelected<Usuario> onSelected,
                      Iterable<Usuario> options,
                    ) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 250,
                              maxWidth:
                                  MediaQuery.of(context).size.width - 40, // Ancho casi completo
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final Usuario option = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: ListTile(
                                    leading: Icon(
                                      option.roles.contains(UserRole.paciente)
                                          ? Icons.personal_injury_outlined
                                          : option.roles.contains(UserRole.doctor)
                                          ? Icons.medical_services_outlined
                                          : option.roles.contains(UserRole.admin)
                                          ? Icons.admin_panel_settings_outlined
                                          : Icons.person_outline,
                                      size: 20,
                                    ),
                                    title: Text(option.displayName),
                                    subtitle: Text(option.email),
                                    dense: true,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    displayStringForOption: (Usuario option) => option.displayName,
                    onSelected: (Usuario selection) {
                      if (kDebugMode) print('Seleccionaste: ${selection.displayName}');
                      _updateSearchTerm(selection.displayName);
                      _searchController.text =
                          selection.displayName; // Actualiza nuestro controlador
                      // Cierra el teclado/overlay
                      FocusScope.of(context).unfocus();
                      // Podrías querer navegar al detalle del usuario seleccionado aquí si lo deseas
                    },
                  ),
                ),
                // --- Botón para cambiar vista Lista/Grid ---
                IconButton(
                  icon: Icon(
                    _currentViewType == UserViewType.list
                        ? Icons.grid_view_outlined
                        : Icons.view_list_outlined,
                  ),
                  tooltip:
                      _currentViewType == UserViewType.list ? 'Vista Cuadrícula' : 'Vista Lista',
                  onPressed: () {
                    setState(() {
                      _currentViewType =
                          _currentViewType == UserViewType.list
                              ? UserViewType.grid
                              : UserViewType.list;
                    });
                  },
                ),
                // --- NUEVO: Botón para agrupar (condicional) ---
                if (_tabController.index == 0) // Mostrar solo en la pestaña Pacientes (índice 0)
                  IconButton(
                    icon: Icon(
                      _isGroupedByRisk ? Icons.list_alt : Icons.layers,
                      color: _isGroupedByRisk ? Theme.of(context).colorScheme.primary : null,
                    ),
                    tooltip: _isGroupedByRisk ? 'Vista Estándar' : 'Agrupar por Riesgo',
                    onPressed: () {
                      setState(() {
                        _isGroupedByRisk = !_isGroupedByRisk;
                      });
                    },
                  ),
                // ---------------------------------------------
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // --- Pasar ambos estados a las tabs ---
                PacienteManagementTab(
                  searchTerm: _searchTerm,
                  viewType: _currentViewType,
                  isGroupedByRisk: _isGroupedByRisk, // <-- Pasar estado de agrupación
                ),
                DoctorManagementTab(searchTerm: _searchTerm, viewType: _currentViewType),
                if (_isSuperAdmin)
                  AdminManagementTab(searchTerm: _searchTerm, viewType: _currentViewType),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateUserScreen()));
        },
        tooltip: 'Crear Usuario',
        child: const Icon(Icons.person_add_alt_1),
      ),
    );
  }
}


/* // gestion_users.dart
// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/modelos.dart'; // Importa tus modelos
import '../../services/firestore_service.dart'; // Importa tu servicio

import 'admin_management_tab.dart';
import 'create_user_form.dart';
import 'doctores/doctor_management_tab.dart';
import 'pacientes/paciente_management_tab.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bool _isSuperAdmin = true; // <-- Reemplaza con tu lógica de roles real
  final FirestoreService _firestoreService = FirestoreService();

  // Estados para búsqueda y autocompletado
  final TextEditingController _searchController = TextEditingController();
  List<Usuario> _allUsers = [];
  bool _isLoadingUsers = true;
  String _searchTerm = '';

  // --- NUEVO: Estado para el tipo de vista ---
  UserViewType _currentViewType = UserViewType.grid; // Vista inicial: Lista

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _isSuperAdmin ? 3 : 2, vsync: this);
    _loadAllUsersForAutocomplete();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsersForAutocomplete() async {
    // ... (código de carga sin cambios) ...
    setState(() => _isLoadingUsers = true);
    try {
      final List<Usuario> pacientes = await _firestoreService.getAllpacientesStream().first;
      final List<Usuario> doctores = await _firestoreService.getAllDoctorsStream().first;
      List<Usuario> admins = [];
      if (_isSuperAdmin) {
        admins = await _firestoreService.getAllAdminsStream().first;
      }
      final Map<String, Usuario> userMap = {};
      for (var user in [...pacientes, ...doctores, ...admins]) {
        userMap[user.uid] = user;
      }
      setState(() {
        _allUsers = userMap.values.toList();
        _isLoadingUsers = false;
      });
    } catch (e) {
      if (kDebugMode) print("Error cargando usuarios para autocomplete: $e");
      setState(() => _isLoadingUsers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar lista de usuarios: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateSearchTerm(String term) {
    // ... (código sin cambios) ...
    if (_searchTerm != term) {
      setState(() {
        _searchTerm = term;
      });
    }
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
            if (_isSuperAdmin) const Tab(icon: Icon(Icons.admin_panel_settings), text: 'Admins'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(30.0, 12.0, 12.0, 10), // Ajusta padding
            child: Row(
              // Usa Row para poner el botón al lado
              children: [
                // --- Campo Autocomplete (Expandido) ---
                Expanded(
                  child: Autocomplete<Usuario>(
                    fieldViewBuilder: (
                      BuildContext context,
                      TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted,
                    ) {
                      return TextField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Buscar usuario...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none, // Quita el borde si se prefiere
                          ),
                          filled: true, // Añade un fondo
                          fillColor:
                              Theme.of(context).inputDecorationTheme.fillColor ??
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                          suffixIcon:
                              fieldTextEditingController.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      fieldTextEditingController.clear();
                                      _updateSearchTerm('');
                                    },
                                  )
                                  : null,
                        ),
                        onChanged: (value) {
                          _updateSearchTerm(value);
                        },
                        onSubmitted: (_) => _updateSearchTerm(fieldTextEditingController.text),
                      );
                    },
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      // ... (código optionsBuilder sin cambios) ...
                      if (_isLoadingUsers) {
                        return const Iterable<Usuario>.empty();
                      }
                      final query = textEditingValue.text.toLowerCase();
                      if (query.isEmpty) {
                        return const Iterable<Usuario>.empty();
                      }
                      return _allUsers.where((Usuario user) {
                        return user.displayName.toLowerCase().contains(query) ||
                            user.email.toLowerCase().contains(query);
                      });
                    },
                    optionsViewBuilder: (
                      BuildContext context,
                      AutocompleteOnSelected<Usuario> onSelected,
                      Iterable<Usuario> options,
                    ) {
                      // ... (código optionsViewBuilder sin cambios) ...
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 250,
                              maxWidth: MediaQuery.of(context).size.width - 100,
                            ), // Ajusta maxWidth si es necesario
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final Usuario option = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: ListTile(
                                    title: Text(option.displayName),
                                    subtitle: Text(option.email),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    displayStringForOption: (Usuario option) => option.displayName,
                    onSelected: (Usuario selection) {
                      // ... (código onSelected sin cambios) ...
                      if (kDebugMode) print('Seleccionaste: ${selection.displayName}');
                      _updateSearchTerm(selection.displayName);
                      // Opcional: Limpiar el campo después de seleccionar
                      // FocusScope.of(context).unfocus(); // Quita el foco
                      // Future.delayed(Duration(milliseconds: 50), () => _searchController.clear()); // Limpia después de un frame
                    },
                  ),
                ),
                // --- NUEVO: Botón para cambiar vista ---
                const SizedBox(width: 8), // Espacio entre buscador y botón
                IconButton(
                  icon: Icon(
                    _currentViewType == UserViewType.list
                        ? Icons
                            .grid_view_outlined // Muestra icono de grid si la vista es lista
                        : Icons.view_list_outlined, // Muestra icono de lista si la vista es grid
                  ),
                  tooltip:
                      _currentViewType == UserViewType.list ? 'Vista Cuadrícula' : 'Vista Lista',
                  onPressed: () {
                    setState(() {
                      _currentViewType =
                          _currentViewType == UserViewType.list
                              ? UserViewType.grid
                              : UserViewType.list;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // --- Pasa el viewType a cada pestaña ---
                PacienteManagementTab(searchTerm: _searchTerm, viewType: _currentViewType),
                DoctorManagementTab(searchTerm: _searchTerm, viewType: _currentViewType),
                if (_isSuperAdmin)
                  AdminManagementTab(searchTerm: _searchTerm, viewType: _currentViewType),
              ],
            ),
          ),
        ],
      ),
      // --- FAB ahora gestionado aquí (opcional, podrías quitarlo de las tabs) ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateUserScreen()));
        },
        tooltip: 'Crear Usuario',
        child: const Icon(Icons.person_add_alt_1), // Icono genérico
      ),
    );
  }
}
 */