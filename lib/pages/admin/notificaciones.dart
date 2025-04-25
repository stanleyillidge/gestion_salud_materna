import 'package:flutter/material.dart';

class Notificaciones extends StatelessWidget {
  const Notificaciones({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.all(16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Notificaciones', style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            NotificationTile(
              type: 'Error',
              message: 'Error en el sistema',
            ),
            NotificationTile(
              type: 'Advertencia',
              message: 'Nueva cita agendada',
            ),
            NotificationTile(
              type: 'Información',
              message: 'Cita cancelada',
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final String type;
  final String message;

  const NotificationTile({super.key, required this.type, required this.message});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.notification_important),
      title: Text(type),
      subtitle: Text(message),
    );
  }
}
