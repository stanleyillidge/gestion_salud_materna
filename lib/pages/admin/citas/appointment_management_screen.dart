// pages/admin/appointment_management_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/modelos.dart';
import '../../../services/firestore_service.dart';
import 'appointment_form_dialog.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  State<AppointmentManagementScreen> createState() => _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState extends State<AppointmentManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final DateFormat _formatter = DateFormat('EEEE dd MMM yyyy hh:mm a', 'es_ES');
  final DateFormat _dateFilterFormatter = DateFormat('dd MMM yyyy', 'es_ES');

  // --- ESTADO PARA BÚSQUEDA Y FILTROS ---
  final TextEditingController _userSearchController = TextEditingController();
  List<Usuario> _allUsersForSearch = [];
  Usuario? _selectedUserFilter;
  bool _isLoadingUsers = true;
  String? _userLoadError;
  String? _selectedStatusFilter;
  DateTime? _selectedDateFilter;
  final List<String> _statuses = ['programada', 'completada', 'cancelada'];

  // --- NUEVO: Estado para el tipo de vista ---
  UserViewType _currentViewType = UserViewType.list; // Vista inicial

  @override
  void initState() {
    super.initState();
    _loadAllUsersForSearch();
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  // --- Carga de Usuarios (sin cambios) ---
  Future<void> _loadAllUsersForSearch() async {
    // ... (código existente sin cambios) ...
    setState(() {
      _isLoadingUsers = true;
      _userLoadError = null;
    });
    try {
      final results = await Future.wait([
        _firestoreService.getAllpacientesStream().first,
        _firestoreService.getAllDoctorsStream().first,
      ]);
      final List<Usuario> pacientes = results[0];
      final List<Usuario> doctores = results[1];
      final Map<String, Usuario> userMap = {};
      for (var user in [...pacientes, ...doctores]) {
        userMap[user.uid] = user;
      }
      setState(() {
        _allUsersForSearch =
            userMap.values.toList()
              ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
        _isLoadingUsers = false;
      });
    } catch (e) {
      print("Error cargando usuarios para búsqueda: $e");
      setState(() {
        _userLoadError = "Error al cargar lista de usuarios.";
        _isLoadingUsers = false;
      });
    }
  }

  // --- Funciones CRUD y UI (_showAppointmentDialog, _confirmDelete, etc. sin cambios) ---
  Future<void> _showAppointmentDialog({Cita? cita}) async {
    // ... (código existente sin cambios) ...
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppointmentFormDialog(firestoreService: _firestoreService, cita: cita),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cita == null ? 'Cita creada.' : 'Cita actualizada.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Cita cita) async {
    // ... (código existente sin cambios) ...
    if (cita.id == null) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de eliminar la cita de "${cita.nombrePaciente}" el ${_formatter.format(cita.fecha)}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      try {
        await _firestoreService.deleteAppointment(cita.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita eliminada.'), backgroundColor: Colors.orange),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusCardColor(BuildContext context, String? status) {
    // ... (código existente sin cambios) ...
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    switch (status?.toLowerCase()) {
      case 'completada':
        return isDarkMode ? Colors.green.shade900.withOpacity(0.4) : Colors.green.shade50;
      case 'cancelada':
        return isDarkMode
            ? colorScheme.errorContainer.withOpacity(0.3)
            : colorScheme.errorContainer;
      case 'programada':
      default:
        return isDarkMode
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : colorScheme.primaryContainer.withOpacity(0.4);
    }
  }

  Widget _getStatusIconVisual(BuildContext context, String? status) {
    // ... (código existente sin cambios) ...
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color iconColor;
    IconData statusIcon;
    switch (status?.toLowerCase()) {
      case 'completada':
        iconColor = isDarkMode ? Colors.green.shade300 : Colors.green.shade700;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelada':
        iconColor = colorScheme.error;
        statusIcon = Icons.cancel;
        break;
      case 'programada':
      default:
        iconColor = colorScheme.primary;
        statusIcon = Icons.schedule;
        break;
    }
    return Icon(statusIcon, color: iconColor);
  }

  String _capitalize(String? s) {
    // ... (código existente sin cambios) ...
    if (s == null || s.isEmpty) return 'Desconocido';
    return s[0].toUpperCase() + s.substring(1);
  }

  Future<void> _selectFilterDate(BuildContext context) async {
    // ... (código existente sin cambios) ...
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Selecciona una fecha para filtrar',
      cancelText: 'Cancelar',
      confirmText: 'Filtrar',
    );
    if (picked != null && picked != _selectedDateFilter) {
      setState(() {
        _selectedDateFilter = picked;
      });
    }
  }

  // --- MODIFICADO: Construir la barra de filtros (añadir botón de vista) ---
  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Wrap(
        spacing: _selectedDateFilter != null ? 0.0 : 15.0,
        runSpacing: 10.0,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: [
          // --- Filtro de Fecha (como antes) ---
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 48,
                constraints: const BoxConstraints(minWidth: 160),
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TextButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _selectedDateFilter == null
                        ? 'Filtrar Fecha'
                        : _dateFilterFormatter.format(_selectedDateFilter!),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(
                        _selectedDateFilter == null ? 0.7 : 1.0,
                      ),
                      fontWeight: _selectedDateFilter == null ? FontWeight.normal : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () => _selectFilterDate(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    splashFactory: NoSplash.splashFactory,
                    // highlightColor: Colors.transparent,
                  ),
                ),
              ),
              if (_selectedDateFilter != null)
                SizedBox(
                  width: 40,
                  height: 48,
                  child: IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: 'Quitar filtro de fecha',
                    onPressed: () {
                      setState(() {
                        _selectedDateFilter = null;
                      });
                    },
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                )
              else
                const SizedBox(width: 0), // Placeholder
            ],
          ),

          // --- Filtro de Estado (como antes) ---
          SizedBox(
            width: 175,
            child: DropdownButtonFormField<String?>(
              // ... (código dropdown sin cambios) ...
              value: _selectedStatusFilter,
              isDense: true,
              decoration: InputDecoration(
                labelText: 'Estado',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                suffixIcon:
                    _selectedStatusFilter != null
                        ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Quitar filtro de estado',
                          onPressed: () {
                            setState(() {
                              _selectedStatusFilter = null;
                            });
                          },
                          visualDensity: VisualDensity.compact,
                        )
                        : null,
              ),
              hint: const Text('Todos'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                ..._statuses.map(
                  (status) => DropdownMenuItem(value: status, child: Text(_capitalize(status))),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatusFilter = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- NUEVO: Widget Builder para el item de la lista (extraído) ---
  Widget _buildAppointmentListItem(BuildContext context, Cita cita) {
    final cardBackgroundColor = _getStatusCardColor(context, cita.estado);
    final textColor =
        ThemeData.estimateBrightnessForColor(cardBackgroundColor) == Brightness.dark
            ? Colors.white70
            : Colors.black87;
    final actionIconColor = textColor.withOpacity(0.8);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      color: cardBackgroundColor,
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: _getStatusIconVisual(context, cita.estado),
        title: Text(
          cita.titulo ?? 'Cita',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Paciente: ${cita.nombrePaciente}\n'
          'Doctor: ${cita.nombreDoctor ?? "No asignado"}\n'
          'Fecha: ${_formatter.format(cita.fecha)}\n'
          'Estado: ${_capitalize(cita.estado)}',
          style: TextStyle(color: textColor.withOpacity(0.9)),
        ),
        isThreeLine: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: Colors.orange.shade300),
              tooltip: 'Editar Cita',
              onPressed: () => _showAppointmentDialog(cita: cita),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
              tooltip: 'Eliminar Cita',
              onPressed: () => _confirmDelete(cita),
            ),
          ],
        ),
        onTap: () => _showAppointmentDialog(cita: cita),
      ),
    );
  }

  // --- NUEVO: Widget Builder para el item de la tarjeta (Wrap/Grid) ---
  // --- MODIFICADO: Widget Builder para el item de la tarjeta (Wrap/Grid) ---
  Widget _buildAppointmentCardItem(BuildContext context, Cita cita) {
    final cardBackgroundColor = _getStatusCardColor(context, cita.estado);
    final textColor =
        ThemeData.estimateBrightnessForColor(cardBackgroundColor) == Brightness.dark
            ? Colors.white70
            : Colors.black87;
    // final actionIconColor = textColor.withOpacity(0.8); // Ya no es necesario aquí directamente

    return SizedBox(
      width: 350,
      child: Card(
        margin: const EdgeInsets.all(4),
        color: cardBackgroundColor,
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showAppointmentDialog(cita: cita),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              // La columna que causaba el problema
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Mantenemos esto
              children: [
                Row(
                  // Título y Estado
                  children: [
                    _getStatusIconVisual(context, cita.estado),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cita.titulo ?? 'Cita',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _capitalize(cita.estado),
                      style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 12),
                    ),
                  ],
                ),
                const Divider(height: 12),
                Text(
                  'Paciente: ${cita.nombrePaciente}',
                  style: TextStyle(color: textColor, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Doctor: ${cita.nombreDoctor ?? "No asignado"}',
                  style: TextStyle(color: textColor, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Fecha: ${_formatter.format(cita.fecha)}',
                  style: TextStyle(color: textColor, fontSize: 13),
                ),
                // const Spacer(), // <<<====== ELIMINADO!
                // Añadimos un SizedBox para asegurar algo de espacio antes de los botones
                const SizedBox(height: 8),
                const Divider(height: 12),
                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: Colors.orange.shade300, size: 20),
                      tooltip: 'Editar Cita',
                      onPressed: () => _showAppointmentDialog(cita: cita),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                      tooltip: 'Eliminar Cita',
                      onPressed: () => _confirmDelete(cita),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Citas')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Autocomplete (sin cambios)
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Autocomplete<Usuario>(
                    /* ... código autocomplete ... */
                    fieldViewBuilder: (context, fieldController, fieldFocusNode, onFieldSubmitted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_userSearchController.text != fieldController.text &&
                            mounted &&
                            _selectedUserFilter != null) {
                          if (fieldController.text != _selectedUserFilter!.displayName) {
                            fieldController.text = _selectedUserFilter!.displayName;
                          }
                        }
                      });
                      return TextFormField(
                        controller: fieldController,
                        focusNode: fieldFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Buscar por paciente o doctor...',
                          prefixIcon:
                              _isLoadingUsers
                                  ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                  : const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          suffixIcon:
                              fieldController.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    tooltip: 'Limpiar filtro',
                                    onPressed: () {
                                      fieldController.clear();
                                      setState(() {
                                        _selectedUserFilter = null;
                                      });
                                      fieldFocusNode.unfocus();
                                    },
                                  )
                                  : null,
                        ),
                        onChanged: (value) {
                          if (value.isEmpty && _selectedUserFilter != null) {
                            setState(() {
                              _selectedUserFilter = null;
                            });
                          }
                        },
                      );
                    },
                    optionsBuilder: (TextEditingValue tv) {
                      if (_isLoadingUsers) return const Iterable.empty();
                      final q = tv.text.toLowerCase();
                      if (q.length < 2) return const Iterable.empty();
                      return _allUsersForSearch.where(
                        (u) =>
                            u.displayName.toLowerCase().contains(q) ||
                            u.email.toLowerCase().contains(q),
                      );
                    },
                    optionsViewBuilder:
                        (context, onSelected, options) => Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: 250,
                                maxWidth:
                                    MediaQuery.of(context).size.width - 40 > 600
                                        ? 600
                                        : MediaQuery.of(context).size.width - 40,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (ctx, i) {
                                  final o = options.elementAt(i);
                                  final d = o.roles.contains(UserRole.doctor);
                                  return InkWell(
                                    onTap: () => onSelected(o),
                                    child: ListTile(
                                      leading: Icon(
                                        d ? Icons.medical_services_outlined : Icons.person_outline,
                                      ),
                                      title: Text(o.displayName),
                                      subtitle: Text(
                                        d
                                            ? (o.doctorProfile?.specialties.join(', ') ?? o.email)
                                            : o.email,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                    onSelected: (Usuario s) {
                      setState(() {
                        _selectedUserFilter = s;
                        _userSearchController.text = s.displayName;
                      });
                      FocusScope.of(context).unfocus();
                    },
                    displayStringForOption: (Usuario o) => o.displayName,
                  ),
                ),
              ),
              // --- NUEVO: Botón para cambiar vista ---
              IconButton(
                icon: Icon(
                  _currentViewType == UserViewType.list
                      ? Icons
                          .grid_view_outlined // Si es lista, muestra icono grid
                      : Icons.view_list_outlined, // Si es grid, muestra icono lista
                ),
                tooltip: _currentViewType == UserViewType.list ? 'Vista Tarjetas' : 'Vista Lista',
                onPressed: () {
                  setState(() {
                    // Cambia al otro tipo de vista
                    _currentViewType =
                        _currentViewType == UserViewType.list
                            ? UserViewType.grid
                            : UserViewType.list;
                  });
                },
              ),
            ],
          ),

          // Barra de Filtros (ahora incluye el botón de vista)
          _buildFilterBar(),
          const Divider(height: 1),

          // --- Lista/Grid de Citas ---
          Expanded(
            child: StreamBuilder<List<Cita>>(
              stream: _firestoreService.getAppointmentsStream(
                pacienteId:
                    _selectedUserFilter?.roles.contains(UserRole.paciente) ?? false
                        ? _selectedUserFilter!.uid
                        : null,
                doctorId:
                    _selectedUserFilter?.roles.contains(UserRole.doctor) ?? false
                        ? _selectedUserFilter!.uid
                        : null,
                startDate: _selectedDateFilter,
                endDate: _selectedDateFilter,
              ),
              builder: (context, snapshot) {
                // ... (manejo de loading y error) ...
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                List<Cita> citas = snapshot.data ?? [];
                if (_selectedStatusFilter != null) {
                  citas = citas.where((c) => c.estado == _selectedStatusFilter).toList();
                }

                if (citas.isEmpty) {
                  String message = 'No hay citas registradas';
                  if (_selectedUserFilter != null ||
                      _selectedDateFilter != null ||
                      _selectedStatusFilter != null) {
                    message = 'No se encontraron citas con los filtros aplicados.';
                  }
                  return Center(child: Text(message));
                }

                // *** DECISIÓN DE LAYOUT ***
                if (_currentViewType == UserViewType.list) {
                  // --- VISTA LISTA ---
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80), // Espacio para FAB
                    itemCount: citas.length,
                    itemBuilder: (context, index) {
                      // Llama al helper para construir el ListTile
                      return _buildAppointmentListItem(context, citas[index]);
                    },
                  );
                } else {
                  // --- VISTA TARJETAS (Wrap) ---
                  return SingleChildScrollView(
                    // Necesario para que Wrap sea स्क्रॉल करने योग्य
                    padding: const EdgeInsets.all(
                      8.0,
                    ).copyWith(bottom: 80), // Padding y espacio FAB
                    child: Wrap(
                      spacing: 8.0, // Espacio horizontal entre tarjetas
                      runSpacing: 8.0, // Espacio vertical entre filas
                      children:
                          citas.map((cita) {
                            // Llama al helper para construir la Card
                            return _buildAppointmentCardItem(context, cita);
                          }).toList(),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAppointmentDialog(),
        tooltip: 'Nueva Cita',
        child: const Icon(Icons.add),
      ),
    );
  }
}
