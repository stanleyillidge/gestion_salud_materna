// pages/admin/admin_management_tab.dart
// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, must_be_immutable

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/modelos.dart'; // Asegúrate que la ruta sea correcta
import '../../services/firestore_service.dart'; // Asegúrate que la ruta sea correcta
// import 'admin_detail_screen.dart'; // Pantalla de detalle si la tienes

class AdminManagementTab extends StatefulWidget {
  final String? searchTerm;
  // --- NUEVO: Parámetro para recibir tipo de vista ---
  final UserViewType viewType;

  const AdminManagementTab({
    this.searchTerm,
    required this.viewType, // Requerido
    super.key,
  });

  @override
  State<AdminManagementTab> createState() => _AdminManagementTabState();
}

class _AdminManagementTabState extends State<AdminManagementTab> {
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
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: StreamBuilder<List<Usuario>>(
        stream: _firestoreService.getAllAdminsStream(),
        builder: (context, snapshot) {
          // ... (manejo de loading, error, no data sin cambios) ...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            if (kDebugMode) print("Error Stream Admins: ${snapshot.error}");
            return Center(child: Text('Error al cargar administradores: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            if (widget.searchTerm?.isNotEmpty ?? false) {
              return Center(child: Text('No se encontraron admins para "${widget.searchTerm}".'));
            } else {
              return const Center(child: Text('No hay administradores registrados.'));
            }
          }

          final allAdmins = snapshot.data!;
          final displayedAdmins = _filterUsers(allAdmins, widget.searchTerm);

          if (displayedAdmins.isEmpty) {
            return Center(
              child: Text(
                (widget.searchTerm?.isNotEmpty ?? false)
                    ? 'No se encontraron admins para "${widget.searchTerm}".'
                    : 'No hay administradores que mostrar.',
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
              itemCount: displayedAdmins.length,
              itemBuilder: (context, index) {
                return _buildUserGridItem(
                  displayedAdmins[index],
                  currentUserId,
                ); // Pasa currentUserId
              },
            );
          } else {
            // --- Vista Lista (por defecto) ---
            return ListView.builder(
              itemCount: displayedAdmins.length,
              itemBuilder: (context, index) {
                return _buildUserListItem(
                  displayedAdmins[index],
                  currentUserId,
                ); // Pasa currentUserId
              },
            );
          }
        },
      ),
      // FAB Removido - Gestionado en el padre
    );
  }

  // --- Builder para elemento de LISTA ---
  Widget _buildUserListItem(Usuario adminUser, String? currentUserId) {
    final adminId = adminUser.uid;
    final adminName = adminUser.displayName;
    final adminEmail = adminUser.email;
    final bool isCurrentUser = adminId == currentUserId;

    // ... (código del ListTile sin cambios estructurales, pero usa isCurrentUser) ...
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              (adminUser.photoUrl != null && adminUser.photoUrl!.isNotEmpty)
                  ? NetworkImage(adminUser.photoUrl!)
                  : null,
          child:
              (adminUser.photoUrl == null || adminUser.photoUrl!.isEmpty)
                  ? const Icon(Icons.admin_panel_settings_outlined) // Icono admin
                  : null,
        ),
        title: Text(adminName),
        subtitle: Text("Email: $adminEmail"),
        // isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.blue),
              tooltip: 'Ver Detalles del Admin',
              onPressed: () {
                if (kDebugMode) print("Navegar a detalles del admin: $adminId");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pantalla de detalle del admin no implementada.')),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: isCurrentUser ? Colors.grey : Colors.red),
              tooltip: isCurrentUser ? 'No puedes eliminarte' : 'Eliminar Admin',
              onPressed: isCurrentUser ? null : () => _confirmDeleteAdmin(context, adminUser),
            ),
          ],
        ),
        onTap: () {
          if (kDebugMode) print("Navegar a detalles del admin: $adminId");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pantalla de detalle del admin no implementada.')),
          );
        },
      ),
    );
  }

  // --- NUEVO: Builder para elemento de GRID ---
  Widget _buildUserGridItem(Usuario adminUser, String? currentUserId) {
    final adminId = adminUser.uid;
    final adminName = adminUser.displayName;
    final adminEmail = adminUser.email;
    final bool isCurrentUser = adminId == currentUserId;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4.0),
      child: InkWell(
        onTap: () {
          if (kDebugMode) print("Navegar a detalles del admin: $adminId");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pantalla de detalle del admin no implementada.')),
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
                    (adminUser.photoUrl != null && adminUser.photoUrl!.isNotEmpty)
                        ? NetworkImage(adminUser.photoUrl!)
                        : null,
                child:
                    (adminUser.photoUrl == null || adminUser.photoUrl!.isEmpty)
                        ? const Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 30,
                        ) // Icono admin más grande
                        : null,
              ),
              const SizedBox(height: 8),
              Text(
                adminName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                // Podrías mostrar "Admin" o el email
                adminEmail,
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
                      if (kDebugMode) print("Navegar a detalles del admin: $adminId");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pantalla de detalle del admin no implementada.'),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20),
                    color: isCurrentUser ? Colors.grey : Colors.red,
                    tooltip: isCurrentUser ? 'No puedes eliminarte' : 'Eliminar Admin',
                    onPressed: isCurrentUser ? null : () => _confirmDeleteAdmin(context, adminUser),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Modificado para recibir Usuario ---
  void _confirmDeleteAdmin(BuildContext context, Usuario adminUser) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de eliminar al administrador ${adminUser.displayName}? Esta acción eliminará su perfil y acceso (requiere Cloud Function).',
            ),
            actions: <Widget>[
              TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop()),
              TextButton(
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(ctx).pop(); // Cierra el diálogo
                  try {
                    // --- LLAMADA A TU FUNCIÓN DE ELIMINACIÓN COMPLETA ---
                    // Pasa el tipo de perfil correcto
                    await _firestoreService.deleteUser(adminUser.uid, 'admin');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Admin eliminado.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar admin: ${e.toString()}'),
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
