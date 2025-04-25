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
        // appBar: AppBar(
        //   title: const Text('Gestión de Pacientes'),
        // ),
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

/* class Pacientes extends StatefulWidget {
  const Pacientes({super.key});

  @override
  PacientesState createState() => PacientesState();
}

class PacientesState extends State<Pacientes> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _pacientes = [
    {
      'name': 'Juan Perez',
      'dob': '01/01/1990',
      'weeks': 20,
      'doctor': 'Dr. Smith',
      'nextAppointment': '2023-06-15 14:00'
    },
    {
      'name': 'Maria Lopez',
      'dob': '12/12/1985',
      'weeks': 18,
      'doctor': 'Dr. Johnson',
      'nextAppointment': '2023-06-16 10:00'
    },
    // Agrega más pacientes según sea necesario
  ];

  List<Map<String, dynamic>>? _filteredpacientes;

  @override
  void initState() {
    super.initState();
    _filteredpacientes = List.from(_pacientes);
  }

  void _filterpacientes() {
    setState(() {
      _filteredpacientes = _pacientes
          .where((paciente) =>
              paciente['name'].toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  void _sortpacientes(String criteria) {
    setState(() {
      _filteredpacientes!.sort((a, b) {
        if (criteria == 'name') {
          return a['name'].compareTo(b['name']);
        } else if (criteria == 'dob') {
          return a['dob'].compareTo(b['dob']);
        } else if (criteria == 'weeks') {
          return a['weeks'].compareTo(b['weeks']);
        } else if (criteria == 'doctor') {
          return a['doctor'].compareTo(b['doctor']);
        } else if (criteria == 'nextAppointment') {
          return a['nextAppointment'].compareTo(b['nextAppointment']);
        }
        return 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pacientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navegar a la pantalla de agregar nuevo paciente
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar Pacientes',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _filterpacientes,
                ),
              ),
              onChanged: (value) {
                _filterpacientes();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterButton('Nombre', 'name'),
                _buildFilterButton('Fecha de Nacimiento', 'dob'),
                _buildFilterButton('Semanas de Gestación', 'weeks'),
                _buildFilterButton('Doctor Asignado', 'doctor'),
                _buildFilterButton('Próxima Cita', 'nextAppointment'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredpacientes!.length,
              itemBuilder: (context, index) {
                final paciente = _filteredpacientes![index];
                return ListTile(
                  title: Text(paciente['name']),
                  subtitle: Text(
                      'Fecha de Nacimiento: ${paciente['dob']}\nSemanas de Gestación: ${paciente['weeks']}\nDoctor: ${paciente['doctor']}\nPróxima Cita: ${paciente['nextAppointment']}'),
                  onTap: () {
                    // Navegar a la pantalla de perfil completo del paciente
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Navegar a la pantalla de edición de paciente
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String criteria) {
    return ElevatedButton(
      onPressed: () {
        _sortpacientes(criteria);
      },
      child: Text(label),
    );
  }
} */
