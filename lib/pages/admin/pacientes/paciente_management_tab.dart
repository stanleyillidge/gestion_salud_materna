// pages/admin/pacientes/paciente_management_tab.dart
// ignore_for_file: use_build_context_synchronously, must_be_immutable

import 'package:flutter/material.dart';

// import '../../../models/modelos.dart'; // Asegúrate que la ruta sea correcta
import '../../../models/modelos.dart';
import '../../../services/firestore_service.dart'; // Asegúrate que la ruta sea correcta
import 'paciente_detail_screen.dart';

class PacienteManagementTab extends StatefulWidget {
  final String? searchTerm;
  // --- NUEVO: Parámetro para recibir tipo de vista ---
  final UserViewType viewType;

  const PacienteManagementTab({
    this.searchTerm,
    required this.viewType, // Requerido
    super.key,
  });

  @override
  State<PacienteManagementTab> createState() => _PacienteManagementTabState();
}

class _PacienteManagementTabState extends State<PacienteManagementTab> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Usuario> _filterUsers(List<Usuario> allUsers, String? searchTerm) {
    // ... (código de filtro sin cambios) ...
    if (searchTerm == null || searchTerm.isEmpty) {
      return allUsers;
    }
    final lowerSearchTerm = searchTerm.toLowerCase();
    return allUsers.where((user) {
      return user.displayName.toLowerCase().contains(lowerSearchTerm) ||
          user.email.toLowerCase().contains(lowerSearchTerm);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mantenemos el Scaffold interno por si necesitas FAB específico aquí
      body: StreamBuilder<List<Usuario>>(
        stream: _firestoreService.getAllpacientesStream(),
        builder: (context, snapshot) {
          // ... (manejo de loading, error, no data sin cambios) ...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            if (widget.searchTerm?.isNotEmpty ?? false) {
              return Center(
                child: Text('No se encontraron pacientes para "${widget.searchTerm}".'),
              );
            } else {
              return const Center(child: Text('No hay pacientes registrados.'));
            }
          }

          final allPacientes = snapshot.data!;
          final displayedPacientes = _filterUsers(allPacientes, widget.searchTerm);

          if (displayedPacientes.isEmpty) {
            return Center(
              child: Text(
                (widget.searchTerm?.isNotEmpty ?? false)
                    ? 'No se encontraron pacientes para "${widget.searchTerm}".'
                    : 'No hay pacientes que mostrar.',
              ),
            );
          }

          // --- NUEVO: Decisión de layout ---
          if (widget.viewType == UserViewType.grid) {
            // --- Vista Grid ---
            return LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 125.0, left: 10.0, right: 10.0),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent:
                        constraints.maxWidth < 600
                            ? constraints.maxWidth
                            : 300.0, // Ancho máximo de cada tarjeta
                    childAspectRatio:
                        constraints.maxWidth < 600
                            ? 1.850
                            : 2 / 1.85, // Relación ancho/alto (ajustar)
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: displayedPacientes.length,
                  itemBuilder: (context, index) {
                    return _buildUserGridItem(displayedPacientes[index]); // Llama al nuevo builder
                  },
                );
              },
            );
          } else {
            // --- Vista Lista (por defecto) ---
            return ListView.builder(
              padding: const EdgeInsets.only(top: 10.0, bottom: 125.0, left: 4.0, right: 4.0),
              itemCount: displayedPacientes.length,
              itemBuilder: (context, index) {
                return _buildUserListItem(displayedPacientes[index]); // Llama al builder de lista
              },
            );
          }
        },
      ),
      // FAB Removido - Gestionado en el padre
      // floatingActionButton: FloatingActionButton(...)
    );
  }

  // --- Builder para elemento de LISTA ---
  Widget _buildUserListItem(Usuario user) {
    // ... (código del ListTile sin cambios estructurales) ...
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?'),
        ),
        title: Text(user.displayName),
        subtitle: Text("Email: ${user.email}"),
        // isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.blue),
              tooltip: 'Ver Detalles',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PacienteDetailScreen(pacienteId: user.uid, isAdminView: true),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Eliminar Paciente',
              onPressed: () => _confirmDeletepaciente(context, user),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PacienteDetailScreen(pacienteId: user.uid, isAdminView: true),
            ),
          );
        },
      ),
    );
  }

  // --- NUEVO: Builder para elemento de GRID ---
  Widget _buildUserGridItem(Usuario user) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4.0), // Menor margen para grid
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PacienteDetailScreen(pacienteId: user.uid, isAdminView: true),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Espacia verticalmente
            children: [
              // Icono/Avatar
              CircleAvatar(
                radius: 30,
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : 'P', // 'P' de Paciente
                  style: const TextStyle(fontSize: 20),
                ),
                // Podrías añadir backgroundImage si tienes photoUrl
              ),
              const SizedBox(height: 8),

              // Nombre y Email (ajusta maxLines y overflow)
              Text(
                user.displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Acciones
              const Spacer(), // Empuja las acciones hacia abajo
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround, // Espacia los iconos
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20), // Icono más pequeño
                    color: Colors.blue,
                    tooltip: 'Ver Detalles',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => PacienteDetailScreen(pacienteId: user.uid, isAdminView: true),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20), // Icono más pequeño
                    color: Colors.red,
                    tooltip: 'Eliminar Paciente',
                    onPressed: () => _confirmDeletepaciente(context, user),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _confirmDeletepaciente se mantiene igual
  void _confirmDeletepaciente(BuildContext context, Usuario user) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de que quieres eliminar al paciente ${user.displayName}? Esta acción NO se puede deshacer y eliminará su cuenta y datos asociados.',
            ),
            actions: <Widget>[
              TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop()),
              TextButton(
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    // Llama a la función de borrado completa (Auth + Firestore)
                    await _firestoreService.deleteUser(user.uid, 'paciente'); // Pasa el tipo
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Paciente eliminado correctamente'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }
}

/* // paciente_management_tab.dart
// ignore_for_file: use_build_context_synchronously, must_be_immutable

import 'package:flutter/material.dart';

import '../../../models/modelos.dart';
import '../../../services/firestore_service.dart';
import '../create_user_form.dart'; // Asumiendo que está un nivel arriba
import 'paciente_detail_screen.dart';

class PacienteManagementTab extends StatefulWidget {
  // --- NUEVO: Parámetro para recibir término de búsqueda ---
  final String? searchTerm;

  const PacienteManagementTab({this.searchTerm, super.key});

  @override
  State<PacienteManagementTab> createState() => _PacienteManagementTabState();
}

class _PacienteManagementTabState extends State<PacienteManagementTab> {
  final FirestoreService _firestoreService = FirestoreService();

  // --- NUEVO: Helper para filtrar la lista ---
  List<Usuario> _filterUsers(List<Usuario> allUsers, String? searchTerm) {
    if (searchTerm == null || searchTerm.isEmpty) {
      return allUsers; // Devuelve todos si no hay búsqueda
    }
    final lowerSearchTerm = searchTerm.toLowerCase();
    return allUsers.where((user) {
      return user.displayName.toLowerCase().contains(lowerSearchTerm) ||
          user.email.toLowerCase().contains(lowerSearchTerm);
      // || user.uid.contains(lowerSearchTerm); // Opcional: buscar por UID
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Usuario>>(
        // Cambiado a Stream<List<Usuario>>
        stream: _firestoreService.getAllpacientesStream(), // Usa el stream del servicio
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay pacientes registrados.'));
          }

          final allPacientes = snapshot.data!;
          // --- NUEVO: Filtrar ANTES de construir la lista ---
          final displayedPacientes = _filterUsers(allPacientes, widget.searchTerm);

          if (displayedPacientes.isEmpty && (widget.searchTerm?.isNotEmpty ?? false)) {
            return Center(child: Text('No se encontraron pacientes para "${widget.searchTerm}".'));
          }
          if (displayedPacientes.isEmpty) {
            return const Center(child: Text('No hay pacientes registrados.'));
          }

          return ListView.builder(
            itemCount: displayedPacientes.length, // Usa la lista filtrada
            itemBuilder: (context, index) {
              final user = displayedPacientes[index]; // Usa la lista filtrada

              // El resto del ListTile se mantiene igual
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Text(user.displayName),
                  subtitle: Text("ID: ${user.uid}\nEmail: ${user.email}"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'Ver Detalles',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => PacienteDetailScreen(
                                    pacienteId: user.uid,
                                    isAdminView: true, // Asume que esta tab es para admin
                                  ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Eliminar Paciente',
                        onPressed: () => _confirmDeletepaciente(context, user),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => PacienteDetailScreen(
                              pacienteId: user.uid,
                              isAdminView: true, // Asume que esta tab es para admin
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      // El FAB se puede mover al Scaffold principal (UserManagementScreen)
      // O mantenerlo aquí si quieres un FAB específico por pestaña.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateUserScreen()));
        },
        tooltip: 'Crear Paciente',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  // _confirmDeletepaciente se mantiene igual
  void _confirmDeletepaciente(BuildContext context, Usuario user) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de que quieres eliminar al paciente ${user.displayName}? Esta acción NO se puede deshacer y eliminará su cuenta y datos asociados.',
            ),
            actions: <Widget>[
              TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop()),
              TextButton(
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    // Llama a la función de borrado completa (Auth + Firestore)
                    await _firestoreService.deleteUser(user.uid, 'paciente'); // Pasa el tipo
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Paciente eliminado correctamente'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }
}
 */
