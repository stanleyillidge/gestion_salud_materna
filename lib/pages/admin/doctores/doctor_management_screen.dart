// doctor_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:gestion_salud_materna/models/modelos.dart';

class DoctorManagementScreen extends StatefulWidget {
  const DoctorManagementScreen({super.key});

  @override
  State<DoctorManagementScreen> createState() => _DoctorManagementScreenState();
}

class _DoctorManagementScreenState extends State<DoctorManagementScreen> {
  bool _isLoading = true;
  String? _error;
  List<Usuario> _allDoctors = [];
  List<Usuario> _filteredDoctors = [];
  List<String> _availableSpecialties = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  String? _selectedSpecialtyFilter;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  bool _currentUserIsSuperAdmin = false;
  bool _currentUserIsAdmin = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _checkPermissionsAndLoadDoctors();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndLoadDoctors() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentUserIsAdmin = false;
      _currentUserIsSuperAdmin = false;
    });
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("Usuario no autenticado.");
      final claims = (await currentUser.getIdTokenResult(true)).claims ?? {};
      _currentUserIsSuperAdmin = claims['superadmin'] == true;
      _currentUserIsAdmin = claims['admin'] == true && !_currentUserIsSuperAdmin;
      if (!_currentUserIsAdmin && !_currentUserIsSuperAdmin) {
        throw Exception("Acceso denegado. Se requiere rol Admin o Superadmin.");
      }
      await _loadDoctors();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDoctors() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final snapshot =
          await _firestore.collection('usuarios').where('roles', arrayContains: 'doctor').get();
      _allDoctors =
          snapshot.docs
              .map((doc) {
                try {
                  return Usuario.fromFirestore(doc);
                } catch (_) {
                  return null;
                }
              })
              .whereType<Usuario>()
              .toList();
      _extractSpecialties();
      _applyFiltersAndSortDoctors();
    } catch (e) {
      if (mounted) setState(() => _error = "Error al cargar doctores: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _extractSpecialties() {
    final Set<String> specialties = {};
    for (var user in _allDoctors) {
      specialties.addAll(user.doctorProfile?.specialties ?? []);
    }
    setState(() {
      _availableSpecialties = specialties.toList()..sort();
    });
  }

  void _onSearchChanged() {
    final term = _searchController.text.trim();
    if (term != _searchTerm) {
      _searchTerm = term;
      _applyFiltersAndSortDoctors();
    }
  }

  void _applyFiltersAndSortDoctors() {
    var result = List<Usuario>.from(_allDoctors);
    if (_selectedSpecialtyFilter != null) {
      result =
          result.where((u) {
            return u.doctorProfile?.specialties.contains(_selectedSpecialtyFilter!) ?? false;
          }).toList();
    }
    if (_searchTerm.isNotEmpty) {
      final lower = _searchTerm.toLowerCase();
      result =
          result.where((u) {
            final name = u.displayName.toLowerCase();
            final email = u.email.toLowerCase();
            final specMatches =
                u.doctorProfile?.specialties.any((s) => s.toLowerCase().contains(lower)) ?? false;
            return name.contains(lower) || email.contains(lower) || specMatches;
          }).toList();
    }
    result.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    if (mounted) {
      setState(() {
        _filteredDoctors = result;
      });
    }
  }

  Future<void> _callManageAuthUserFunction(
    String action, {
    required String uid,
    Map<String, dynamic>? updateData,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showErrorSnackBar('Error: No autenticado.');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ejecutando "$action"...'), duration: const Duration(seconds: 2)),
    );
    try {
      await currentUser.getIdTokenResult(true);
      final callable = _functions.httpsCallable('manageAuthUser');
      final params = {'action': action, 'uid': uid};
      if (updateData != null) params['updateData'] = updateData as String;
      final result = await callable.call(params);
      _showSuccessSnackBar(result.data['message'] ?? '$action exitoso.');
      await _loadDoctors();
    } on FirebaseFunctionsException catch (e) {
      _showErrorSnackBar('Error al $action (${e.code}): ${e.message}');
    } catch (e) {
      _showErrorSnackBar('Error inesperado al $action: $e');
    }
  }

  Future<void> _toggleDoctorStatus(Usuario user, bool isDisabled) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text(isDisabled ? 'Activar Doctor' : 'Desactivar Doctor'),
                content: Text(
                  'Esto cambiará el acceso del doctor ${user.displayName}. ¿Continuar?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      isDisabled ? 'Activar' : 'Desactivar',
                      style: TextStyle(color: isDisabled ? Colors.green : Colors.orange),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
    if (confirm) {
      _callManageAuthUserFunction('update', uid: user.uid, updateData: {'disabled': !isDisabled});
    }
  }

  void _showDoctorDetailsDialog(Usuario user) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Detalles del Doctor'),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  _detailRow('Nombre:', user.displayName),
                  _detailRow('Email:', user.email),
                  _detailRow('Licencia médica:', user.doctorProfile?.licenseNumber),
                  _detailRow('Especialidades:', user.doctorProfile?.specialties.join(', ')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
            ],
          ),
    );
  }

  Future<void> _showEditDoctorDialog(Usuario user) async {
    final updatedData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => EditDoctorFormDialog(doctor: user),
    );
    if (updatedData != null) {
      try {
        await _firestore.collection('usuarios').doc(user.uid).update({
          'doctorProfile': updatedData,
        });
        _showSuccessSnackBar("Perfil del doctor actualizado.");
        await _loadDoctors();
      } catch (e) {
        _showErrorSnackBar("Error al actualizar perfil: $e");
      }
    }
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value ?? 'No disponible'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gestión de Doctores (${_filteredDoctors.length})')),
      body: Column(
        children: [
          _buildDoctorControlBar(),
          const Divider(height: 1),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _filteredDoctors.isEmpty
                    ? Center(
                      child: Text(
                        'No se encontraron doctores${_searchTerm.isNotEmpty || _selectedSpecialtyFilter != null ? ' con esos filtros.' : '.'}',
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadDoctors,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredDoctors.length,
                        itemBuilder: (context, i) => _buildDoctorCard(_filteredDoctors[i]),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorControlBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 15,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 350,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar doctor por nombre, email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                suffixIcon:
                    _searchTerm.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                        : null,
              ),
            ),
          ),
          if (_availableSpecialties.isNotEmpty)
            DropdownButton<String?>(
              value: _selectedSpecialtyFilter,
              hint: const Text('Filtrar por especialidad'),
              onChanged: (v) {
                setState(() {
                  _selectedSpecialtyFilter = v;
                  _applyFiltersAndSortDoctors();
                });
              },
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ..._availableSpecialties.map((s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Usuario user) {
    final isDisabled = false; // TODO: obtener estado real de Auth
    final canEdit = _currentUserIsSuperAdmin || _currentUserIsAdmin;
    final canToggle = canEdit && user.uid != _auth.currentUser?.uid;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage:
                  (user.photoUrl?.isNotEmpty ?? false) ? NetworkImage(user.photoUrl!) : null,
              child:
                  (user.photoUrl == null || user.photoUrl!.isEmpty)
                      ? const Icon(Icons.medical_services_outlined, size: 30)
                      : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.doctorProfile?.specialties.isNotEmpty == true
                        ? user.doctorProfile!.specialties.first
                        : 'Especialidad no indicada',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    isDisabled ? 'Estado: Inactivo' : 'Estado: Activo',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDisabled ? Colors.orange.shade800 : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Ver'),
                  onPressed: () => _showDoctorDetailsDialog(user),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                  onPressed: canEdit ? () => _showEditDoctorDialog(user) : null,
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
                TextButton.icon(
                  icon: Icon(
                    isDisabled ? Icons.toggle_on_outlined : Icons.toggle_off_outlined,
                    size: 18,
                  ),
                  label: Text(isDisabled ? 'Activar' : 'Desactivar'),
                  onPressed: canToggle ? () => _toggleDoctorStatus(user, isDisabled) : null,
                  style: TextButton.styleFrom(
                    foregroundColor: isDisabled ? Colors.green : Colors.orange,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para editar perfil del doctor (Usuario con rol 'doctor')
class EditDoctorFormDialog extends StatefulWidget {
  final Usuario doctor;
  const EditDoctorFormDialog({super.key, required this.doctor});

  @override
  State<EditDoctorFormDialog> createState() => _EditDoctorFormDialogState();
}

class _EditDoctorFormDialogState extends State<EditDoctorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _especialidadesController;
  late TextEditingController _licenciaController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.doctor.displayName);
    _especialidadesController = TextEditingController(
      text: widget.doctor.doctorProfile?.specialties.join(', '),
    );
    _licenciaController = TextEditingController(text: widget.doctor.doctorProfile?.licenseNumber);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _especialidadesController.dispose();
    _licenciaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Perfil Doctor'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: ListBody(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _licenciaController,
                decoration: const InputDecoration(labelText: 'Licencia Médica'),
                validator: (v) => v == null || v.isEmpty ? 'Requerida' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _especialidadesController,
                decoration: const InputDecoration(labelText: 'Especialidades (separadas por coma)'),
                validator: (v) => v == null || v.isEmpty ? 'Requerida al menos una' : null,
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
              final updatedProfile = {
                'licenseNumber': _licenciaController.text.trim(),
                'specialties':
                    _especialidadesController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList(),
              };
              Navigator.of(context).pop(updatedProfile);
            }
          },
          child: const Text('Guardar Cambios'),
        ),
      ],
    );
  }
}

/* import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Necesario para saber quién llama
import 'package:cloud_functions/cloud_functions.dart'; // Necesario para activar/desactivar

// Asegúrate que la ruta a tus modelos sea correcta
import 'package:gestion_salud_materna/models/modelos.dart';

// --- Widget Principal ---
class DoctorManagementScreen extends StatefulWidget {
  const DoctorManagementScreen({super.key});

  @override
  State<DoctorManagementScreen> createState() => _DoctorManagementScreenState();
}

class _DoctorManagementScreenState extends State<DoctorManagementScreen> {
  // --- Estado ---
  bool _isLoading = true;
  String? _error;
  List<Doctor> _allDoctors = []; // Lista completa de doctores
  List<Doctor> _filteredDoctors = []; // Lista filtrada/ordenada para mostrar
  List<String> _availableSpecialties = []; // Para el filtro

  // --- Controles ---
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  String? _selectedSpecialtyFilter; // Filtro de especialidad

  // Instancias de Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Necesitamos llamar a la función para activar/desactivar
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  ); // AJUSTA REGIÓN

  // Roles del usuario actual (para permisos de acciones)
  bool _currentUserIsSuperAdmin = false;
  bool _currentUserIsAdmin = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _checkPermissionsAndLoadDoctors(); // Cargar datos al iniciar
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // --- Carga y Permisos ---
  Future<void> _checkPermissionsAndLoadDoctors() async {
    // Verificar roles del usuario actual (similar a SuperAdminUserManagement)
    setState(() {
      _isLoading = true;
      _error = null;
      _currentUserIsAdmin = false;
      _currentUserIsSuperAdmin = false;
    });
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("Usuario no autenticado.");
      final idTokenResult = await currentUser.getIdTokenResult(true);
      final claims = idTokenResult.claims ?? {};
      _currentUserIsSuperAdmin = claims['superadmin'] == true;
      _currentUserIsAdmin = claims['admin'] == true && !_currentUserIsSuperAdmin;

      if (!_currentUserIsAdmin && !_currentUserIsSuperAdmin) {
        throw Exception("Acceso denegado. Se requiere rol Admin o Superadmin.");
      }
      await _loadDoctors(); // Cargar doctores si tiene permiso
    } catch (e) {
      print("Error chequeando permisos o cargando doctores: $e");
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDoctors() async {
    if (!mounted) return; // Verificar si el widget sigue montado
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('doctores').get();
      print(['doctores', snapshot.docs.length]);
      // Mapear documentos a objetos Doctor
      _allDoctors =
          snapshot.docs
              .map((doc) {
                try {
                  // Necesitas asegurar que Doctor.fromDocument exista y funcione correctamente
                  return Doctor.fromDocument(doc);
                } catch (e) {
                  print("Error parseando doctor ${doc.id}: $e");
                  // Podrías retornar un objeto Doctor inválido o null y filtrarlo después
                  return null;
                }
              })
              .whereType<Doctor>()
              .toList(); // whereType filtra los nulls si el parseo falla

      _extractSpecialties(); // Extraer especialidades para el filtro
      _applyFiltersAndSortDoctors(); // Aplicar filtro/orden inicial
    } catch (e, stacktrace) {
      print("Error cargando doctores: $e\n$stacktrace");
      if (mounted) {
        setState(() {
          _error = "Error al cargar doctores: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Extrae especialidades únicas de la lista de doctores
  void _extractSpecialties() {
    final Set<String> specialties = {};
    for (var doctor in _allDoctors) {
      if (doctor.especialidades != null) {
        specialties.addAll(doctor.especialidades!);
      }
      // Si 'specialty' es un campo simple String, usa:
      // if (doctor.specialty != null && doctor.specialty.isNotEmpty) {
      //    specialties.add(doctor.specialty);
      // }
    }
    setState(() {
      _availableSpecialties = specialties.toList()..sort(); // Guardar ordenado
    });
  }

  // --- Búsqueda, Filtro y Orden ---
  void _onSearchChanged() {
    if (_searchTerm != _searchController.text.trim()) {
      setState(() {
        _searchTerm = _searchController.text.trim();
        _applyFiltersAndSortDoctors();
      });
    }
  }

  void _applyFiltersAndSortDoctors() {
    List<Doctor> result = List.from(_allDoctors);

    // 1. Filtrar por Especialidad
    if (_selectedSpecialtyFilter != null && _selectedSpecialtyFilter!.isNotEmpty) {
      result =
          result.where((doctor) {
            // Ajusta según si 'especialidades' es Lista o String simple
            return doctor.especialidades?.contains(_selectedSpecialtyFilter!) ?? false;
            // return doctor.specialty == _selectedSpecialtyFilter; // Si es String simple
          }).toList();
    }

    // 2. Filtrar por Término de Búsqueda (nombre, email, especialidad)
    if (_searchTerm.isNotEmpty) {
      final lowerCaseSearchTerm = _searchTerm.toLowerCase();
      result =
          result.where((doctor) {
            final nameMatch = doctor.nombre?.toLowerCase().contains(lowerCaseSearchTerm) ?? false;
            final emailMatch = doctor.email?.toLowerCase().contains(lowerCaseSearchTerm) ?? false;
            final specialtyMatch =
                doctor.especialidades?.any((s) => s.toLowerCase().contains(lowerCaseSearchTerm)) ??
                false;
            // final specialtyMatch = doctor.specialty?.toLowerCase().contains(lowerCaseSearchTerm) ?? false; // Si es String simple
            return nameMatch || emailMatch || specialtyMatch;
          }).toList();
    }

    // 3. Ordenar (Ej: por nombre ascendente)
    result.sort((a, b) {
      return (a.nombre ?? '').toLowerCase().compareTo((b.nombre ?? '').toLowerCase());
    });

    // Actualizar lista filtrada
    if (mounted) {
      // Asegurarse que el widget aún existe
      setState(() {
        _filteredDoctors = result;
      });
    }
  }

  // --- Acciones ---

  // Reutilizar o adaptar la función para llamar a 'manageAuthUser'
  // (Asegúrate que esta función esté disponible o cópiala/ajústala desde SuperAdminUserManagement)
  Future<void> _callManageAuthUserFunction(
    String action, {
    required String uid,
    Map<String, dynamic>? updateData,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showErrorSnackBar('Error: No autenticado.');
      return;
    }
    // No necesitamos verificar rol aquí porque el botón solo se muestra si se tiene permiso

    String processingMessage = 'Ejecutando "$action"...';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(processingMessage), duration: Duration(seconds: 2)));

    try {
      await currentUser.getIdTokenResult(true); // Token fresco
      final HttpsCallable callable = _functions.httpsCallable('manageAuthUser');
      final params = <String, dynamic>{'action': action, 'uid': uid};
      if (updateData != null) params['updateData'] = updateData;

      print('Llamando manageAuthUser (desde Doctores): $params');
      final HttpsCallableResult result = await callable.call(params);
      print('Resultado "$action": ${result.data}');

      _showSuccessSnackBar(result.data['message'] ?? '$action exitoso.');
      // Podríamos solo actualizar el estado local del doctor afectado en _allDoctors
      // O recargar todo para simplicidad
      await _loadDoctors(); // Recargar lista
    } on FirebaseFunctionsException catch (e) {
      /* ... manejo error ... */
      _showErrorSnackBar('Error al $action (${e.code}): ${e.message ?? "N/A"}');
    } catch (e) {
      /* ... manejo error ... */
      _showErrorSnackBar('Error inesperado al $action: ${e.toString()}');
    }
  }

  Future<void> _toggleDoctorStatus(Doctor doctor, bool currentAuthDisabledStatus) async {
    // Usamos la función genérica, la lógica de permisos está en la CF y en la UI
    final bool disableAction =
        !currentAuthDisabledStatus; // Si está habilitado (false), la acción es deshabilitar (true)
    final confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text(disableAction ? 'Desactivar Doctor' : 'Activar Doctor'),
                content: Text(
                  'Esto cambiará el estado de autenticación del doctor ${doctor.nombre}.\n¿Continuar?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      disableAction ? 'Desactivar' : 'Activar',
                      style: TextStyle(color: disableAction ? Colors.orange : Colors.green),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm && doctor.id != null) {
      // Asegurarse que el doctor tiene ID (viene de Firestore doc ID)
      _callManageAuthUserFunction(
        'update',
        uid: doctor.id!,
        updateData: {'disabled': disableAction},
      );
    }
  }

  // Mostrar diálogo de detalles (simplificado)
  void _showDoctorDetailsDialog(Doctor doctor) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Detalles del Doctor'),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  _detailRow('Nombre:', doctor.nombre),
                  _detailRow('Email:', doctor.email),
                  _detailRow('Teléfono:', doctor.telefono),
                  _detailRow('Especialidades:', doctor.especialidades?.join(', ')),
                  _detailRow('Licencia:', doctor.licenciaMedica),
                  _detailRow('Años Exp:', doctor.anosExperiencia?.toString()),
                  // Podríamos añadir horarios aquí si se cargan
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cerrar'))],
          ),
    );
  }

  // Mostrar diálogo/pantalla de edición
  Future<void> _showEditDoctorDialog(Doctor doctor) async {
    // Usaremos un Dialog simple aquí, podría ser una pantalla completa (Dialog.fullscreen)
    final updatedDoctorData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => EditDoctorFormDialog(doctor: doctor),
    );

    if (updatedDoctorData != null && doctor.id != null) {
      print("Datos para actualizar doctor ${doctor.id}: $updatedDoctorData");
      // Actualizar en Firestore
      try {
        await _firestore.collection('doctores').doc(doctor.id).update(updatedDoctorData);
        _showSuccessSnackBar("Perfil del doctor actualizado.");
        await _loadDoctors(); // Recargar
      } catch (e) {
        _showErrorSnackBar("Error al actualizar perfil: ${e.toString()}");
      }
    }
  }

  // --- Helpers UI ---
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

  Widget _detailRow(String label, String? value) {
    /* ... */
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(text: '$label ', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value ?? 'No disponible'),
          ],
        ),
      ),
    );
  }

  // --- Build Principal ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Doctores (${_filteredDoctors.length})'),
        // Podríamos añadir aquí el botón "+ Nuevo Doctor" si decidimos
        // que SÍ debe estar aquí y llame a la función de creación general.
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.person_add_alt_1),
        //     tooltip: 'Crear Nuevo Doctor (Usuario)',
        //     onPressed: () { /* Llamar a _showCreateUserDialog adaptado para doctor? */ },
        //   )
        // ],
      ),
      body: Column(
        children: [
          // --- Barra de Controles ---
          _buildDoctorControlBar(),
          Divider(height: 1),

          // --- Contenido Principal (Lista/Grid) ---
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(_error!, style: TextStyle(color: Colors.red)),
                      ),
                    )
                    : _filteredDoctors.isEmpty
                    ? Center(
                      child: Text(
                        'No se encontraron doctores${_searchTerm.isNotEmpty || _selectedSpecialtyFilter != null ? ' con los filtros aplicados.' : '.'}',
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadDoctors,
                      // Usaremos ListView por simplicidad, podrías añadir lógica para GridView
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _filteredDoctors.length,
                        itemBuilder: (context, index) {
                          return _buildDoctorCard(_filteredDoctors[index]);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  // --- Widgets Builders Específicos ---

  Widget _buildDoctorControlBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Wrap(
        spacing: 15.0,
        runSpacing: 10.0,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Buscador
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 350),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar doctor por nombre, email...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                suffixIcon:
                    _searchTerm.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                        : null,
              ),
            ),
          ),
          // Filtro por Especialidad
          if (_availableSpecialties.isNotEmpty)
            DropdownButton<String?>(
              value: _selectedSpecialtyFilter,
              hint: Text('Filtrar por especialidad'),
              isDense: true,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSpecialtyFilter = newValue;
                  _applyFiltersAndSortDoctors();
                });
              },
              items: [
                // Opción para quitar filtro
                DropdownMenuItem<String?>(value: null, child: Text('Todas las especialidades')),
                // Opciones de especialidades disponibles
                ..._availableSpecialties.map<DropdownMenuItem<String?>>((String value) {
                  return DropdownMenuItem<String?>(value: value, child: Text(value));
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    // Necesitamos saber el estado de Auth (disabled) para el indicador y acciones
    // Esto requiere una consulta adicional o tener esta info precargada.
    // Por ahora, asumiremos que no lo tenemos y el botón siempre dice "Desactivar".
    // TODO: Obtener el estado 'disabled' real de Firebase Auth para este doctor.
    bool isCurrentlyDisabled = false; // <- Placeholder! Reemplazar con estado real.

    // Determinar si el usuario actual puede editar/desactivar
    // Superadmin puede todo, Admin puede doctores
    bool canEdit = _currentUserIsSuperAdmin || _currentUserIsAdmin;
    bool canToggle =
        (_currentUserIsSuperAdmin || _currentUserIsAdmin) &&
        doctor.id != _auth.currentUser?.uid; // No auto-desactivar

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Foto
            CircleAvatar(
              radius: 30,
              backgroundImage:
                  doctor.fotoPerfilURL != null && doctor.fotoPerfilURL!.isNotEmpty
                      ? NetworkImage(doctor.fotoPerfilURL!)
                      : null, // Placeholder si no hay foto
              child:
                  doctor.fotoPerfilURL == null || doctor.fotoPerfilURL!.isEmpty
                      ? Icon(Icons.medical_services_outlined, size: 30)
                      : null,
            ),
            SizedBox(width: 15),
            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.nombre ?? 'Nombre no disponible',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    // Mostrar primera especialidad o un texto por defecto
                    (doctor.especialidades?.isNotEmpty ?? false)
                        ? doctor.especialidades!.first
                        : 'Especialidad no indicada',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    doctor.email ?? 'Email no disponible',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                  // Indicador de estado (basado en el placeholder)
                  Text(
                    isCurrentlyDisabled ? "Estado: Inactivo" : "Estado: Activo",
                    style: TextStyle(
                      fontSize: 12,
                      color: isCurrentlyDisabled ? Colors.orange.shade800 : Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Botones de Acción
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.visibility_outlined, size: 18),
                  label: Text('Ver'),
                  onPressed: () => _showDoctorDetailsDialog(doctor),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
                TextButton.icon(
                  icon: Icon(Icons.edit_outlined, size: 18),
                  label: Text('Editar'),
                  // Habilitar solo si tiene permiso
                  onPressed: canEdit ? () => _showEditDoctorDialog(doctor) : null,
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
                TextButton.icon(
                  icon: Icon(
                    isCurrentlyDisabled ? Icons.toggle_on_outlined : Icons.toggle_off_outlined,
                    size: 18,
                  ),
                  label: Text(isCurrentlyDisabled ? 'Activar' : 'Desactivar'),
                  // Habilitar solo si tiene permiso
                  onPressed:
                      canToggle ? () => _toggleDoctorStatus(doctor, isCurrentlyDisabled) : null,
                  style: TextButton.styleFrom(
                    foregroundColor: isCurrentlyDisabled ? Colors.green : Colors.orange,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Formulario de Edición (Dialogo) ---
class EditDoctorFormDialog extends StatefulWidget {
  final Doctor doctor;

  const EditDoctorFormDialog({super.key, required this.doctor});

  @override
  State<EditDoctorFormDialog> createState() => _EditDoctorFormDialogState();
}

class _EditDoctorFormDialogState extends State<EditDoctorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _emailController; // Generalmente no editable aquí
  late TextEditingController _telefonoController;
  late TextEditingController _especialidadesController;
  late TextEditingController _licenciaController;
  late TextEditingController _experienciaController;
  // Añadir controlador para fotoURL si se quiere editar

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.doctor.nombre);
    _emailController = TextEditingController(text: widget.doctor.email);
    _telefonoController = TextEditingController(text: widget.doctor.telefono);
    _especialidadesController = TextEditingController(
      text: widget.doctor.especialidades?.join(', '),
    );
    _licenciaController = TextEditingController(text: widget.doctor.licenciaMedica);
    _experienciaController = TextEditingController(text: widget.doctor.anosExperiencia?.toString());
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _especialidadesController.dispose();
    _licenciaController.dispose();
    _experienciaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar Perfil Doctor'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: ListBody(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(labelText: 'Nombre Completo'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                // Email usualmente se gestiona desde Auth
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email (No editable aquí)'),
                readOnly: true,
              ),
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _especialidadesController,
                decoration: InputDecoration(labelText: 'Especialidades (separadas por coma)'),
                validator: (v) => v == null || v.isEmpty ? 'Requerida al menos una' : null,
              ),
              TextFormField(
                controller: _licenciaController,
                decoration: InputDecoration(labelText: 'Licencia Médica'),
                validator: (v) => v == null || v.isEmpty ? 'Requerida' : null,
              ),
              TextFormField(
                controller: _experienciaController,
                decoration: InputDecoration(labelText: 'Años Experiencia'),
                keyboardType: TextInputType.number,
                validator:
                    (v) =>
                        v == null || v.isEmpty || int.tryParse(v) == null || int.parse(v) < 0
                            ? 'Número inválido'
                            : null,
              ),
              // Añadir campo para editar URL de foto si es necesario
              // TextFormField(...) para fotoPerfilURL
              // O mejor, un botón para subir nueva foto (más complejo)
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              // Crear mapa con los datos actualizados
              final updatedData = {
                'nombre': _nombreController.text.trim(),
                'telefono': _telefonoController.text.trim(),
                'especialidades':
                    _especialidadesController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList(),
                'licenciaMedica': _licenciaController.text.trim(),
                'anosExperiencia': int.tryParse(_experienciaController.text.trim()) ?? 0,
                // 'fotoPerfilURL': _fotoUrlController.text.trim(), // Si se añade
              };
              // Devolver los datos actualizados
              Navigator.of(context).pop(updatedData);
            }
          },
          child: Text('Guardar Cambios'),
        ),
      ],
    );
  }
} */
