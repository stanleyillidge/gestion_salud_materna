import 'package:flutter/material.dart';

class PerfilPaciente extends StatelessWidget {
  const PerfilPaciente({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Gestión de Pacientes',
              style: TextStyle(fontSize: 12),
            ),
            Text('Perfil del Paciente'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Información Personal',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Text('Nombre completo: Paciente X'),
              const Text('Fecha de nacimiento: DD/MM/YYYY'),
              const Text('Número de documento de identidad: XXXXXXXXX'),
              const Text('Nacionalidad: País'),
              const Text('Dirección: Dirección del paciente'),
              const Text('Teléfono: +XX XXXX XXX XXX'),
              const Text('Correo electrónico: correo@ejemplo.com'),
              const SizedBox(height: 20),
              const Text('Información Clínica',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Text('Grupo sanguíneo: AB+'),
              const Text('Factor RH: Positivo'),
              const Text('Alergias: Ninguna'),
              const Text('Enfermedades preexistentes: Ninguna'),
              const Text('Medicamentos actuales: Ninguno'),
              const SizedBox(height: 20),
              const Text('Información del Embarazo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Text('Fecha de la última menstruación: DD/MM/YYYY'),
              const Text('Semanas de gestación: XX'),
              const Text('Fecha probable de parto: DD/MM/YYYY'),
              const Text('Número de gestaciones previas: X'),
              const Text('Número de partos vaginales previos: X'),
              const Text('Número de cesáreas previas: X'),
              const Text('Número de abortos previos: X'),
              const Text('Embarazo múltiple: No'),
              const SizedBox(height: 20),
              const Text('Información de Ubicación',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Text('Coordenadas: Latitud, Longitud'),
              const SizedBox(height: 20),
              const Text('Historial de Citas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              DataTable(
                columns: const <DataColumn>[
                  DataColumn(label: Text('Fecha')),
                  DataColumn(label: Text('Tipo de cita')),
                  DataColumn(label: Text('Doctor')),
                  DataColumn(label: Text('Observaciones')),
                ],
                rows: const <DataRow>[
                  DataRow(
                    cells: <DataCell>[
                      DataCell(Text('DD/MM/YYYY')),
                      DataCell(Text('Consulta general')),
                      DataCell(Text('Doctor X')),
                      DataCell(Text('Observación del médico')),
                    ],
                  ),
                  // Añadir más filas según sea necesario
                ],
              ),
              const SizedBox(height: 20),
              const Text('Doctor Asignado',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Text('Nombre: Doctor X'),
              const Text('Especialidad: Especialidad del doctor'),
              ElevatedButton(
                onPressed: () {
                  // Navegar a la pantalla de asignación de doctor
                },
                child: const Text('Cambiar Doctor'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Lógica para editar información
                },
                child: const Text('Editar Información'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Lógica para eliminar perfil del paciente
                },
                child: const Text('Eliminar Perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
