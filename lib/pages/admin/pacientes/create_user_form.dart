// D:\proyectos\gestion_salud_materna\lib\pages\admin\pacientes\create_user_form.dart
// create_user_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../models/modelos.dart'; // Importa tus modelos
import '../../../services/users_service.dart';

/// Calcula el ancho adecuado para los campos de formulario basado en el ancho de la pantalla.
///
/// Define breakpoints para diferentes tamaños (móvil, tablet, desktop)
/// y aplica límites mínimo y máximo.
///
/// [context]: El BuildContext actual para obtener el MediaQuery.
/// Retorna un [double] con el ancho calculado para el campo.
double getResponsiveFieldWidth(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  double calculatedWidth;

  // Define tus breakpoints y anchos deseados
  if (screenWidth < 600) {
    // Móvil
    // Ocupar casi todo el ancho menos padding lateral
    calculatedWidth = screenWidth - 32.0; // (Padding de 16 a cada lado)
  } else if (screenWidth < 900) {
    // Tablet pequeña / Web mediana
    calculatedWidth = 350.0;
  } else {
    // Desktop / Web ancha
    calculatedWidth = 400.0;
    // Podrías incluso usar un porcentaje: calculatedWidth = screenWidth * 0.3;
  }
  // Asegúrate de que el ancho no sea menor que un mínimo razonable (opcional)
  calculatedWidth = calculatedWidth.clamp(250.0, 500.0); // Ej: mínimo 250, máximo 500

  return calculatedWidth;
}

class CreateUserScreen extends StatefulWidget {
  // --- NUEVO: Parámetro opcional para datos iniciales (modo edición) ---
  final Usuario? initialData;

  const CreateUserScreen({
    super.key,
    this.initialData, // Hacerlo opcional
  });

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final UsersService _usersService = UsersService();
  bool _isSaving = false; // Renombrado para claridad (aplica a crear y guardar)
  // --- NUEVO: Determinar si estamos en modo edición ---
  late bool _isEditMode;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.initialData != null; // True si se pasaron datos iniciales
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // --- NUEVO: Título dinámico ---
        title: Text(_isEditMode ? 'Editar Usuario' : 'Crear Nuevo Usuario'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            child: CreateUserForm(
              // --- NUEVO: Pasar datos iniciales al formulario ---
              initialData: widget.initialData,
              isSubmitting: _isSaving, // Usar el estado renombrado
              onSubmit: (formData) async {
                if (_isSaving) return;

                setState(() {
                  _isSaving = true;
                });

                final messenger = ScaffoldMessenger.of(context);
                // --- NUEVO: Log diferente para edición ---
                print(
                  _isEditMode
                      ? 'Enviando a CF para ACTUALIZAR usuario: ${widget.initialData!.uid}'
                      : 'Enviando a CF para CREAR usuario: $formData',
                );
                // print('Datos del formulario: $formData'); // Opcional: loguear datos

                try {
                  Map<String, dynamic> result;
                  if (_isEditMode) {
                    // --- LLAMAR AL SERVICIO DE ACTUALIZACIÓN ---
                    // Necesitamos el UID y los datos del formulario
                    // El servicio debería manejar qué se actualiza en Auth y qué en Firestore
                    result = await _usersService.updateUserWithProfile(
                      widget.initialData!.uid,
                      formData, // El formulario ya NO incluye contraseña si está deshabilitada
                    );
                    print('Respuesta de CF (update): $result');
                  } else {
                    // --- LLAMAR AL SERVICIO DE CREACIÓN (como antes) ---
                    result = await _usersService.createUserWithProfile(formData);
                    print('Respuesta de CF (create): $result');
                  }

                  if (!mounted) return;

                  if (result['success'] == true) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          result['message'] ??
                              (_isEditMode
                                  ? 'Usuario actualizado con éxito'
                                  : 'Usuario creado con éxito'),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop(); // Volver
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          _isEditMode
                              ? 'Error al actualizar: ${result['message'] ?? 'Error desconocido'}'
                              : 'Error al crear: ${result['message'] ?? 'Error desconocido'}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } on Exception catch (e) {
                  print(
                    _isEditMode ? 'Error al actualizar usuario: $e' : 'Error al crear usuario: $e',
                  );
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  if (mounted) {
                    setState(() {
                      _isSaving = false;
                    });
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class CreateUserForm extends StatefulWidget {
  // --- NUEVO: Parámetro opcional para datos iniciales ---
  final Usuario? initialData;
  final bool isSubmitting;
  final Function(Map<String, dynamic> formData) onSubmit;

  const CreateUserForm({
    super.key,
    required this.onSubmit,
    this.initialData, // Hacerlo opcional
    this.isSubmitting = false,
  });

  @override
  _CreateUserFormState createState() => _CreateUserFormState();
}

class _CreateUserFormState extends State<CreateUserForm> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEditMode;

  // --- Controladores (igual que antes) ---
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); // Se mantiene, pero se deshabilita
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedProfileType = 'paciente';
  bool _obscurePassword = true;
  final _fechaNacimientoController = TextEditingController();
  DateTime? _selectedFechaNacimiento;
  final _nacionalidadController = TextEditingController();
  final _documentoIdentidadController = TextEditingController();
  final _direccionController = TextEditingController();
  final _grupoSanguineoController = TextEditingController();
  final _factorRHController = TextEditingController();
  final _alergiasController = TextEditingController();
  final _enfermedadesController = TextEditingController();
  final _medicamentosController = TextEditingController();
  final _fumController = TextEditingController();
  DateTime? _selectedFUM;
  final _semanasGestacionController = TextEditingController();
  final _fppController = TextEditingController();
  DateTime? _selectedFPP;
  final _gestacionesController = TextEditingController();
  final _partosVaginalesController = TextEditingController();
  final _cesareasController = TextEditingController();
  final _abortosController = TextEditingController();
  bool? _embarazoMultiple = false;
  final _especialidadesController = TextEditingController();
  final _licenciaMedicaController = TextEditingController();
  final _anosExperienciaController = TextEditingController();

  double _fieldWidth = 300.0;
  final double _fieldSpacing = 16.0;
  Color? _fillColor; // Color de fondo del formulario (opcional)

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.initialData != null;

    // --- NUEVO: Pre-rellenar formulario si estamos en modo edición ---
    if (_isEditMode && widget.initialData != null) {
      final user = widget.initialData!;
      _emailController.text = user.email;
      _displayNameController.text = user.displayName;
      _phoneController.text =
          user.pacienteProfile?.telefono ?? // Primero intenta paciente
          user.doctorProfile?.telefono ?? // Luego doctor
          ''; // Default vacío si no está en ninguno

      // Determinar y seleccionar el tipo de perfil
      if (user.roles.contains(UserRole.paciente)) {
        _selectedProfileType = 'paciente';
        _populatePacienteFields(user.pacienteProfile);
      } else if (user.roles.contains(UserRole.doctor)) {
        _selectedProfileType = 'doctor';
        _populateDoctorFields(user.doctorProfile);
      } else if (user.roles.contains(UserRole.admin)) {
        _selectedProfileType = 'admin';
        // No hay campos específicos de admin en este formulario por ahora
      }
      // El campo contraseña se deja vacío y deshabilitado en modo edición
    }
  }

  // --- NUEVO: Helper para poblar campos de Paciente ---
  void _populatePacienteFields(PacienteProfile? profile) {
    if (profile == null) return;
    _selectedFechaNacimiento = profile.fechaNacimiento;
    _fechaNacimientoController.text =
        _selectedFechaNacimiento != null
            ? DateFormat('yyyy-MM-dd').format(_selectedFechaNacimiento!)
            : '';
    _nacionalidadController.text = profile.nacionalidad ?? '';
    _documentoIdentidadController.text = profile.documentoIdentidad ?? '';
    _direccionController.text = profile.direccion ?? '';
    // Teléfono ya se pobló desde la info general o específica
    _phoneController.text = profile.telefono ?? _phoneController.text; // Prioriza perfil si existe
    _grupoSanguineoController.text = profile.grupoSanguineo ?? '';
    _factorRHController.text = profile.factorRH ?? '';
    _alergiasController.text = profile.alergias?.join(', ') ?? '';
    _enfermedadesController.text = profile.enfermedadesPreexistentes?.join(', ') ?? '';
    _medicamentosController.text = profile.medicamentos?.join(', ') ?? '';
    _selectedFUM = profile.fechaUltimaMenstruacion;
    _fumController.text =
        _selectedFUM != null ? DateFormat('yyyy-MM-dd').format(_selectedFUM!) : '';
    _semanasGestacionController.text = profile.semanasGestacion?.toString() ?? '';
    _selectedFPP = profile.fechaProbableParto;
    _fppController.text =
        _selectedFPP != null ? DateFormat('yyyy-MM-dd').format(_selectedFPP!) : '';
    _gestacionesController.text = profile.numeroGestaciones?.toString() ?? '';
    _partosVaginalesController.text = profile.numeroPartosVaginales?.toString() ?? '';
    _cesareasController.text = profile.numeroCesareas?.toString() ?? '';
    _abortosController.text = profile.abortos?.toString() ?? '';
    _embarazoMultiple = profile.embarazoMultiple;
  }

  // --- NUEVO: Helper para poblar campos de Doctor ---
  void _populateDoctorFields(DoctorProfile? profile) {
    if (profile == null) return;
    // Teléfono ya se pobló desde la info general o específica
    _phoneController.text = profile.telefono ?? _phoneController.text; // Prioriza perfil si existe
    _especialidadesController.text = profile.specialties.join(', ');
    _licenciaMedicaController.text = profile.licenseNumber;
    _anosExperienciaController.text = profile.anosExperiencia?.toString() ?? '';
  }

  @override
  void dispose() {
    // ... (dispose igual que antes) ...
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    _fechaNacimientoController.dispose();
    _nacionalidadController.dispose();
    _documentoIdentidadController.dispose();
    _direccionController.dispose();
    _grupoSanguineoController.dispose();
    _factorRHController.dispose();
    _alergiasController.dispose();
    _enfermedadesController.dispose();
    _medicamentosController.dispose();
    _fumController.dispose();
    _semanasGestacionController.dispose();
    _fppController.dispose();
    _gestacionesController.dispose();
    _partosVaginalesController.dispose();
    _cesareasController.dispose();
    _abortosController.dispose();
    _especialidadesController.dispose();
    _licenciaMedicaController.dispose();
    _anosExperienciaController.dispose();
    super.dispose();
  }

  // --- Helper para seleccionar fecha (sin cambios) ---
  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
    Function(DateTime?) onDateSelected, // Acepta null para deseleccionar
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _parseCurrentDate(controller.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    setState(() {
      if (picked != null) {
        onDateSelected(picked);
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      } else {
        // Opcional: Permitir borrar la fecha
        // onDateSelected(null);
        // controller.clear();
      }
    });
  }

  // Helper para parsear fecha del controlador para initialDate
  DateTime? _parseCurrentDate(String text) {
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(text);
    } catch (e) {
      return null;
    }
  }

  // --- Widget Helper para Campos de Texto (sin cambios) ---
  Widget _buildWrappedTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isRequired = false,
    int? maxLines = 1,
    bool readOnly = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
    bool enabled = true, // NUEVO: para deshabilitar campos
  }) {
    _fillColor =
        !enabled // Solo aplica fillColor si está deshabilitado
            ? (Theme.of(context).brightness == Brightness.light
                // --- Color para Tema CLARO ---
                // Opciones comunes:
                // ? Colors.grey.shade200 // Un gris claro estándar
                // ? Theme.of(context).colorScheme.surfaceVariant // Color M3 para superficies ligeramente diferentes
                ? Colors
                    .grey
                    .shade200 // Manteniendo tu elección original si te gusta
                // --- Color para Tema OSCURO ---
                // Opciones comunes:
                // : Colors.grey.shade800 // Un gris oscuro estándar
                : Theme.of(context).colorScheme.onSurface.withOpacity(
                  0.06,
                ) // Overlay sutil sobre el fondo oscuro (Recomendado M3)
            // : Theme.of(context).colorScheme.surfaceContainerHighest // Variante de superficie M3 más clara en modo oscuro
            )
            : null; // Si está habilitado (enabled == true), no tendrá fillColor (o el default)
    return Padding(
      padding: EdgeInsets.only(bottom: _fieldSpacing),
      child: SizedBox(
        width: _fieldWidth,
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          autovalidateMode: autovalidateMode,
          enabled: enabled, // Aplicar aquí
          decoration: InputDecoration(
            labelText: isRequired ? '$labelText *' : labelText,
            hintText: hintText,
            border: const OutlineInputBorder(),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            // Cambiar apariencia si está deshabilitado
            filled: !enabled,
            fillColor: _fillColor, // Aplicar color de fondo aquí
          ),
        ),
      ),
    );
  }

  // --- Widget Helper para Campos de Fecha (adaptado para aceptar DateTime?) ---
  Widget _buildWrappedDateField({
    required TextEditingController controller,
    required String labelText,
    required Function(DateTime?) onDateSelected,
    String? Function(String?)? validator,
    bool isRequired = false,
    bool enabled = true,
  }) {
    _fillColor =
        !enabled // Solo aplica fillColor si está deshabilitado
            ? (Theme.of(context).brightness == Brightness.light
                // --- Color para Tema CLARO ---
                // Opciones comunes:
                // ? Colors.grey.shade200 // Un gris claro estándar
                // ? Theme.of(context).colorScheme.surfaceVariant // Color M3 para superficies ligeramente diferentes
                ? Colors
                    .grey
                    .shade200 // Manteniendo tu elección original si te gusta
                // --- Color para Tema OSCURO ---
                // Opciones comunes:
                // : Colors.grey.shade800 // Un gris oscuro estándar
                : Theme.of(context).colorScheme.onSurface.withOpacity(
                  0.06,
                ) // Overlay sutil sobre el fondo oscuro (Recomendado M3)
            // : Theme.of(context).colorScheme.surfaceContainerHighest // Variante de superficie M3 más clara en modo oscuro
            )
            : null; // Si está habilitado (enabled == true), no tendrá fillColor (o el default)
    return Padding(
      padding: EdgeInsets.only(bottom: _fieldSpacing),
      child: SizedBox(
        width: _fieldWidth,
        child: TextFormField(
          controller: controller,
          readOnly: true,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: isRequired ? '$labelText *' : labelText,
            hintText: 'YYYY-MM-DD',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              // Deshabilitar botón si el campo está deshabilitado
              onPressed: enabled ? () => _selectDate(context, controller, onDateSelected) : null,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: !enabled,
            fillColor: _fillColor,
          ),
          // No necesitamos onTap aquí porque readOnly=true y usamos el suffixIcon
        ),
      ),
    );
  }

  // --- Widgets de Campos Específicos (_buildPacienteFields, _buildDoctorFields sin cambios estructurales) ---
  // Solo necesitan usar los helpers con `enabled` si es necesario (no parece ser el caso aquí)
  Widget _buildPacienteFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 15),
        Text('Datos Personales', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: _fieldSpacing,
          runSpacing: 0,
          children: [
            _buildWrappedDateField(
              controller: _fechaNacimientoController,
              labelText: 'Fecha Nacimiento',
              isRequired: true,
              onDateSelected: (date) => setState(() => _selectedFechaNacimiento = date),
              validator: (v) => v == null || v.isEmpty ? 'Selecciona fecha' : null,
            ),
            _buildWrappedTextField(
              controller: _nacionalidadController,
              labelText: 'Nacionalidad',
              isRequired: true,
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa nacionalidad' : null,
            ),
            _buildWrappedTextField(
              controller: _documentoIdentidadController,
              labelText: 'Documento Identidad',
              isRequired: true,
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa documento' : null,
            ),
            _buildWrappedTextField(
              controller: _direccionController,
              labelText: 'Dirección',
              isRequired: true,
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa dirección' : null,
              maxLines: 2,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Datos Médicos (Opcional)', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: _fieldSpacing,
          runSpacing: 0,
          children: [
            _buildWrappedTextField(
              controller: _grupoSanguineoController,
              labelText: 'Grupo Sanguíneo',
            ),
            _buildWrappedTextField(controller: _factorRHController, labelText: 'Factor RH'),
            _buildWrappedTextField(
              controller: _alergiasController,
              labelText: 'Alergias (separadas por coma)',
              maxLines: 3,
            ),
            _buildWrappedTextField(
              controller: _enfermedadesController,
              labelText: 'Enfermedades Preexistentes (separadas por coma)',
              maxLines: 3,
            ),
            _buildWrappedTextField(
              controller: _medicamentosController,
              labelText: 'Medicamentos Actuales (separados por coma)',
              maxLines: 3,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Datos Obstétricos (Opcional)', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: _fieldSpacing,
          runSpacing: 0,
          children: [
            _buildWrappedDateField(
              controller: _fumController,
              labelText: 'Fecha Última Menstruación',
              onDateSelected: (date) => setState(() => _selectedFUM = date),
            ),
            _buildWrappedTextField(
              controller: _semanasGestacionController,
              labelText: 'Semanas Gestación',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            _buildWrappedDateField(
              controller: _fppController,
              labelText: 'Fecha Probable Parto',
              onDateSelected: (date) => setState(() => _selectedFPP = date),
            ),
            _buildWrappedTextField(
              controller: _gestacionesController,
              labelText: 'Nº Gestaciones',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            _buildWrappedTextField(
              controller: _partosVaginalesController,
              labelText: 'Nº P. Vaginales',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            _buildWrappedTextField(
              controller: _cesareasController,
              labelText: 'Nº Cesáreas',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            _buildWrappedTextField(
              controller: _abortosController,
              labelText: 'Nº Abortos',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        SizedBox(
          width: _fieldWidth,
          child: CheckboxListTile(
            title: const Text('Embarazo Múltiple'),
            value: _embarazoMultiple ?? false,
            onChanged: (bool? value) {
              setState(() {
                _embarazoMultiple = value;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 15),
        Text('Información Profesional', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: _fieldSpacing,
          runSpacing: 0,
          children: [
            _buildWrappedTextField(
              controller: _especialidadesController,
              labelText: 'Especialidades (separadas por coma)',
              isRequired: true,
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa especialidades' : null,
              maxLines: 3,
            ),
            _buildWrappedTextField(
              controller: _licenciaMedicaController,
              labelText: 'Licencia Médica',
              isRequired: true,
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa licencia' : null,
            ),
            _buildWrappedTextField(
              controller: _anosExperienciaController,
              labelText: 'Años de Experiencia',
              isRequired: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Ingresa años';
                if (int.tryParse(value) == null) return 'Número inválido';
                return null;
              },
            ),
          ],
        ),
      ],
    );
  }

  // --- Función para construir el objeto de datos para onSubmit (Adaptada) ---
  Map<String, dynamic> _buildSubmitData() {
    final phoneInput = _phoneController.text.trim();
    final Map<String, dynamic> commonData = {
      'email': _emailController.text.trim(),
      // --- NO incluir contraseña si estamos editando ---
      if (!_isEditMode) 'password': _passwordController.text,
      'displayName': _displayNameController.text.trim(),
      'phoneNumber': phoneInput.isNotEmpty ? phoneInput : null,
      // --- El tipo de perfil NO debería cambiar en modo edición ---
      // Si permites cambiar roles, necesitarías lógica adicional aquí y en el servicio
      'profileType': _selectedProfileType,
    };

    Map<String, dynamic> profileSpecificData = {};
    if (_selectedProfileType == 'paciente') {
      profileSpecificData = {
        'nombre': _displayNameController.text.trim(),
        // Usar .toIso8601String() sigue siendo válido para guardar fechas
        'fechaNacimiento': _selectedFechaNacimiento?.toIso8601String(),
        'nacionalidad': _nacionalidadController.text.trim(),
        'documentoIdentidad': _documentoIdentidadController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'telefono': phoneInput.isNotEmpty ? phoneInput : null,
        'email': _emailController.text.trim(), // Redundante pero ok si modelo lo espera
        'grupoSanguineo': _emptyOrNull(_grupoSanguineoController.text),
        'factorRH': _emptyOrNull(_factorRHController.text),
        'alergias': _splitTrim(_alergiasController.text),
        'enfermedadesPreexistentes': _splitTrim(_enfermedadesController.text),
        'medicamentos': _splitTrim(_medicamentosController.text),
        'fechaUltimaMenstruacion': _selectedFUM?.toIso8601String(),
        'semanasGestacion': int.tryParse(_semanasGestacionController.text.trim()),
        'fechaProbableParto': _selectedFPP?.toIso8601String(),
        'numeroGestaciones': int.tryParse(_gestacionesController.text.trim()),
        'numeroPartosVaginales': int.tryParse(_partosVaginalesController.text.trim()),
        'numeroCesareas': int.tryParse(_cesareasController.text.trim()),
        // Usa la misma clave para abortos
        'abortos': int.tryParse(_abortosController.text.trim()),
        'embarazoMultiple': _embarazoMultiple,
        // Campos que no se editan aquí se mantienen null o su valor anterior (el servicio maneja)
        'photoUrl': widget.initialData?.photoUrl,
        'coordenadas': widget.initialData?.pacienteProfile?.coordenadas,
      };
    } else if (_selectedProfileType == 'doctor') {
      profileSpecificData = {
        'nombre': _displayNameController.text.trim(),
        'email': _emailController.text.trim(),
        'telefono': phoneInput.isNotEmpty ? phoneInput : null,
        'specialties': _splitTrim(_especialidadesController.text), // Cambiado a 'specialties'
        'licenseNumber': _emptyOrNull(_licenciaMedicaController.text), // Cambiado a 'licenseNumber'
        'anosExperiencia': int.tryParse(_anosExperienciaController.text.trim()),
        'photoUrl': widget.initialData?.photoUrl,
        // 'horarios': widget.initialData?.doctorProfile?.horarios.map((h) => h.toJson()).toList() ?? [], // Mantener horarios existentes
        // 'rating': widget.initialData?.doctorProfile?.rating ?? 0.0, // Mantener rating
        'horarios': [], // Requerido por el modelo, pero no editable aquí
        'rating': 0.0, // Requerido por el modelo
      };
    } else if (_selectedProfileType == 'admin') {
      profileSpecificData = {
        // Campos específicos del admin si los hubiera en el form
        // 'permisos': ...,
      };
    }

    return {...commonData, 'profileData': profileSpecificData};
  }

  // Helper para retornar null si el string está vacío
  String? _emptyOrNull(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  // Helper para dividir por comas y limpiar
  List<String> _splitTrim(String text) {
    return text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  // --- Método build principal del Widget (Adaptado) ---
  @override
  Widget build(BuildContext context) {
    _fieldWidth = getResponsiveFieldWidth(context); // Obtener el ancho responsivo
    _fillColor =
        !_isEditMode // Solo aplica fillColor si está deshabilitado
            ? (Theme.of(context).brightness == Brightness.light
                // --- Color para Tema CLARO ---
                // Opciones comunes:
                // ? Colors.grey.shade200 // Un gris claro estándar
                // ? Theme.of(context).colorScheme.surfaceVariant // Color M3 para superficies ligeramente diferentes
                ? Colors
                    .grey
                    .shade200 // Manteniendo tu elección original si te gusta
                // --- Color para Tema OSCURO ---
                // Opciones comunes:
                // : Colors.grey.shade800 // Un gris oscuro estándar
                : Theme.of(context).colorScheme.onSurface.withOpacity(
                  0.06,
                ) // Overlay sutil sobre el fondo oscuro (Recomendado M3)
            // : Theme.of(context).colorScheme.surfaceContainerHighest // Variante de superficie M3 más clara en modo oscuro
            )
            : null; // Si está habilitado (enabled == true), no tendrá fillColor (o el default)
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Información de Cuenta', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: _fieldSpacing,
              runSpacing: 0,
              alignment: WrapAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: _fieldSpacing),
                  child: SizedBox(
                    width: _fieldWidth,
                    child: DropdownButtonFormField<String>(
                      value: _selectedProfileType,
                      // --- DESHABILITAR Dropdown en modo edición ---
                      onChanged:
                          _isEditMode
                              ? null // No permitir cambio de rol en edición
                              : (value) {
                                if (value != null) {
                                  setState(() => _selectedProfileType = value);
                                }
                              },
                      decoration: InputDecoration(
                        labelText: 'Tipo de Perfil *',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        // Estilo visual cuando está deshabilitado
                        filled: _isEditMode,
                        fillColor: _fillColor,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'paciente', child: Text('Paciente')),
                        DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      validator: (value) => value == null ? 'Selecciona un tipo' : null,
                    ),
                  ),
                ),
                _buildWrappedTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  isRequired: true,
                  keyboardType: TextInputType.emailAddress,
                  // --- DESHABILITAR Email en modo edición ---
                  // Firebase Auth no permite cambiar email fácilmente sin reautenticar
                  enabled: !_isEditMode,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa email';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                // --- CAMPO CONTRASEÑA: Mostrar solo en modo CREACIÓN ---
                if (!_isEditMode)
                  _buildWrappedTextField(
                    controller: _passwordController,
                    labelText: 'Contraseña',
                    isRequired: true, // Solo requerido al crear
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      // Validar solo si no estamos editando
                      if (!_isEditMode) {
                        if (v == null || v.isEmpty) return 'Ingresa contraseña';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  )
                else
                  // Mostrar un texto indicando que la contraseña no se edita aquí
                  Padding(
                    padding: EdgeInsets.only(bottom: _fieldSpacing),
                    child: SizedBox(
                      width: _fieldWidth,
                      child: TextFormField(
                        initialValue: '********', // Placeholder
                        enabled: false, // Deshabilitado
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          hintText: 'No editable aquí',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.light
                                  // --- Color para Tema CLARO ---
                                  // Opciones comunes:
                                  // ? Colors.grey.shade200 // Un gris claro estándar
                                  // ? Theme.of(context).colorScheme.surfaceVariant // Color M3 para superficies ligeramente diferentes
                                  ? Colors
                                      .grey
                                      .shade200 // Manteniendo tu elección original si te gusta
                                  // --- Color para Tema OSCURO ---
                                  // Opciones comunes:
                                  // : Colors.grey.shade800 // Un gris oscuro estándar
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(
                                    0.06,
                                  ), // Overlay sutil sobre el fondo oscuro (Recomendado M3),
                        ),
                      ),
                    ),
                  ),

                _buildWrappedTextField(
                  controller: _displayNameController,
                  labelText: 'Nombre Completo',
                  isRequired: true,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa nombre' : null,
                ),
                _buildWrappedTextField(
                  controller: _phoneController,
                  labelText: 'Teléfono (Opcional)',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            const Divider(height: 30, thickness: 1),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                key: ValueKey<String>(_selectedProfileType),
                child:
                    _selectedProfileType == 'paciente'
                        ? _buildPacienteFields()
                        : _selectedProfileType == 'doctor'
                        ? _buildDoctorFields()
                        : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed:
                    widget.isSubmitting
                        ? null
                        : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            final formData = _buildSubmitData();
                            widget.onSubmit(formData);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Por favor, corrige los errores marcados.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                child:
                    widget.isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                        // --- NUEVO: Texto dinámico del botón ---
                        : Text(_isEditMode ? 'Guardar Cambios' : 'Crear Usuario'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/* // create_user_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../services/users_service.dart';

class CreateUserScreen extends StatefulWidget {
  // Convertir a StatefulWidget para usar el servicio
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final UsersService _usersService = UsersService(); // Instancia del servicio
  bool _isCreating = false; // Estado para mostrar carga en el botón

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nuevo Usuario')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            child: CreateUserForm(
              // CreateUserForm no necesita cambios internos aquí
              onSubmit: (createData) async {
                if (_isCreating) return; // Evitar doble submit

                setState(() {
                  _isCreating = true;
                }); // Mostrar indicador en botón

                final messenger = ScaffoldMessenger.of(context);
                print('Enviando a CF para crear usuario: $createData');

                try {
                  // --- LLAMAR AL SERVICIO ACTUALIZADO ---
                  final result = await _usersService.createUserWithProfile(createData);
                  print('Respuesta de CF (create): $result'); // Loguear respuesta

                  if (!mounted) return;

                  // Asumiendo que la CF devuelve { success: true, message: '...', uid: '...' }
                  if (result['success'] == true) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Usuario creado con éxito'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop(); // Volver a la pantalla anterior
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error al crear: ${result['message'] ?? 'Error desconocido'}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } on Exception catch (e) {
                  // Captura excepciones específicas o genéricas
                  print('Error al crear usuario: $e');
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString().replaceFirst("Exception: ", "")}',
                      ), // Limpiar mensaje
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  if (mounted) {
                    setState(() {
                      _isCreating = false;
                    }); // Ocultar indicador
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class CreateUserForm extends StatefulWidget {
  final Function(Map<String, dynamic> createData) onSubmit;
  // Añadir estado de carga desde el padre
  final bool isSubmitting;

  const CreateUserForm({
    super.key,
    required this.onSubmit,
    this.isSubmitting = false, // Valor por defecto
  });

  @override
  _CreateUserFormState createState() => _CreateUserFormState();
}

class _CreateUserFormState extends State<CreateUserForm> {
  // ... (Todos los controladores, helpers y widgets internos _build...Fields sin cambios) ...
  final _formKey = GlobalKey<FormState>();

  // --- Controladores (igual que antes) ---
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedProfileType = 'paciente';
  bool _obscurePassword = true;
  final _fechaNacimientoController = TextEditingController();
  DateTime? _selectedFechaNacimiento;
  final _nacionalidadController = TextEditingController();
  final _documentoIdentidadController = TextEditingController();
  final _direccionController = TextEditingController();
  final _grupoSanguineoController = TextEditingController();
  final _factorRHController = TextEditingController();
  final _alergiasController = TextEditingController();
  final _enfermedadesController = TextEditingController();
  final _medicamentosController = TextEditingController();
  final _fumController = TextEditingController();
  DateTime? _selectedFUM;
  final _semanasGestacionController = TextEditingController();
  final _fppController = TextEditingController();
  DateTime? _selectedFPP;
  final _gestacionesController = TextEditingController();
  final _partosVaginalesController = TextEditingController();
  final _cesareasController = TextEditingController();
  final _abortosController = TextEditingController();
  bool? _embarazoMultiple = false;
  final _especialidadesController = TextEditingController();
  final _licenciaMedicaController = TextEditingController();
  final _anosExperienciaController = TextEditingController();

  // --- Constante para el ancho de los campos ---
  final double _fieldWidth = 300.0;
  final double _fieldSpacing = 16.0; // Espacio horizontal y vertical entre campos en Wrap

  @override
  void dispose() {
    // ... (dispose igual que antes) ...
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    _fechaNacimientoController.dispose();
    _nacionalidadController.dispose();
    _documentoIdentidadController.dispose();
    _direccionController.dispose();
    _grupoSanguineoController.dispose();
    _factorRHController.dispose();
    _alergiasController.dispose();
    _enfermedadesController.dispose();
    _medicamentosController.dispose();
    _fumController.dispose();
    _semanasGestacionController.dispose();
    _fppController.dispose();
    _gestacionesController.dispose();
    _partosVaginalesController.dispose();
    _cesareasController.dispose();
    _abortosController.dispose();
    _especialidadesController.dispose();
    _licenciaMedicaController.dispose();
    _anosExperienciaController.dispose();
    super.dispose();
  }

  // --- Helper para seleccionar fecha (sin cambios) ---
  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
    Function(DateTime) onDateSelected,
  ) async {
    // ... (igual que antes) ...
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        onDateSelected(picked);
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // --- Widget Helper para Campos de Texto ---
  // Simplifica la creación de campos con ancho fijo y padding para Wrap
  Widget _buildWrappedTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isRequired = false,
    int? maxLines = 1,
    bool readOnly = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: _fieldSpacing), // Añade espacio debajo para el runSpacing
      child: SizedBox(
        width: _fieldWidth,
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          autovalidateMode: autovalidateMode,
          decoration: InputDecoration(
            labelText: isRequired ? '$labelText *' : labelText,
            hintText: hintText,
            border: const OutlineInputBorder(),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ), // Ajusta padding interno
          ),
        ),
      ),
    );
  }

  Widget _buildWrappedDateField({
    required TextEditingController controller,
    required String labelText,
    required Function(DateTime) onDateSelected,
    String? Function(String?)? validator,
    bool isRequired = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: _fieldSpacing),
      child: SizedBox(
        width: _fieldWidth,
        child: TextFormField(
          controller: controller,
          readOnly: true,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            labelText: isRequired ? '$labelText *' : labelText,
            hintText: 'YYYY-MM-DD',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectDate(context, controller, onDateSelected),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    );
  }

  // --- Widgets de Campos Específicos (Adaptados con Wrap y Helper) ---
  Widget _buildPacienteFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Alinea títulos a la izquierda
      children: <Widget>[
        const SizedBox(height: 15),
        Text('Datos Personales', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: _fieldSpacing, // Espacio horizontal
          runSpacing: 0, // Espacio vertical gestionado por el Padding del helper
          children: [
            _buildWrappedDateField(
              controller: _fechaNacimientoController,
              labelText: 'Fecha Nacimiento',
              isRequired: true,
              onDateSelected: (date) => _selectedFechaNacimiento = date,
              validator: (v) => v == null || v.isEmpty ? 'Selecciona fecha' : null,
            ),
            _buildWrappedTextField(
              controller: _nacionalidadController,
              labelText: 'Nacionalidad',
              isRequired: true,
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa nacionalidad' : null,
            ),
            _buildWrappedTextField(
              controller: _documentoIdentidadController,
              labelText: 'Documento Identidad',
              isRequired: true,
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa documento' : null,
            ),
            _buildWrappedTextField(
              controller: _direccionController,
              labelText: 'Dirección',
              isRequired: true,
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa dirección' : null,
              maxLines: 2, // Dirección puede ser más larga
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Datos Médicos (Opcional)', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: _fieldSpacing,
          runSpacing: 0,
          children: [
            _buildWrappedTextField(
              controller: _grupoSanguineoController,
              labelText: 'Grupo Sanguíneo',
            ),
            _buildWrappedTextField(controller: _factorRHController, labelText: 'Factor RH'),
            // Campos de texto más largos, podrían necesitar más espacio o ir fuera del wrap
            _buildWrappedTextField(
              controller: _alergiasController,
              labelText: 'Alergias (separadas por coma)',
              maxLines: 3,
            ),
            _buildWrappedTextField(
              controller: _enfermedadesController,
              labelText: 'Enfermedades Preexistentes (separadas por coma)',
              maxLines: 3,
            ),
            _buildWrappedTextField(
              controller: _medicamentosController,
              labelText: 'Medicamentos Actuales (separados por coma)',
              maxLines: 3,
            ),
          ],
        ),

        const SizedBox(height: 20),
        Text('Datos Obstétricos (Opcional)', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: _fieldSpacing,
          runSpacing: 0,
          children: [
            _buildWrappedDateField(
              controller: _fumController,
              labelText: 'Fecha Última Menstruación',
              onDateSelected: (date) => _selectedFUM = date,
            ),
            _buildWrappedTextField(
              controller: _semanasGestacionController,
              labelText: 'Semanas Gestación',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            _buildWrappedDateField(
              controller: _fppController,
              labelText: 'Fecha Probable Parto',
              onDateSelected: (date) => _selectedFPP = date,
            ),
            _buildWrappedTextField(
              controller: _gestacionesController,
              labelText: 'Nº Gestaciones',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            _buildWrappedTextField(
              controller: _partosVaginalesController,
              labelText: 'Nº P. Vaginales',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            _buildWrappedTextField(
              controller: _cesareasController,
              labelText: 'Nº Cesáreas',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            _buildWrappedTextField(
              controller: _abortosController,
              labelText: 'Nº Abortos',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        // Checkbox fuera del Wrap o con un SizedBox más ancho
        SizedBox(
          width: _fieldWidth, // O double.infinity si quieres que ocupe línea
          child: CheckboxListTile(
            title: const Text('Embarazo Múltiple'),
            value: _embarazoMultiple ?? false,
            onChanged: (bool? value) {
              setState(() {
                _embarazoMultiple = value;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero, // Quitar padding extra
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 15),
        Text('Información Profesional', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: _fieldSpacing,
          runSpacing: 0,
          children: [
            _buildWrappedTextField(
              controller: _especialidadesController,
              labelText: 'Especialidades (separadas por coma)',
              isRequired: true,
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa especialidades' : null,
              maxLines: 3, // Permitir varias líneas
            ),
            _buildWrappedTextField(
              controller: _licenciaMedicaController,
              labelText: 'Licencia Médica',
              isRequired: true,
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa licencia' : null,
            ),
            _buildWrappedTextField(
              controller: _anosExperienciaController,
              labelText: 'Años de Experiencia',
              isRequired: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Ingresa años';
                if (int.tryParse(value) == null) return 'Número inválido';
                return null;
              },
            ),
          ],
        ),
      ],
    );
  }

  // --- Función para construir el objeto de datos para onSubmit (sin cambios) ---
  Map<String, dynamic> _buildSubmitData() {
    // ... (igual que antes) ...
    final phoneInput = _phoneController.text.trim();
    final Map<String, dynamic> commonData = {
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'displayName': _displayNameController.text.trim(),
      'phoneNumber': phoneInput.isNotEmpty ? phoneInput : null,
      'profileType': _selectedProfileType,
    };
    Map<String, dynamic> profileSpecificData = {};
    if (_selectedProfileType == 'paciente') {
      profileSpecificData = {
        'nombre': _displayNameController.text.trim(),
        'fechaNacimiento': _selectedFechaNacimiento?.toIso8601String(),
        'nacionalidad': _nacionalidadController.text.trim(),
        'documentoIdentidad': _documentoIdentidadController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'telefono': phoneInput.isNotEmpty ? phoneInput : null,
        'email': _emailController.text.trim(),
        'grupoSanguineo':
            _grupoSanguineoController.text.trim().isNotEmpty
                ? _grupoSanguineoController.text.trim()
                : null,
        'factorRH':
            _factorRHController.text.trim().isNotEmpty ? _factorRHController.text.trim() : null,
        'alergias':
            _alergiasController.text
                .trim()
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
        'enfermedadesPreexistentes':
            _enfermedadesController.text
                .trim()
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
        'medicamentos':
            _medicamentosController.text
                .trim()
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
        'fechaUltimaMenstruacion': _selectedFUM?.toIso8601String(),
        'semanasGestacion': int.tryParse(_semanasGestacionController.text.trim()),
        'fechaProbableParto': _selectedFPP?.toIso8601String(),
        'numeroGestaciones': int.tryParse(_gestacionesController.text.trim()),
        'numeroPartosVaginales': int.tryParse(_partosVaginalesController.text.trim()),
        'numeroCesareas': int.tryParse(_cesareasController.text.trim()),
        'numeroAbortos': int.tryParse(_abortosController.text.trim()),
        'embarazoMultiple': _embarazoMultiple,
        'photoUrl': null,
        'coordenadas': null,
      };
    } else if (_selectedProfileType == 'doctor') {
      profileSpecificData = {
        'nombre': _displayNameController.text.trim(),
        'email': _emailController.text.trim(),
        'telefono': phoneInput.isNotEmpty ? phoneInput : null,
        'especialidades':
            _especialidadesController.text
                .trim()
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
        'licenciaMedica': _licenciaMedicaController.text.trim(),
        'anosExperiencia': int.tryParse(_anosExperienciaController.text.trim()),
        'photoUrl': null,
        'horario': [],
        'rating': 0.0,
      };
    }
    return {...commonData, 'profileData': profileSpecificData};
  }

  // --- Método build principal del Widget ---
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          // Usar Column para la estructura general
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Sección Tipo y Comunes ---
            Text('Información de Cuenta', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              // Wrap para campos de cuenta
              spacing: _fieldSpacing,
              runSpacing: 0,
              alignment: WrapAlignment.start, // Alinear al inicio
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: _fieldSpacing),
                  child: SizedBox(
                    width: _fieldWidth,
                    child: DropdownButtonFormField<String>(
                      /* ... Dropdown igual ... */
                      value: _selectedProfileType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Perfil *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'paciente', child: Text('Paciente')),
                        DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedProfileType = value;
                          });
                        }
                      },
                      validator: (value) => value == null ? 'Selecciona un tipo' : null,
                    ),
                  ),
                ),
                _buildWrappedTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  isRequired: true,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa email';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                _buildWrappedTextField(
                  controller: _passwordController,
                  labelText: 'Contraseña',
                  isRequired: true,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                _buildWrappedTextField(
                  controller: _displayNameController,
                  labelText: 'Nombre Completo',
                  isRequired: true,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa nombre' : null,
                ),
                _buildWrappedTextField(
                  controller: _phoneController,
                  labelText: 'Teléfono (Opcional)',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),

            const Divider(height: 30, thickness: 1),

            // --- Campos Específicos del Perfil ---
            // El título se mueve dentro de los métodos _build...Fields
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                key: ValueKey<String>(_selectedProfileType),
                child:
                    _selectedProfileType == 'paciente'
                        ? _buildPacienteFields()
                        : _selectedProfileType == 'doctor'
                        ? _buildDoctorFields()
                        : const SizedBox.shrink(),
              ),
            ),

            const SizedBox(height: 25),

            // --- Botón de Envío ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                // Mostrar indicador de carga si widget.isSubmitting es true
                onPressed:
                    widget.isSubmitting
                        ? null
                        : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            final createData = _buildSubmitData();
                            widget.onSubmit(createData);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Por favor, corrige los errores marcados.'),
                              ),
                            );
                          }
                        },
                child:
                    widget.isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                        : const Text('Crear Usuario'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
 */
