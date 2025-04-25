// create_user_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/users_service.dart';

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
        'fotoPerfilURL': null,
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
        'fotoPerfilURL': null,
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

/* import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// create_user_screen.dart
// import 'services/firebase_service.dart';

class CreateUserScreen extends StatelessWidget {
  const CreateUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nuevo Usuario')),
      body: Center(
        // Centra el contenido en pantallas anchas
        child: ConstrainedBox(
          // Limita el ancho máximo del formulario
          constraints: const BoxConstraints(maxWidth: 900), // Ajusta este valor según necesites
          child: SingleChildScrollView(
            // Permite scroll si el contenido es largo o el teclado aparece
            child: CreateUserForm(
              onSubmit: (createData) async {
                // --- AQUÍ MANEJAS LA LÓGICA DE SUBMIT ---
                print('Datos recibidos del formulario: $createData');
                // Mostrar un indicador de carga
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Creando usuario...'), duration: Duration(seconds: 2)),
                );

                // Llamar a la Cloud Function (ejemplo con manejo básico de errores)
                try {
                  // Reemplaza con tu lógica real para llamar a la CF
                  // final success = await FirebaseService.instance.createUserWithProfile(createData);
                  bool success = await Future.delayed(
                    Duration(seconds: 2),
                    () => true,
                  ); // Simular llamada

                  if (success && context.mounted) {
                    // Verificar que el widget aún esté montado
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Usuario creado con éxito'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Navegar hacia atrás o a otra pantalla
                    Navigator.of(context).pop();
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al crear usuario (respuesta negativa)'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  print('Error al llamar a Cloud Function: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            /* CreateUserForm(
              onSubmit: (createData) async {
                // --- LÓGICA DE ENVÍO Y RESPUESTA (Igual que antes) ---
                print('Datos recibidos del formulario: $createData');
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Creando usuario...'),
                    duration: Duration(seconds: 3),
                  ),
                );
                try {
                  print("Simulando llamada a Cloud Function...");
                  await Future.delayed(const Duration(seconds: 2));
                  bool success = true;

                  if (!context.mounted) return;

                  if (success) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Usuario creado con éxito'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop();
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Error: No se pudo crear el usuario.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  print('Error al crear usuario vía Cloud Function: $e');
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error al crear: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ), */
          ),
        ),
      ),
    );
  }
}

class CreateUserForm extends StatefulWidget {
  final Function(Map<String, dynamic> createData) onSubmit;

  const CreateUserForm({super.key, required this.onSubmit});

  @override
  _CreateUserFormState createState() => _CreateUserFormState();
}

class _CreateUserFormState extends State<CreateUserForm> {
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
        'fotoPerfilURL': null,
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
        'fotoPerfilURL': null,
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
          // Cambiado a Column para controlar mejor las secciones
          crossAxisAlignment: CrossAxisAlignment.start, // Alinea títulos a la izquierda
          children: <Widget>[
            // --- Sección Tipo y Comunes ---
            Wrap(
              // Usar Wrap también para los campos comunes
              spacing: _fieldSpacing,
              runSpacing: 0,
              children: [
                // Dropdown con ancho fijo también
                Padding(
                  padding: EdgeInsets.only(bottom: _fieldSpacing),
                  child: SizedBox(
                    width: _fieldWidth,
                    child: DropdownButtonFormField<String>(
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
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim()))
                      return 'Email inválido';
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
            // Usamos AnimatedSwitcher para una transición suave al cambiar de perfil
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                // KeyedSubtree ayuda al AnimatedSwitcher a diferenciar los widgets
                key: ValueKey<String>(_selectedProfileType), // La clave cambia con el perfil
                child:
                    _selectedProfileType == 'paciente'
                        ? _buildPacienteFields()
                        : _selectedProfileType == 'doctor'
                        ? _buildDoctorFields()
                        : const SizedBox.shrink(), // No mostrar nada extra para admin
              ),
            ),

            const SizedBox(height: 25),

            // --- Botón de Envío ---
            // Centrar el botón o darle ancho completo
            SizedBox(
              width: double.infinity, // Ocupar todo el ancho disponible
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  // backgroundColor: Theme.of(context).primaryColor, // Usar backgroundColor
                  // foregroundColor: Colors.white, // Usar foregroundColor
                ),
                child: const Text('Crear Usuario'),
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final createData = _buildSubmitData();
                    widget.onSubmit(createData);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor, corrige los errores marcados.')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
} */
