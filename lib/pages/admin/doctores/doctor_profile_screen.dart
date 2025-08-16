// Archivo: pages/medico/doctor_profile_screen.dart
// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Modelos y Servicios
import '../../../models/modelos.dart';
import '../../../services/firestore_service.dart';
import '../../../services/users_service.dart';
import '../../auth/login.dart';
import '../pacientes/paciente_detail_screen.dart';

// --- Funciones Auxiliares de Tiempo (Fuera de la clase) ---
TimeOfDay _timeOfDayFromString(String timeString) {
  /* ... */
  try {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  } catch (e) {
    print("Error parsing TimeOfDay: $timeString -> $e");
    return TimeOfDay.now();
  }
}

String _formatTimeOfDay(TimeOfDay time) {
  /* ... */
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

double _timeOfDayToDouble(TimeOfDay time) {
  /* ... */
  return time.hour + time.minute / 60.0;
}
// --- FIN Funciones Auxiliares ---

class DoctorProfileScreen extends StatefulWidget {
  final String? uidDoctor;

  const DoctorProfileScreen({this.uidDoctor, super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final UsersService _usersService = UsersService();
  final Authentication _auth = Authentication();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  late TabController _tabController;

  Usuario? _doctorData;
  bool _isLoading = true;
  String? _error;
  late bool _isViewingOwnProfile;
  late String _targetUid;

  // --- NUEVO: Estados para el rol del usuario logueado ---
  bool _loggedInUserIsAdmin = false;
  bool _loggedInUserIsSuperAdmin = false;
  bool _isLoadingPermissions = true; // Indicador para carga de permisos

  List<Usuario> _assignedPatients = [];
  bool _isLoadingPatients = false;

  final List<Tab> _tabs = const [
    Tab(icon: Icon(Icons.person_outline), text: 'Perfil'),
    Tab(icon: Icon(Icons.schedule_outlined), text: 'Horarios'),
    Tab(icon: Icon(Icons.calendar_today_outlined), text: 'Citas'),
  ];

  final List<String> _diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_updateFabVisibility);

    final currentUserUid = _firebaseAuth.currentUser?.uid;
    _targetUid = widget.uidDoctor ?? currentUserUid ?? '';
    _isViewingOwnProfile =
        (widget.uidDoctor == null || widget.uidDoctor == currentUserUid) && currentUserUid != null;

    if (_targetUid.isEmpty) {
      setState(() {
        _error = "No se pudo determinar qué perfil de doctor cargar.";
        _isLoading = false;
        _isLoadingPermissions = false; // Permisos no son relevantes si no hay target
      });
    } else {
      // --- Llamar a la función combinada ---
      _loadPermissionsAndDoctorData();
      if (_isViewingOwnProfile) {
        // Cargar pacientes solo si es perfil propio (o decidir si admin también necesita)
        _loadAssignedPatients(_targetUid);
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_updateFabVisibility);
    _tabController.dispose();
    super.dispose();
  }

  void _updateFabVisibility() {
    if (mounted) setState(() {});
  }

  // --- NUEVO: Función combinada para cargar permisos y datos ---
  Future<void> _loadPermissionsAndDoctorData() async {
    setState(() {
      _isLoading = true;
      _isLoadingPermissions = true; // Inicia carga de permisos
      _error = null;
    });

    // 1. Cargar Permisos del Usuario Logueado
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      try {
        final idTokenResult = await currentUser.getIdTokenResult(true); // Forzar refresh
        final claims = idTokenResult.claims ?? {};
        setState(() {
          _loggedInUserIsSuperAdmin = claims['superadmin'] == true;
          // Admin es true si tiene claim 'admin' y NO es superadmin
          _loggedInUserIsAdmin = claims['admin'] == true && !_loggedInUserIsSuperAdmin;
          _isLoadingPermissions = false; // Termina carga de permisos
        });
        print(
          "Permisos cargados: Admin=$_loggedInUserIsAdmin, SuperAdmin=$_loggedInUserIsSuperAdmin",
        );
      } catch (e) {
        print("Error cargando claims/permisos: $e");
        setState(() {
          _error = "Error al verificar permisos.";
          _isLoadingPermissions = false;
          // Podríamos detener la carga del doctor aquí si los permisos son cruciales
          // _isLoading = false;
          // return;
        });
      }
    } else {
      // No hay usuario logueado, no puede ser admin/superadmin
      setState(() {
        _loggedInUserIsAdmin = false;
        _loggedInUserIsSuperAdmin = false;
        _isLoadingPermissions = false;
        // Podríamos poner error aquí si se espera un usuario logueado
        // _error = "Usuario no autenticado";
        // _isLoading = false;
        // return;
      });
    }

    // 2. Cargar Datos del Doctor (si _targetUid es válido)
    if (_targetUid.isEmpty) {
      setState(() {
        _isLoading = false;
      }); // Ya había error
      return;
    }
    try {
      _firestoreService
          .getUserStream(_targetUid)
          .listen(
            (userData) {
              if (mounted) {
                if (userData != null && !userData.roles.contains(UserRole.doctor)) {
                  setState(() {
                    _error = "El usuario no es doctor.";
                    _doctorData = null;
                    _isLoading = false;
                  });
                } else if (userData != null) {
                  setState(() {
                    _doctorData = userData;
                    _isLoading = false;
                    _error = null;
                  });
                } else {
                  setState(() {
                    _doctorData = null;
                    _isLoading = false;
                    _error = "No se encontró el perfil.";
                  });
                }
              }
            },
            onError: (e) {
              if (mounted)
                setState(() {
                  _error = 'Error: ${e.toString()}';
                  _isLoading = false;
                });
            },
            onDone: () {
              if (mounted && _doctorData == null && _error == null)
                setState(() {
                  _error = 'Conexión perdida.';
                  _isLoading = false;
                });
            },
            cancelOnError: true,
          );
    } catch (e) {
      if (mounted)
        setState(() {
          _error = 'Error carga: ${e.toString()}';
          _isLoading = false;
        });
    }
  }

  // --- loadAssignedPatients sin cambios ---
  Future<void> _loadAssignedPatients(String doctorId) async {
    /* ... código igual ... */
    if (!_isViewingOwnProfile) return; // Quizás admin sí necesite verlos? Ajustar si es necesario
    setState(() => _isLoadingPatients = true);
    try {
      _assignedPatients = await _firestoreService.getDoctorpacientesStream(doctorId).first;
    } catch (e) {
      print("Error cargando pacientes: $e");
    } finally {
      if (mounted) setState(() => _isLoadingPatients = false);
    }
  }

  // --- NUEVO: Getter para permisos de gestión de horarios ---
  bool get _canManageSchedule {
    // Se puede gestionar si:
    // 1. Es el propio doctor viendo su perfil O
    // 2. El usuario logueado es Admin O
    // 3. El usuario logueado es Superadmin
    return _isViewingOwnProfile || _loggedInUserIsAdmin || _loggedInUserIsSuperAdmin;
  }

  // --- Construcción de Pestañas ---

  Widget _buildProfileTab(Usuario doctor) {
    // ... (código igual, el botón editar sigue dependiendo de _isViewingOwnProfile) ...
    final profile = doctor.doctorProfile;
    if (profile == null) return const Center(child: Text("Perfil detallado no encontrado."));
    final List<Map<String, dynamic>> infoItems = [
      {'label': 'Nombre:', 'value': doctor.displayName},
      {'label': 'Email:', 'value': doctor.email},
      {'label': 'Licencia:', 'value': profile.licenseNumber},
      {'label': 'Especialidades:', 'value': profile.specialties.join(', ')},
      {'label': 'Años Exp.:', 'value': profile.anosExperiencia?.toString()},
      {'label': 'Teléfono:', 'value': profile.telefono},
      {'label': 'Rating:', 'value': profile.rating?.toStringAsFixed(1)},
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...infoItems.map((item) => _buildInfoRow(item['label'], item['value'])),
        const SizedBox(height: 20),
        if (_isViewingOwnProfile)
          ElevatedButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar Perfil'),
            onPressed: () => _showEditProfileDialog(doctor),
          ),
      ],
    );
  }

  // --- MODIFICADO: Usa _canManageSchedule para botones ---
  Widget _buildScheduleTab(Usuario doctor) {
    final horarios = doctor.doctorProfile?.horarios ?? [];
    final Map<String, List<Horario>> groupedHorarios = {};
    for (var h in horarios) {
      groupedHorarios.putIfAbsent(h.diaSemana, () => []).add(h);
    }
    final sortedDays =
        groupedHorarios.keys.toList()
          ..sort((a, b) => _diasSemana.indexOf(a).compareTo(_diasSemana.indexOf(b)));

    if (horarios.isEmpty)
      return Center(
        child: Text(
          _canManageSchedule ? "Define los horarios laborales." : "Horarios no definidos.",
        ),
      ); // Mensaje adaptado

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final dia = sortedDays[index];
        final horariosDia = groupedHorarios[dia]!;
        horariosDia.sort(
          (a, b) =>
              _timeOfDayFromString(a.horaInicio).compareTo(_timeOfDayFromString(b.horaInicio)),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            key: PageStorageKey(dia),
            title: Text(dia, style: const TextStyle(fontWeight: FontWeight.bold)),
            children:
                horariosDia.map((horario) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.access_time, size: 18),
                    title: Text('${horario.horaInicio} - ${horario.horaFin}'),
                    // --- USA _canManageSchedule ---
                    trailing:
                        _canManageSchedule // Permitir si es propio o admin/superadmin
                            ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  tooltip: 'Editar',
                                  onPressed: () => _showAddEditHorarioDialog(horario: horario),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Eliminar',
                                  onPressed: () => _confirmDeleteHorario(horario),
                                ),
                              ],
                            )
                            : null, // No mostrar botones si no tiene permiso
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  // --- MODIFICADO: Usa _canManageSchedule para botones y _isViewingOwnProfile para detalles ---
  Widget _buildAppointmentsTab(String doctorId) {
    return StreamBuilder<List<Cita>>(
      stream: _firestoreService.getAppointmentsStream(doctorId: doctorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        final citas = snapshot.data ?? [];
        if (citas.isEmpty) return const Center(child: Text('No hay citas programadas.'));
        return ListView.builder(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 80),
          itemCount: citas.length,
          itemBuilder: (context, index) => _buildAppointmentListItem(citas[index]),
        );
      },
    );
  }

  // --- Helpers UI (sin cambios internos) ---
  Widget _buildInfoRow(String label, dynamic value) {
    /* ... código idéntico ... */
    String text;
    if (value == null || (value is String && value.isEmpty)) {
      text = 'No especificado';
    } else if (value is bool) {
      text = value ? 'Sí' : 'No';
    } else if (value is DateTime) {
      text = DateFormat('dd MMM yyyy', 'es_ES').format(value);
    } else if (value is Timestamp) {
      text = DateFormat('dd MMM yyyy HH:mm', 'es_ES').format(value.toDate());
    } else if (value is List<String>) {
      text = value.isEmpty ? 'Ninguno/a' : value.join(', ');
    } else if (value is double) {
      text = value.toStringAsFixed(1);
    } else {
      text = value.toString();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildAppointmentListItem(Cita cita) {
    /* ... código idéntico, usa _canManageSchedule ahora */
    final DateFormat formatter = DateFormat('EEEE dd MMM, hh:mm a', 'es_ES');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(_getStatusIcon(cita.estado), color: _getStatusColor(cita.estado)),
        title: Text(cita.titulo ?? 'Cita', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Paciente: ${cita.nombrePaciente}\nFecha: ${formatter.format(cita.fecha)}'),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- USA _canManageSchedule para editar/borrar citas ---
            if (_canManageSchedule)
              IconButton(
                icon: const Icon(Icons.edit_calendar_outlined, size: 20, color: Colors.orange),
                tooltip: 'Editar Cita',
                onPressed: () => _showAddEditAppointmentDialog(cita: cita),
              ),
            IconButton(
              icon: const Icon(Icons.person_search_outlined, size: 20, color: Colors.blue),
              tooltip: 'Ver Paciente',
              onPressed: () {
                if (cita.pacienteId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => PacienteDetailScreen(
                            pacienteId: cita.pacienteId!,
                            isAdminView: false,
                          ),
                    ),
                  );
                } else {
                  _showErrorSnackBar('ID paciente no disponible.');
                }
              },
            ),
            if (_canManageSchedule)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                tooltip: 'Eliminar Cita',
                onPressed: () => _confirmDeleteAppointment(cita),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String? status) {
    /* ... */
    return status?.toLowerCase() == 'completada'
        ? Icons.check_circle
        : status?.toLowerCase() == 'cancelada'
        ? Icons.cancel
        : Icons.schedule;
  }

  Color _getStatusColor(String? status) {
    /* ... */
    return status?.toLowerCase() == 'completada'
        ? Colors.green
        : status?.toLowerCase() == 'cancelada'
        ? Colors.red
        : Colors.blue;
  }

  // --- Diálogos y Formularios (sin cambios internos, permisos ya controlados en UI) ---
  Future<void> _showEditProfileDialog(Usuario currentDoctorData) async {
    /* ... código igual ... */
    final DoctorProfile? initialProfile = currentDoctorData.doctorProfile;
    if (initialProfile == null) {
      _showErrorSnackBar("No perfil.");
      return;
    }
    final Map<String, dynamic>? updatedProfileData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _EditDoctorProfileDialogContent(initialProfile: initialProfile),
    );
    if (updatedProfileData != null && _doctorData != null) {
      try {
        Map<String, dynamic> firestoreUpdate = {};
        updatedProfileData.forEach((key, value) {
          firestoreUpdate['doctorProfile.$key'] = value;
        });
        await _usersService.updateUserWithProfile(_doctorData!.uid, firestoreUpdate);
        _showSuccessSnackBar("Perfil actualizado.");
      } catch (e) {
        _showErrorSnackBar("Error: ${e.toString()}");
      }
    }
  }

  Future<void> _showAddEditHorarioDialog({Horario? horario}) async {
    /* ... código igual ... */
    final bool isEditing = horario != null;
    String? selectedDia = isEditing ? horario.diaSemana : null;
    TimeOfDay? startTime = isEditing ? _timeOfDayFromString(horario.horaInicio) : null;
    TimeOfDay? endTime = isEditing ? _timeOfDayFromString(horario.horaFin) : null;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setStateDialog) {
              Future<void> pickTime(bool isStart) async {
                final initial = isStart ? startTime : endTime;
                final picked = await showTimePicker(
                  context: context,
                  initialTime: initial ?? TimeOfDay.now(),
                  builder:
                      (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      ),
                );
                if (picked != null)
                  setStateDialog(() {
                    if (isStart)
                      startTime = picked;
                    else
                      endTime = picked;
                  });
              }

              return AlertDialog(
                title: Text(isEditing ? 'Editar Horario' : 'Añadir Horario'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedDia,
                        hint: const Text('Día *'),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items:
                            _diasSemana
                                .map((dia) => DropdownMenuItem(value: dia, child: Text(dia)))
                                .toList(),
                        onChanged: (value) => setStateDialog(() => selectedDia = value),
                        validator: (v) => v == null ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        title: Text(startTime == null ? 'Inicio *' : startTime!.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => pickTime(true),
                      ),
                      ListTile(
                        title: Text(endTime == null ? 'Fin *' : endTime!.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => pickTime(false),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedDia != null && startTime != null && endTime != null) {
                        if (_timeOfDayToDouble(endTime!) <= _timeOfDayToDouble(startTime!)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fin > Inicio.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        Navigator.of(ctx).pop({
                          'diaSemana': selectedDia,
                          'horaInicio': _formatTimeOfDay(startTime!),
                          'horaFin': _formatTimeOfDay(endTime!),
                          'id': horario?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Completa campos.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    child: Text(isEditing ? 'Guardar' : 'Añadir'),
                  ),
                ],
              );
            },
          ),
    );
    if (result != null) {
      final nuevoHorario = Horario.fromJson(result);
      _updateHorarios(nuevoHorario, isEditing: isEditing);
    }
  }

  Future<void> _confirmDeleteHorario(Horario horario) async {
    /* ... código igual ... */
    final confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Confirmar'),
                content: Text(
                  '¿Eliminar ${horario.diaSemana} ${horario.horaInicio}-${horario.horaFin}?',
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
        ) ??
        false;
    if (confirm) {
      _updateHorarios(horario, isDeleting: true);
    }
  }

  Future<void> _showAddEditAppointmentDialog({Cita? cita}) async {
    /* ... código igual ... */
    if (!_canManageSchedule || _doctorData == null) return; // Usa _canManageSchedule
    final bool isEditing = cita != null;
    final bool? result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AppointmentFormDialogDoctor(
            firestoreService: _firestoreService,
            cita: cita,
            doctorId: _doctorData!.uid,
            doctorName: _doctorData!.displayName,
            doctorHorarios: _doctorData!.doctorProfile?.horarios ?? [],
            assignedPatients: _assignedPatients,
            isLoadingPatients: _isLoadingPatients,
            diasSemana: _diasSemana,
          ),
    );
    if (result == true && mounted) {
      _showSuccessSnackBar(isEditing ? 'Cita actualizada.' : 'Cita creada.');
    }
  }

  Future<void> _confirmDeleteAppointment(Cita cita) async {
    /* ... código igual ... */
    if (!_canManageSchedule || cita.id == null) return; // Usa _canManageSchedule
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Confirmar'),
                content: Text(
                  '¿Eliminar cita de "${cita.nombrePaciente}"\n${DateFormat('dd/MM/yyyy HH:mm').format(cita.fecha)}?',
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
        ) ??
        false;
    if (confirmed == true) {
      try {
        await _firestoreService.deleteAppointment(cita.id!);
        _showSuccessSnackBar('Cita eliminada.');
      } catch (e) {
        _showErrorSnackBar('Error al eliminar: $e');
      }
    }
  }

  // --- Lógica de Actualización de Horarios (sin cambios internos) ---
  Future<void> _updateHorarios(
    Horario horario, {
    bool isEditing = false,
    bool isDeleting = false,
  }) async {
    /* ... código igual ... */
    if (_doctorData == null) return;
    final List<Horario> currentHorarios = List.from(_doctorData!.doctorProfile?.horarios ?? []);
    if (isDeleting) {
      currentHorarios.removeWhere((h) => h.id == horario.id);
    } else if (isEditing) {
      final index = currentHorarios.indexWhere((h) => h.id == horario.id);
      if (index != -1)
        currentHorarios[index] = horario;
      else
        currentHorarios.add(horario);
    } else {
      currentHorarios.add(horario);
    }
    final List<Map<String, dynamic>> horariosJson = currentHorarios.map((h) => h.toJson()).toList();
    try {
      await _usersService.updateUserWithProfile(_doctorData!.uid, {
        'doctorProfile.horario': horariosJson,
      });
      _showSuccessSnackBar(
        isDeleting
            ? 'Horario eliminado.'
            : (isEditing ? 'Horario actualizado.' : 'Horario añadido.'),
      );
    } catch (e) {
      _showErrorSnackBar("Error: ${e.toString()}");
    }
  }

  // --- Helpers Generales (sin cambios) ---
  void _showSuccessSnackBar(String message) {
    /* ... */
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  void _showErrorSnackBar(String message) {
    /* ... */
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  // --- Build Principal ---
  @override
  Widget build(BuildContext context) {
    // --- Lógica del FAB (MODIFICADA: Usa _canManageSchedule) ---
    Widget? fabWidget;
    bool showFab = false;
    int currentTabIndex = _tabController.index;

    // Mostrar FABs si NO está cargando, hay datos Y tiene permiso
    if (!_isLoading && _doctorData != null && _canManageSchedule) {
      if (currentTabIndex == 1) {
        // Pestaña "Horarios"
        showFab = true;
        fabWidget = FloatingActionButton(
          heroTag: 'addScheduleBtn',
          onPressed: () => _showAddEditHorarioDialog(),
          tooltip: 'Añadir Horario',
          child: const Icon(Icons.add_alarm),
        );
      } else if (currentTabIndex == 2) {
        // Pestaña "Citas"
        showFab = true;
        fabWidget = FloatingActionButton(
          heroTag: 'addAppointmentBtn',
          onPressed: () => _showAddEditAppointmentDialog(),
          tooltip: 'Crear Cita',
          child: const Icon(Icons.add_circle_outline),
        );
      }
    }
    // --- Fin Lógica FAB ---

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isViewingOwnProfile
              ? 'Mi Perfil y Agenda'
              : (_doctorData?.displayName ?? 'Perfil Doctor'),
        ),
        actions: [
          if (_isViewingOwnProfile)
            IconButton(icon: const Icon(Icons.logout), onPressed: () => _auth.logout(context)),
        ],
        bottom: TabBar(controller: _tabController, tabs: _tabs, isScrollable: _tabs.length > 4),
      ),
      body:
          _isLoading ||
                  _isLoadingPermissions // Muestra carga si alguna está activa
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _doctorData == null
              ? const Center(child: Text('No se encontró el perfil del doctor.'))
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(_doctorData!),
                  _buildScheduleTab(_doctorData!),
                  _buildAppointmentsTab(_doctorData!.uid),
                ],
              ),
      floatingActionButton: showFab ? fabWidget : null,
    );
  }
}

// --- Widget Interno Formulario Edición Perfil (sin cambios) ---
class _EditDoctorProfileDialogContent extends StatefulWidget {
  // ... (código idéntico) ...
  final DoctorProfile initialProfile;
  const _EditDoctorProfileDialogContent({required this.initialProfile});
  @override
  __EditDoctorProfileDialogContentState createState() => __EditDoctorProfileDialogContentState();
}

class __EditDoctorProfileDialogContentState extends State<_EditDoctorProfileDialogContent> {
  // ... (código idéntico) ...
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _e;
  late TextEditingController _l;
  late TextEditingController _a;
  late TextEditingController _t;
  @override
  void initState() {
    super.initState();
    _e = TextEditingController(text: widget.initialProfile.specialties.join(', '));
    _l = TextEditingController(text: widget.initialProfile.licenseNumber);
    _a = TextEditingController(text: widget.initialProfile.anosExperiencia?.toString());
    _t = TextEditingController(text: widget.initialProfile.telefono);
  }

  @override
  void dispose() {
    _e.dispose();
    _l.dispose();
    _a.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Mi Perfil'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: ListBody(
            children: [
              TextFormField(
                controller: _l,
                decoration: const InputDecoration(labelText: 'Licencia *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Req' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _e,
                decoration: const InputDecoration(labelText: 'Especialidades (,) *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Req' : null,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _a,
                decoration: const InputDecoration(labelText: 'Años Exp.'),
                keyboardType: TextInputType.number,
                validator:
                    (v) =>
                        (v != null && v.isNotEmpty && int.tryParse(v.trim()) == null)
                            ? 'Inválido'
                            : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _t,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final d = {
                'licenseNumber': _l.text.trim(),
                'specialties':
                    _e.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                'anosExperiencia': int.tryParse(_a.text.trim()),
                'telefono': _t.text.trim().isEmpty ? null : _t.text.trim(),
              };
              if (d['anosExperiencia'] == null) d.remove('anosExperiencia');
              if (d['telefono'] == null) d.remove('telefono');
              Navigator.of(context).pop(d);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// --- Widget Formulario Citas para Doctor (sin cambios internos) ---
class AppointmentFormDialogDoctor extends StatefulWidget {
  // ... (propiedades y constructor igual que antes) ...
  final FirestoreService firestoreService;
  final Cita? cita;
  final String doctorId;
  final String doctorName;
  final List<Horario> doctorHorarios;
  final List<Usuario> assignedPatients;
  final bool isLoadingPatients;
  final List<String> diasSemana;
  const AppointmentFormDialogDoctor({
    required this.firestoreService,
    this.cita,
    required this.doctorId,
    required this.doctorName,
    required this.doctorHorarios,
    required this.assignedPatients,
    required this.isLoadingPatients,
    required this.diasSemana,
    super.key,
  });
  @override
  State<AppointmentFormDialogDoctor> createState() => _AppointmentFormDialogDoctorState();
}

class _AppointmentFormDialogDoctorState extends State<AppointmentFormDialogDoctor> {
  // ... (estado y métodos internos _selectDate, _selectTime, _isSlotAvailable, _saveAppointment, _showError, dispose, build igual que antes) ...
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late TextEditingController _titleController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Usuario? _selectedPaciente;
  String? _selectedEstado;
  final TextEditingController _pacienteSearchController = TextEditingController();
  final List<String> _estadosPosibles = ['programada', 'completada', 'cancelada'];
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.cita?.titulo);
    _selectedDate = widget.cita?.fecha;
    _selectedTime = widget.cita != null ? TimeOfDay.fromDateTime(widget.cita!.fecha) : null;
    _selectedEstado = widget.cita?.estado ?? 'programada';
    if (widget.cita?.pacienteId != null) {
      try {
        _selectedPaciente = widget.assignedPatients.firstWhere(
          (p) => p.uid == widget.cita!.pacienteId,
        );
        _pacienteSearchController.text = _selectedPaciente!.displayName;
      } catch (e) {
        _pacienteSearchController.text = widget.cita!.nombrePaciente;
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
      });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
    );
    if (picked != null && picked != _selectedTime)
      setState(() {
        _selectedTime = picked;
      });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pacienteSearchController.dispose();
    super.dispose();
  }

  Future<bool> _isSlotAvailable(DateTime proposedDateTime) async {
    final diaSemana = widget.diasSemana[proposedDateTime.weekday - 1];
    final proposedTime = TimeOfDay.fromDateTime(proposedDateTime);
    final double proposedTimeDouble = _timeOfDayToDouble(proposedTime);
    final horariosDelDia = widget.doctorHorarios.where((h) => h.diaSemana == diaSemana).toList();
    if (horariosDelDia.isEmpty) {
      _showError('No horario para $diaSemana.');
      return false;
    }
    bool withinWorkingHours = false;
    for (var h in horariosDelDia) {
      final start = _timeOfDayToDouble(_timeOfDayFromString(h.horaInicio));
      final end = _timeOfDayToDouble(_timeOfDayFromString(h.horaFin));
      if (proposedTimeDouble >= start && proposedTimeDouble < end) {
        withinWorkingHours = true;
        break;
      }
    }
    if (!withinWorkingHours) {
      _showError('Fuera horario para $diaSemana.');
      return false;
    }
    const appointmentDuration = Duration(hours: 1);
    final proposedEndDateTime = proposedDateTime.add(appointmentDuration);
    try {
      final existingAppointments =
          await widget.firestoreService
              .getAppointmentsStream(
                doctorId: widget.doctorId,
                startDate: DateTime(
                  proposedDateTime.year,
                  proposedDateTime.month,
                  proposedDateTime.day,
                ),
                endDate: DateTime(
                  proposedDateTime.year,
                  proposedDateTime.month,
                  proposedDateTime.day,
                ),
              )
              .first;
      for (var existingCita in existingAppointments) {
        if (widget.cita != null && existingCita.id == widget.cita!.id) continue;
        final existingStart = existingCita.fecha;
        final existingEnd = existingStart.add(appointmentDuration);
        if (proposedDateTime.isBefore(existingEnd) && proposedEndDateTime.isAfter(existingStart)) {
          _showError(
            'Solapa con ${DateFormat('HH:mm').format(existingStart)}-${DateFormat('HH:mm').format(existingEnd)}.',
          );
          return false;
        }
      }
    } catch (e) {
      _showError("Error citas: $e");
      return false;
    }
    return true;
  }

  void _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPaciente == null) {
      _showError('Selecciona paciente.');
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      _showError('Selecciona fecha/hora.');
      return;
    }
    final fechaHora = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final bool available = await _isSlotAvailable(fechaHora);
    if (!available || !mounted) {
      if (available && !mounted) _showError("Cancelado.");
      return;
    }
    setState(() => _isLoading = true);
    final citaData = Cita(
      id: widget.cita?.id,
      titulo: _titleController.text.trim(),
      pacienteId: _selectedPaciente!.uid,
      nombrePaciente: _selectedPaciente!.displayName,
      doctorId: widget.doctorId,
      nombreDoctor: widget.doctorName,
      fecha: fechaHora,
      estado: _selectedEstado ?? 'programada',
    );
    try {
      if (widget.cita == null) {
        await widget.firestoreService.createAppointment(citaData);
      } else {
        await widget.firestoreService.updateAppointment(widget.cita!.id!, citaData.toJson());
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.cita != null;
    final String dialogTitle = isEditing ? 'Editar Cita' : 'Nueva Cita';

    return AlertDialog(
      title: Text(dialogTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: ListBody(
            children: <Widget>[
              // --- Selector de Paciente (Autocomplete) ---
              Autocomplete<Usuario>(
                // ... (código del Autocomplete similar al de AppointmentFormDialog) ...
                // ... (pero usando widget.assignedPatients y widget.isLoadingPatients) ...
                fieldViewBuilder: (context, fieldController, fieldFocusNode, onFieldSubmitted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    /* Sincronizar controlador */
                    if (_pacienteSearchController.text != fieldController.text && mounted) {
                      if (_pacienteSearchController.text.isEmpty &&
                          fieldController.text.isNotEmpty &&
                          widget.cita?.pacienteId != null) {
                        _pacienteSearchController.text = fieldController.text;
                      } else if (fieldController.text.isEmpty &&
                          _pacienteSearchController.text.isNotEmpty) {
                        fieldController.text = _pacienteSearchController.text;
                      }
                    }
                  });
                  return TextFormField(
                    controller: fieldController,
                    focusNode: fieldFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Buscar Paciente Asignado *',
                      hintText: 'Escribe nombre...',
                      border: const OutlineInputBorder(),
                      prefixIcon:
                          widget.isLoadingPatients
                              ? const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: SizedBox(
                                  height: 15,
                                  width: 15,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                              : const Icon(Icons.person_search),
                      suffixIcon:
                          fieldController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  fieldController.clear();
                                  setState(() {
                                    _selectedPaciente = null;
                                  });
                                },
                              )
                              : null,
                    ),
                    validator:
                        (v) =>
                            (v != null && v.isNotEmpty && _selectedPaciente == null)
                                ? 'Selecciona paciente válido'
                                : ((v == null || v.isEmpty) && _selectedPaciente == null)
                                ? 'Selecciona un paciente'
                                : null,
                  );
                },
                optionsBuilder: (textEditingValue) {
                  if (widget.isLoadingPatients) return const Iterable.empty();
                  final query = textEditingValue.text.toLowerCase();
                  if (query.isEmpty) return const Iterable<Usuario>.empty();
                  return widget.assignedPatients.where(
                    (p) =>
                        p.displayName.toLowerCase().contains(query) ||
                        p.email.toLowerCase().contains(query),
                  ); // Usa la lista de asignados
                },
                optionsViewBuilder:
                    (context, onSelected, options) => Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (ctx, i) {
                              final o = options.elementAt(i);
                              return InkWell(
                                onTap: () => onSelected(o),
                                child: ListTile(
                                  title: Text(o.displayName),
                                  subtitle: Text(o.email),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                onSelected: (selection) {
                  setState(() {
                    _selectedPaciente = selection;
                    _pacienteSearchController.text = selection.displayName;
                    _formKey.currentState?.validate();
                  });
                  FocusScope.of(context).unfocus();
                },
                displayStringForOption: (option) => option.displayName,
                initialValue:
                    _selectedPaciente != null
                        ? TextEditingValue(text: _selectedPaciente!.displayName)
                        : null,
              ),
              const SizedBox(height: 12),

              // --- Campos de Fecha y Hora (sin cambios) ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedDate == null
                      ? 'Selecciona Fecha *'
                      : 'Fecha: ${DateFormat('EE dd MMM yyyy', 'es_ES').format(_selectedDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedTime == null
                      ? 'Selecciona Hora *'
                      : 'Hora: ${_selectedTime!.format(context)}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 12),

              // --- Campo Título/Motivo ---
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título/Motivo'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un título' : null,
              ),
              const SizedBox(height: 12),

              // --- Selector de Estado (Opcional para el doctor, podría fijarse o limitarse) ---
              DropdownButtonFormField<String>(
                value: _selectedEstado,
                decoration: const InputDecoration(labelText: 'Estado Cita'),
                items:
                    _estadosPosibles
                        .map(
                          (estado) => DropdownMenuItem<String>(
                            value: estado,
                            child: Text(estado[0].toUpperCase() + estado.substring(1)),
                          ),
                        )
                        .toList(),
                onChanged: (newValue) => setState(() => _selectedEstado = newValue),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveAppointment,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Guardar'),
        ),
      ],
    );
  }
}


/* // Archivo: pages/medico/doctor_profile_screen.dart
// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Modelos y Servicios
// Modelos y Servicios
import '../../../models/modelos.dart';
import '../../../services/firestore_service.dart';
import '../../../services/users_service.dart';
import '../../auth/login.dart';
import '../pacientes/paciente_detail_screen.dart';

// --- NUEVO: Funciones Auxiliares de Tiempo (Fuera de la clase) ---
TimeOfDay _timeOfDayFromString(String timeString) {
  try {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  } catch (e) {
    print("Error parsing TimeOfDay: $timeString -> $e");
    return TimeOfDay.now();
  }
}

double _timeOfDayToDouble(TimeOfDay time) {
  return time.hour + time.minute / 60.0;
}

final List<String> _diasSemana = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
Usuario? _doctorData;
// --- FIN Funciones Auxiliares ---

// --- Pantalla Principal del Perfil del Doctor (MODIFICADA) ---
class DoctorProfileScreen extends StatefulWidget {
  // --- NUEVO: UID Opcional ---
  final String? uidDoctor; // UID del doctor a mostrar (si es null, muestra el logueado)

  const DoctorProfileScreen({
    this.uidDoctor, // Hacerlo opcional
    super.key,
  });

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final UsersService _usersService = UsersService();
  final Authentication _auth = Authentication();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;
  late bool _isViewingOwnProfile;
  late String _targetUid;

  // --- NUEVO: Lista de pacientes asignados (para el selector en creación de citas) ---
  List<Usuario> _assignedPatients = [];
  bool _isLoadingPatients = false;

  final List<Tab> _tabs = const [
    Tab(icon: Icon(Icons.person_outline), text: 'Perfil'),
    Tab(icon: Icon(Icons.schedule_outlined), text: 'Horarios'), // Renombrado
    Tab(icon: Icon(Icons.calendar_today_outlined), text: 'Citas'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_updateFabVisibility);

    final currentUserUid = _firebaseAuth.currentUser?.uid;
    _targetUid = widget.uidDoctor ?? currentUserUid ?? '';
    _isViewingOwnProfile =
        (widget.uidDoctor == null || widget.uidDoctor == currentUserUid) && currentUserUid != null;

    if (_targetUid.isEmpty) {
      setState(() {
        _error = "No se pudo determinar qué perfil de doctor cargar.";
        _isLoading = false;
      });
    } else {
      _loadDoctorData();
      // --- NUEVO: Cargar pacientes asignados si está viendo su propio perfil ---
      if (_isViewingOwnProfile) {
        _loadAssignedPatients(_targetUid);
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_updateFabVisibility);
    _tabController.dispose();
    super.dispose();
  }

  void _updateFabVisibility() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDoctorData() async {
    // ... (código sin cambios) ...
    if (_targetUid.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _firestoreService
          .getUserStream(_targetUid)
          .listen(
            (userData) {
              if (mounted) {
                if (userData != null && !userData.roles.contains(UserRole.doctor)) {
                  setState(() {
                    _error = "El usuario no es doctor.";
                    _doctorData = null;
                    _isLoading = false;
                  });
                } else if (userData != null) {
                  setState(() {
                    _doctorData = userData;
                    _isLoading = false;
                    _error = null;
                  });
                } else {
                  setState(() {
                    _doctorData = null;
                    _isLoading = false;
                    _error = "No se encontró el perfil.";
                  });
                }
              }
            },
            onError: (e) {
              if (mounted) {
                setState(() {
                  _error = 'Error: ${e.toString()}';
                  _isLoading = false;
                });
              }
            },
            onDone: () {
              if (mounted && _doctorData == null && _error == null) {
                setState(() {
                  _error = 'Conexión perdida o doctor no existe.';
                  _isLoading = false;
                });
              }
            },
            cancelOnError: true,
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error carga: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // --- NUEVO: Cargar pacientes asignados ---
  Future<void> _loadAssignedPatients(String doctorId) async {
    if (!_isViewingOwnProfile) return; // Solo si es el perfil propio
    setState(() => _isLoadingPatients = true);
    try {
      // Usamos .first para obtener la lista una vez
      _assignedPatients = await _firestoreService.getDoctorpacientesStream(doctorId).first;
    } catch (e) {
      print("Error cargando pacientes asignados: $e");
      // Opcional: mostrar un mensaje
    } finally {
      if (mounted) setState(() => _isLoadingPatients = false);
    }
  }

  // --- Pestaña Perfil (sin cambios significativos, solo usa _isViewingOwnProfile) ---
  Widget _buildProfileTab(Usuario doctor) {
    // ... (código igual que antes, el botón editar ya depende de _isViewingOwnProfile) ...
    final profile = doctor.doctorProfile;
    if (profile == null) return const Center(child: Text("Perfil detallado no encontrado."));

    final List<Map<String, dynamic>> infoItems = [
      {'label': 'Nombre:', 'value': doctor.displayName},
      {'label': 'Email:', 'value': doctor.email},
      {'label': 'Licencia:', 'value': profile.licenseNumber},
      {'label': 'Especialidades:', 'value': profile.specialties.join(', ')},
      {'label': 'Años Exp.:', 'value': profile.anosExperiencia?.toString()},
      {'label': 'Teléfono:', 'value': profile.telefono},
      {'label': 'Rating:', 'value': profile.rating?.toStringAsFixed(1)},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...infoItems.map((item) => _buildInfoRow(item['label'], item['value'])),
        const SizedBox(height: 20),
        if (_isViewingOwnProfile)
          ElevatedButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar Perfil'),
            onPressed: () => _showEditProfileDialog(doctor),
          ),
      ],
    );
  }

  // --- Pestaña Horarios (sin cambios significativos, usa _isViewingOwnProfile) ---
  Widget _buildScheduleTab(Usuario doctor) {
    // ... (código igual que antes, los botones editar/eliminar ya dependen de _isViewingOwnProfile) ...
    final horarios = doctor.doctorProfile?.horarios ?? [];
    final Map<String, List<Horario>> groupedHorarios = {};
    for (var h in horarios) {
      groupedHorarios.putIfAbsent(h.diaSemana, () => []).add(h);
    }

    final sortedDays =
        groupedHorarios.keys.toList()
          ..sort((a, b) => _diasSemana.indexOf(a).compareTo(_diasSemana.indexOf(b)));

    if (horarios.isEmpty) {
      return Center(
        child: Text(
          _isViewingOwnProfile ? "Define tus horarios laborales." : "Horarios no definidos.",
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final dia = sortedDays[index];
        final horariosDia = groupedHorarios[dia]!;
        horariosDia.sort(
          (a, b) =>
              _timeOfDayFromString(a.horaInicio).compareTo(_timeOfDayFromString(b.horaInicio)),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            key: PageStorageKey(dia),
            title: Text(dia, style: const TextStyle(fontWeight: FontWeight.bold)),
            children:
                horariosDia.map((horario) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.access_time, size: 18),
                    title: Text('${horario.horaInicio} - ${horario.horaFin}'),
                    trailing:
                        _isViewingOwnProfile
                            ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showAddEditHorarioDialog(horario: horario),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _confirmDeleteHorario(horario),
                                ),
                              ],
                            )
                            : null,
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  // --- Pestaña Citas (MODIFICADA) ---
  Widget _buildAppointmentsTab(String doctorId) {
    return StreamBuilder<List<Cita>>(
      stream: _firestoreService.getAppointmentsStream(doctorId: doctorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar citas: ${snapshot.error}'));
        }
        final citas = snapshot.data ?? [];
        if (citas.isEmpty) {
          return const Center(child: Text('No tienes citas programadas.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 80), // Espacio para FAB
          itemCount: citas.length,
          itemBuilder: (context, index) {
            // --- LLAMA AL ITEM MODIFICADO ---
            return _buildAppointmentListItem(citas[index]);
          },
        );
      },
    );
  }

  // --- Helpers UI ---
  Widget _buildInfoRow(String label, dynamic value) {
    // ... (código idéntico) ...
    String text;
    if (value == null || (value is String && value.isEmpty)) {
      text = 'No especificado';
    } else if (value is bool) {
      text = value ? 'Sí' : 'No';
    } else if (value is DateTime) {
      text = DateFormat('dd MMM yyyy', 'es_ES').format(value);
    } else if (value is Timestamp) {
      text = DateFormat('dd MMM yyyy HH:mm', 'es_ES').format(value.toDate());
    } else if (value is List<String>) {
      text = value.isEmpty ? 'Ninguno/a' : value.join(', ');
    } else if (value is double) {
      text = value.toStringAsFixed(1);
    } else {
      text = value.toString();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // --- MODIFICADO: Item de Cita con acciones ---
  Widget _buildAppointmentListItem(Cita cita) {
    final DateFormat formatter = DateFormat('EEEE dd MMM, hh:mm a', 'es_ES');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(_getStatusIcon(cita.estado), color: _getStatusColor(cita.estado)),
        title: Text(cita.titulo ?? 'Cita', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Paciente: ${cita.nombrePaciente}\nFecha: ${formatter.format(cita.fecha)}'),
        isThreeLine: true,
        trailing: Row(
          // Usa Row para múltiples iconos
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón Editar Cita (si es el perfil propio)
            if (_isViewingOwnProfile)
              IconButton(
                icon: const Icon(Icons.edit_calendar_outlined, size: 20, color: Colors.orange),
                tooltip: 'Editar Cita',
                onPressed: () => _showAddEditAppointmentDialog(cita: cita), // Pasa la cita a editar
              ),
            // Botón Ver Detalles Paciente
            IconButton(
              icon: const Icon(
                Icons.person_search_outlined,
                size: 20,
                color: Colors.blue,
              ), // Icono diferente
              tooltip: 'Ver Detalles del Paciente',
              onPressed: () {
                if (cita.pacienteId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => PacienteDetailScreen(
                            pacienteId: cita.pacienteId!,
                            isAdminView: false, // Vista de doctor
                          ),
                    ),
                  );
                } else {
                  _showErrorSnackBar('ID del paciente no disponible.');
                }
              },
            ),
            // Botón Eliminar Cita (si es el perfil propio)
            if (_isViewingOwnProfile)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                tooltip: 'Eliminar Cita',
                onPressed: () => _confirmDeleteAppointment(cita), // Llama a eliminar cita
              ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String? status) {
    /* ... idéntico ... */
    switch (status?.toLowerCase()) {
      case 'completada':
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      case 'programada':
      default:
        return Icons.schedule;
    }
  }

  Color _getStatusColor(String? status) {
    /* ... idéntico ... */
    switch (status?.toLowerCase()) {
      case 'completada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'programada':
      default:
        return Colors.blue;
    }
  }

  // --- Diálogos y Formularios ---
  Future<void> _showEditProfileDialog(Usuario currentDoctorData) async {
    // ... (código sin cambios) ...
    final DoctorProfile? initialProfile = currentDoctorData.doctorProfile;
    if (initialProfile == null) {
      _showErrorSnackBar("Error: No perfil para editar.");
      return;
    }

    final Map<String, dynamic>? updatedProfileData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _EditDoctorProfileDialogContent(initialProfile: initialProfile),
    );

    if (updatedProfileData != null && _doctorData != null) {
      try {
        Map<String, dynamic> firestoreUpdate = {};
        updatedProfileData.forEach((key, value) {
          firestoreUpdate['doctorProfile.$key'] = value;
        });
        await _usersService.updateUserWithProfile(_doctorData!.uid, firestoreUpdate);
        _showSuccessSnackBar("Perfil actualizado.");
      } catch (e) {
        _showErrorSnackBar("Error al actualizar: ${e.toString()}");
      }
    }
  }

  Future<void> _showAddEditHorarioDialog({Horario? horario}) async {
    // ... (código sin cambios) ...
    final bool isEditing = horario != null;
    String? selectedDia = isEditing ? horario.diaSemana : null;
    TimeOfDay? startTime = isEditing ? _timeOfDayFromString(horario.horaInicio) : null;
    TimeOfDay? endTime = isEditing ? _timeOfDayFromString(horario.horaFin) : null;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setStateDialog) {
              Future<void> pickTime(bool isStart) async {
                /* ... */
                final initial = isStart ? startTime : endTime;
                final picked = await showTimePicker(
                  context: context,
                  initialTime: initial ?? TimeOfDay.now(),
                  builder:
                      (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      ),
                );
                if (picked != null) {
                  setStateDialog(() {
                    if (isStart) {
                      startTime = picked;
                    } else {
                      endTime = picked;
                    }
                  });
                }
              }

              return AlertDialog(
                title: Text(isEditing ? 'Editar Horario' : 'Añadir Horario'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedDia,
                        hint: const Text('Día *'),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items:
                            _diasSemana
                                .map((dia) => DropdownMenuItem(value: dia, child: Text(dia)))
                                .toList(),
                        onChanged: (value) => setStateDialog(() => selectedDia = value),
                        validator: (v) => v == null ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        title: Text(
                          startTime == null ? 'Hora Inicio *' : startTime!.format(context),
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => pickTime(true),
                      ),
                      ListTile(
                        title: Text(endTime == null ? 'Hora Fin *' : endTime!.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => pickTime(false),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedDia != null && startTime != null && endTime != null) {
                        if (_timeOfDayToDouble(endTime!) <= _timeOfDayToDouble(startTime!)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Hora fin debe ser posterior.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        Navigator.of(ctx).pop({
                          'diaSemana': selectedDia,
                          'horaInicio': _formatTimeOfDay(startTime!),
                          'horaFin': _formatTimeOfDay(endTime!),
                          'id': horario?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Completa campos.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    child: Text(isEditing ? 'Guardar' : 'Añadir'),
                  ),
                ],
              );
            },
          ),
    );
    if (result != null) {
      final nuevoHorario = Horario.fromJson(result);
      _updateHorarios(nuevoHorario, isEditing: isEditing);
    }
  }

  Future<void> _confirmDeleteHorario(Horario horario) async {
    // ... (código sin cambios) ...
    final confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Confirmar'),
                content: Text(
                  '¿Eliminar ${horario.diaSemana} ${horario.horaInicio}-${horario.horaFin}?',
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
        ) ??
        false;
    if (confirm) {
      _updateHorarios(horario, isDeleting: true);
    }
  }

  // --- NUEVO: Diálogo para Crear/Editar Cita (Adaptado de Admin) ---
  Future<void> _showAddEditAppointmentDialog({Cita? cita}) async {
    if (!_isViewingOwnProfile || _doctorData == null) return; // Solo el doctor logueado

    final bool isEditing = cita != null;

    // Usa el AppointmentFormDialog adaptado o crea uno nuevo específico
    final bool? result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AppointmentFormDialogDoctor(
            firestoreService: _firestoreService,
            cita: cita,
            doctorId: _doctorData!.uid, // Pasa el ID del doctor actual
            doctorHorarios: _doctorData!.doctorProfile?.horarios ?? [], // Pasa horarios
            assignedPatients: _assignedPatients, // Pasa pacientes asignados
            isLoadingPatients: _isLoadingPatients, // Pasa estado de carga
          ),
    );

    if (result == true && mounted) {
      _showSuccessSnackBar(isEditing ? 'Cita actualizada.' : 'Cita creada.');
      // El StreamBuilder de citas se actualizará solo
    }
  }

  // --- NUEVO: Confirmar borrado de cita ---
  Future<void> _confirmDeleteAppointment(Cita cita) async {
    if (!_isViewingOwnProfile || cita.id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de eliminar la cita de "${cita.nombrePaciente}" el ${DateFormat('dd/MM/yyyy HH:mm').format(cita.fecha)}?',
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
        _showSuccessSnackBar('Cita eliminada.');
      } catch (e) {
        _showErrorSnackBar('Error al eliminar cita: $e');
      }
    }
  }

  // --- Lógica de Actualización de Horarios (sin cambios) ---
  Future<void> _updateHorarios(
    Horario horario, {
    bool isEditing = false,
    bool isDeleting = false,
  }) async {
    // ... (código idéntico) ...
    if (_doctorData == null) return;
    final List<Horario> currentHorarios = List.from(_doctorData!.doctorProfile?.horarios ?? []);
    if (isDeleting) {
      currentHorarios.removeWhere((h) => h.id == horario.id);
    } else if (isEditing) {
      final index = currentHorarios.indexWhere((h) => h.id == horario.id);
      if (index != -1) {
        currentHorarios[index] = horario;
      } else {
        currentHorarios.add(horario);
      }
    } else {
      currentHorarios.add(horario);
    }
    final List<Map<String, dynamic>> horariosJson = currentHorarios.map((h) => h.toJson()).toList();
    try {
      await _usersService.updateUserWithProfile(_doctorData!.uid, {
        'doctorProfile.horarios': horariosJson,
      });
      _showSuccessSnackBar(
        isDeleting
            ? 'Horario eliminado.'
            : (isEditing ? 'Horario actualizado.' : 'Horario añadido.'),
      );
    } catch (e) {
      _showErrorSnackBar("Error al actualizar horarios: ${e.toString()}");
    }
  }

  // --- Helpers para Horarios (idénticos) ---
  TimeOfDay _timeOfDayFromString(String timeString) {
    /* ... */
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      print("Error parsing TimeOfDay: $timeString -> $e");
      return TimeOfDay.now();
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    /* ... */
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  double _timeOfDayToDouble(TimeOfDay time) {
    /* ... */
    return time.hour + time.minute / 60.0;
  }

  // --- Helpers Generales (idénticos) ---
  void _showSuccessSnackBar(String message) {
    /* ... */
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  void _showErrorSnackBar(String message) {
    /* ... */
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  // --- Build Principal ---
  @override
  Widget build(BuildContext context) {
    // --- Lógica del FloatingActionButton (MODIFICADA) ---
    Widget? fabWidget;
    bool showFab = false;
    int currentTabIndex = _tabController.index;

    // Mostrar FABs solo si está viendo su propio perfil y no está cargando
    if (!_isLoading && _doctorData != null) {
      if (currentTabIndex == 1) {
        // Pestaña "Horarios"
        showFab = true;
        fabWidget = FloatingActionButton(
          heroTag: 'addScheduleBtn',
          onPressed: () => _showAddEditHorarioDialog(),
          tooltip: 'Añadir Horario Laboral',
          child: const Icon(Icons.add_alarm),
        );
      } else if (currentTabIndex == 2) {
        // Pestaña "Citas"
        showFab = true;
        fabWidget = FloatingActionButton(
          heroTag: 'addAppointmentBtn',
          onPressed: () => _showAddEditAppointmentDialog(), // Llama sin cita para crear
          tooltip: 'Crear Nueva Cita',
          child: const Icon(Icons.add_circle_outline),
        );
      }
    }
    // --- Fin Lógica FAB ---

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isViewingOwnProfile
              ? 'Mi Perfil y Agenda'
              : (_doctorData?.displayName ?? 'Perfil Doctor'),
        ),
        actions: [
          if (_isViewingOwnProfile)
            IconButton(icon: const Icon(Icons.logout), onPressed: () => _auth.logout(context)),
        ],
        bottom: TabBar(controller: _tabController, tabs: _tabs, isScrollable: _tabs.length > 4),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _doctorData == null
              ? const Center(child: Text('No se encontró el perfil del doctor.'))
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(_doctorData!),
                  _buildScheduleTab(_doctorData!),
                  _buildAppointmentsTab(_doctorData!.uid),
                ],
              ),
      floatingActionButton: showFab ? fabWidget : null, // FAB dinámico
    );
  }
}

// --- Widget Interno Formulario Edición Perfil (igual) ---
class _EditDoctorProfileDialogContent extends StatefulWidget {
  // ... (código idéntico a la versión anterior) ...
  final DoctorProfile initialProfile;
  const _EditDoctorProfileDialogContent({required this.initialProfile});
  @override
  __EditDoctorProfileDialogContentState createState() => __EditDoctorProfileDialogContentState();
}

class __EditDoctorProfileDialogContentState extends State<_EditDoctorProfileDialogContent> {
  // ... (código idéntico a la versión anterior) ...
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _especialidadesController;
  late TextEditingController _licenciaController;
  late TextEditingController _anosExperienciaController;
  late TextEditingController _telefonoController;

  @override
  void initState() {
    super.initState();
    _especialidadesController = TextEditingController(
      text: widget.initialProfile.specialties.join(', '),
    );
    _licenciaController = TextEditingController(text: widget.initialProfile.licenseNumber);
    _anosExperienciaController = TextEditingController(
      text: widget.initialProfile.anosExperiencia?.toString(),
    );
    _telefonoController = TextEditingController(text: widget.initialProfile.telefono);
  }

  @override
  void dispose() {
    _especialidadesController.dispose();
    _licenciaController.dispose();
    _anosExperienciaController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Mi Perfil'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: ListBody(
            children: [
              TextFormField(
                controller: _licenciaController,
                decoration: const InputDecoration(labelText: 'Licencia *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _especialidadesController,
                decoration: const InputDecoration(labelText: 'Especialidades (coma) *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _anosExperienciaController,
                decoration: const InputDecoration(labelText: 'Años Exp.'),
                keyboardType: TextInputType.number,
                validator:
                    (v) =>
                        (v != null && v.isNotEmpty && int.tryParse(v.trim()) == null)
                            ? 'Inválido'
                            : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final updatedData = {
                'licenseNumber': _licenciaController.text.trim(),
                'specialties':
                    _especialidadesController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList(),
                'anosExperiencia': int.tryParse(_anosExperienciaController.text.trim()),
                'telefono':
                    _telefonoController.text.trim().isEmpty
                        ? null
                        : _telefonoController.text.trim(),
              };
              if (updatedData['anosExperiencia'] == null) updatedData.remove('anosExperiencia');
              if (updatedData['telefono'] == null) updatedData.remove('telefono');
              Navigator.of(context).pop(updatedData);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// --- NUEVO: Diálogo/Formulario para Citas (Adaptado para Doctor) ---
class AppointmentFormDialogDoctor extends StatefulWidget {
  final FirestoreService firestoreService;
  final Cita? cita; // Cita existente para editar (opcional)
  final String doctorId; // ID del doctor actual (requerido)
  final List<Horario> doctorHorarios; // Horarios del doctor (requerido)
  final List<Usuario> assignedPatients; // Pacientes asignados (requerido)
  final bool isLoadingPatients; // Estado de carga de pacientes

  const AppointmentFormDialogDoctor({
    required this.firestoreService,
    this.cita,
    required this.doctorId,
    required this.doctorHorarios,
    required this.assignedPatients,
    required this.isLoadingPatients,
    super.key,
  });

  @override
  State<AppointmentFormDialogDoctor> createState() => _AppointmentFormDialogDoctorState();
}

class _AppointmentFormDialogDoctorState extends State<AppointmentFormDialogDoctor> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Para el botón de guardar

  // Controladores y variables de estado del formulario
  late TextEditingController _titleController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Usuario? _selectedPaciente;
  String? _selectedEstado; // Podría ser opcional o fijo para el doctor

  final TextEditingController _pacienteSearchController = TextEditingController();
  final List<String> _estadosPosibles = [
    'programada',
    'completada',
    'cancelada',
  ]; // O los que el doctor pueda manejar

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.cita?.titulo);
    _selectedDate = widget.cita?.fecha;
    _selectedTime = widget.cita != null ? TimeOfDay.fromDateTime(widget.cita!.fecha) : null;
    _selectedEstado = widget.cita?.estado ?? 'programada'; // Estado por defecto

    // Preseleccionar paciente si estamos editando
    if (widget.cita != null && widget.cita!.pacienteId != null) {
      try {
        // Busca en la lista de pacientes *asignados* pasada como parámetro
        _selectedPaciente = widget.assignedPatients.firstWhere(
          (p) => p.uid == widget.cita!.pacienteId,
        );
        _pacienteSearchController.text = _selectedPaciente!.displayName;
      } catch (e) {
        print(
          "Advertencia: Paciente asignado ${widget.cita!.pacienteId} no encontrado en la lista.",
        );
        _pacienteSearchController.text = widget.cita!.nombrePaciente; // Muestra nombre guardado
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(
        const Duration(days: 7),
      ), // Rango (ej. desde hace 1 semana)
      lastDate: DateTime.now().add(const Duration(days: 90)), // Rango (ej. hasta 3 meses)
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      // Opcional: Restringir minutos a intervalos (ej. cada 30 min)
      // minuteInterval: 30,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), // Formato 24h
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // --- NUEVO: Lógica de Validación de Disponibilidad ---
  Future<bool> _isSlotAvailable(DateTime proposedDateTime) async {
    // 1. Verificar Horario Laboral Semanal
    final diaSemana = _diasSemana[proposedDateTime.weekday - 1]; // Lunes=1 -> Domingo=7
    final proposedTime = TimeOfDay.fromDateTime(proposedDateTime);
    final double proposedTimeDouble = _timeOfDayToDouble(proposedTime);

    final horariosDelDia = widget.doctorHorarios.where((h) => h.diaSemana == diaSemana).toList();

    if (horariosDelDia.isEmpty) {
      _showError('No hay horario laboral definido para los $diaSemana.');
      return false;
    }

    bool withinWorkingHours = false;
    for (var h in horariosDelDia) {
      final start = _timeOfDayToDouble(_timeOfDayFromString(h.horaInicio));
      final end = _timeOfDayToDouble(_timeOfDayFromString(h.horaFin));
      if (proposedTimeDouble >= start && proposedTimeDouble < end) {
        // Asume citas de 1h o verificar duración
        withinWorkingHours = true;
        break;
      }
    }

    if (!withinWorkingHours) {
      _showError('La hora seleccionada está fuera del horario laboral para los $diaSemana.');
      return false;
    }

    // 2. Verificar Conflictos con Citas Existentes
    // Asume una duración de cita (ej. 1 hora). Deberías hacer esto más robusto.
    const appointmentDuration = Duration(hours: 1);
    final proposedEndDateTime = proposedDateTime.add(appointmentDuration);

    try {
      final existingAppointments =
          await widget.firestoreService
              .getAppointmentsStream(
                doctorId: widget.doctorId,
                startDate: DateTime(
                  proposedDateTime.year,
                  proposedDateTime.month,
                  proposedDateTime.day,
                ), // Mismo día inicio
                endDate: DateTime(
                  proposedDateTime.year,
                  proposedDateTime.month,
                  proposedDateTime.day,
                ), // Mismo día fin
              )
              .first; // Obtener la lista actual de citas para ese día

      for (var existingCita in existingAppointments) {
        // Ignorar la propia cita si estamos editando
        if (widget.cita != null && existingCita.id == widget.cita!.id) {
          continue;
        }

        final existingStart = existingCita.fecha;
        final existingEnd = existingStart.add(appointmentDuration); // Asume duración

        // Comprobar solapamiento
        if (proposedDateTime.isBefore(existingEnd) && proposedEndDateTime.isAfter(existingStart)) {
          _showError(
            'El horario se solapa con una cita existente (${DateFormat('HH:mm').format(existingStart)} - ${DateFormat('HH:mm').format(existingEnd)}).',
          );
          return false;
        }
      }
    } catch (e) {
      _showError("Error al verificar citas existentes: $e");
      return false; // Mejor no permitir si hay error
    }

    return true; // Si pasa todas las validaciones
  }

  // --- Guardar Cita (Adaptado) ---
  void _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return; // Validación básica
    if (_selectedPaciente == null) {
      _showError('Selecciona un paciente.');
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      _showError('Selecciona fecha y hora.');
      return;
    }

    final fechaHora = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // --- LLAMAR A VALIDACIÓN DE DISPONIBILIDAD ---
    final bool available = await _isSlotAvailable(fechaHora);
    if (!available || !mounted) {
      // Si no está disponible o el widget se desmontó
      if (available && !mounted) {
        _showError("Operación cancelada."); // O un mensaje más genérico
      }
      // El mensaje de error específico ya se mostró en _isSlotAvailable
      return;
    }
    // ---------------------------------------------

    setState(() => _isLoading = true);

    final citaData = Cita(
      id: widget.cita?.id, // ID si estamos editando
      titulo: _titleController.text.trim(),
      pacienteId: _selectedPaciente!.uid,
      nombrePaciente: _selectedPaciente!.displayName,
      doctorId: widget.doctorId, // ID del doctor actual
      nombreDoctor: _doctorData?.displayName, // Nombre del doctor actual
      fecha: fechaHora,
      estado: _selectedEstado ?? 'programada',
    );

    try {
      if (widget.cita == null) {
        // Creando
        await widget.firestoreService.createAppointment(citaData);
      } else {
        // Editando
        await widget.firestoreService.updateAppointment(widget.cita!.id!, citaData.toJson());
      }
      Navigator.of(context).pop(true); // Devuelve true para indicar éxito
    } catch (e) {
      _showError('Error al guardar cita: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pacienteSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.cita != null;
    final String dialogTitle = isEditing ? 'Editar Cita' : 'Nueva Cita';

    return AlertDialog(
      title: Text(dialogTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: ListBody(
            children: <Widget>[
              // --- Selector de Paciente (Autocomplete) ---
              Autocomplete<Usuario>(
                // ... (código del Autocomplete similar al de AppointmentFormDialog) ...
                // ... (pero usando widget.assignedPatients y widget.isLoadingPatients) ...
                fieldViewBuilder: (context, fieldController, fieldFocusNode, onFieldSubmitted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    /* Sincronizar controlador */
                    if (_pacienteSearchController.text != fieldController.text && mounted) {
                      if (_pacienteSearchController.text.isEmpty &&
                          fieldController.text.isNotEmpty &&
                          widget.cita?.pacienteId != null) {
                        _pacienteSearchController.text = fieldController.text;
                      } else if (fieldController.text.isEmpty &&
                          _pacienteSearchController.text.isNotEmpty) {
                        fieldController.text = _pacienteSearchController.text;
                      }
                    }
                  });
                  return TextFormField(
                    controller: fieldController,
                    focusNode: fieldFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Buscar Paciente Asignado *',
                      hintText: 'Escribe nombre...',
                      border: const OutlineInputBorder(),
                      prefixIcon:
                          widget.isLoadingPatients
                              ? const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: SizedBox(
                                  height: 15,
                                  width: 15,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                              : const Icon(Icons.person_search),
                      suffixIcon:
                          fieldController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  fieldController.clear();
                                  setState(() {
                                    _selectedPaciente = null;
                                  });
                                },
                              )
                              : null,
                    ),
                    validator:
                        (v) =>
                            (v != null && v.isNotEmpty && _selectedPaciente == null)
                                ? 'Selecciona paciente válido'
                                : ((v == null || v.isEmpty) && _selectedPaciente == null)
                                ? 'Selecciona un paciente'
                                : null,
                  );
                },
                optionsBuilder: (textEditingValue) {
                  if (widget.isLoadingPatients) return const Iterable.empty();
                  final query = textEditingValue.text.toLowerCase();
                  if (query.isEmpty) return const Iterable<Usuario>.empty();
                  return widget.assignedPatients.where(
                    (p) =>
                        p.displayName.toLowerCase().contains(query) ||
                        p.email.toLowerCase().contains(query),
                  ); // Usa la lista de asignados
                },
                optionsViewBuilder:
                    (context, onSelected, options) => Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (ctx, i) {
                              final o = options.elementAt(i);
                              return InkWell(
                                onTap: () => onSelected(o),
                                child: ListTile(
                                  title: Text(o.displayName),
                                  subtitle: Text(o.email),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                onSelected: (selection) {
                  setState(() {
                    _selectedPaciente = selection;
                    _pacienteSearchController.text = selection.displayName;
                    _formKey.currentState?.validate();
                  });
                  FocusScope.of(context).unfocus();
                },
                displayStringForOption: (option) => option.displayName,
                initialValue:
                    _selectedPaciente != null
                        ? TextEditingValue(text: _selectedPaciente!.displayName)
                        : null,
              ),
              const SizedBox(height: 12),

              // --- Campos de Fecha y Hora (sin cambios) ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedDate == null
                      ? 'Selecciona Fecha *'
                      : 'Fecha: ${DateFormat('EE dd MMM yyyy', 'es_ES').format(_selectedDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedTime == null
                      ? 'Selecciona Hora *'
                      : 'Hora: ${_selectedTime!.format(context)}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 12),

              // --- Campo Título/Motivo ---
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título/Motivo'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un título' : null,
              ),
              const SizedBox(height: 12),

              // --- Selector de Estado (Opcional para el doctor, podría fijarse o limitarse) ---
              DropdownButtonFormField<String>(
                value: _selectedEstado,
                decoration: const InputDecoration(labelText: 'Estado Cita'),
                items:
                    _estadosPosibles
                        .map(
                          (estado) => DropdownMenuItem<String>(
                            value: estado,
                            child: Text(estado[0].toUpperCase() + estado.substring(1)),
                          ),
                        )
                        .toList(),
                onChanged: (newValue) => setState(() => _selectedEstado = newValue),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveAppointment,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Guardar'),
        ),
      ],
    );
  }
}
 */