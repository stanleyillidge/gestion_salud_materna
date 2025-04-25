import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class GestionVisitas extends StatefulWidget {
  const GestionVisitas({super.key});

  @override
  GestionVisitasState createState() => GestionVisitasState();
}

class GestionVisitasState extends State<GestionVisitas> {
  DateTime _selectedDay = DateTime.now();
  final List<Map<String, dynamic>> _visitas = [];
  final _formKey = GlobalKey<FormState>();

  String _motivoVisita = '';
  String _observaciones = '';
  String _medicacion = '';

  void _addVisit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _visitas.add({
          'fecha': _selectedDay,
          'hora': TimeOfDay.now(),
          'motivo': _motivoVisita,
          'observaciones': _observaciones,
          'medicacion': _medicacion,
        });
      });
      Navigator.of(context).pop();
    }
  }

  void _showAddVisitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar Visita'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Motivo de la visita'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Por favor, ingrese el motivo de la visita';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _motivoVisita = value!;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                  onSaved: (value) {
                    _observaciones = value!;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Medicación prescrita'),
                  onSaved: (value) {
                    _medicacion = value!;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: _addVisit,
              child: const Text('Registrar'),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _getVisitsForDay(DateTime day) {
    return _visitas.where((visit) => isSameDay(visit['fecha'], day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Visitas'),
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _selectedDay,
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _getVisitsForDay(_selectedDay).length,
              itemBuilder: (context, index) {
                final visit = _getVisitsForDay(_selectedDay)[index];
                return ListTile(
                  title: Text('${visit['motivo']}'),
                  subtitle: Text('${visit['observaciones']}'),
                  trailing: Text('${visit['hora'].format(context)}'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVisitDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: GestionVisitas(),
  ));
}
