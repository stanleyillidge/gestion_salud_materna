// pages/medico/home.dart
// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Modelos y Servicios
import '../../models/modelos.dart';
import '../../services/firestore_service.dart';
import '../../services/vertex_service.dart'; // Servicio Vertex AI
import '../admin/pacientes/historia clinica/gestion_historia_clinica_form.dart';
import '../admin/pacientes/historia clinica/gestion_historia_clinica_view.dart'; // Vista de H. Clínica
import '../admin/pacientes/recomendaciones_screen.dart'; // Pantalla/Form de Recomendaciones
import '../admin/notificaciones.dart'; // Pantalla de Notificaciones
import '../auth/login.dart'; // Servicio de Autenticación

// --- Pantalla Principal del Doctor ---
class DoctorDashboardScreen extends StatelessWidget {
  DoctorDashboardScreen({super.key});
  final Authentication _auth = Authentication();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // En un caso real, podrías redirigir a Login aquí
      return const Scaffold(body: Center(child: Text("Usuario no autenticado.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Doctor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notificaciones',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Notificaciones()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _auth.logout(context),
          ),
        ],
      ),
      // Muestra la lista de pacientes asignados al doctor logueado
      body: DoctorpacienteListView(doctorId: user.uid),
    );
  }
}

// --- Widget: Lista de Pacientes del Doctor ---
class DoctorpacienteListView extends StatefulWidget {
  final String doctorId;
  const DoctorpacienteListView({required this.doctorId, super.key});

  @override
  State<DoctorpacienteListView> createState() => _DoctorpacienteListViewState();
}

class _DoctorpacienteListViewState extends State<DoctorpacienteListView> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    // Stream para obtener los pacientes asignados a este doctor
    return StreamBuilder<List<Usuario>>(
      stream: _firestoreService.getDoctorpacientesStream(widget.doctorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          if (kDebugMode) print("Error Stream Pacientes Doctor: ${snapshot.error}");
          return Center(child: Text('Error al cargar pacientes: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No tienes pacientes asignados.'));
        }

        final pacientes = snapshot.data!;

        // Muestra la lista de pacientes
        return ListView.builder(
          itemCount: pacientes.length,
          itemBuilder: (context, index) {
            final paciente = pacientes[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    paciente.displayName.isNotEmpty ? paciente.displayName[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(paciente.displayName),
                subtitle: Text('Email: ${paciente.email}'), // Mostrar email u otro dato
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navega a la pantalla de detalle del paciente seleccionado
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Pasa el ID del paciente a la pantalla de detalle
                      builder: (_) => PacienteDetailScreenDoctorView(pacienteId: paciente.uid),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// --- Widget: Pantalla de Detalle del Paciente (Vista Doctor) ---
// Renombrado para claridad, similar a PacienteDetailScreen pero sin opciones de admin
class PacienteDetailScreenDoctorView extends StatefulWidget {
  final String pacienteId;
  const PacienteDetailScreenDoctorView({required this.pacienteId, super.key});

  @override
  State<PacienteDetailScreenDoctorView> createState() => _PacienteDetailScreenDoctorViewState();
}

class _PacienteDetailScreenDoctorViewState extends State<PacienteDetailScreenDoctorView>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  late final Future<VertexAiClient> _vertexClientFuture;

  Usuario? _pacienteData; // Datos generales del paciente
  bool _isLoadingPaciente = true;
  bool _isAICallLoading = false;
  String? _lastAIRiskResult;
  String? _errorLoadingPaciente;

  // Tabs para la vista del doctor
  final List<Tab> _doctorTabs = const [
    Tab(icon: Icon(Icons.person_outline), text: 'General'),
    Tab(icon: Icon(Icons.medical_information_outlined), text: 'H. Clínica'),
    Tab(icon: Icon(Icons.healing_outlined), text: 'Recomendaciones'),
    Tab(icon: Icon(Icons.analytics_outlined), text: 'Consultas IA'),
  ];

  @override
  void initState() {
    super.initState();
    _vertexClientFuture = initVertexClient(); // Inicializa cliente Vertex
    _tabController = TabController(length: _doctorTabs.length, vsync: this);
    _tabController.addListener(_updateFabVisibility); // Listener para el FAB
    _fetchPacienteDetails(); // Carga los datos del paciente
  }

  @override
  void dispose() {
    _tabController.removeListener(_updateFabVisibility);
    _tabController.dispose();
    super.dispose();
  }

  void _updateFabVisibility() {
    if (mounted) setState(() {}); // Fuerza redibujo para actualizar FAB
  }

  /// Carga los datos generales del paciente (Usuario) usando un Stream
  Future<void> _fetchPacienteDetails() async {
    setState(() {
      _isLoadingPaciente = true;
      _errorLoadingPaciente = null;
    });
    try {
      _firestoreService
          .getUserStream(widget.pacienteId)
          .listen(
            (userData) {
              if (mounted) {
                setState(() {
                  _pacienteData = userData;
                  _isLoadingPaciente = false;
                });
              }
            },
            onError: (e) {
              if (mounted) {
                setState(() {
                  _errorLoadingPaciente = 'Error al cargar: ${e.toString()}';
                  _isLoadingPaciente = false;
                });
              }
            },
            onDone: () {
              if (mounted && _pacienteData == null) {
                setState(() {
                  _errorLoadingPaciente = 'El paciente ya no existe.';
                  _isLoadingPaciente = false;
                });
              }
            },
            cancelOnError: true,
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorLoadingPaciente = 'Error al iniciar carga: ${e.toString()}';
          _isLoadingPaciente = false;
        });
      }
    }
  }

  /// Evalúa el riesgo con IA usando el último registro clínico disponible.
  Future<void> _evaluateRisk() async {
    // Validaciones iniciales
    if (_pacienteData == null || _isAICallLoading) return;
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    if (doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Doctor no autenticado."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isAICallLoading = true;
      _lastAIRiskResult = null;
    });

    try {
      // 1. Obtener el último registro clínico
      final clinicalRecordsStream = _firestoreService.getClinicalRecordsStream(widget.pacienteId);
      final latestRecordsList = await clinicalRecordsStream.first; // Obtiene la lista actual

      if (latestRecordsList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay datos clínicos para evaluar.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isAICallLoading = false);
        return;
      }
      final datosClinicosParaEvaluar = latestRecordsList.first; // El más reciente

      // 2. Llamar a Vertex AI
      final client = await _vertexClientFuture;
      final riesgo = await client.callVertex(
        datos: datosClinicosParaEvaluar,
        pacienteId: widget.pacienteId,
        doctorId: doctorId,
        firestoreService: _firestoreService,
      );

      // 3. Actualizar UI
      if (mounted) {
        setState(() => _lastAIRiskResult = riesgo);
        // Mostrar Snackbar con resultado
        if (riesgo != null && !riesgo.toLowerCase().contains('error') && riesgo != 'Inválido') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Evaluación IA completada: $riesgo"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Respuesta IA: ${riesgo ?? 'Desconocido'}"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _lastAIRiskResult = "Error interno al evaluar");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al realizar evaluación: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
      print("Error en _evaluateRisk: $e");
    } finally {
      if (mounted) setState(() => _isAICallLoading = false);
    }
  }

  /// Navega al formulario para añadir una nueva recomendación.
  void _navigateToAddRecomendacion() {
    if (_pacienteData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecomendacionFormScreen(pacienteId: widget.pacienteId)),
    );
  }

  // Nota: La función _confirmDeleteRecomendacion no es necesaria en la vista del doctor
  // a menos que quieras que los doctores puedan borrar sus propias recomendaciones.
  // Si es así, cópiala desde PacienteDetailScreen (admin view).

  @override
  Widget build(BuildContext context) {
    // --- Lógica del FloatingActionButton para la vista del Doctor ---
    Widget? fabWidget;
    bool showFab = false;
    int currentTabIndex = _tabController.index;

    if (!_isLoadingPaciente && _pacienteData != null) {
      if (currentTabIndex == 1) {
        // Índice "H. Clínica"
        showFab = true;
        fabWidget = FloatingActionButton(
          heroTag: 'doctorAddHistoryBtn',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => GestionHistoriaClinicaFormScreen(pacienteId: widget.pacienteId),
              ),
            );
          },
          tooltip: 'Añadir Registro Clínico',
          child: const Icon(Icons.post_add),
        );
      } else if (currentTabIndex == 2) {
        // Índice "Recomendaciones"
        showFab = true;
        fabWidget = FloatingActionButton(
          heroTag: 'doctorAddRecomendacionBtn',
          tooltip: 'Nueva Recomendación',
          onPressed: _navigateToAddRecomendacion,
          child: const Icon(Icons.add_comment),
        );
      } else if (currentTabIndex == 3) {
        // Índice "Consultas IA"
        showFab = true;
        fabWidget = FloatingActionButton.extended(
          heroTag: 'doctorEvaluateAIBtn',
          onPressed: _isAICallLoading ? null : _evaluateRisk,
          icon:
              _isAICallLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                  : const Icon(Icons.online_prediction),
          label: Text(_isAICallLoading ? 'Evaluando...' : 'Evaluar Riesgo IA'),
        );
      }
    }
    // --- Fin Lógica FAB ---

    return Scaffold(
      appBar: AppBar(
        title: Text(_pacienteData?.displayName ?? 'Detalle Paciente'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _doctorTabs, // Usa las tabs definidas para doctores
          isScrollable: _doctorTabs.length > 4,
        ),
        // No hay acciones de admin aquí
      ),
      body:
          _isLoadingPaciente
              ? const Center(child: CircularProgressIndicator())
              : _errorLoadingPaciente != null
              ? Center(
                child: Text(_errorLoadingPaciente!, style: const TextStyle(color: Colors.red)),
              )
              : _pacienteData == null
              ? const Center(child: Text('No se encontraron datos para este paciente.'))
              : TabBarView(
                controller: _tabController,
                children: [
                  // Contenido de las tabs para el doctor
                  _buildGeneralInfoTab(_pacienteData!),
                  _buildClinicalHistoryTab(widget.pacienteId),
                  _buildRecomendacionesTab(widget.pacienteId),
                  _buildAIConsultationsTab(widget.pacienteId),
                ],
              ),
      floatingActionButton: showFab ? fabWidget : null, // Muestra el FAB apropiado
    );
  }

  // --- Construcción de Pestañas (Reutilizadas de PacienteDetailScreen) ---

  /// Pestaña "General" (Idéntica a la de Admin View)
  Widget _buildGeneralInfoTab(Usuario user) {
    final profile = user.pacienteProfile;
    final DateFormat formatter = DateFormat('dd MMMM yyyy', 'es_ES');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoRow('Nombre Completo:', user.displayName),
        _buildInfoRow('Email:', user.email),
        _buildInfoRow('ID Usuario:', user.uid),
        const Divider(height: 20, thickness: 1),
        Text("Datos del Perfil", style: Theme.of(context).textTheme.titleMedium),
        _buildInfoRow(
          'Fec. Nacimiento:',
          profile?.fechaNacimiento != null ? formatter.format(profile!.fechaNacimiento!) : null,
        ),
        _buildInfoRow('Nacionalidad:', profile?.nacionalidad),
        _buildInfoRow('Doc. Identidad:', profile?.documentoIdentidad),
        _buildInfoRow('Dirección:', profile?.direccion),
        _buildInfoRow('Teléfono Contacto:', profile?.telefono),
        _buildInfoRow('Grupo Sanguíneo:', profile?.grupoSanguineo),
        _buildInfoRow('Factor RH:', profile?.factorRH),
        _buildInfoRow('Alergias:', profile?.alergias?.join(', ')),
        _buildInfoRow('Enf. Preexistentes:', profile?.enfermedadesPreexistentes?.join(', ')),
        _buildInfoRow('Medicamentos:', profile?.medicamentos?.join(', ')),
        const Divider(height: 20, thickness: 1),
        Text("Datos Obstétricos", style: Theme.of(context).textTheme.titleMedium),
        _buildInfoRow(
          'FUM:',
          profile?.fechaUltimaMenstruacion != null
              ? formatter.format(profile!.fechaUltimaMenstruacion!)
              : null,
        ),
        _buildInfoRow('Semanas Gestación:', profile?.semanasGestacion?.toString()),
        _buildInfoRow(
          'FPP:',
          profile?.fechaProbableParto != null
              ? formatter.format(profile!.fechaProbableParto!)
              : null,
        ),
        _buildInfoRow('Nº Gestaciones:', profile?.numeroGestaciones?.toString()),
        _buildInfoRow('Nº Partos Vaginales:', profile?.numeroPartosVaginales?.toString()),
        _buildInfoRow('Nº Cesáreas:', profile?.numeroCesareas?.toString()),
        _buildInfoRow('Nº Abortos:', profile?.abortos?.toString()),
        _buildInfoRow('Embarazo Múltiple:', profile?.embarazoMultiple),
        // No mostramos el doctor asignado aquí, ya que es el doctor actual
      ],
    );
  }

  /// Pestaña "H. Clínica" - Usa el widget dedicado
  Widget _buildClinicalHistoryTab(String pacienteId) {
    return GestionHistoriaClinicaView(pacienteId: pacienteId);
  }

  /// Pestaña "Recomendaciones" (Sin botón de eliminar)
  Widget _buildRecomendacionesTab(String pacienteId) {
    return StreamBuilder<List<Recomendacion>>(
      stream: _firestoreService.getRecomendacionesStream(pacienteId),
      builder: (ctx, snap) {
        // ... (manejo de loading, error, lista vacía igual que antes) ...
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        final recs = snap.data ?? [];
        if (recs.isEmpty) return const Center(child: Text('No hay recomendaciones.'));

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: recs.length,
          itemBuilder: (c, i) {
            final r = recs[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(_iconForTipo(r.tipo)),
                title: Text(r.tipoDisplay, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.descripcion),
                    if (r.tipo == TipoRecomendacion.medicamento)
                      Text(
                        "Med: ${r.medicamentoNombre ?? '?'} - Dosis: ${r.dosis ?? '?'} - Freq: ${r.frecuencia ?? '?'} ${r.duracion != null ? '(${r.duracion})' : ''}",
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    if (r.tipo == TipoRecomendacion.tratamiento && r.detallesTratamiento != null)
                      Text(
                        "Detalles: ${r.detallesTratamiento}",
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    Text(
                      "Por Dr.: ${r.doctorId.length > 6 ? r.doctorId.substring(0, 6) : r.doctorId}... - ${r.timestampDisplay}",
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                isThreeLine:
                    r.tipo == TipoRecomendacion.medicamento ||
                    (r.tipo == TipoRecomendacion.tratamiento && r.detallesTratamiento != null),
                // trailing: null, // No hay botón de eliminar en la vista del doctor
              ),
            );
          },
        );
      },
    );
  }

  // Helper icono recomendación
  IconData _iconForTipo(TipoRecomendacion tipo) {
    switch (tipo) {
      case TipoRecomendacion.medicamento:
        return Icons.medication_outlined;
      case TipoRecomendacion.tratamiento:
        return Icons.healing_outlined;
      case TipoRecomendacion.general:
        return Icons.lightbulb_outline;
      default:
        return Icons.notes_outlined;
    }
  }

  /// Pestaña "Consultas IA" (Idéntica a la de Admin View)
  Widget _buildAIConsultationsTab(String pacienteId) {
    final lastResultDisplay =
        _lastAIRiskResult != null
            ? Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Última Evaluación IA: $_lastAIRiskResult',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      _lastAIRiskResult!.toLowerCase().contains('error') ||
                              _lastAIRiskResult!.toLowerCase().contains('inválido')
                          ? Colors.redAccent
                          : Colors.blueAccent,
                ),
              ),
            )
            : const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getAIConsultationsStream(pacienteId),
      builder: (context, snapshot) {
        // ... (manejo de loading, error, lista vacía igual) ...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar historial IA: ${snapshot.error}'));
        }
        final consultas =
            snapshot.data?.docs
                .map(
                  (doc) => ConsultaIA.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>),
                )
                .toList() ??
            [];
        if (consultas.isEmpty && _lastAIRiskResult == null) {
          return const Center(child: Text('No hay consultas de IA registradas.'));
        }

        // Usa la lógica de layout (Desktop/Mobile) y _buildConsultaCard que definiste antes
        // O simplifica a un ListView si no necesitas la diferencia Desktop/Mobile aquí
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: consultas.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return lastResultDisplay;
            final consulta = consultas[index - 1];
            return _buildConsultaCard(consulta); // Reutiliza el builder de la tarjeta
          },
        );
      },
    );
  }

  // Helper para construir tarjeta de consulta IA (reutilizado)
  Widget _buildConsultaCard(ConsultaIA consulta) {
    final formatter = DateFormat('EEEE dd MMMM, hh:mm a', 'es');
    Color cardColor;
    switch (consulta.nivelRiesgo.toLowerCase()) {
      case 'crítico':
        cardColor = Colors.red.shade100;
        break;
      case 'alto':
        cardColor = Colors.orange.shade100;
        break;
      case 'moderado':
        cardColor = Colors.yellow.shade100;
        break;
      case 'bajo':
        cardColor = Colors.green.shade100;
        break;
      default:
        cardColor = Colors.grey.shade200;
        break;
    }
    // ... (código idéntico al de PacienteDetailScreen para construir la tarjeta) ...
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Riesgo: ${consulta.nivelRiesgo}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              formatter.format(consulta.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                child: const Text("Ver Detalles"),
                onPressed: () => _showRawResponseDialog(consulta),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para mostrar diálogo de IA (reutilizado)
  void _showRawResponseDialog(ConsultaIA consulta) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Respuesta Completa de la IA'),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  SelectableText("Nivel Riesgo: ${consulta.nivelRiesgo}\n"),
                  SelectableText("Input Enviado:\n${consulta.inputDetails}\n"),
                  SelectableText("Versión del Modelo:\n${consulta.modelVersion}"),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
            ],
          ),
    );
  }

  // --- Helper General ---
  /// Construye filas de información (Idéntico al de Admin View)
  Widget _buildInfoRow(String label, dynamic value) {
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
      text = value.toStringAsFixed(2);
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
}
