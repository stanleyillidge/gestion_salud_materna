// gestion_users.dart
// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/modelos.dart'; // Importa tus modelos
import '../../services/firestore_service.dart'; // Importa tu servicio

import 'admin_management_tab.dart';
import 'create_user_form.dart';
import 'doctor_management_tab.dart';
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
  UserViewType _currentViewType = UserViewType.list; // Vista inicial: Lista

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
