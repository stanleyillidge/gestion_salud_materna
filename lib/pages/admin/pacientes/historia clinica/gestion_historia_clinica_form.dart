// pages/admin/pacientes/historia_clinica/gestion_historia_clinica_form.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../models/modelos.dart';
import '../../../../services/firestore_service.dart';
import 'gestion_historia_clinica_view.dart';

class GestionHistoriaClinicaFormScreen extends StatefulWidget {
  final String pacienteId;
  final DatosClinicos? initialData; // Se mantiene para edición

  const GestionHistoriaClinicaFormScreen({required this.pacienteId, this.initialData, super.key});

  @override
  State<GestionHistoriaClinicaFormScreen> createState() => _GestionHistoriaClinicaFormScreenState();
}

class _GestionHistoriaClinicaFormScreenState extends State<GestionHistoriaClinicaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSaving = false;
  late Map<String, TextEditingController> _controllers;
  late Map<String, bool?> _boolValues;

  // *** ACTUALIZAR LISTAS DE CLAVES ***
  // Deben coincidir EXACTAMENTE con las propiedades de la clase DatosClinicos (revisada)
  final List<String> _textFieldKeys = [
    'institucion',
    'procedencia',
    'etnia',
    'escolaridad',
    'viaParto',
    'ocurrenciaGestacion',
    'estadoObstetrico',
    'conscienciaIngreso',
  ];
  final List<String> _numberFieldKeys = [
    'abortos',
    'ectopicos',
    'numControles',
    'semanasOcurrencia',
    'peso',
    'altura',
    'imc',
    'frecuenciaCardiacaIngresoAlta',
    'fRespiratoriaIngresoAlta',
    'pasIngresoAlta',
    'padIngresoBaja',
    'hemoglobinaIngreso',
    'creatininaIngreso',
    'gptIngreso',
    'unidadesTransfundidas',
    'apgar1Minuto',
    'fCardiacaEstanciaMax',
    'fCardiacaEstanciaMin',
    'pasEstanciaMin',
    'padEstanciaMin',
    'sao2EstanciaMax',
    'hemoglobinaEstanciaMin',
    'creatininaEstanciaMax',
    'gotAspartatoAminotransferasaMax',
    'recuentoPlaquetasPltMin',
    'diasEstancia',
  ];
  final List<String> _boolFieldKeys = [
    'indigena',
    'remitidaOtraInst',
    'manejoEspecificoCirugiaAdicional',
    'manejoEspecificoIngresoUado',
    'manejoEspecificoIngresoUci',
    'manejoQxLaparotomia',
    'manejoQxOtra',
    'desgarroPerineal',
    'suturaPerinealPosparto',
    'tratamientosUadoMonitoreoHemodinamico',
    'tratamientosUadoOxigeno',
    'tratamientosUadoTransfusiones',
    'diagPrincipalThe',
    'diagPrincipalHemorragia',
    'waosProcedimientoQuirurgicoNoProgramado',
    'waosRoturaUterinaDuranteElParto',
    'waosLaceracionPerineal3erO4toGrado',
    'desenlaceMaterno2',
    'desenlaceNeonatal',
  ];

  // Combinar todas las claves para la inicialización y construcción
  late List<String> _allKeys;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _boolValues = {};

    // Combinar todas las claves definidas
    _allKeys = [..._textFieldKeys, ..._numberFieldKeys, ..._boolFieldKeys];

    // Ordenar alfabéticamente por etiqueta (opcional, mejora la UI)
    _allKeys.sort(
      (a, b) => (GestionHistoriaClinicaView.fieldLabels[a] ?? a).compareTo(
        GestionHistoriaClinicaView.fieldLabels[b] ?? b,
      ),
    );

    // Usar toMap() del modelo inicial (que ahora devuelve claves correctas)
    final initialMap = widget.initialData?.toMap() ?? {};

    for (var key in _allKeys) {
      if (_boolFieldKeys.contains(key)) {
        _boolValues[key] = _parseBoolSafe(initialMap[key]);
      } else {
        _controllers[key] = TextEditingController(text: _formatInitialValue(initialMap[key]));
      }
    }
  }

  // _parseBoolSafe se mantiene igual
  bool? _parseBoolSafe(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == 'true' || lower == 'si') return true; // Considerar 'Si'
      if (lower == 'false' || lower == 'no') return false; // Considerar 'No'
    }
    if (value is int) return value == 1;
    return null;
  }

  // _formatInitialValue se mantiene igual
  String _formatInitialValue(dynamic value) {
    if (value == null) return '';
    if (value is double) return value.toStringAsFixed(2);
    if (value is Timestamp) {
      return DateFormat('yyyy-MM-dd HH:mm').format(value.toDate()); // Hora incluida?
    }
    if (value is DateTime) return DateFormat('yyyy-MM-dd HH:mm').format(value);
    if (value is int) return value.toString(); // Añadir para enteros
    if (value is bool) return value.toString(); // Añadir para booleanos
    return value.toString();
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      // --- Construcción del objeto DatosClinicos (SIN CAMBIOS) ---
      final dataMap = <String, dynamic>{};
      _controllers.forEach((key, controller) {
        final value = controller.text.trim();
        if (value.isNotEmpty) {
          if (_numberFieldKeys.contains(key)) {
            dataMap[key] = double.tryParse(value.replaceAll(',', '.')) ?? int.tryParse(value);
          } else {
            dataMap[key] = value;
          }
        } else {
          dataMap[key] = null;
        }
      });
      _boolValues.forEach((key, value) {
        dataMap[key] = value;
      });

      final datosParaGuardar = DatosClinicos(
        // --- ID SIEMPRE VACÍO al crear un nuevo registro ---
        id: '', // Firestore generará el ID automáticamente al usar add()
        pacienteId: widget.pacienteId, // El ID del paciente no cambia
        doctorId: fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'DOCTOR_DESCONOCIDO',
        // --- TIMESTAMP se establecerá en el servicio con serverTimestamp ---
        timestamp: Timestamp.now(), // Placeholder, el servicio lo sobrescribirá
        // --- Asignar todos los valores desde dataMap (SIN CAMBIOS) ---
        institucion: dataMap['institucion'],
        procedencia: dataMap['procedencia'],
        etnia: dataMap['etnia'],
        indigena: dataMap['indigena'],
        escolaridad: dataMap['escolaridad'],
        // ... (resto de las propiedades igual que antes) ...
        remitidaOtraInst: dataMap['remitidaOtraInst'],
        abortos: dataMap['abortos']?.toInt(),
        ectopicos: dataMap['ectopicos']?.toInt(),
        numControles: dataMap['numControles']?.toInt(),
        viaParto: dataMap['viaParto'],
        semanasOcurrencia: dataMap['semanasOcurrencia']?.toInt(),
        ocurrenciaGestacion: dataMap['ocurrenciaGestacion'],
        estadoObstetrico: dataMap['estadoObstetrico'],
        peso: dataMap['peso']?.toDouble(),
        altura: dataMap['altura']?.toInt(), // Cambiado a int según revisión
        imc: dataMap['imc']?.toDouble(),
        frecuenciaCardiacaIngresoAlta: dataMap['frecuenciaCardiacaIngresoAlta']?.toInt(),
        fRespiratoriaIngresoAlta: dataMap['fRespiratoriaIngresoAlta']?.toInt(),
        pasIngresoAlta: dataMap['pasIngresoAlta']?.toInt(),
        padIngresoBaja: dataMap['padIngresoBaja']?.toInt(),
        conscienciaIngreso: dataMap['conscienciaIngreso'],
        hemoglobinaIngreso: dataMap['hemoglobinaIngreso']?.toDouble(),
        creatininaIngreso: dataMap['creatininaIngreso']?.toDouble(),
        gptIngreso: dataMap['gptIngreso']?.toDouble(),
        manejoEspecificoCirugiaAdicional: dataMap['manejoEspecificoCirugiaAdicional'],
        manejoEspecificoIngresoUado: dataMap['manejoEspecificoIngresoUado'],
        manejoEspecificoIngresoUci: dataMap['manejoEspecificoIngresoUci'],
        unidadesTransfundidas: dataMap['unidadesTransfundidas']?.toInt(),
        manejoQxLaparotomia: dataMap['manejoQxLaparotomia'],
        manejoQxOtra: dataMap['manejoQxOtra'],
        desgarroPerineal: dataMap['desgarroPerineal'],
        suturaPerinealPosparto: dataMap['suturaPerinealPosparto'],
        tratamientosUadoMonitoreoHemodinamico: dataMap['tratamientosUadoMonitoreoHemodinamico'],
        tratamientosUadoOxigeno: dataMap['tratamientosUadoOxigeno'],
        tratamientosUadoTransfusiones: dataMap['tratamientosUadoTransfusiones'],
        diagPrincipalThe: dataMap['diagPrincipalThe'],
        diagPrincipalHemorragia: dataMap['diagPrincipalHemorragia'],
        waosProcedimientoQuirurgicoNoProgramado: dataMap['waosProcedimientoQuirurgicoNoProgramado'],
        waosRoturaUterinaDuranteElParto: dataMap['waosRoturaUterinaDuranteElParto'],
        waosLaceracionPerineal3erO4toGrado: dataMap['waosLaceracionPerineal3erO4toGrado'],
        apgar1Minuto: dataMap['apgar1Minuto']?.toInt(),
        fCardiacaEstanciaMax: dataMap['fCardiacaEstanciaMax']?.toInt(),
        fCardiacaEstanciaMin: dataMap['fCardiacaEstanciaMin']?.toInt(),
        pasEstanciaMin: dataMap['pasEstanciaMin']?.toInt(),
        padEstanciaMin: dataMap['padEstanciaMin']?.toInt(),
        sao2EstanciaMax: dataMap['sao2EstanciaMax']?.toInt(),
        hemoglobinaEstanciaMin: dataMap['hemoglobinaEstanciaMin']?.toDouble(),
        creatininaEstanciaMax: dataMap['creatininaEstanciaMax']?.toDouble(),
        gotAspartatoAminotransferasaMax: dataMap['gotAspartatoAminotransferasaMax']?.toDouble(),
        recuentoPlaquetasPltMin: dataMap['recuentoPlaquetasPltMin']?.toInt(),
        diasEstancia: dataMap['diasEstancia']?.toInt(),
        desenlaceMaterno2: dataMap['desenlaceMaterno2'],
        desenlaceNeonatal: dataMap['desenlaceNeonatal'],
      );

      // --- LLAMAR SIEMPRE A addClinicalRecord ---
      // Ya no hay distinción entre crear y editar en términos de la acción de guardado
      await _firestoreService.addClinicalRecord(widget.pacienteId, datosParaGuardar);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Mensaje genérico, ya que siempre es una nueva versión
          content: Text(
            widget.initialData == null
                ? 'Nuevo registro clínico añadido.'
                : 'Nueva versión del registro clínico guardada.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(); // Volver a la vista anterior
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildFormField(String key, {double? fieldWidth}) {
    // Añadir fieldWidth opcional
    final String label = GestionHistoriaClinicaView.fieldLabels[key] ?? key;
    // Ya no marcamos requeridos aquí visualmente, la validación se hace al guardar
    // final bool isRequired = false;
    // final String labelText = isRequired ? '$label *' : label;
    final String labelText = label; // Usar label directamente

    final double spacing = 12.0; // Espacio vertical

    // --- Campo Booleano (Dropdown) ---
    if (_boolFieldKeys.contains(key)) {
      return Padding(
        padding: EdgeInsets.only(bottom: spacing), // Espacio vertical
        child: SizedBox(
          // Envolver en SizedBox
          width: fieldWidth, // Aplicar ancho si se proporciona
          child: DropdownButtonFormField<bool?>(
            value: _boolValues[key],
            decoration: InputDecoration(labelText: labelText, border: const OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: null, child: Text('No especificado')),
              DropdownMenuItem(value: true, child: Text('Sí')),
              DropdownMenuItem(value: false, child: Text('No')),
            ],
            onChanged: (newValue) {
              setState(() {
                _boolValues[key] = newValue;
              });
            },
            // validator: (value) => isRequired && value == null ? 'Obligatorio' : null, // Ya no se valida aquí
          ),
        ),
      );
    }
    // --- Campo Numérico ---
    else if (_numberFieldKeys.contains(key)) {
      return Padding(
        padding: EdgeInsets.only(bottom: spacing), // Espacio vertical
        child: SizedBox(
          // Envolver en SizedBox
          width: fieldWidth, // Aplicar ancho si se proporciona
          child: TextFormField(
            controller: _controllers[key],
            decoration: InputDecoration(labelText: labelText, border: const OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*'))],
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final parseValue = value.replaceAll(',', '.');
                if (num.tryParse(parseValue) == null) {
                  return 'Número inválido';
                }
              }
              // if (isRequired && (value == null || value.trim().isEmpty)) return 'Obligatorio'; // Ya no se valida aquí
              return null;
            },
          ),
        ),
      );
    }
    // --- Campo de Texto ---
    else {
      return Padding(
        padding: EdgeInsets.only(bottom: spacing), // Espacio vertical
        child: SizedBox(
          // Envolver en SizedBox
          width: fieldWidth, // Aplicar ancho si se proporciona
          child: TextFormField(
            controller: _controllers[key],
            decoration: InputDecoration(labelText: labelText, border: const OutlineInputBorder()),
            // validator: (value) => isRequired && (value == null || value.trim().isEmpty) ? 'Obligatorio' : null, // Ya no se valida aquí
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (el código del build se mantiene igual, usando LayoutBuilder si lo implementaste)
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialData == null ? 'Nuevo Registro Clínico' : 'Editar Registro Clínico',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveForm,
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            // <--- Usar LayoutBuilder
            builder: (context, constraints) {
              // --- Calcular ancho y decidir layout ---
              const double breakpoint = 720.0;
              final bool useWideLayout = constraints.maxWidth >= breakpoint;
              final double fieldWidth =
                  useWideLayout ? 350.0 : double.infinity; // Ancho para Wrap vs Column
              final double fieldSpacing = 16.0;

              // --- Construir la lista de widgets de formulario ---
              // Asegúrate que _allKeys esté definido correctamente en tu initState
              List<Widget> formFields =
                  _allKeys.map((key) {
                    // Pasar el ancho calculado al helper
                    // NOTA: Si _buildFormField no acepta fieldWidth, necesitas añadirlo
                    return _buildFormField(key, fieldWidth: useWideLayout ? fieldWidth : null);
                  }).toList();

              return Column(
                // Mantener la columna principal para estructura
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Datos Clínicos',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 15),

                  // --- Renderizar Column o Wrap ---
                  if (useWideLayout)
                    Wrap(
                      spacing: fieldSpacing, // Espacio horizontal
                      runSpacing:
                          0, // Espacio vertical gestionado por el Padding en _buildFormField
                      children: formFields,
                    )
                  else
                    Column(
                      // Layout estrecho: Column como antes
                      crossAxisAlignment: CrossAxisAlignment.stretch, // Estirar campos
                      children: formFields,
                    ),

                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: Text(_isSaving ? 'Guardando...' : 'Guardar Registro'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
