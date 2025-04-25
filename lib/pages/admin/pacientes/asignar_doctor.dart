import 'package:flutter/material.dart';

class AsignarDoctor extends StatelessWidget {
  const AsignarDoctor({super.key});

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
            Text('Asignar Doctor'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ID del Paciente',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const TextField(
              decoration: InputDecoration(
                labelText: 'ID del Paciente',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Doctores Disponibles',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: 10, // Número de doctores disponibles (actualizar según la lista real)
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Doctor $index'),
                    subtitle: const Text('Especialidad del doctor'),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                    onTap: () {
                      // Lógica para asignar el doctor al paciente
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
