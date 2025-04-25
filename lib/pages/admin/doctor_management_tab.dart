// pages/admin/doctor_management_tab.dart
// ignore_for_file: use_build_context_synchronously, must_be_immutable

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/modelos.dart'; // Asegúrate que la ruta sea correcta
import '../../services/firestore_service.dart'; // Asegúrate que la ruta sea correcta
import 'create_user_form.dart';
import '../admin/gestion_users.dart'; // Importa el enum UserViewType
// import 'doctor_detail_screen.dart'; // Pantalla de detalle si la tienes

class DoctorManagementTab extends StatefulWidget {
  final String? searchTerm;
  // --- NUEVO: Parámetro para recibir tipo de vista ---
  final UserViewType viewType;

  const DoctorManagementTab({
    this.searchTerm,
    required this.viewType, // Requerido
    super.key,
  });

  @override
  State<DoctorManagementTab> createState() => _DoctorManagementTabState();
}

class _DoctorManagementTabState extends State<DoctorManagementTab> {
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
    bool isSuperAdmin = true; // Reemplaza con tu lógica real

    return Scaffold(
      body: StreamBuilder<List<Usuario>>(
        stream: _firestoreService.getAllDoctorsStream(),
        builder: (context, snapshot) {
          // ... (manejo de loading, error, no data sin cambios) ...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar doctores: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            if (widget.searchTerm?.isNotEmpty ?? false) {
              return Center(child: Text('No se encontraron doctores para "${widget.searchTerm}".'));
            } else {
              return const Center(child: Text('No hay doctores registrados.'));
            }
          }

          final allDoctors = snapshot.data!;
          final displayedDoctors = _filterUsers(allDoctors, widget.searchTerm);

          if (displayedDoctors.isEmpty) {
            return Center(
              child: Text(
                (widget.searchTerm?.isNotEmpty ?? false)
                    ? 'No se encontraron doctores para "${widget.searchTerm}".'
                    : 'No hay doctores que mostrar.',
              ),
            );
          }

          // --- NUEVO: Decisión de layout ---
          if (widget.viewType == UserViewType.grid) {
            // --- Vista Grid ---
            return GridView.builder(
              padding: const EdgeInsets.all(10.0),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300.0,
                childAspectRatio: 2 / 2.5, // Ajusta según necesites
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: displayedDoctors.length,
              itemBuilder: (context, index) {
                return _buildUserGridItem(
                  displayedDoctors[index],
                  isSuperAdmin,
                ); // Pasa isSuperAdmin
              },
            );
          } else {
            // --- Vista Lista (por defecto) ---
            return ListView.builder(
              itemCount: displayedDoctors.length,
              itemBuilder: (context, index) {
                return _buildUserListItem(
                  displayedDoctors[index],
                  isSuperAdmin,
                ); // Pasa isSuperAdmin
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
  Widget _buildUserListItem(Usuario user, bool isSuperAdmin) {
    final profile = user.doctorProfile;
    // ... (código del ListTile sin cambios estructurales, pero usa `isSuperAdmin`) ...
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                  ? NetworkImage(user.photoUrl!)
                  : null,
          child:
              (user.photoUrl == null || user.photoUrl!.isEmpty)
                  ? const Icon(Icons.medical_services_outlined) // Icono doctor
                  : null,
        ),
        title: Text(user.displayName),
        subtitle: Text(
          'Especialidades: ${profile?.specialties.join(', ') ?? 'N/A'}\n'
          'Email: ${user.email}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.blue),
              tooltip: 'Ver Detalles del Doctor',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pantalla de detalle del doctor no implementada.')),
                );
              },
            ),
            if (isSuperAdmin) // Usa la variable pasada
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Eliminar Doctor',
                onPressed: () => _confirmDeleteDoctor(context, user),
              ),
          ],
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pantalla de detalle del doctor no implementada.')),
          );
        },
      ),
    );
  }

  // --- NUEVO: Builder para elemento de GRID ---
  Widget _buildUserGridItem(Usuario user, bool isSuperAdmin) {
    final profile = user.doctorProfile;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4.0),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pantalla de detalle del doctor no implementada.')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage:
                    (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                        ? NetworkImage(user.photoUrl!)
                        : null,
                child:
                    (user.photoUrl == null || user.photoUrl!.isEmpty)
                        ? const Icon(Icons.medical_services_outlined)
                        : null,
              ),
              const SizedBox(height: 8),
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
                profile?.specialties.isNotEmpty ?? false
                    ? profile!.specialties.first
                    : 'Sin Esp.', // Muestra primera especialidad
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    color: Colors.blue,
                    tooltip: 'Ver Detalles',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pantalla de detalle del doctor no implementada.'),
                        ),
                      );
                    },
                  ),
                  if (isSuperAdmin) // Usa la variable pasada
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red,
                      tooltip: 'Eliminar Doctor',
                      onPressed: () => _confirmDeleteDoctor(context, user),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _confirmDeleteDoctor se mantiene igual
  void _confirmDeleteDoctor(BuildContext context, Usuario user) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de eliminar al doctor ${user.displayName}? Esta acción eliminará su perfil y acceso.',
            ),
            actions: <Widget>[
              TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop()),
              TextButton(
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(ctx).pop(); // Cierra el diálogo
                  try {
                    // Llama al borrado completo (Auth + Firestore)
                    await _firestoreService.deleteUser(user.uid, 'doctor'); // Pasa el tipo
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Doctor eliminado correctamente.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar doctor: ${e.toString()}'),
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

/* // doctor_management_tab.dart
// ignore_for_file: use_build_context_synchronously, must_be_immutable

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/modelos.dart';
import '../../services/firestore_service.dart';
import 'create_user_form.dart';
// import 'doctor_detail_screen.dart';

class DoctorManagementTab extends StatefulWidget {
  // --- NUEVO: Parámetro para recibir término de búsqueda ---
  final String? searchTerm;

  const DoctorManagementTab({this.searchTerm, super.key});

  @override
  State<DoctorManagementTab> createState() => _DoctorManagementTabState();
}

class _DoctorManagementTabState extends State<DoctorManagementTab> {
  final FirestoreService _firestoreService = FirestoreService();

  // --- NUEVO: Helper para filtrar la lista ---
  List<Usuario> _filterUsers(List<Usuario> allUsers, String? searchTerm) {
    if (searchTerm == null || searchTerm.isEmpty) {
      return allUsers;
    }
    final lowerSearchTerm = searchTerm.toLowerCase();
    return allUsers.where((user) {
      return user.displayName.toLowerCase().contains(lowerSearchTerm) ||
          user.email.toLowerCase().contains(lowerSearchTerm);
      // || user.uid.contains(lowerSearchTerm);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    bool isSuperAdmin = true; // Reemplaza con tu lógica real

    return Scaffold(
      body: StreamBuilder<List<Usuario>>(
        stream: _firestoreService.getAllDoctorsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar doctores: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay doctores registrados.'));
          }

          final allDoctors = snapshot.data!;
          // --- NUEVO: Filtrar ANTES de construir la lista ---
          final displayedDoctors = _filterUsers(allDoctors, widget.searchTerm);

          if (displayedDoctors.isEmpty && (widget.searchTerm?.isNotEmpty ?? false)) {
            return Center(child: Text('No se encontraron doctores para "${widget.searchTerm}".'));
          }
          if (displayedDoctors.isEmpty) {
            return const Center(child: Text('No hay doctores registrados.'));
          }

          return ListView.builder(
            itemCount: displayedDoctors.length, // Usa la lista filtrada
            itemBuilder: (context, index) {
              final user = displayedDoctors[index]; // Usa la lista filtrada
              final profile = user.doctorProfile;

              // El ListTile se mantiene igual
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                            ? NetworkImage(user.photoUrl!)
                            : null,
                    child:
                        (user.photoUrl == null || user.photoUrl!.isEmpty)
                            ? Text(
                              user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                            )
                            : null,
                  ),
                  title: Text(user.displayName),
                  subtitle: Text(
                    'Especialidades: ${profile?.specialties.join(', ') ?? 'N/A'}\n'
                    'Email: ${user.email}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'Ver Detalles del Doctor',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pantalla de detalle del doctor no implementada.'),
                            ),
                          );
                        },
                      ),
                      if (isSuperAdmin) // Asume lógica de permisos aquí
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Eliminar Doctor',
                          onPressed: () => _confirmDeleteDoctor(context, user),
                        ),
                    ],
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pantalla de detalle del doctor no implementada.'),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      // FAB opcional aquí o en el padre
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateUserScreen()));
        },
        tooltip: 'Crear Doctor',
        child: const Icon(Icons.medical_services),
      ),
    );
  }

  // _confirmDeleteDoctor se mantiene igual
  void _confirmDeleteDoctor(BuildContext context, Usuario user) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de eliminar al doctor ${user.displayName}? Esta acción eliminará su perfil y acceso.',
            ),
            actions: <Widget>[
              TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop()),
              TextButton(
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(ctx).pop(); // Cierra el diálogo
                  try {
                    // Llama al borrado completo (Auth + Firestore)
                    await _firestoreService.deleteUser(user.uid, 'doctor'); // Pasa el tipo
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Doctor eliminado correctamente.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar doctor: ${e.toString()}'),
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
