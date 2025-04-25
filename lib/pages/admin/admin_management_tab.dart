// admin_management_tab.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/modelos.dart';
import '../../services/firestore_service.dart';
import 'create_user_form.dart';
// import 'admin_detail_screen.dart'; // Necesitarás crear esta pantalla

class AdminManagementTab extends StatefulWidget {
  const AdminManagementTab({super.key});

  @override
  State<AdminManagementTab> createState() => _AdminManagementTabState();
}

class _AdminManagementTabState extends State<AdminManagementTab> {
  final FirestoreService _firestoreService = FirestoreService();
  // Podrías añadir búsqueda/filtrado

  @override
  Widget build(BuildContext context) {
    // Obtener UID del usuario actual para evitar auto-eliminación
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: StreamBuilder<List<Usuario>>(
        // Espera una lista de Mapas
        stream: _firestoreService.getAllAdminsStream(), // Llama al método correcto
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar administradores: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay administradores registrados.'));
          }

          final admins = snapshot.data!;

          return ListView.builder(
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final adminData = admins[index];
              final adminId = adminData.uid as String?; // Obtener ID añadido por el servicio
              final adminName = adminData.displayName as String?;
              final adminEmail = adminData.email as String?;

              if (adminId == null) {
                // Si no hay ID, no podemos hacer nada con este registro
                return ListTile(
                  title: Text("Error: Registro de admin inválido (sin ID)"),
                  leading: Icon(Icons.error),
                );
              }

              // Lógica para deshabilitar la eliminación del propio usuario
              final bool isCurrentUser = adminId == currentUserId;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.admin_panel_settings),
                  ), // Icono genérico para admin
                  title: Text(adminName ?? 'Admin Sin Nombre'),
                  subtitle: Text("ID: $adminId\nEmail: ${adminEmail ?? 'N/A'}"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'Ver Detalles del Admin',
                        onPressed: () {
                          // --- NAVEGAR A ADMIN DETAIL SCREEN ---
                          /*
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AdminDetailScreen(adminId: adminId)),
                          );
                          */
                          print("Navegar a detalles del admin: $adminId");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pantalla de detalle del admin no implementada.'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: isCurrentUser ? Colors.grey : Colors.red,
                        ), // Deshabilitar visualmente
                        tooltip:
                            isCurrentUser ? 'No puedes eliminarte a ti mismo' : 'Eliminar Admin',
                        // Deshabilitar onPressed si es el usuario actual
                        onPressed:
                            isCurrentUser
                                ? null
                                : () => _confirmDeleteAdmin(context, adminId, adminName),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navegar al detalle al tocar
                    print("Navegar a detalles del admin: $adminId");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pantalla de detalle del admin no implementada.'),
                      ),
                    );
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDetailScreen(adminId: adminId)));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a la pantalla de creación, podría preseleccionar 'admin'
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateUserScreen(/* initialProfileType: 'admin' */),
            ),
          );
        },
        tooltip: 'Crear Admin',
        child: const Icon(Icons.add_moderator), // Icono diferente
      ),
    );
  }

  void _confirmDeleteAdmin(BuildContext context, String adminId, String? adminName) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de eliminar al administrador ${adminName ?? adminId}? Esta acción eliminará su perfil y acceso (requiere Cloud Function).',
            ),
            actions: <Widget>[
              TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop()),
              TextButton(
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(ctx).pop(); // Cierra el diálogo
                  try {
                    // --- LLAMADA A TU FUNCIÓN DE ELIMINACIÓN ---
                    await _firestoreService.deleteUser(adminId, 'admin');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Admin eliminado (Firestore).'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al eliminar admin: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
    );
  }
}
