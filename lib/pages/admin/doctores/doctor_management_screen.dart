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
