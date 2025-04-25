// pages/admin/pacientes/historia_clinica/gestion_historia_clinica_form.dart

// ... (imports)

// *** ELIMINAR relevantFieldsMapping y relevantModelProperties ***
// Ya no son necesarios.

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
      final dataMap = <String, dynamic>{};
      // No necesitamos añadir pacienteId/doctorId aquí si el modelo los tiene
      // y toMap los incluye.

      _controllers.forEach((key, controller) {
        final value = controller.text.trim();
        if (value.isNotEmpty) {
          if (_numberFieldKeys.contains(key)) {
            // Intentar parsear como double primero (más flexible), luego int si falla
            dataMap[key] = double.tryParse(value.replaceAll(',', '.')) ?? int.tryParse(value);
          } else {
            dataMap[key] = value;
          }
        } else {
          dataMap[key] = null; // Guardar null si está vacío
        }
      });
      _boolValues.forEach((key, value) {
        dataMap[key] = value; // Guardar el valor booleano (o null)
      });

      // Crear la instancia del modelo DatosClinicos con los datos recolectados
      final datosParaGuardar = DatosClinicos(
        id: widget.initialData?.id ?? '', // Usar ID existente o vacío
        pacienteId: widget.pacienteId,
        doctorId: fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'DOCTOR_DESCONOCIDO',
        // Usar timestamp existente o uno nuevo si es creación
        timestamp: widget.initialData?.timestamp ?? Timestamp.now(),
        // Asignar todos los valores desde dataMap a las propiedades correspondientes
        institucion: dataMap['institucion'],
        procedencia: dataMap['procedencia'],
        etnia: dataMap['etnia'],
        indigena: dataMap['indigena'],
        escolaridad: dataMap['escolaridad'],
        remitidaOtraInst: dataMap['remitidaOtraInst'],
        abortos: dataMap['abortos']?.toInt(), // Asegurar conversión a int si es num
        ectopicos: dataMap['ectopicos']?.toInt(),
        numControles: dataMap['numControles']?.toInt(),
        viaParto: dataMap['viaParto'],
        semanasOcurrencia: dataMap['semanasOcurrencia']?.toInt(),
        ocurrenciaGestacion: dataMap['ocurrenciaGestacion'],
        estadoObstetrico: dataMap['estadoObstetrico'],
        peso: dataMap['peso']?.toDouble(), // Asegurar conversión a double
        altura: dataMap['altura']?.toInt(), // JSON es int
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

      if (widget.initialData == null) {
        await _firestoreService.addClinicalRecord(widget.pacienteId, datosParaGuardar);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nuevo registro clínico añadido'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // EDITAR: Llama al servicio para actualizar
        // ¡Necesitas implementar updateClinicalRecord en FirestoreService!
        await _firestoreService.updateClinicalRecord(
          widget.pacienteId,
          widget.initialData!.id,
          datosParaGuardar.toMap(),
        );
        print("ACTUALIZACIÓN NO IMPLEMENTADA EN SERVICIO (ejemplo)");
        // Simulación temporal - Actualiza localmente para ver el cambio (si la vista depende del objeto pasado)
        // O mejor aún, confía en que el StreamBuilder de la vista anterior se actualizará al volver.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro clínico actualizado'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      Navigator.of(context).pop(); // Volver a la vista anterior
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // _buildFormField se mantiene igual
  Widget _buildFormField(String key) {
    final String label = GestionHistoriaClinicaView.fieldLabels[key] ?? key;
    final bool isRequired =
        false; // Ya no necesitamos la lista 'relevantKeys' para esto. Validar en _saveForm si es necesario.
    final String labelText = isRequired ? '$label *' : label;

    if (_boolFieldKeys.contains(key)) {
      // --- Campo Booleano (Dropdown) ---
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: DropdownButtonFormField<bool?>(
          value: _boolValues[key],
          decoration: InputDecoration(labelText: labelText, border: const OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: null, child: Text('No especificado')),
            DropdownMenuItem(value: true, child: Text('Sí')), // O '1' si prefieres guardar números
            DropdownMenuItem(value: false, child: Text('No')), // O '0'
          ],
          onChanged: (newValue) {
            setState(() {
              _boolValues[key] = newValue;
            });
          },
          // Ya no se valida aquí como obligatorio
        ),
      );
    } else if (_numberFieldKeys.contains(key)) {
      // --- Campo Numérico ---
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: TextFormField(
          controller: _controllers[key],
          decoration: InputDecoration(labelText: labelText, border: const OutlineInputBorder()),
          // Permitir números y punto/coma decimal
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            // Permite dígitos, punto y coma. Reemplaza coma por punto para el parseo.
            FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
          ],
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              // Intenta parsear reemplazando coma por punto
              final parseValue = value.replaceAll(',', '.');
              if (num.tryParse(parseValue) == null) {
                return 'Ingrese un número válido';
              }
            }
            // Ya no se valida aquí como obligatorio
            return null;
          },
        ),
      );
    } else {
      // --- Campo de Texto ---
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: TextFormField(
          controller: _controllers[key],
          decoration: InputDecoration(labelText: labelText, border: const OutlineInputBorder()),
          // Ya no se valida aquí como obligatorio
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                // Un solo título o agrupar por lógica médica
                'Datos Clínicos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 10),
              // Mostrar TODOS los campos existentes en el modelo
              ..._allKeys.map((key) => _buildFormField(key)), // No se pasa isRequired
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
          ),
        ),
      ),
    );
  }
}

/* // Archivo: gestion_historia_clinica_form.dart
// Ruta: D:\proyectos\salud_materna\lib\pages\admin\pacientes\gestion_historia_clinica_form.dart

import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Alias explícito
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatear fechas en el valor inicial

import '../../../../models/modelos.dart';
import '../../../../services/firestore_service.dart';
import 'gestion_historia_clinica_view.dart'; // Para las etiquetas

// --- INICIO: Mapeo de Campos Relevantes ---
// Este mapa traduce las claves del JSON de carga a los nombres de propiedad
// del modelo DatosClinicos que son considerados relevantes para la IA.
const Map<String, String> relevantFieldsMapping = {
  // Claves del JSON original mapeadas a propiedades del modelo
  "edad_": "edad",
  "num_gestac": "numeroGestaciones",
  "num_aborto": "abortos",
  "num_muerto": "fetosMuertos",
  "endoc_meta": "enfermedadEndocrinaMetabolica",
  "card_cereb": "enfermedadCardiovascularCerebrovascular",
  "renales": "enfermedadRenal",
  "otras_enfe": "otrasEnfermedades",
  "preclampsi": "preeclampsia",
  "hemorragia_obst_severa": "hemorragiaObstetricaSevera",
  "hem_mas_sever_MM": "hemorragiaMasSeveraMM",
  // 'area_': 'procedencia', // Podría ser relevante, pero ya existe 'PROCEDENCIA'
  "tip_ss_": "tipoAfiliacionSS",
  "no_con_pre": "numControles",
  "sem_c_pren": "semanasPrimerControlPrenatal",
  "cod_mun_r": "codigoMunicipioResidencia",
  "cod_pre": "codigoPrestador",
  "estrato_": "estratoSocioeconomico",
  "eclampsia": "eclampsia",
  // 'dias_hospi': 'diasEstancia', // Podría ser relevante, pero ya existe 'DIAS_ESTANCIA'
  "term_gesta": "terminacionGestacion",
  "moc_rel_tg": "morbilidadRelacionadaTG",
  "tip_cas_": "tipoCaso",
  "num_cesare": "numeroCesareas",
  "caus_princ": "causaPrincipalMorbilidad",
  "rupt_uteri": "waosRoturaUterinaDuranteElParto", // Mapeo explícito si clave difiere
  "peso_rnacx": "pesoRecienNacido",

  // --- Añadir aquí Mapeos para Campos Clave del Diccionario Original ---
  // Estos campos son cruciales para la evaluación de riesgo según las condiciones
  // definidas en la función de formato del prompt.
  // Si la clave del JSON y la propiedad del modelo son iguales, se mapea a sí misma.
  'HEMOGLOBINA_INGRESO': 'hemoglobinaIngreso',
  'Recuento_de_plaquetas_-_PLT___min': 'recuentoPlaquetasPltMin',
  'PAS_INGRESO_ALTA': 'pasIngresoAlta',
  'PAD_INGRESO_BAJA': 'padIngresoBaja', // Revisa si esta es la clave correcta en tu JSON
  'CONSCIENCIA_INGRESO': 'conscienciaIngreso',
  'GOT_Aspartato_aminotransferasa_max': 'gotAspartatoAminotransferasaMax',
  'GPT_INGRESO': 'gptIngreso',
  'CREATININA_ESTANCIA_MAX': 'creatininaEstanciaMax', // Usamos el máximo de la estancia
  'FRECUENCIA_CARDIACA_INGRESO_ALTA':
      'frecuenciaCardiacaIngresoAlta', // Podría ser FC_MAX/MIN también
  'F_RESPIRATORIA_INGRESO_ALTA': 'fRespiratoriaIngresoAlta',
  'PAS_ESTANCIA_MIN': 'pasEstanciaMin',
  'PAD_ESTANCIA_MIN': 'padEstanciaMin',
  'F_CARIDIACA_ESTANCIA_MAX': 'fCardiacaEstanciaMax', // ¡Ojo con el typo 'CARIDIACA'!
  'F_CARDIACA_ESTANCIA_MIN': 'fCardiacaEstanciaMin',
  'MANEJO_ESPECÍFICO_Ingreso_a_UCI': 'manejoEspecificoIngresoUci',
  'UNIDADES_TRANSFUNDIDAS': 'unidadesTransfundidas',
  'MANEJO_QX_LAPAROTOMIA': 'manejoQxLaparotomia',
  'DIAG_PRINCIPAL_HEMORRAGIA': 'diagPrincipalHemorragia',
  'DIAG_PRINCIPAL_THE': 'diagPrincipalThe',
  'WAOS_Rotura_uterina_durante_el_parto':
      'waosRoturaUterinaDuranteElParto', // Si la clave es diferente
};

/// Lista de nombres de propiedades del modelo [DatosClinicos] consideradas relevantes para la IA.
/// Se deriva automáticamente de los *valores* del mapa [relevantFieldsMapping].
/// Usar un Set elimina duplicados si varias claves JSON mapean a la misma propiedad.
final List<String> relevantModelProperties = relevantFieldsMapping.values.toSet().toList();
// --- FIN: Mapeo ---

class GestionHistoriaClinicaFormScreen extends StatefulWidget {
  final String pacienteId;
  final DatosClinicos? initialData;

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
  // final Uuid _uuid = const Uuid(); // Ya no se usa para generar ID aquí

  // Define las listas de keys agrupadas por tipo de input (como antes)
  final List<String> _allTextFieldKeys = [
    'institucion', 'procedencia', 'etnia', 'escolaridad', 'viaParto',
    'ocurrenciaGestacion', 'estadoObstetrico', 'conscienciaIngreso',
    // Nuevos campos de texto (si los hay en el mapeo)
    'enfermedadEndocrinaMetabolica', 'enfermedadCardiovascularCerebrovascular',
    'enfermedadRenal', 'otrasEnfermedades', 'preeclampsia',
    'hemorragiaObstetricaSevera', 'hemorragiaMasSeveraMM',
    'tipoAfiliacionSS', 'codigoMunicipioResidencia', 'codigoPrestador',
    'estratoSocioeconomico', 'eclampsia', 'terminacionGestacion',
    'morbilidadRelacionadaTG', 'tipoCaso', 'causaPrincipalMorbilidad',
  ];
  final List<String> _allNumberFieldKeys = [
    'abortos', 'ectopicos', 'numControles', 'semanasOcurrencia',
    'peso', 'altura', 'imc', 'frecuenciaCardiacaIngresoAlta',
    'fRespiratoriaIngresoAlta', 'pasIngresoAlta', 'padIngresoBaja',
    'hemoglobinaIngreso', 'creatininaIngreso', 'gptIngreso',
    'unidadesTransfundidas', 'apgar1Minuto', 'fCardiacaEstanciaMax',
    'fCardiacaEstanciaMin', 'pasEstanciaMin', 'padEstanciaMin',
    'sao2EstanciaMax', 'hemoglobinaEstanciaMin', 'creatininaEstanciaMax',
    'gotAspartatoAminotransferasaMax', 'recuentoPlaquetasPltMin', 'diasEstancia',
    // Nuevos campos numéricos
    'edad', 'numeroGestaciones', 'fetosMuertos', 'semanasPrimerControlPrenatal',
    'numeroCesareas', 'pesoRecienNacido',
  ];
  final List<String> _allBoolFieldKeys = [
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

  late List<String> _relevantKeys;
  late List<String> _otherKeys;

  /* @override
  void initState() {
    super.initState();
    _controllers = {};
    _boolValues = {};

    final allKeys = [..._allTextFieldKeys, ..._allNumberFieldKeys, ..._allBoolFieldKeys];
    final allKeysSet = allKeys.toSet();

    // --- AQUÍ SE USA relevantModelProperties ---
    // Separa las keys en relevantes (obligatorias) y otras (opcionales)
    // Usamos la lista global `relevantModelProperties` definida arriba
    _relevantKeys =
        relevantModelProperties
            .where(
              (key) => allKeysSet.contains(key),
            ) // Asegura que la key exista en los campos definidos
            .toList();
    _otherKeys =
        allKeys
            .where(
              (key) => !relevantModelProperties.contains(key),
            ) // Las que NO están en la lista relevante
            .toList();

    // Ordenar alfabéticamente por etiqueta (opcional)
    _relevantKeys.sort(
      (a, b) => (GestionHistoriaClinicaView.fieldLabels[a] ?? a).compareTo(
        GestionHistoriaClinicaView.fieldLabels[b] ?? b,
      ),
    );
    _otherKeys.sort(
      (a, b) => (GestionHistoriaClinicaView.fieldLabels[a] ?? a).compareTo(
        GestionHistoriaClinicaView.fieldLabels[b] ?? b,
      ),
    );

    // Inicializar controladores y boolValues
    final initialMap = widget.initialData?.toMap() ?? {};
    for (var key in allKeys) {
      if (_allBoolFieldKeys.contains(key)) {
        _boolValues[key] = initialMap[key] as bool?;
      } else {
        _controllers[key] = TextEditingController(text: _formatInitialValue(initialMap[key]));
      }
    }
  } */
  @override
  void initState() {
    super.initState();
    _controllers = {};
    _boolValues = {};

    final allKeys = [..._allTextFieldKeys, ..._allNumberFieldKeys, ..._allBoolFieldKeys];
    final allKeysSet = allKeys.toSet();

    _relevantKeys = relevantModelProperties.where((key) => allKeysSet.contains(key)).toList();
    _otherKeys = allKeys.where((key) => !relevantModelProperties.contains(key)).toList();

    _relevantKeys.sort(
      (a, b) => (GestionHistoriaClinicaView.fieldLabels[a] ?? a).compareTo(
        GestionHistoriaClinicaView.fieldLabels[b] ?? b,
      ),
    );
    _otherKeys.sort(
      (a, b) => (GestionHistoriaClinicaView.fieldLabels[a] ?? a).compareTo(
        GestionHistoriaClinicaView.fieldLabels[b] ?? b,
      ),
    );

    // *** CORREGIDO: Usa toMap() que ahora devuelve claves correctas ***
    final initialMap = widget.initialData?.toMap() ?? {};

    for (var key in allKeys) {
      if (_allBoolFieldKeys.contains(key)) {
        // *** CORREGIDO: Usar parseo seguro para booleanos ***
        _boolValues[key] = _parseBoolSafe(initialMap[key]);
      } else {
        _controllers[key] = TextEditingController(
          // _formatInitialValue ya maneja bien los otros tipos
          text: _formatInitialValue(initialMap[key]),
        );
      }
    }
  }

  // *** NUEVO HELPER: Parseo seguro de booleanos ***
  bool? _parseBoolSafe(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    // Añadir otras posibles representaciones si es necesario (ej. 'true'/'false' strings, 0/1)
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    if (value is int) return value == 1; // Asumir 1 = true, 0 = false
    // Si no se pudo parsear, devuelve null
    return null;
  }

  // --- El resto de _GestionHistoriaClinicaFormScreenState sin cambios ---
  // _formatInitialValue, dispose, _saveForm, _buildFormField, build
  // ... (resto del código de la clase _GestionHistoriaClinicaFormScreenState) ...
  String _formatInitialValue(dynamic value) {
    if (value == null) return '';
    if (value is double) return value.toStringAsFixed(2);
    if (value is Timestamp)
      return DateFormat('yyyy-MM-dd').format(value.toDate()); // Formato para fechas
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
      final dataMap = <String, dynamic>{};
      dataMap['pacienteId'] = widget.pacienteId;
      dataMap['doctorId'] = fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'DOCTOR_DESCONOCIDO';

      _controllers.forEach((key, controller) {
        final value = controller.text.trim();
        if (value.isNotEmpty) {
          if (_allNumberFieldKeys.contains(key)) {
            dataMap[key] = num.tryParse(value);
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
        id: widget.initialData?.id ?? '', // Usa ID existente o vacío si es nuevo
        pacienteId: widget.pacienteId,
        doctorId: dataMap['doctorId'],
        timestamp:
            widget.initialData?.timestamp ?? Timestamp.now(), // Usa ts existente o uno temporal
        institucion: dataMap['institucion'],
        procedencia: dataMap['procedencia'],
        etnia: dataMap['etnia'],
        indigena: dataMap['indigena'],
        escolaridad: dataMap['escolaridad'],
        remitidaOtraInst: dataMap['remitidaOtraInst'],
        abortos: dataMap['abortos']?.toInt(),
        ectopicos: dataMap['ectopicos']?.toInt(),
        numControles: dataMap['numControles']?.toInt(),
        viaParto: dataMap['viaParto'],
        semanasOcurrencia: dataMap['semanasOcurrencia']?.toInt(),
        ocurrenciaGestacion: dataMap['ocurrenciaGestacion'],
        estadoObstetrico: dataMap['estadoObstetrico'],
        peso: dataMap['peso']?.toDouble(),
        altura: dataMap['altura']?.toDouble(),
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
        edad: dataMap['edad']?.toInt(),
        numeroGestaciones: dataMap['numeroGestaciones']?.toInt(),
        fetosMuertos: dataMap['fetosMuertos']?.toInt(),
        enfermedadEndocrinaMetabolica: dataMap['enfermedadEndocrinaMetabolica'],
        enfermedadCardiovascularCerebrovascular: dataMap['enfermedadCardiovascularCerebrovascular'],
        enfermedadRenal: dataMap['enfermedadRenal'],
        otrasEnfermedades: dataMap['otrasEnfermedades'],
        preeclampsia: dataMap['preeclampsia'],
        hemorragiaObstetricaSevera: dataMap['hemorragiaObstetricaSevera'],
        hemorragiaMasSeveraMM: dataMap['hemorragiaMasSeveraMM'],
        tipoAfiliacionSS: dataMap['tipoAfiliacionSS'],
        semanasPrimerControlPrenatal: dataMap['semanasPrimerControlPrenatal']?.toInt(),
        codigoMunicipioResidencia: dataMap['codigoMunicipioResidencia'],
        codigoPrestador: dataMap['codigoPrestador'],
        estratoSocioeconomico: dataMap['estratoSocioeconomico'],
        eclampsia: dataMap['eclampsia'],
        terminacionGestacion: dataMap['terminacionGestacion'],
        morbilidadRelacionadaTG: dataMap['morbilidadRelacionadaTG'],
        tipoCaso: dataMap['tipoCaso'],
        numeroCesareas: dataMap['numeroCesareas']?.toInt(),
        causaPrincipalMorbilidad: dataMap['causaPrincipalMorbilidad'],
        pesoRecienNacido: dataMap['pesoRecienNacido']?.toDouble(),
      );

      if (widget.initialData == null) {
        await _firestoreService.addClinicalRecord(widget.pacienteId, datosParaGuardar);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nuevo registro clínico añadido'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // EDITAR: Llama al servicio para actualizar (si lo implementaste)
        // Asegúrate de que el servicio `updateClinicalRecord` exista y funcione
        // await _firestoreService.updateClinicalRecord(widget.pacienteId, widget.initialData!.id, dataMap);
        print("ACTUALIZACIÓN NO IMPLEMENTADA EN SERVICIO (ejemplo)");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro clínico actualizado (Simulado)'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildFormField(String key, bool isRequired) {
    final String label = GestionHistoriaClinicaView.fieldLabels[key] ?? key;
    final String labelText = isRequired ? '$label *' : label;

    if (_allBoolFieldKeys.contains(key)) {
      // --- Campo Booleano (Dropdown) ---
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
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
          validator: (value) {
            if (isRequired && value == null) {
              return 'Este campo es obligatorio';
            }
            return null;
          },
        ),
      );
    } else if (_allNumberFieldKeys.contains(key)) {
      // --- Campo Numérico ---
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: TextFormField(
          controller: _controllers[key],
          decoration: InputDecoration(labelText: labelText, border: const OutlineInputBorder()),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          validator: (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return 'Este campo es obligatorio';
            }
            if (value != null && value.isNotEmpty && num.tryParse(value) == null) {
              return 'Ingrese un número válido';
            }
            return null;
          },
        ),
      );
    } else {
      // --- Campo de Texto ---
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: TextFormField(
          controller: _controllers[key],
          decoration: InputDecoration(labelText: labelText, border: const OutlineInputBorder()),
          validator: (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return 'Este campo es obligatorio';
            }
            return null;
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Datos Relevantes para IA (Obligatorios)',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 10),
              ..._relevantKeys.map((key) => _buildFormField(key, true)),

              const Divider(height: 30, thickness: 1),

              Text(
                'Otros Datos Clínicos (Opcional)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              ..._otherKeys.map((key) => _buildFormField(key, false)),

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
          ),
        ),
      ),
    );
  }
} */
