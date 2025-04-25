// doctor_management_tab.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../models/modelos.dart';
import '../../services/firestore_service.dart';
import 'create_user_form.dart';
// import 'doctor_detail_screen.dart'; // Puedes crear esta pantalla si la necesitas

class DoctorManagementTab extends StatefulWidget {
  const DoctorManagementTab({super.key});

  @override
  State<DoctorManagementTab> createState() => _DoctorManagementTabState();
}

class _DoctorManagementTabState extends State<DoctorManagementTab> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    // Aquí determinas si el usuario actual es SuperAdmin (ajusta según tu lógica real)
    bool isSuperAdmin = true;

    return Scaffold(
      body: StreamBuilder<List<Usuario>>(
        // Ahora obtenemos los usuarios con rol 'doctor'
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

          final doctors = snapshot.data!;

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final user = doctors[index];
              final profile = user.doctorProfile;

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
                          // Navegar a DoctorDetailScreen si la implementas
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctorId: user.uid)),
                          // );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pantalla de detalle del doctor no implementada.'),
                            ),
                          );
                        },
                      ),
                      if (isSuperAdmin)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Eliminar Doctor',
                          onPressed: () => _confirmDeleteDoctor(context, user),
                        ),
                    ],
                  ),
                  onTap: () {
                    // Igual que el botón de detalles
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a la pantalla de creación, con perfil doctor si tu formulario lo soporta
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateUserScreen()));
        },
        tooltip: 'Crear Doctor',
        child: const Icon(Icons.medical_services),
      ),
    );
  }

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
                    // Elimina el usuario con rol doctor
                    await _firestoreService.deleteUser(user.uid, UserRole.doctor as String);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Doctor eliminado correctamente.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al eliminar doctor: ${e.toString()}'),
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

/* // doctor_management_tab.dart
import 'package:flutter/material.dart';

import '../../models/modelos.dart';
import '../../services/firestore_service.dart';
import 'create_user_form.dart';
// import 'doctor_detail_screen.dart'; // Necesitarás crear esta pantalla

class DoctorManagementTab extends StatefulWidget {
  const DoctorManagementTab({super.key});

  @override
  State<DoctorManagementTab> createState() => _DoctorManagementTabState();
}

class _DoctorManagementTabState extends State<DoctorManagementTab> {
  final FirestoreService _firestoreService = FirestoreService();
  // Podrías añadir un TextEditingController para búsqueda/filtrado

  @override
  Widget build(BuildContext context) {
    // Asume que tienes forma de saber si el usuario actual es SuperAdmin
    bool isSuperAdmin = true; // Reemplaza con tu lógica de roles real

    return Scaffold(
      body: StreamBuilder<List<Doctor>>(
        // Usa el stream de doctores
        stream: _firestoreService.getAllDoctorsStream(), // Llama al método correcto
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

          final doctors = snapshot.data!;

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    // Usa foto de perfil si existe, sino iniciales
                    backgroundImage:
                        doctor.fotoPerfilURL != null && doctor.fotoPerfilURL!.isNotEmpty
                            ? NetworkImage(doctor.fotoPerfilURL!)
                            : null,
                    child:
                        doctor.fotoPerfilURL == null || doctor.fotoPerfilURL!.isEmpty
                            ? Text(doctor.nombre?[0].toUpperCase() ?? '?')
                            : null,
                  ),
                  title: Text(doctor.nombre ?? 'Sin Nombre'),
                  subtitle: Text(
                    "Especialidades: ${doctor.especialidades?.join(', ') ?? 'N/A'}\nEmail: ${doctor.email ?? 'N/A'}",
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'Ver Detalles del Doctor',
                        onPressed: () {
                          // --- NAVEGAR A DOCTOR DETAIL SCREEN ---
                          // Necesitarás crear DoctorDetailScreen
                          /*
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctorId: doctor.id!)),
                          );
                          */
                          print("Navegar a detalles del doctor: ${doctor.id}");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pantalla de detalle del doctor no implementada.'),
                            ),
                          );
                        },
                      ),
                      // Solo SuperAdmin puede eliminar doctores (ejemplo de permiso)
                      if (isSuperAdmin)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Eliminar Doctor',
                          onPressed: () => _confirmDeleteDoctor(context, doctor),
                        ),
                    ],
                  ),
                  onTap: () {
                    // Navegar al detalle al tocar
                    print("Navegar a detalles del doctor: ${doctor.id}");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pantalla de detalle del doctor no implementada.'),
                      ),
                    );
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctorId: doctor.id!)));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a la pantalla de creación, podría preseleccionar 'doctor'
          Navigator.push(
            context,
            // Podrías pasar un argumento inicial si CreateUserScreen lo soporta
            MaterialPageRoute(
              builder: (_) => const CreateUserScreen(/* initialProfileType: 'doctor' */),
            ),
          );
        },
        tooltip: 'Crear Doctor',
        child: const Icon(Icons.medical_services),
      ),
    );
  }

  void _confirmDeleteDoctor(BuildContext context, Doctor doctor) {
    if (doctor.id == null) return; // No se puede eliminar sin ID
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de eliminar al doctor ${doctor.nombre ?? doctor.id}? Esta acción eliminará su perfil y acceso (requiere Cloud Function).',
            ),
            actions: <Widget>[
              TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop()),
              TextButton(
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(ctx).pop(); // Cierra el diálogo
                  try {
                    // --- LLAMADA A TU FUNCIÓN DE ELIMINACIÓN ---
                    // Recuerda: deleteUser solo borra Firestore, necesitas CF para Auth
                    await _firestoreService.deleteUser(doctor.id!, 'doctor');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Doctor eliminado (Firestore).'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al eliminar doctor: ${e.toString()}'),
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
} */
