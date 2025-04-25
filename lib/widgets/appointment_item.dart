import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/modelos.dart';
import '../providers/appointment_provider.dart';

class AppointmentItem extends StatelessWidget {
  final Cita appointment;

  const AppointmentItem(this.appointment, {super.key});

  @override
  Widget build(BuildContext context) {
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    // Formatear la fecha
    final String formattedDate = DateFormat('yyyy-MM-dd').format(appointment.fecha);
    if (kDebugMode) {
      print('${appointment.nombrePaciente} - $formattedDate'.split(' '));
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(appointment.titulo ?? 'Sin Título'),
        subtitle: Text('${appointment.nombrePaciente} - $formattedDate'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditAppointmentDialog(context, appointment),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                appointmentProvider.eliminarCita(appointment.id!);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAppointmentDialog(BuildContext context, Cita appointment) {
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    String? title = appointment.titulo;
    String pacienteName = appointment.nombrePaciente;
    DateTime date = appointment.fecha;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Cita'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: title,
                  decoration: const InputDecoration(labelText: 'Título'),
                  onSaved: (value) {
                    title = value;
                  },
                ),
                TextFormField(
                  initialValue: pacienteName,
                  decoration: const InputDecoration(labelText: 'Nombre del Paciente'),
                  onSaved: (value) {
                    pacienteName = value!;
                  },
                ),
                TextButton(
                  onPressed: () async {
                    date =
                        await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        ) ??
                        date;
                  },
                  child: const Text('Seleccionar Fecha'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  final updatedAppointment = appointment.copiarCon(
                    titulo: title,
                    nombrePaciente: pacienteName,
                    fecha: date,
                  );
                  appointmentProvider.editarCita(updatedAppointment);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}
