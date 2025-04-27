// pages/admin/appointment_form_dialog.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/modelos.dart';
import '../../../services/firestore_service.dart';

class AppointmentFormDialog extends StatefulWidget {
  final FirestoreService firestoreService;
  final Cita? cita;

  const AppointmentFormDialog({required this.firestoreService, this.cita, super.key});

  @override
  State<AppointmentFormDialog> createState() => _AppointmentFormDialogState();
}

class _AppointmentFormDialogState extends State<AppointmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingPacientes = true;
  bool _isLoadingDoctores = true;

  late TextEditingController _titleController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Usuario? _selectedPaciente;
  Usuario? _selectedDoctor;
  String? _selectedEstado;

  // --- NUEVO: Controladores para los Autocomplete ---
  final TextEditingController _pacienteSearchController = TextEditingController();
  final TextEditingController _doctorSearchController = TextEditingController();

  List<Usuario> _pacientes = [];
  List<Usuario> _doctores = [];

  final List<String> _estadosPosibles = ['programada', 'completada', 'cancelada'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.cita?.titulo);
    _selectedDate = widget.cita?.fecha;
    _selectedTime = widget.cita != null ? TimeOfDay.fromDateTime(widget.cita!.fecha) : null;
    _selectedEstado = widget.cita?.estado ?? 'programada';
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingPacientes = true;
      _isLoadingDoctores = true;
    }); // Marcar inicio de carga

    await Future.wait([_loadPacientes(), _loadDoctores()]);

    if (widget.cita != null) {
      // Preseleccionar paciente si estamos editando
      if (widget.cita!.pacienteId != null) {
        try {
          _selectedPaciente = _pacientes.firstWhere((p) => p.uid == widget.cita!.pacienteId);
          // --- NUEVO: Establecer texto inicial del Autocomplete ---
          _pacienteSearchController.text = _selectedPaciente!.displayName;
        } catch (e) {
          print("Advertencia: Paciente ${widget.cita!.pacienteId} no encontrado en lista cargada.");
          // Opcional: mostrar el nombre guardado si no se encuentra el objeto completo
          _pacienteSearchController.text = widget.cita!.nombrePaciente;
        }
      }
      // Preseleccionar doctor si estamos editando
      if (widget.cita!.doctorId != null) {
        try {
          _selectedDoctor = _doctores.firstWhere((d) => d.uid == widget.cita!.doctorId);
          // --- NUEVO: Establecer texto inicial del Autocomplete ---
          _doctorSearchController.text = _selectedDoctor!.displayName;
        } catch (e) {
          print("Advertencia: Doctor ${widget.cita!.doctorId} no encontrado en lista cargada.");
          _doctorSearchController.text =
              widget.cita!.nombreDoctor ?? 'ID: ${widget.cita!.doctorId!}';
        }
      }
    }

    // Indicar que la carga general ha terminado (aunque los flags específicos ya estén false)
    if (mounted) {
      setState(() {}); // Actualizar UI general
    }
  }

  Future<void> _loadPacientes() async {
    // setState(() => _isLoadingPacientes = true); // Ya se hace en _loadInitialData
    try {
      _pacientes = await widget.firestoreService.getAllpacientesStream().first;
    } catch (e) {
      _showError("Error cargando pacientes: $e");
    } finally {
      if (mounted) setState(() => _isLoadingPacientes = false);
    }
  }

  Future<void> _loadDoctores() async {
    // setState(() => _isLoadingDoctores = true); // Ya se hace en _loadInitialData
    try {
      _doctores = await widget.firestoreService.getAllDoctorsStream().first;
    } catch (e) {
      _showError("Error cargando doctores: $e");
    } finally {
      if (mounted) setState(() => _isLoadingDoctores = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    // ... (código sin cambios)
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Rango
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    // ... (código sin cambios)
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveAppointment() async {
    // *** VALIDACIÓN CAMBIADA: Verificar _selectedPaciente y _selectedDoctor ***
    if (!_formKey.currentState!.validate()) {
      // Valida campos de texto como el título
      // Y ahora también valida los Autocomplete (si _selected... es null)
      return;
    }
    // La validación de selección se hace en los propios Autocomplete

    if (_selectedDate == null || _selectedTime == null) {
      _showError('Por favor, selecciona fecha y hora.');
      return;
    }
    // Ya no necesitamos verificar los controladores de búsqueda aquí, sino las variables de estado _selected...
    // if (_selectedPaciente == null) -> Ya cubierto por el validator del Autocomplete
    // if (_selectedDoctor == null) -> Ya cubierto por el validator del Autocomplete

    setState(() => _isLoading = true);

    final fechaHora = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // *** Usar datos de _selectedPaciente y _selectedDoctor ***
    final citaData = Cita(
      id: widget.cita?.id,
      titulo: _titleController.text.trim(),
      pacienteId: _selectedPaciente!.uid,
      nombrePaciente: _selectedPaciente!.displayName,
      doctorId: _selectedDoctor!.uid,
      nombreDoctor: _selectedDoctor!.displayName,
      fecha: fechaHora,
      estado: _selectedEstado,
    );

    try {
      if (widget.cita == null) {
        await widget.firestoreService.createAppointment(citaData);
      } else {
        await widget.firestoreService.updateAppointment(widget.cita!.id!, citaData.toJson());
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      _showError('Error al guardar cita: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    // --- NUEVO: Dispose de los nuevos controladores ---
    _pacienteSearchController.dispose();
    _doctorSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Combina los indicadores de carga individuales
    final bool dataLoading = _isLoadingPacientes || _isLoadingDoctores;
    final String dialogTitle = widget.cita == null ? 'Nueva Cita' : 'Editar Cita';

    return AlertDialog(
      title: Text(dialogTitle),
      content:
          dataLoading
              ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Cargando datos..."),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: ListBody(
                    children: <Widget>[
                      // --- NUEVO: Autocomplete para Paciente ---
                      Autocomplete<Usuario>(
                        // Controlador del campo de texto
                        fieldViewBuilder: (
                          BuildContext context,
                          TextEditingController fieldController,
                          FocusNode fieldFocusNode,
                          VoidCallback onFieldSubmitted,
                        ) {
                          // Asignamos nuestro controlador para poder limpiarlo etc.
                          // Hacemos esto aquí porque el fieldController es interno al Autocomplete
                          // Nota: No asignamos a _pacienteSearchController aquí directamente
                          // porque este builder se reconstruye. Usaremos el stateful controller.
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_pacienteSearchController.text != fieldController.text && mounted) {
                              // Sincronizar si es necesario (ej. al inicio)
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
                            controller: fieldController, // Usar el controlador del builder
                            focusNode: fieldFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Buscar Paciente *',
                              hintText: 'Escribe nombre o email...',
                              border: const OutlineInputBorder(),
                              // Mostrar icono de carga si la lista de pacientes aún no carga
                              prefixIcon:
                                  _isLoadingPacientes
                                      ? const Padding(
                                        padding: EdgeInsets.all(10.0),
                                        child: SizedBox(
                                          height: 15,
                                          width: 15,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                      : const Icon(Icons.person_search),
                              // Limpiar campo si hay texto
                              suffixIcon:
                                  fieldController.text.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: () {
                                          fieldController.clear();
                                          setState(() {
                                            _selectedPaciente = null; // Deseleccionar
                                          });
                                        },
                                      )
                                      : null,
                            ),
                            // Importante: Validar que _selectedPaciente no sea null
                            validator: (value) {
                              // Si hay texto pero no hay selección, es inválido
                              if (value != null && value.isNotEmpty && _selectedPaciente == null) {
                                return 'Selecciona un paciente válido de la lista';
                              }
                              // Si no hay texto Y no hay selección (campo vacío inicial)
                              if ((value == null || value.isEmpty) && _selectedPaciente == null) {
                                return 'Debes seleccionar un paciente';
                              }
                              return null; // Válido si hay selección o está vacío (y no requerido?)
                            },
                            // No permitir envío directo desde el campo
                            // onFieldSubmitted: (_) => onFieldSubmitted(),
                          );
                        },
                        // Función que genera las opciones basadas en el texto
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (_isLoadingPacientes)
                            return const Iterable.empty(); // No mostrar nada mientras carga
                          final query = textEditingValue.text.toLowerCase();
                          if (query.isEmpty) {
                            // No mostrar opciones si no hay texto
                            return const Iterable<Usuario>.empty();
                          }
                          // Filtrar la lista de pacientes
                          return _pacientes.where((Usuario paciente) {
                            return paciente.displayName.toLowerCase().contains(query) ||
                                paciente.email.toLowerCase().contains(query);
                          });
                        },
                        // Cómo mostrar cada opción en la lista desplegable
                        optionsViewBuilder: (
                          BuildContext context,
                          AutocompleteOnSelected<Usuario> onSelected,
                          Iterable<Usuario> options,
                        ) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 200), // Limitar altura
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final Usuario option = options.elementAt(index);
                                    return InkWell(
                                      onTap: () {
                                        onSelected(option);
                                      },
                                      child: ListTile(
                                        title: Text(option.displayName),
                                        subtitle: Text(option.email),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        // Qué hacer cuando se selecciona una opción
                        onSelected: (Usuario selection) {
                          setState(() {
                            _selectedPaciente = selection;
                            // Actualizamos el texto del controlador que SÍ vemos
                            _pacienteSearchController.text = selection.displayName;
                            // Forzamos la validación de nuevo por si acaso
                            _formKey.currentState?.validate();
                          });
                          // Quitar foco para cerrar el teclado/overlay
                          FocusScope.of(context).unfocus();
                        },
                        // Cómo mostrar la opción seleccionada en el TextField
                        // (usamos el controlador manualmente en onSelected)
                        displayStringForOption: (Usuario option) => option.displayName,
                        // Valor inicial si estamos editando
                        initialValue:
                            _selectedPaciente != null
                                ? TextEditingValue(text: _selectedPaciente!.displayName)
                                : null,
                      ),
                      const SizedBox(height: 12),

                      // --- NUEVO: Autocomplete para Doctor ---
                      Autocomplete<Usuario>(
                        fieldViewBuilder: (
                          BuildContext context,
                          TextEditingController fieldController,
                          FocusNode fieldFocusNode,
                          VoidCallback onFieldSubmitted,
                        ) {
                          // Sincronizar controlador interno con el nuestro
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_doctorSearchController.text != fieldController.text && mounted) {
                              if (_doctorSearchController.text.isEmpty &&
                                  fieldController.text.isNotEmpty &&
                                  widget.cita?.doctorId != null) {
                                _doctorSearchController.text = fieldController.text;
                              } else if (fieldController.text.isEmpty &&
                                  _doctorSearchController.text.isNotEmpty) {
                                fieldController.text = _doctorSearchController.text;
                              }
                            }
                          });

                          return TextFormField(
                            controller: fieldController,
                            focusNode: fieldFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Buscar Doctor *',
                              hintText: 'Escribe nombre o email...',
                              border: const OutlineInputBorder(),
                              prefixIcon:
                                  _isLoadingDoctores
                                      ? const Padding(
                                        padding: EdgeInsets.all(10.0),
                                        child: SizedBox(
                                          height: 15,
                                          width: 15,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                      : const Icon(Icons.medical_services_outlined),
                              suffixIcon:
                                  fieldController.text.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: () {
                                          fieldController.clear();
                                          setState(() {
                                            _selectedDoctor = null; // Deseleccionar
                                          });
                                        },
                                      )
                                      : null,
                            ),
                            validator: (value) {
                              if (value != null && value.isNotEmpty && _selectedDoctor == null) {
                                return 'Selecciona un doctor válido de la lista';
                              }
                              if ((value == null || value.isEmpty) && _selectedDoctor == null) {
                                return 'Debes seleccionar un doctor';
                              }
                              return null;
                            },
                          );
                        },
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (_isLoadingDoctores) return const Iterable.empty();
                          final query = textEditingValue.text.toLowerCase();
                          if (query.isEmpty) {
                            return const Iterable<Usuario>.empty();
                          }
                          return _doctores.where((Usuario doctor) {
                            return doctor.displayName.toLowerCase().contains(query) ||
                                doctor.email.toLowerCase().contains(query);
                          });
                        },
                        optionsViewBuilder: (
                          BuildContext context,
                          AutocompleteOnSelected<Usuario> onSelected,
                          Iterable<Usuario> options,
                        ) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 200), // Limitar altura
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final Usuario option = options.elementAt(index);
                                    return InkWell(
                                      onTap: () {
                                        onSelected(option);
                                      },
                                      child: ListTile(
                                        title: Text(option.displayName),
                                        subtitle: Text(
                                          option.doctorProfile?.specialties.join(', ') ??
                                              option.email,
                                        ), // Mostrar especialidad o email
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        onSelected: (Usuario selection) {
                          setState(() {
                            _selectedDoctor = selection;
                            _doctorSearchController.text = selection.displayName;
                            _formKey.currentState?.validate(); // Revalidar
                          });
                          FocusScope.of(context).unfocus();
                        },
                        displayStringForOption: (Usuario option) => option.displayName,
                        initialValue:
                            _selectedDoctor != null
                                ? TextEditingValue(text: _selectedDoctor!.displayName)
                                : null,
                      ),
                      const SizedBox(height: 12),

                      // --- Campos restantes (Título, Fecha, Hora, Estado) sin cambios ---
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Título/Motivo'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa un título o motivo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _selectedDate == null
                              ? 'Selecciona Fecha *'
                              : 'Fecha: ${DateFormat('EE dd MMM yyyy', 'es_ES').format(_selectedDate!)}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectDate(context),
                        // Añadir validación implícita (aunque ya se verifica en _saveAppointment)
                        subtitle:
                            (_selectedDate == null &&
                                    _formKey.currentState?.validate() == false &&
                                    _formKey.currentState?.widget != null)
                                ? Text(
                                  'Campo requerido',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 12,
                                  ),
                                )
                                : null,
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
                        subtitle:
                            (_selectedTime == null &&
                                    _formKey.currentState?.validate() == false &&
                                    _formKey.currentState?.widget != null)
                                ? Text(
                                  'Campo requerido',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 12,
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedEstado,
                        decoration: const InputDecoration(labelText: 'Estado Cita'),
                        items:
                            _estadosPosibles.map((String estado) {
                              return DropdownMenuItem<String>(
                                value: estado,
                                child: Text(estado[0].toUpperCase() + estado.substring(1)),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedEstado = newValue;
                          });
                        },
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
