// paciente_detail_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/modelos.dart';
import '../../../services/firestore_service.dart';
import '../../../services/vertex_service.dart'; // Asume que este servicio ahora existe
// Importa las vistas y formularios necesarios
import 'historia clinica/gestion_historia_clinica_view.dart';
import 'historia clinica/gestion_historia_clinica_form.dart';
import 'recomendaciones_screen.dart'; // Asegúrate que esta pantalla exista

enum _AILayout { card, listDetail }

class PacienteDetailScreen extends StatefulWidget {
  final String pacienteId;
  final bool isAdminView; // Si es true, muestra opciones de admin

  const PacienteDetailScreen({required this.pacienteId, this.isAdminView = false, super.key});

  @override
  State<PacienteDetailScreen> createState() => _PacienteDetailScreenState();
}

class _PacienteDetailScreenState extends State<PacienteDetailScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  late final Future<VertexAiClient> _vertexClientFuture; // Para el cliente Vertex
  _AILayout _currentAILayout = _AILayout.card; // Vista inicial
  ConsultaIA? _selectedConsultaIA;

  Usuario? _pacienteData; // Mantiene los datos generales del usuario
  String? _assignedDoctorId;
  List<Usuario>? _availableDoctors;
  String? _selectedDoctorIdForAssignment;

  bool _isLoadingPaciente = true; // Renombrado para claridad
  bool _isLoadingDoctors = false;
  bool _isAICallLoading = false;
  String? _lastAIRiskResult;
  String? _errorLoadingPaciente; // Renombrado para claridad

  // --- Definición de Tabs ---
  // Tabs comunes a ambas vistas (Admin y Doctor/Paciente)
  final List<Tab> _commonTabs = const [
    Tab(icon: Icon(Icons.person_outline), text: 'General'),
    Tab(icon: Icon(Icons.medical_information_outlined), text: 'H. Clínica'),
    Tab(icon: Icon(Icons.healing_outlined), text: 'Recomendaciones'),
    Tab(icon: Icon(Icons.analytics_outlined), text: 'Consultas IA'),
  ];
  // Tabs exclusivas para la vista de Admin
  final List<Tab> _adminTabs = const [
    Tab(icon: Icon(Icons.assignment_ind_outlined), text: 'Admin'),
  ];

  @override
  void initState() {
    super.initState();
    _vertexClientFuture = initVertexClient(); // Inicializa el cliente Vertex

    // Calcula el número total de tabs según la vista
    final totalTabs = _commonTabs.length + (widget.isAdminView ? _adminTabs.length : 0);
    _tabController = TabController(length: totalTabs, vsync: this);

    // Listener para actualizar la UI (especialmente el FAB) al cambiar de tab
    _tabController.addListener(_updateFabVisibility);

    // Carga inicial de datos
    _fetchPacienteDetails();
    if (widget.isAdminView) {
      _fetchAvailableDoctors();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_updateFabVisibility); // Limpia el listener
    _tabController.dispose();
    super.dispose();
  }

  // Helper para actualizar el estado y forzar redibujo del FAB
  void _updateFabVisibility() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Carga los datos generales del paciente (Usuario) desde Firestore usando un Stream.
  Future<void> _fetchPacienteDetails() async {
    setState(() {
      _isLoadingPaciente = true;
      _errorLoadingPaciente = null;
    });
    try {
      // Escucha cambios en el documento del usuario
      _firestoreService
          .getUserStream(widget.pacienteId)
          .listen(
            (userData) {
              if (mounted) {
                setState(() {
                  _pacienteData = userData;
                  // Actualiza el doctor asignado desde el perfil del paciente
                  _assignedDoctorId = userData?.pacienteProfile?.doctorId;
                  // Si se estaba editando, resetea la selección al valor actual
                  if (_isLoadingDoctors == false) {
                    // Evita resetear si doctores aún no cargan
                    _selectedDoctorIdForAssignment = _assignedDoctorId;
                  }
                  _isLoadingPaciente = false;
                  _errorLoadingPaciente = null;
                });
              }
            },
            onError: (e) {
              if (mounted) {
                setState(() {
                  _errorLoadingPaciente = 'Error al cargar datos en tiempo real: ${e.toString()}';
                  _isLoadingPaciente = false;
                });
              }
            },
            onDone: () {
              // El stream se cerró (puede pasar si el documento se borra)
              if (mounted && _pacienteData == null) {
                // Si no se recibieron datos antes de cerrar
                setState(() {
                  _errorLoadingPaciente = 'El paciente ya no existe.';
                  _isLoadingPaciente = false;
                });
              }
            },
            cancelOnError: true, // Detener el stream si hay un error irrecuperable
          );
    } catch (e) {
      // Captura error inicial si getUserStream falla al suscribirse
      if (mounted) {
        setState(() {
          _errorLoadingPaciente = 'Error al iniciar la carga: ${e.toString()}';
          _isLoadingPaciente = false;
        });
      }
    }
  }

  /// Carga la lista de doctores disponibles para asignar (solo en vista Admin).
  Future<void> _fetchAvailableDoctors() async {
    if (!widget.isAdminView) return; // Solo necesario para Admin
    setState(() => _isLoadingDoctors = true);
    try {
      // Usamos .first para obtener la lista una vez, no necesitamos stream aquí
      _availableDoctors = await _firestoreService.getAllDoctorsStream().first;
      // Establece el doctor seleccionado inicialmente si ya hay uno asignado
      if (_assignedDoctorId != null) {
        _selectedDoctorIdForAssignment = _assignedDoctorId;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar doctores: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Asegura que isLoadingDoctors se ponga en false incluso si _assignedDoctorId era null
      if (mounted) setState(() => _isLoadingDoctors = false);
    }
  }

  /// Asigna el doctor seleccionado al paciente (solo Admin).
  Future<void> _assignDoctor() async {
    // Verifica que haya datos y que el doctor seleccionado sea válido y diferente
    final pacienteId = _pacienteData?.uid;
    final nuevoDoctorId = _selectedDoctorIdForAssignment;

    if (pacienteId == null || nuevoDoctorId == null || !_isDoctorSelectionValid(nuevoDoctorId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un doctor válido.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (nuevoDoctorId == _assignedDoctorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este doctor ya está asignado.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Confirmación
    final confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Confirmar Asignación'),
                content: const Text('¿Asignar este doctor al paciente?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Asignar'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    // Lógica de asignación
    try {
      await _firestoreService.assignDoctorTopaciente(pacienteId, nuevoDoctorId);
      // El StreamBuilder en _fetchPacienteDetails actualizará la UI automáticamente
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor asignado correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
      // No necesitamos setState aquí, el stream lo hará.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asignar doctor: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper para validar selección de doctor
  bool _isDoctorSelectionValid(String? doctorId) {
    return doctorId != null && _availableDoctors?.any((d) => d.uid == doctorId) == true;
  }

  /// Quita la asignación actual del doctor (solo Admin).
  Future<void> _removeDoctorAssignment() async {
    final pacienteId = _pacienteData?.uid;
    if (pacienteId == null || _assignedDoctorId == null) return; // No hay nada que quitar

    // Confirmación
    final confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Quitar Asignación'),
                content: const Text('¿Quitar la asignación del doctor actual?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Quitar', style: TextStyle(color: Colors.orange)),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    // Lógica para quitar asignación
    try {
      await _firestoreService.removeDoctorAssignment(pacienteId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asignación de doctor removida.'),
          backgroundColor: Colors.orange,
        ),
      );
      // El stream actualizará la UI. _assignedDoctorId se actualizará en el listener.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al quitar asignación: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Evalúa el riesgo con IA usando el último registro clínico.
  Future<void> _evaluateRisk() async {
    if (_pacienteData == null || _isAICallLoading) return; // Chequeo inicial

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
      // 1. Obtener el último registro clínico desde el servicio
      final clinicalRecordsStream = _firestoreService.getClinicalRecordsStream(widget.pacienteId);
      final latestRecordsList =
          await clinicalRecordsStream.first; // Obtiene la primera emisión (la lista más reciente)

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

      final datosClinicosParaEvaluar = latestRecordsList.first; // El primero es el más reciente

      // 2. Llamar al servicio Vertex AI
      final client = await _vertexClientFuture; // Asegura que el cliente esté listo
      final riesgo = await client.callVertex(
        datos: datosClinicosParaEvaluar,
        pacienteId: widget.pacienteId,
        doctorId: doctorId,
        firestoreService: _firestoreService, // Pasa el servicio para el log
      );

      // 3. Actualizar UI y mostrar resultado
      if (mounted) {
        setState(() => _lastAIRiskResult = riesgo); // Actualiza el estado para la UI

        // Mostrar Snackbar de éxito o error/inválido
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
      // Captura errores durante la obtención de datos o la llamada a Vertex
      if (mounted) {
        setState(() => _lastAIRiskResult = "Error interno");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al realizar evaluación: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
      print("Error en _evaluateRisk: $e"); // Log del error
    } finally {
      if (mounted) setState(() => _isAICallLoading = false);
    }
  }

  /// Navega a la pantalla de edición del paciente (solo Admin).
  void _navigateToEdit() {
    if (!widget.isAdminView || _pacienteData == null) return;
    // TODO: Implementar navegación a una pantalla de edición general del usuario (si existe)
    // Por ejemplo, podría reutilizar CreateUserScreen pasándole los datos existentes.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Funcionalidad Editar Paciente no implementada')));
  }

  /// Confirmación y eliminación del paciente (solo Admin).
  void _confirmDeletePaciente() async {
    if (!widget.isAdminView || _pacienteData == null) return;

    final confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Confirmar Eliminación'),
                content: Text(
                  '¿Eliminar permanentemente al paciente ${_pacienteData!.displayName}? Esto también borrará sus datos asociados y acceso.',
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
      try {
        // Llama al servicio que usa la Cloud Function para borrar Auth y Firestore
        await _firestoreService.deleteUser(widget.pacienteId, UserRole.paciente.name);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paciente eliminado.'), backgroundColor: Colors.orange),
        );
        Navigator.of(context).pop(); // Vuelve a la lista anterior
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    // Combina las tabs comunes y las de admin si aplica
    final List<Tab> tabsToShow = List.from(_commonTabs);
    if (widget.isAdminView) {
      tabsToShow.addAll(_adminTabs);
    }

    // --- Lógica del FloatingActionButton ---
    Widget? fabWidget;
    bool showFab = false;
    int currentTabIndex = _tabController.index; // Índice de la tab actual

    if (!_isLoadingPaciente && _pacienteData != null) {
      // Solo mostrar si no está cargando y hay datos
      if (currentTabIndex == 1) {
        // Índice de "H. Clínica"
        showFab = true;
        fabWidget = FloatingActionButton(
          heroTag: 'addHistoryBtn',
          onPressed: () {
            // Navega al formulario de CREACIÓN
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
        // Índice de "Recomendaciones"
        showFab = true;
        fabWidget = FloatingActionButton(
          heroTag: 'addRecomendacionBtn',
          tooltip: 'Nueva Recomendación',
          onPressed: _navigateToAddRecomendacion,
          child: const Icon(Icons.add_comment),
        );
      } else if (currentTabIndex == 3) {
        // Índice de "Consultas IA"
        showFab = true;
        fabWidget = FloatingActionButton.extended(
          heroTag: 'evaluateAIBtn',
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
        // Muestra la barra de tabs
        bottom: TabBar(
          controller: _tabController,
          tabs: tabsToShow, // Usa la lista de tabs calculada
          // isScrollable: tabsToShow.length > 4, // Hacer scrollable si hay muchas tabs
        ),
        actions: [
          // Mostrar botones de admin solo si isAdminView es true
          if (widget.isAdminView)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar Paciente',
              onPressed: _navigateToEdit,
            ),
          if (widget.isAdminView)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              tooltip: 'Eliminar Paciente',
              onPressed: _confirmDeletePaciente,
            ),
        ],
      ),
      body:
          _isLoadingPaciente
              ? const Center(child: CircularProgressIndicator())
              : _errorLoadingPaciente != null
              ? Center(
                child: Text(_errorLoadingPaciente!, style: const TextStyle(color: Colors.red)),
              )
              : _pacienteData == null
              ? const Center(child: Text('No se encontraron datos.'))
              : TabBarView(
                controller: _tabController,
                children: [
                  // Vistas para las otras tabs (ajusta según la clase)
                  _buildGeneralInfoTab(_pacienteData!),
                  _buildClinicalHistoryTab(widget.pacienteId),
                  _buildRecomendacionesTab(widget.pacienteId),
                  // -- Pestaña de Consultas IA MODIFICADA --
                  _buildAIConsultationsTabContainer(widget.pacienteId), // Llama al contenedor
                  // Si es PacienteDetailScreen (Admin), añade la tab de admin
                  if (widget.runtimeType == PacienteDetailScreen && (widget).isAdminView)
                    _buildAdminTab(_pacienteData!),
                ],
              ),
      // Mostrar el FAB calculado dinámicamente
      floatingActionButton: showFab ? fabWidget : null,
    );
  }

  // --- NUEVO: Contenedor para la Pestaña de Consultas IA ---
  /// Construye el contenedor principal de la pestaña AI, incluyendo el botón de cambio de vista.
  /// // --- Contenedor para la Pestaña de Consultas IA (MODIFICADO) ---
  Widget _buildAIConsultationsTabContainer(String pacienteId) {
    // Muestra el último resultado SIEMPRE arriba si existe y estamos en modo tarjeta
    final lastResultDisplay =
        _lastAIRiskResult != null && _currentAILayout == _AILayout.card
            ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), // Ajusta padding si es necesario
              child: Align(
                // Alinea el texto a la izquierda
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  // Limita el ancho si quieres (opcional para el texto)
                  width: 350,
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
                ),
              ),
            )
            : const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Asegura alineación izquierda general
      children: [
        // --- Botón para cambiar layout ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(_currentAILayout == _AILayout.card ? Icons.view_list : Icons.view_module),
              tooltip: 'Cambiar Vista',
              onPressed: () {
                setState(() {
                  _currentAILayout =
                      _currentAILayout == _AILayout.card ? _AILayout.listDetail : _AILayout.card;
                  _selectedConsultaIA = null;
                });
              },
            ),
          ),
        ),

        // --- Mostrar Último Resultado (si aplica) ---
        lastResultDisplay, // Muestra el widget del último resultado aquí
        // --- Contenido principal (StreamBuilder) ---
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getAIConsultationsStream(pacienteId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error al cargar historial IA: ${snapshot.error}'));
              }
              final consultas =
                  snapshot.data?.docs
                      .map(
                        (doc) =>
                            ConsultaIA.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>),
                      )
                      .toList() ??
                  [];

              // No mostrar mensaje si ya mostramos _lastAIRiskResult
              if (consultas.isEmpty && _lastAIRiskResult == null) {
                return const Center(child: Text('No hay consultas de IA registradas.'));
              }

              // Renderiza el layout actual (Wrap o List/Detail)
              if (_currentAILayout == _AILayout.card) {
                // Pasa la lista SIN el último resultado, ya que se muestra arriba
                return _buildWrapLayout(consultas);
              } else {
                return _buildListDetailLayout(consultas);
              }
            },
          ),
        ),
      ],
    );
  }

  // --- NUEVO: Layout de Tarjetas con Wrap ---
  Widget _buildWrapLayout(List<ConsultaIA> consultas) {
    // Mapea las consultas a los widgets de tarjeta con ancho limitado
    List<Widget> cardWidgets =
        consultas.map((consulta) {
          return SizedBox(
            width: 350, // Ancho máximo para cada tarjeta
            child: _buildConsultaCard(consulta), // Reutiliza tu widget de tarjeta
          );
        }).toList();

    // Usa SingleChildScrollView por si el Wrap excede la altura
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: 8,
        left: 16.0,
        right: 16.0,
        bottom: 120.0,
      ), // Espacio alrededor del contenido del Wrap
      child: Wrap(
        spacing: 12.0, // Espacio horizontal entre tarjetas
        runSpacing: 12.0, // Espacio vertical entre filas de tarjetas
        alignment: WrapAlignment.start, // Alinea las *filas* al inicio (izquierda)
        children: cardWidgets, // Los widgets de tarjeta que creamos
      ),
    );
  }

  // --- NUEVO: Layout Lista/Detalle ---
  Widget _buildListDetailLayout(List<ConsultaIA> consultas) {
    final DateFormat compactFormatter = DateFormat('EEEE dd MMM yyy hh:mm a', 'es_ES');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Columna Izquierda: Lista ---
        Expanded(
          flex: 1, // Ocupa 1/3 del espacio (ajustable)
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, left: 8, bottom: 8), // Padding para la lista
            itemCount: consultas.length,
            itemBuilder: (context, index) {
              final consulta = consultas[index];
              final isSelected = _selectedConsultaIA?.id == consulta.id;
              Color cardColor;
              List<String> recomendaciones = [];

              switch (consulta.nivelRiesgo.toLowerCase()) {
                case 'crítico':
                  cardColor = Colors.redAccent.shade100;
                  recomendaciones = [
                    'Monitorización continua de signos vitales.',
                    'Realizar exámenes de laboratorio urgentes.',
                    'Preparar para posible intervención quirúrgica o transfusión sanguínea.',
                    'Activar protocolo de emergencia obstétrica.',
                  ];
                  break;
                case 'alto':
                  cardColor = Colors.orange.shade300;
                  recomendaciones = [
                    'Monitorización estricta de signos vitales y bienestar fetales.',
                    'Considerar traslado a un centro de mayor complejidad si no se dispone de los recursos necesarios.',
                    'Administrar oxigeno suplementario.',
                  ];
                  break;
                case 'moderado':
                  cardColor = Colors.lime.shade400;
                  recomendaciones = [
                    'Evaluación por médico especialista.',
                    'Monitorización cada hora.',
                    'Considerar laboratorios y estudios complementarios.',
                  ];
                  break;
                case 'bajo':
                  cardColor = Colors.greenAccent.shade200;
                  recomendaciones = [
                    'Observación cada 12 horas.',
                    'Vigilar signos de alarma.',
                    'Educar al paciente sobre el plan de manejo y la importancia del cumplimiento.',
                  ];
                  break;
                default: // Errores o categorías no definidas
                  cardColor = Colors.blueGrey.shade100;
                  recomendaciones = ['Reportar con el área de sistemas.'];
                  break;
              }
              return Card(
                margin: const EdgeInsets.only(right: 8, bottom: 4), // Espacio entre items
                elevation: isSelected ? 4 : 1,
                child: ListTile(
                  dense: true, // Hace el ListTile más compacto
                  title: Text(
                    consulta.nivelRiesgo,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    compactFormatter.format(consulta.timestamp),
                    style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  ),
                  selected: isSelected, // Marca visualmente el seleccionado
                  selectedTileColor: cardColor.withOpacity(0.8),
                  tileColor: cardColor.withOpacity(0.3),
                  onTap: () {
                    setState(() {
                      _selectedConsultaIA = consulta;
                    });
                  },
                ),
              );
            },
          ),
        ),
        // --- Divisor Vertical ---
        const VerticalDivider(width: 1, thickness: 1),
        // --- Columna Derecha: Detalle ---
        Expanded(
          flex: 2, // Ocupa 2/3 del espacio (ajustable)
          child:
              _selectedConsultaIA == null
                  ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Selecciona una consulta de la lista para ver los detalles.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                  : SingleChildScrollView(
                    // Permite scroll si el detalle es largo
                    padding: const EdgeInsets.all(16.0), // Padding para el detalle
                    child: _buildConsultaCard(_selectedConsultaIA!), // Reutiliza la tarjeta
                  ),
        ),
      ],
    );
  }

  // --- Métodos _buildConsultaCard y _showRawResponseDialog sin cambios ---
  // ... (pega aquí los métodos _buildConsultaCard y _showRawResponseDialog
  //      que ya tenías en PacienteDetailScreen) ...
  // Helper para construir la tarjeta de una consulta IA
  Widget _buildConsultaCard(ConsultaIA consulta) {
    final formatter = DateFormat('EEEE dd MMMM, hh:mm a', 'es');
    Color cardColor;
    List<String> recomendaciones = [];

    switch (consulta.nivelRiesgo.toLowerCase()) {
      case 'crítico':
        cardColor =
            (_currentAILayout == _AILayout.card) ? Colors.redAccent.shade100 : Colors.red.shade100;
        recomendaciones = [
          'Monitorización continua de signos vitales.',
          'Realizar exámenes de laboratorio urgentes.',
          'Preparar para posible intervención quirúrgica o transfusión sanguínea.',
          'Activar protocolo de emergencia obstétrica.',
        ];
        break;
      case 'alto':
        cardColor =
            (_currentAILayout == _AILayout.card) ? Colors.orange.shade300 : Colors.orange.shade50;
        recomendaciones = [
          'Monitorización estricta de signos vitales y bienestar fetales.',
          'Considerar traslado a un centro de mayor complejidad si no se dispone de los recursos necesarios.',
          'Administrar oxigeno suplementario.',
        ];
        break;
      case 'moderado':
        cardColor =
            (_currentAILayout == _AILayout.card) ? Colors.lime.shade400 : Colors.lime.shade100;
        recomendaciones = [
          'Evaluación por médico especialista.',
          'Monitorización cada hora.',
          'Considerar laboratorios y estudios complementarios.',
        ];
        break;
      case 'bajo':
        cardColor =
            (_currentAILayout == _AILayout.card)
                ? Colors.greenAccent.shade200
                : Colors.green.shade100;
        recomendaciones = [
          'Observación cada 12 horas.',
          'Vigilar signos de alarma.',
          'Educar al paciente sobre el plan de manejo y la importancia del cumplimiento.',
        ];
        break;
      default: // Errores o categorías no definidas
        cardColor = Colors.blueGrey.shade100;
        recomendaciones = ['Reportar con el área de sistemas.'];
        break;
    }

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
              consulta.nivelRiesgo,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              formatter.format(consulta.timestamp),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Recomendaciones:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...recomendaciones.map(
              (recomendacion) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(recomendacion, maxLines: 3, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_currentAILayout == _AILayout.card)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  child: const Text("Ver Detalles"),
                  onPressed: () => _showRawResponseDialog(consulta),
                ),
              )
            else
              SingleChildScrollView(
                child: ListBody(
                  children: [
                    Text("Input Enviado:", style: TextStyle(fontWeight: FontWeight.bold)),
                    SelectableText("${consulta.inputDetails}\n"),
                    SelectableText("Versión del Modelo:\n${consulta.modelVersion}"),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper para mostrar diálogo con detalles de IA
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

  // --- El resto de los métodos (_buildGeneralInfoTab, _buildClinicalHistoryTab, _buildRecomendacionesTab, _buildInfoRow, etc.) sin cambios ---
  // ... (pega aquí el resto de los métodos build de las otras tabs y los helpers) ...

  Widget _buildGeneralInfoTab(Usuario user) {
    final profile = user.pacienteProfile; // Accede al perfil específico
    final DateFormat formatter = DateFormat('dd MMMM yyyy', 'es_ES');

    // Lista de widgets a mostrar en esta pestaña
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Información básica del Usuario (común)
        _buildInfoRow('Nombre Completo:', user.displayName),
        _buildInfoRow('Email:', user.email),
        _buildInfoRow('ID Usuario:', user.uid),
        const Divider(height: 20, thickness: 1),

        // Información específica del PacienteProfile
        Text("Datos del Perfil de Paciente", style: Theme.of(context).textTheme.titleMedium),
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
        _buildInfoRow('Medicamentos Actuales:', profile?.medicamentos?.join(', ')),
        const Divider(height: 20, thickness: 1),

        // Datos Obstétricos del PacienteProfile
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
        // Solo muestra doctor asignado si es admin view
        if (widget.runtimeType == PacienteDetailScreen && (widget).isAdminView)
          _buildInfoRow('Doctor Asignado ID:', profile?.doctorId ?? 'Ninguno'),
      ],
    );
  }

  Widget _buildClinicalHistoryTab(String pacienteId) {
    return GestionHistoriaClinicaView(pacienteId: pacienteId);
  }

  Widget _buildRecomendacionesTab(String pacienteId) {
    return StreamBuilder<List<Recomendacion>>(
      stream: _firestoreService.getRecomendacionesStream(pacienteId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error al cargar recomendaciones: ${snap.error}'));
        }
        final recs = snap.data ?? [];
        if (recs.isEmpty) {
          return const Center(child: Text('No hay recomendaciones para este paciente.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: recs.length,
          itemBuilder: (c, i) {
            final r = recs[i];
            bool isAdmin = widget.runtimeType == PacienteDetailScreen && (widget).isAdminView;
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
                trailing:
                    isAdmin
                        ? IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Eliminar Recomendación',
                          onPressed: () => _confirmDeleteRecomendacion(r),
                        )
                        : null,
              ),
            );
          },
        );
      },
    );
  }

  // Necesitarás mover o copiar _confirmDeleteRecomendacion aquí si no estaba
  Future<void> _confirmDeleteRecomendacion(Recomendacion rec) async {
    if (rec.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: ID de recomendación nulo.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Confirmar Eliminación'),
                content: Text('¿Eliminar esta recomendación? "${rec.descripcion}"'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ],
              ),
        ) ??
        false;
    if (confirm) {
      try {
        await _firestoreService.deleteRecomendacion(
          rec.pacienteId,
          rec,
        ); // Asume que pasas el objeto
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recomendación eliminada.'), backgroundColor: Colors.orange),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar recomendación: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Necesitarás mover o copiar _iconForTipo aquí
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

  // Necesitarás mover o copiar _buildAdminTab aquí
  Widget _buildAdminTab(Usuario user) {
    final doctorAsignadoNombre =
        _availableDoctors
            ?.firstWhere(
              (doc) => doc.uid == _assignedDoctorId,
              orElse: () => Usuario(uid: '', email: '', displayName: 'Desconocido', roles: []),
            )
            .displayName;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Asignación de Doctor', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (_assignedDoctorId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text("Doctor Actual: ${doctorAsignadoNombre ?? _assignedDoctorId}"),
          ),
        _isLoadingDoctors
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : DropdownButtonFormField<String>(
              value: _selectedDoctorIdForAssignment,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Seleccionar Doctor',
                hintText: 'Asignar un doctor',
              ),
              items:
                  _availableDoctors == null || _availableDoctors!.isEmpty
                      ? [const DropdownMenuItem(value: null, child: Text("No hay doctores"))]
                      : _availableDoctors!.map((d) {
                        return DropdownMenuItem(value: d.uid, child: Text(d.displayName));
                      }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDoctorIdForAssignment = value);
                }
              },
            ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.assignment_ind_outlined),
          label: const Text('Asignar Doctor Seleccionado'),
          onPressed:
              (_selectedDoctorIdForAssignment != null &&
                      _selectedDoctorIdForAssignment != _assignedDoctorId)
                  ? _assignDoctor
                  : null,
        ),
        if (_assignedDoctorId != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton.icon(
              icon: const Icon(Icons.link_off, color: Colors.red),
              label: const Text('Quitar asignación actual', style: TextStyle(color: Colors.red)),
              onPressed: _removeDoctorAssignment,
            ),
          ),
      ],
    );
  }

  // Necesitarás mover o copiar _buildInfoRow aquí
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
