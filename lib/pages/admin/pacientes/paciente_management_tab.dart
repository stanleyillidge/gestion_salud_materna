// Archivo: pages_admin_paciente_management_tab.dart
// Ruta: D:\proyectos\salud_materna\lib\pages\admin\paciente_management_tab.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/modelos.dart';
import '../../../services/firestore_service.dart';
import '../create_user_form.dart';
import 'paciente_detail_screen.dart';

class pacienteManagementTab extends StatefulWidget {
  const pacienteManagementTab({super.key});

  @override
  State<pacienteManagementTab> createState() => _pacienteManagementTabState();
}

class _pacienteManagementTabState extends State<pacienteManagementTab> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .where('roles', arrayContains: 'paciente')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay pacientes registrados.'));
          }

          final userDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: userDocs.length,
            itemBuilder: (context, index) {
              Usuario user;
              try {
                user = Usuario.fromFirestore(userDocs[index]);
              } catch (e) {
                if (kDebugMode) {
                  print("Error parseando usuario Doc ID ${userDocs[index].id}: $e");
                }
                return ListTile(
                  leading: Icon(Icons.error, color: Colors.red),
                  title: Text("Error al cargar Usuario ID: ${userDocs[index].id}"),
                );
              }

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
                              builder: (_) => PacienteDetailScreen(pacienteId: user.uid),
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
                      MaterialPageRoute(builder: (_) => PacienteDetailScreen(pacienteId: user.uid)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateUserScreen()));
        },
        tooltip: 'Crear Paciente',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _confirmDeletepaciente(BuildContext context, Usuario user) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de que quieres eliminar al paciente ${user.displayName}? Esta acción NO se puede deshacer.',
            ),
            actions: <Widget>[
              TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop()),
              TextButton(
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    await _firestoreService.deleteUser(user.uid, UserRole.paciente as String);
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

/* import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/modelos.dart';
import '../../services/firestore_service.dart';
import 'create_user_form.dart';
import 'paciente_detail_screen.dart';

class pacienteManagementTab extends StatefulWidget {
  const pacienteManagementTab({super.key});

  @override
  State<pacienteManagementTab> createState() => _pacienteManagementTabState();
}

class _pacienteManagementTabState extends State<pacienteManagementTab> {
  final FirestoreService _firestoreService = FirestoreService();
  // Podrías añadir un TextEditingController para búsqueda/filtrado

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold anidado para el FAB específico de esta tab
      body: StreamBuilder<QuerySnapshot>(
        // Asume un método para obtener TODOS los pacientes
        // stream: _firestoreService.getAllpacientesStream(), // Necesitarás crear este método
        stream: FirebaseFirestore.instance.collection('pacientes').snapshots(), // Ejemplo directo
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay pacientes registrados.'));
          }

          final pacientesDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pacientesDocs.length,
            itemBuilder: (context, index) {
              // Intenta parsear, maneja errores si el documento no es válido
              Paciente? paciente;
              try {
                paciente = Paciente.fromFirestore(pacientesDocs[index]);
              } catch (e) {
                print("Error parseando paciente Doc ID ${pacientesDocs[index].id}: $e");
                // Podrías mostrar un ListTile de error o simplemente omitirlo
                return ListTile(
                  leading: Icon(Icons.error, color: Colors.red),
                  title: Text("Error al cargar Paciente ID: ${pacientesDocs[index].id}"),
                );
              } // Omitir si el parseo falló

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(child: Text(paciente.nombre?[0].toUpperCase() ?? '?')),
                  title: Text(paciente.nombre ?? 'Sin Nombre'),
                  subtitle: Text("ID: ${paciente.id}\nEmail: ${paciente.email ?? 'N/A'}"),
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
                              builder: (_) => PacienteDetailScreen(pacienteId: paciente!.id),
                            ), // Asegura que paciente no sea null aquí
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Eliminar Paciente',
                        onPressed:
                            () => _confirmDeletepaciente(
                              context,
                              paciente!,
                            ), // Asegura que paciente no sea null
                      ),
                    ],
                  ),
                  onTap: () {
                    // También navega al detalle al tocar
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PacienteDetailScreen(pacienteId: paciente!.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateUserScreen(),
            ), // Reutiliza la pantalla de creación
          );
        },
        tooltip: 'Crear Paciente',
        child: const Icon(Icons.personal_injury),
      ),
    );
  }

  void _confirmDeletepaciente(BuildContext context, Paciente paciente) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de que quieres eliminar al paciente ${paciente.nombre ?? paciente.id}? Esta acción NO se puede deshacer.',
            ),
            actions: <Widget>[
              TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop()),
              TextButton(
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(ctx).pop(); // Cierra el diálogo
                  try {
                    // --- LLAMADA A TU FUNCIÓN DE ELIMINACIÓN ---
                    // Necesitarás una función en FirestoreService que elimine
                    // el documento de Firestore Y el usuario de Auth.
                    // await _firestoreService.deleteUser(paciente.id, 'paciente');
                    print("Simulando eliminación de paciente ${paciente.id}");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Paciente eliminado (simulado)'),
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
} */
