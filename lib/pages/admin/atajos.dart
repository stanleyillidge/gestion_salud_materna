import 'package:flutter/material.dart';

class Atajos extends StatelessWidget {
  const Atajos({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Atajos', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            ShortcutTile(title: 'Pacientes', icon: Icons.person, onTap: () {}),
            ShortcutTile(title: 'Doctores', icon: Icons.medical_services, onTap: () {}),
            ShortcutTile(title: 'Citas', icon: Icons.calendar_today, onTap: () {}),
            ShortcutTile(
              title: 'Gestionar Usuarios',
              icon: Icons.supervised_user_circle_outlined,
              onTap: () {},
            ),
            ShortcutTile(title: 'Configuración', icon: Icons.settings, onTap: () {}),
          ],
        ),
      ),
    );
  }
}

class ShortcutTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const ShortcutTile({super.key, required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}
