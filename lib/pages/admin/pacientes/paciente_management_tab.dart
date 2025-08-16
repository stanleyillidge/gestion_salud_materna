// pages/admin/pacientes/paciente_management_tab.dart
// ignore_for_file: use_build_context_synchronously, must_be_immutable

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/modelos.dart';
import '../../../services/firestore_service.dart';
import '../../../services/users_service.dart';
import '../create_user_form.dart';
import 'paciente_detail_screen.dart';

class PacienteManagementTab extends StatefulWidget {
  final String? searchTerm;
  final UserViewType viewType;
  // --- NUEVO: Recibir estado de agrupación ---
  final bool isGroupedByRisk;
  // ----------------------------------------

  const PacienteManagementTab({
    this.searchTerm,
    required this.viewType,
    required this.isGroupedByRisk, // <-- Hacerlo requerido
    super.key,
  });

  @override
  State<PacienteManagementTab> createState() => _PacienteManagementTabState();
}

class _PacienteManagementTabState extends State<PacienteManagementTab> {
  final FirestoreService _firestoreService = FirestoreService();
  final UsersService _userService = UsersService();

  // --- ELIMINADO: Estado interno de agrupación ---
  // bool _isGroupedByRisk = false;
  // ---------------------------------------------

  // ... (Funciones _filterUsers, _naturalSortCompare, getRiskColor, getRiskBackgroundColor, _sortRiskLevels SIN CAMBIOS) ...
  List<Usuario> _filterUsers(List<Usuario> allUsers, String? searchTerm) {
    if (searchTerm == null || searchTerm.isEmpty) {
      return allUsers;
    }
    final lowerSearchTerm = searchTerm.toLowerCase();
    return allUsers.where((user) {
      return user.displayName.toLowerCase().contains(lowerSearchTerm) ||
          user.email.toLowerCase().contains(lowerSearchTerm);
    }).toList();
  }

  int _naturalSortCompare(Usuario a, Usuario b) {
    String nameA = a.displayName;
    String nameB = b.displayName;

    if (nameA.isEmpty && nameB.isEmpty) return 0;
    if (nameA.isEmpty) return 1;
    if (nameB.isEmpty) return -1;

    RegExp numRegExp = RegExp(r'(\d+)$');
    Match? matchA = numRegExp.firstMatch(nameA);
    Match? matchB = numRegExp.firstMatch(nameB);

    if (matchA != null && matchB != null) {
      String prefixA = nameA.substring(0, matchA.start).trimRight();
      String prefixB = nameB.substring(0, matchB.start).trimRight();
      int prefixCompare = prefixA.toLowerCase().compareTo(prefixB.toLowerCase());
      if (prefixCompare != 0) return prefixCompare;
      try {
        int numA = int.parse(matchA.group(1)!);
        int numB = int.parse(matchB.group(1)!);
        return numA.compareTo(numB);
      } catch (e) {
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      }
    }
    if (matchA != null && matchB == null) return 1;
    if (matchA == null && matchB != null) return -1;
    return nameA.toLowerCase().compareTo(nameB.toLowerCase());
  }

  Color getRiskColor(String? riesgo) {
    // Define tu lógica de color aquí, puedes usar un ColorScheme si lo prefieres
    switch (riesgo?.toLowerCase()) {
      case 'crítico':
        return Colors.red.shade700;
      case 'alto':
        return Colors.orange.shade700;
      case 'moderado':
        return Colors.yellow.shade700;
      case 'bajo':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade500; // Color para 'null' o no definido
    }
  }

  Color getRiskBackgroundColor(BuildContext context, String? riesgo) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    switch (riesgo?.toLowerCase()) {
      case 'crítico':
        return isDarkMode ? Colors.red.shade900.withOpacity(0.4) : Colors.red.shade50;
      case 'alto':
        return isDarkMode ? Colors.orange.shade900.withOpacity(0.4) : Colors.orange.shade50;
      case 'moderado':
        return isDarkMode ? Colors.yellow.shade900.withOpacity(0.4) : Colors.yellow.shade50;
      case 'bajo':
        return isDarkMode ? Colors.green.shade900.withOpacity(0.4) : Colors.green.shade50;
      default:
        return isDarkMode ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade100;
    }
  }

  List<String?> _sortRiskLevels(List<String?> levels) {
    const order = ['crítico', 'alto', 'moderado', 'bajo'];
    levels.sort((a, b) {
      final indexA = a == null ? order.length : order.indexOf(a.toLowerCase());
      final indexB = b == null ? order.length : order.indexOf(b.toLowerCase());
      // Si no se encuentra en el orden predefinido, va después de los conocidos
      final effectiveIndexA = indexA == -1 ? order.length + 1 : indexA;
      final effectiveIndexB = indexB == -1 ? order.length + 1 : indexB;
      return effectiveIndexA.compareTo(effectiveIndexB);
    });
    return levels;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mantener Scaffold por si se necesita FAB específico aquí en el futuro
      body: StreamBuilder<List<Usuario>>(
        // --- ELIMINADO: Column y botón ---
        stream: _firestoreService.getAllpacientesStream(),
        builder: (context, snapshot) {
          // ... (Manejo de loading, error, no data IGUAL que antes) ...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                (widget.searchTerm?.isNotEmpty ?? false)
                    ? 'No se encontraron pacientes para "${widget.searchTerm}".'
                    : 'No hay pacientes registrados.',
              ),
            );
          }

          final allPacientes = snapshot.data!;
          final filteredPacientes = _filterUsers(allPacientes, widget.searchTerm);
          filteredPacientes.sort(_naturalSortCompare);
          final displayedPacientes = filteredPacientes;

          if (displayedPacientes.isEmpty) {
            return Center(
              child: Text(
                (widget.searchTerm?.isNotEmpty ?? false)
                    ? 'No se encontraron pacientes para "${widget.searchTerm}".'
                    : 'No hay pacientes que mostrar.',
              ),
            );
          }

          // --- Lógica de Renderizado Condicional (USA widget.isGroupedByRisk) ---
          if (widget.isGroupedByRisk) {
            // <-- USA EL PARÁMETRO DEL WIDGET
            // --- Vista Agrupada por Riesgo (Acordeón) ---
            final riskLevels = displayedPacientes.map((p) => p.nivelRiesgo).toSet().toList();
            final sortedRiskLevels = _sortRiskLevels(riskLevels);

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8.0, bottom: 125.0, left: 8.0, right: 8.0),
              itemCount: sortedRiskLevels.length,
              itemBuilder: (context, index) {
                final riskLevel = sortedRiskLevels[index];
                final patientsInGroup =
                    displayedPacientes.where((p) => p.nivelRiesgo == riskLevel).toList();
                final riskLabel = riskLevel ?? 'Sin Riesgo Definido';
                final riskLabelDisplay = (riskLabel == 'Moderado') ? 'Intermedio' : riskLabel;

                return ExpansionTile(
                  key: PageStorageKey(riskLabel), // Clave única para mantener estado
                  leading: Icon(Icons.circle, color: getRiskColor(riskLevel), size: 18),
                  title: Text(
                    '$riskLabelDisplay (${patientsInGroup.length})',
                    style: TextStyle(fontWeight: FontWeight.bold, color: getRiskColor(riskLevel)),
                  ),
                  backgroundColor: getRiskBackgroundColor(context, riskLevel),
                  children:
                      patientsInGroup
                          .map((paciente) => _buildUserListItem(paciente)) // Reusa el ListTile
                          .toList(),
                );
              },
            );
          } else {
            // --- Vista Estándar (Lista o Grid) ---
            if (widget.viewType == UserViewType.grid) {
              // Vista Grid (sin cambios)
              return LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.builder(
                    padding: const EdgeInsets.only(
                      top: 10.0,
                      bottom: 125.0,
                      left: 10.0,
                      right: 10.0,
                    ),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: constraints.maxWidth < 600 ? constraints.maxWidth : 300.0,
                      childAspectRatio:
                          constraints.maxWidth < 600
                              ? 2 / 1.850
                              : 2 / 1.85, // Ajustar para que quepa info
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: displayedPacientes.length,
                    itemBuilder: (context, index) {
                      return _buildUserGridItem(displayedPacientes[index]);
                    },
                  );
                },
              );
            } else {
              // Vista Lista (sin cambios)
              return ListView.builder(
                padding: const EdgeInsets.only(top: 10.0, bottom: 125.0, left: 4.0, right: 4.0),
                itemCount: displayedPacientes.length,
                itemBuilder: (context, index) {
                  return _buildUserListItem(displayedPacientes[index]);
                },
              );
            }
          }
          // --------------------------------------------------------------------
        },
      ),
    );
  }

  // --- Builders (_buildUserListItem, _buildUserGridItem) SIN CAMBIOS ---
  Widget _buildUserListItem(Usuario user) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ), // Ajusta margen si es necesario
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?'),
        ),
        title: Text(user.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Email: ${user.email}"),
            if (user.nivelRiesgo != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "Riesgo: ${(user.nivelRiesgo == 'Moderado') ? 'Intermedio' : user.nivelRiesgo}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getRiskColor(user.nivelRiesgo),
                  ),
                ),
              ),
          ],
        ),
        isThreeLine: user.nivelRiesgo != null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined, color: Colors.blue), // Icono de ver
              tooltip: 'Ver Detalles',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PacienteDetailScreen(pacienteId: user.uid, isAdminView: true),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.orange),
              tooltip: 'Editar Usuario',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreateUserScreen(initialData: user)),
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color:
                    (user.uid == FirebaseAuth.instance.currentUser?.uid) ? Colors.grey : Colors.red,
              ),
              tooltip:
                  (user.uid == FirebaseAuth.instance.currentUser?.uid)
                      ? 'No puedes eliminarte'
                      : 'Eliminar Usuario',
              onPressed:
                  (user.uid == FirebaseAuth.instance.currentUser?.uid)
                      ? null
                      : () => _confirmDeleteUser(context, user),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PacienteDetailScreen(pacienteId: user.uid, isAdminView: true),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserGridItem(Usuario user) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PacienteDetailScreen(pacienteId: user.uid, isAdminView: true),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 30,
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'P',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 8),
              if (user.nivelRiesgo != null)
                Chip(
                  label: Text(
                    "Riesgo: ${(user.nivelRiesgo == 'Moderado') ? 'Intermedio' : user.nivelRiesgo}",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          ThemeData.estimateBrightnessForColor(getRiskColor(user.nivelRiesgo)) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                    ),
                  ),
                  backgroundColor: getRiskColor(user.nivelRiesgo),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  visualDensity: VisualDensity.compact,
                ),

              Text(
                user.displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 1, // Limitado a 1 línea en grid
                overflow: TextOverflow.ellipsis,
              ),
              /* const Spacer(), // Empuja acciones hacia abajo
              const Divider(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    color: Colors.blue,
                    tooltip: 'Ver Detalles',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => PacienteDetailScreen(pacienteId: user.uid, isAdminView: true),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: Colors.orange,
                    tooltip: 'Editar Usuario',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreateUserScreen(initialData: user)),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color:
                          (user.uid == FirebaseAuth.instance.currentUser?.uid)
                              ? Colors.grey
                              : Colors.red,
                    ),
                    tooltip:
                        (user.uid == FirebaseAuth.instance.currentUser?.uid)
                            ? 'No puedes eliminarte'
                            : 'Eliminar Usuario',
                    onPressed:
                        (user.uid == FirebaseAuth.instance.currentUser?.uid)
                            ? null
                            : () => _confirmDeleteUser(context, user),
                  ),
                ],
              ), */
            ],
          ),
        ),
      ),
    );
  }

  // --- Función _confirmDeleteUser SIN CAMBIOS ---
  void _confirmDeleteUser(BuildContext context, Usuario user) {
    String userTypeDisplay = user.roles.isNotEmpty ? user.roles.first.name : 'usuario';
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de que quieres eliminar al $userTypeDisplay ${user.displayName}? Esta acción NO se puede deshacer y eliminará su cuenta y datos asociados.',
            ),
            actions: <Widget>[
              TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop()),
              TextButton(
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    await _userService.deleteUserAndProfile(user.uid, user.roles.first.name);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$userTypeDisplay eliminado correctamente'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }
}

// --- Helper capitalizeFirst (ASEGÚRATE DE QUE ESTÉ DISPONIBLE) ---
// Puedes ponerlo aquí o en un archivo de utilidades si no lo tienes ya
extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

/* // pages/admin/pacientes/paciente_management_tab.dart
// ignore_for_file: use_build_context_synchronously, must_be_immutable

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/modelos.dart';
import '../../../services/firestore_service.dart';
import '../../../services/users_service.dart';
import '../create_user_form.dart'; // Needed for edit navigation
import 'paciente_detail_screen.dart';

class PacienteManagementTab extends StatefulWidget {
  final String? searchTerm;
  final UserViewType viewType;

  const PacienteManagementTab({
    this.searchTerm,
    required this.viewType,
    super.key,
    required bool isGroupedByRisk,
  });

  @override
  State<PacienteManagementTab> createState() => _PacienteManagementTabState();
}

class _PacienteManagementTabState extends State<PacienteManagementTab> {
  final FirestoreService _firestoreService = FirestoreService();
  final UsersService _userService = UsersService();

  // --- NUEVO: Estado para controlar la agrupación ---
  bool _isGroupedByRisk = false;
  // ------------------------------------------------

  List<Usuario> _filterUsers(List<Usuario> allUsers, String? searchTerm) {
    if (searchTerm == null || searchTerm.isEmpty) {
      return allUsers;
    }
    final lowerSearchTerm = searchTerm.toLowerCase();
    return allUsers.where((user) {
      return user.displayName.toLowerCase().contains(lowerSearchTerm) ||
          user.email.toLowerCase().contains(lowerSearchTerm);
    }).toList();
  }

  int _naturalSortCompare(Usuario a, Usuario b) {
    String nameA = a.displayName;
    String nameB = b.displayName;

    if (nameA.isEmpty && nameB.isEmpty) return 0;
    if (nameA.isEmpty) return 1;
    if (nameB.isEmpty) return -1;

    RegExp numRegExp = RegExp(r'(\d+)$');
    Match? matchA = numRegExp.firstMatch(nameA);
    Match? matchB = numRegExp.firstMatch(nameB);

    if (matchA != null && matchB != null) {
      String prefixA = nameA.substring(0, matchA.start).trimRight();
      String prefixB = nameB.substring(0, matchB.start).trimRight();
      int prefixCompare = prefixA.toLowerCase().compareTo(prefixB.toLowerCase());
      if (prefixCompare != 0) return prefixCompare;
      try {
        int numA = int.parse(matchA.group(1)!);
        int numB = int.parse(matchB.group(1)!);
        return numA.compareTo(numB);
      } catch (e) {
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      }
    }
    if (matchA != null && matchB == null) return 1;
    if (matchA == null && matchB != null) return -1;
    return nameA.toLowerCase().compareTo(nameB.toLowerCase());
  }

  Color getRiskColor(String? riesgo) {
    // Define tu lógica de color aquí, puedes usar un ColorScheme si lo prefieres
    switch (riesgo?.toLowerCase()) {
      case 'crítico':
        return Colors.red.shade700;
      case 'alto':
        return Colors.orange.shade700;
      case 'moderado':
        return Colors.yellow.shade700;
      case 'bajo':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade500; // Color para 'null' o no definido
    }
  }

  Color getRiskBackgroundColor(BuildContext context, String? riesgo) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    switch (riesgo?.toLowerCase()) {
      case 'crítico':
        return isDarkMode ? Colors.red.shade900.withOpacity(0.4) : Colors.red.shade50;
      case 'alto':
        return isDarkMode ? Colors.orange.shade900.withOpacity(0.4) : Colors.orange.shade50;
      case 'moderado':
        return isDarkMode ? Colors.yellow.shade900.withOpacity(0.4) : Colors.yellow.shade50;
      case 'bajo':
        return isDarkMode ? Colors.green.shade900.withOpacity(0.4) : Colors.green.shade50;
      default:
        return isDarkMode ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade100;
    }
  }

  // --- NUEVO: Función para ordenar los niveles de riesgo ---
  List<String?> _sortRiskLevels(List<String?> levels) {
    const order = ['crítico', 'alto', 'moderado', 'bajo'];
    levels.sort((a, b) {
      final indexA = a == null ? order.length : order.indexOf(a.toLowerCase());
      final indexB = b == null ? order.length : order.indexOf(b.toLowerCase());
      // Si no se encuentra en el orden predefinido, va después de los conocidos
      final effectiveIndexA = indexA == -1 ? order.length + 1 : indexA;
      final effectiveIndexB = indexB == -1 ? order.length + 1 : indexB;
      return effectiveIndexA.compareTo(effectiveIndexB);
    });
    return levels;
  }
  // ------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        // Envolver en Column para añadir el botón
        children: [
          // --- NUEVO: Fila para el botón de agrupación ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    _isGroupedByRisk ? Icons.list_alt : Icons.layers, // Cambia icono
                    color: _isGroupedByRisk ? Theme.of(context).colorScheme.primary : null,
                  ),
                  tooltip: _isGroupedByRisk ? 'Vista Estándar' : 'Agrupar por Riesgo',
                  onPressed: () {
                    setState(() {
                      _isGroupedByRisk = !_isGroupedByRisk;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ----------------------------------------------
          Expanded(
            // El StreamBuilder ocupa el resto del espacio
            child: StreamBuilder<List<Usuario>>(
              stream: _firestoreService.getAllpacientesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      (widget.searchTerm?.isNotEmpty ?? false)
                          ? 'No se encontraron pacientes para "${widget.searchTerm}".'
                          : 'No hay pacientes registrados.',
                    ),
                  );
                }

                final allPacientes = snapshot.data!;
                final filteredPacientes = _filterUsers(allPacientes, widget.searchTerm);
                filteredPacientes.sort(_naturalSortCompare);
                final displayedPacientes = filteredPacientes;

                if (displayedPacientes.isEmpty) {
                  return Center(
                    child: Text(
                      (widget.searchTerm?.isNotEmpty ?? false)
                          ? 'No se encontraron pacientes para "${widget.searchTerm}".'
                          : 'No hay pacientes que mostrar.',
                    ),
                  );
                }

                // --- Lógica de Renderizado Condicional ---
                if (_isGroupedByRisk) {
                  // --- Vista Agrupada por Riesgo (Acordeón) ---
                  final riskLevels = displayedPacientes.map((p) => p.nivelRiesgo).toSet().toList();
                  final sortedRiskLevels = _sortRiskLevels(riskLevels);

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 125.0, left: 8.0, right: 8.0),
                    itemCount: sortedRiskLevels.length,
                    itemBuilder: (context, index) {
                      final riskLevel = sortedRiskLevels[index];
                      final patientsInGroup =
                          displayedPacientes.where((p) => p.nivelRiesgo == riskLevel).toList();
                      final riskLabel = riskLevel ?? 'Sin Riesgo Definido';
                      final riskLabelDisplay = (riskLabel == 'Moderado') ? 'Intermedio' : riskLabel;

                      return ExpansionTile(
                        key: PageStorageKey(riskLabel), // Clave única para mantener estado
                        leading: Icon(Icons.circle, color: getRiskColor(riskLevel), size: 18),
                        title: Text(
                          '$riskLabelDisplay (${patientsInGroup.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: getRiskColor(riskLevel),
                          ),
                        ),
                        backgroundColor: getRiskBackgroundColor(context, riskLevel),
                        children:
                            patientsInGroup
                                .map(
                                  (paciente) => _buildUserListItem(paciente),
                                ) // Reusa el ListTile
                                .toList(),
                      );
                    },
                  );
                } else {
                  // --- Vista Estándar (Lista o Grid) ---
                  if (widget.viewType == UserViewType.grid) {
                    // Vista Grid (sin cambios)
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.builder(
                          padding: const EdgeInsets.only(
                            top: 10.0,
                            bottom: 125.0,
                            left: 10.0,
                            right: 10.0,
                          ),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent:
                                constraints.maxWidth < 600 ? constraints.maxWidth : 300.0,
                            childAspectRatio: constraints.maxWidth < 600 ? 2 / 1.850 : 2 / 1.85,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: displayedPacientes.length,
                          itemBuilder: (context, index) {
                            return _buildUserGridItem(displayedPacientes[index]);
                          },
                        );
                      },
                    );
                  } else {
                    // Vista Lista (sin cambios)
                    return ListView.builder(
                      padding: const EdgeInsets.only(
                        top: 10.0,
                        bottom: 125.0,
                        left: 4.0,
                        right: 4.0,
                      ),
                      itemCount: displayedPacientes.length,
                      itemBuilder: (context, index) {
                        return _buildUserListItem(displayedPacientes[index]);
                      },
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserListItem(Usuario user) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ), // Ajusta margen si es necesario
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?'),
        ),
        title: Text(user.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Email: ${user.email}"),
            if (user.nivelRiesgo != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "Riesgo: ${(user.nivelRiesgo == 'Moderado') ? 'Intermedio' : user.nivelRiesgo}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getRiskColor(user.nivelRiesgo),
                  ),
                ),
              ),
          ],
        ),
        isThreeLine: user.nivelRiesgo != null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined, color: Colors.blue), // Icono de ver
              tooltip: 'Ver Detalles',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PacienteDetailScreen(pacienteId: user.uid, isAdminView: true),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.orange),
              tooltip: 'Editar Usuario',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreateUserScreen(initialData: user)),
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color:
                    (user.uid == FirebaseAuth.instance.currentUser?.uid) ? Colors.grey : Colors.red,
              ),
              tooltip:
                  (user.uid == FirebaseAuth.instance.currentUser?.uid)
                      ? 'No puedes eliminarte'
                      : 'Eliminar Usuario',
              onPressed:
                  (user.uid == FirebaseAuth.instance.currentUser?.uid)
                      ? null
                      : () => _confirmDeleteUser(context, user),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PacienteDetailScreen(pacienteId: user.uid, isAdminView: true),
            ),
          );
        },
      ),
    );
  }

  /* Widget _buildUserGridItem(Usuario user) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PacienteDetailScreen(pacienteId: user.uid, isAdminView: true),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 30,
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'P',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 8),
              if (user.nivelRiesgo != null)
                Chip(
                  label: Text(
                    "Riesgo: ${(user.nivelRiesgo == 'Moderado') ? 'Intermedio' : user.nivelRiesgo}",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          ThemeData.estimateBrightnessForColor(getRiskColor(user.nivelRiesgo)) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                    ),
                  ),
                  backgroundColor: getRiskColor(user.nivelRiesgo),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  visualDensity: VisualDensity.compact,
                ),
              Text(
                user.displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 1, // Limitado a 1 línea en grid
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(), // Empuja acciones hacia abajo
              const Divider(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: Colors.orange,
                    tooltip: 'Editar Usuario',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreateUserScreen(initialData: user)),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color:
                          (user.uid == FirebaseAuth.instance.currentUser?.uid)
                              ? Colors.grey
                              : Colors.red,
                    ),
                    tooltip:
                        (user.uid == FirebaseAuth.instance.currentUser?.uid)
                            ? 'No puedes eliminarte'
                            : 'Eliminar Usuario',
                    onPressed:
                        (user.uid == FirebaseAuth.instance.currentUser?.uid)
                            ? null
                            : () => _confirmDeleteUser(context, user),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  } */
  // --- NUEVO: Builder para elemento de GRID ---
  Widget _buildUserGridItem(Usuario user) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4.0), // Menor margen para grid
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PacienteDetailScreen(pacienteId: user.uid, isAdminView: true),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            // mainAxisAlignment: MainAxisAlignment.spaceBetween, // You might not need this with Expanded
            mainAxisSize: MainAxisSize.min, // Constrain column height to its content + Expanded
            children: [
              // Icono/Avatar
              CircleAvatar(
                radius: 30,
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : 'P', // 'P' de Paciente
                  style: const TextStyle(fontSize: 20),
                ),
                // Podrías añadir backgroundImage si tienes photoUrl
              ),
              const SizedBox(height: 8),
              // --- MOSTRAR RIESGO EN GRID ---
              if (user.nivelRiesgo != null)
                Padding(
                  // Add some vertical padding if needed
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Chip(
                    label: Text(
                      "Riesgo: ${(user.nivelRiesgo == 'Moderado') ? 'Intermedio' : user.nivelRiesgo}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color:
                            ThemeData.estimateBrightnessForColor(getRiskColor(user.nivelRiesgo)) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                      ),
                    ),
                    backgroundColor: getRiskColor(user.nivelRiesgo),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              // --- FIN MOSTRAR RIESGO ---

              // Nombre y Email (ajusta maxLines y overflow)
              Text(
                user.displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 1, // Limitado a 1 línea en grid
                overflow: TextOverflow.ellipsis,
              ),

              // --- REEMPLAZAR Spacer CON Expanded ---
              // const Spacer(), // REMOVE THIS
              const Expanded(child: SizedBox()), // ADD THIS - Pushes content below it down
              // ---------------------------------------

              // Acciones
              const Divider(height: 8), // Optional: adjust height
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround, // Espacia los iconos
                children: [
                  // --- BOTÓN VER DETALLES (Añadido para consistencia) ---
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    color: Colors.blue,
                    tooltip: 'Ver Detalles',
                    padding: EdgeInsets.zero, // Reduce padding
                    visualDensity: VisualDensity.compact, // Make it smaller
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => PacienteDetailScreen(pacienteId: user.uid, isAdminView: true),
                        ),
                      );
                    },
                  ),
                  // --- BOTÓN EDITAR ---
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: Colors.orange,
                    tooltip: 'Editar Usuario',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreateUserScreen(initialData: user)),
                      );
                    },
                  ),
                  // --- BOTÓN ELIMINAR ---
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color:
                          (user.uid == FirebaseAuth.instance.currentUser?.uid)
                              ? Colors
                                  .grey // Don't allow self-delete visually
                              : Colors.red,
                    ),
                    tooltip:
                        (user.uid == FirebaseAuth.instance.currentUser?.uid)
                            ? 'No puedes eliminarte'
                            : 'Eliminar Usuario',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed:
                        (user.uid == FirebaseAuth.instance.currentUser?.uid)
                            ? null // Disable self-delete action
                            : () => _confirmDeleteUser(context, user),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, Usuario user) {
    String userTypeDisplay = user.roles.isNotEmpty ? user.roles.first.name : 'usuario';
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de que quieres eliminar al $userTypeDisplay ${user.displayName}? Esta acción NO se puede deshacer y eliminará su cuenta y datos asociados.',
            ),
            actions: <Widget>[
              TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop()),
              TextButton(
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    await _userService.deleteUserAndProfile(user.uid, user.roles.first.name);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$userTypeDisplay eliminado correctamente'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }
}

// Helper capitalizeFirst (necesario si no está global)
extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} */

/* // pages/admin/pacientes/paciente_management_tab.dart
// ignore_for_file: use_build_context_synchronously, must_be_immutable

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// import '../../../models/modelos.dart'; // Asegúrate que la ruta sea correcta
import '../../../models/modelos.dart';
import '../../../services/firestore_service.dart'; // Asegúrate que la ruta sea correcta
import '../../../services/users_service.dart';
import '../create_user_form.dart';
import 'paciente_detail_screen.dart';

class PacienteManagementTab extends StatefulWidget {
  final String? searchTerm;
  // --- NUEVO: Parámetro para recibir tipo de vista ---
  final UserViewType viewType;

  const PacienteManagementTab({
    this.searchTerm,
    required this.viewType, // Requerido
    super.key,
  });

  @override
  State<PacienteManagementTab> createState() => _PacienteManagementTabState();
}

class _PacienteManagementTabState extends State<PacienteManagementTab> {
  final FirestoreService _firestoreService = FirestoreService();
  final UsersService _userService = UsersService(); // Asegúrate de tener este servicio

  List<Usuario> _filterUsers(List<Usuario> allUsers, String? searchTerm) {
    // ... (código de filtro sin cambios) ...
    if (searchTerm == null || searchTerm.isEmpty) {
      return allUsers;
    }
    final lowerSearchTerm = searchTerm.toLowerCase();
    return allUsers.where((user) {
      return user.displayName.toLowerCase().contains(lowerSearchTerm) ||
          user.email.toLowerCase().contains(lowerSearchTerm);
    }).toList();
  }

  // --- NUEVO: Función de Comparación Natural ---
  /// Compara dos strings de forma natural (alfanumérica).
  /// Ejemplo: "item 2" < "item 10"
  int _naturalSortCompare(Usuario a, Usuario b) {
    // Obtener nombres, manejar null o vacíos poniéndolos al final
    String nameA = a.displayName;
    String nameB = b.displayName;

    if (nameA.isEmpty && nameB.isEmpty) return 0;
    if (nameA.isEmpty) return 1; // a (vacío) va después de b
    if (nameB.isEmpty) return -1; // b (vacío) va después de a

    // Expresión regular para encontrar números al final del string
    RegExp numRegExp = RegExp(r'(\d+)$');

    Match? matchA = numRegExp.firstMatch(nameA);
    Match? matchB = numRegExp.firstMatch(nameB);

    // Caso 1: Ambos tienen número al final
    if (matchA != null && matchB != null) {
      String prefixA = nameA.substring(0, matchA.start).trimRight();
      String prefixB = nameB.substring(0, matchB.start).trimRight();

      // Compara prefijos (ignorando mayúsculas/minúsculas)
      int prefixCompare = prefixA.toLowerCase().compareTo(prefixB.toLowerCase());
      if (prefixCompare != 0) {
        return prefixCompare;
      }

      // Si los prefijos son iguales, compara los números
      try {
        int numA = int.parse(matchA.group(1)!);
        int numB = int.parse(matchB.group(1)!);
        return numA.compareTo(numB);
      } catch (e) {
        // Si falla el parseo del número, recurre a comparación de strings completa
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      }
    }

    // Caso 2: Solo A tiene número al final (considera A > B)
    if (matchA != null && matchB == null) {
      return 1; // O -1 si prefieres que los que tienen número vayan primero
    }

    // Caso 3: Solo B tiene número al final (considera B > A)
    if (matchA == null && matchB != null) {
      return -1; // O 1 si prefieres que los que tienen número vayan primero
    }

    // Caso 4: Ninguno tiene número al final (comparación estándar)
    return nameA.toLowerCase().compareTo(nameB.toLowerCase());
  }
  // --- FIN Función de Comparación Natural ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mantenemos el Scaffold interno por si necesitas FAB específico aquí
      body: StreamBuilder<List<Usuario>>(
        stream: _firestoreService.getAllpacientesStream(),
        builder: (context, snapshot) {
          // ... (manejo de loading, error, no data sin cambios) ...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            if (widget.searchTerm?.isNotEmpty ?? false) {
              return Center(
                child: Text('No se encontraron pacientes para "${widget.searchTerm}".'),
              );
            } else {
              return const Center(child: Text('No hay pacientes registrados.'));
            }
          }

          final allPacientes = snapshot.data!;
          // final displayedPacientes = _filterUsers(allPacientes, widget.searchTerm);
          // 1. Filtrar
          final filteredPacientes = _filterUsers(allPacientes, widget.searchTerm);

          // --- 2. Ordenar Naturalmente ---
          filteredPacientes.sort(_naturalSortCompare); // Llama a la función de ordenamiento

          // Usar la lista ordenada
          final displayedPacientes = filteredPacientes;
          // --- FIN Ordenamiento ---

          if (displayedPacientes.isEmpty) {
            return Center(
              child: Text(
                (widget.searchTerm?.isNotEmpty ?? false)
                    ? 'No se encontraron pacientes para "${widget.searchTerm}".'
                    : 'No hay pacientes que mostrar.',
              ),
            );
          }

          // --- NUEVO: Decisión de layout ---
          if (widget.viewType == UserViewType.grid) {
            // --- Vista Grid ---
            return LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 125.0, left: 10.0, right: 10.0),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent:
                        constraints.maxWidth < 600
                            ? constraints.maxWidth
                            : 300.0, // Ancho máximo de cada tarjeta
                    childAspectRatio:
                        constraints.maxWidth < 600
                            ? 1.850
                            : 2 / 1.85, // Relación ancho/alto (ajustar)
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: displayedPacientes.length,
                  itemBuilder: (context, index) {
                    return _buildUserGridItem(displayedPacientes[index]); // Llama al nuevo builder
                  },
                );
              },
            );
          } else {
            // --- Vista Lista (por defecto) ---
            return ListView.builder(
              padding: const EdgeInsets.only(top: 10.0, bottom: 125.0, left: 4.0, right: 4.0),
              itemCount: displayedPacientes.length,
              itemBuilder: (context, index) {
                return _buildUserListItem(displayedPacientes[index]); // Llama al builder de lista
              },
            );
          }
        },
      ),
      // FAB Removido - Gestionado en el padre
      // floatingActionButton: FloatingActionButton(...)
    );
  }

  // --- NUEVO: Helper para color de riesgo ---
  Color getRiskColor(String? riesgo) {
    switch (riesgo?.toLowerCase()) {
      case 'crítico':
        return Colors.red.shade700;
      case 'alto':
        return Colors.orange.shade700;
      case 'moderado':
        return Colors.yellow.shade700;
      case 'bajo':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }
  // --- FIN Helper ---

  // --- Builder para elemento de LISTA ---
  Widget _buildUserListItem(Usuario user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?'),
        ),
        title: Text(user.displayName),
        subtitle: Column(
          // Usar Column para múltiples líneas
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Email: ${user.email}"),
            if (user.nivelRiesgo != null) // Mostrar solo si existe
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "Riesgo IA: ${(user.nivelRiesgo == 'Moderado') ? 'Intermedio' : user.nivelRiesgo}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getRiskColor(user.nivelRiesgo), // Usa el helper de color
                  ),
                ),
              ),
          ],
        ),
        isThreeLine: user.nivelRiesgo != null, // Ajustar si se muestra el riesgo
        /* trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.blue),
              tooltip: 'Ver Detalles',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PacienteDetailScreen(pacienteId: user.uid, isAdminView: true),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Eliminar Paciente',
              onPressed: () => _confirmDeletepaciente(context, user),
            ),
          ],
        ), */
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- NUEVO: Botón Editar ---
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.orange), // Icono de editar
              tooltip: 'Editar Usuario',
              onPressed: () {
                // Navegar a CreateUserScreen pasando los datos del usuario
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateUserScreen(initialData: user), // Pasa el 'user' actual
                  ),
                );
              },
            ),
            // --- FIN NUEVO ---
            IconButton(
              icon: Icon(
                Icons.delete,
                // Deshabilitar si es el usuario actual (solo aplica a admin/doctor tab)
                color:
                    (user.uid == FirebaseAuth.instance.currentUser?.uid &&
                            (user.roles.contains(UserRole.admin) ||
                                user.roles.contains(UserRole.doctor)))
                        ? Colors.grey
                        : Colors.red,
              ),
              tooltip:
                  (user.uid == FirebaseAuth.instance.currentUser?.uid &&
                          (user.roles.contains(UserRole.admin) ||
                              user.roles.contains(UserRole.doctor)))
                      ? 'No puedes eliminarte'
                      : 'Eliminar Usuario',
              onPressed:
                  (user.uid == FirebaseAuth.instance.currentUser?.uid &&
                          (user.roles.contains(UserRole.admin) ||
                              user.roles.contains(UserRole.doctor)))
                      ? null // Deshabilitar si es el usuario actual
                      : () => _confirmDeleteUser(
                        context,
                        user,
                      ), // Llama a la función de borrado correcta
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PacienteDetailScreen(pacienteId: user.uid, isAdminView: true),
            ),
          );
        },
      ),
    );
  }

  // --- Función de borrado (renombrada para claridad) ---
  // void _confirmDeletepaciente(BuildContext context, Usuario user) { // <--- Nombre anterior
  void _confirmDeleteUser(BuildContext context, Usuario user) {
    // <--- Nuevo nombre genérico
    String userTypeDisplay =
        user.roles.isNotEmpty ? user.roles.first.name : 'usuario'; // Nombre para mostrar
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de que quieres eliminar al $userTypeDisplay ${user.displayName}? Esta acción NO se puede deshacer y eliminará su cuenta y datos asociados.',
            ),
            actions: <Widget>[
              TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop()),
              TextButton(
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    // Usa el método deleteUserAndProfile del servicio actualizado
                    await _userService.deleteUserAndProfile(
                      user.uid,
                      user.roles.first.name,
                    ); // Pasa el tipo como string
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$userTypeDisplay eliminado correctamente'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }

  // --- NUEVO: Builder para elemento de GRID ---
  Widget _buildUserGridItem(Usuario user) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4.0), // Menor margen para grid
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PacienteDetailScreen(pacienteId: user.uid, isAdminView: true),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Espacia verticalmente
            children: [
              // Icono/Avatar
              CircleAvatar(
                radius: 30,
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : 'P', // 'P' de Paciente
                  style: const TextStyle(fontSize: 20),
                ),
                // Podrías añadir backgroundImage si tienes photoUrl
              ),
              const SizedBox(height: 8),
              // --- MOSTRAR RIESGO EN GRID ---
              if (user.nivelRiesgo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Chip(
                    // Usar Chip para destacar visualmente
                    label: Text(
                      "Riesgo: ${(user.nivelRiesgo == 'Moderado') ? 'Intermedio' : user.nivelRiesgo}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color:
                            ThemeData.estimateBrightnessForColor(getRiskColor(user.nivelRiesgo)) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black87, // Contraste texto
                      ),
                    ),
                    backgroundColor: getRiskColor(user.nivelRiesgo),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              // --- FIN MOSTRAR RIESGO ---

              // Nombre y Email (ajusta maxLines y overflow)
              Text(
                user.displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Acciones
              /* const Spacer(), // Empuja las acciones hacia abajo
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround, // Espacia los iconos
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20), // Icono más pequeño
                    color: Colors.blue,
                    tooltip: 'Ver Detalles',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => PacienteDetailScreen(pacienteId: user.uid, isAdminView: true),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20), // Icono más pequeño
                    color: Colors.red,
                    tooltip: 'Eliminar Paciente',
                    onPressed: () => _confirmDeletepaciente(context, user),
                  ),
                ],
              ), */
            ],
          ),
        ),
      ),
    );
  }

  // _confirmDeletepaciente se mantiene igual
  void _confirmDeletepaciente(BuildContext context, Usuario user) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de que quieres eliminar al paciente ${user.displayName}? Esta acción NO se puede deshacer y eliminará su cuenta y datos asociados.',
            ),
            actions: <Widget>[
              TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop()),
              TextButton(
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    // Llama a la función de borrado completa (Auth + Firestore)
                    await _firestoreService.deleteUser(user.uid, 'paciente'); // Pasa el tipo
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Paciente eliminado correctamente'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }
} */
