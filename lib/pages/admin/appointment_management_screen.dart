import 'package:flutter/material.dart';
// Importa modelo de Cita y servicio Firestore

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  State<AppointmentManagementScreen> createState() => _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState extends State<AppointmentManagementScreen> {
  // final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Citas')),
      body: Center(
        child: Text("Lista de Citas (Implementación Pendiente)"),
        // Aquí iría un StreamBuilder para obtener las citas
        // Podrías usar filtros (por fecha, doctor, paciente)
        // ListView.builder para mostrar las citas
        // Cada ListTile tendría opciones para Editar/Eliminar
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a una pantalla para crear/agendar nueva cita
        },
        tooltip: 'Nueva Cita',
        child: const Icon(Icons.add),
      ),
    );
  }
}
