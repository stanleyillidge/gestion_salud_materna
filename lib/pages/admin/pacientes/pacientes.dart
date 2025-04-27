import 'package:flutter/material.dart';
import '../../../models/modelos.dart';
// import 'gestion_visitas.dart';
import 'lista_pacientes.dart';
import 'perfil_paciente.dart';
import 'asignar_doctor.dart';
import 'nuevo_paciente.dart';

class Pacientes extends StatefulWidget {
  const Pacientes({super.key});

  @override
  PacientesState createState() => PacientesState();
}

class PacientesState extends State<Pacientes> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    // const GestionVisitas(),
    const ListaPacientes(),
    const PerfilPaciente(),
    const AsignarDoctor(),
    const NuevoPaciente(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.9,
        // minWidth: size.width * 0.9,
      ), // Define un alto específico
      child: Scaffold(
        appBar: AppBar(title: const Text('Pacientes')),
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar:
            !smallView
                ? const SizedBox.shrink()
                : BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Lista'),
                    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.assignment_ind),
                      label: 'Asignar Doctor',
                    ),
                    BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Nuevo Paciente'),
                  ],
                  currentIndex: _selectedIndex,
                  selectedItemColor: Theme.of(context).colorScheme.primary,
                  unselectedItemColor: Theme.of(context).colorScheme.secondary,
                  onTap: _onItemTapped,
                ),
      ),
    );
  }
}
