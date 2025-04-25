// pages/admin/pacientes/historia_clinica/gestion_historia_clinica_view.dart
// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/modelos.dart';
import '../../../../services/firestore_service.dart';
import 'gestion_historia_clinica_form.dart'; // Para navegar al form

class GestionHistoriaClinicaView extends StatefulWidget {
  final String pacienteId;
  const GestionHistoriaClinicaView({required this.pacienteId, super.key});

  // Mapa de etiquetas (se mantiene igual que la versión corregida)
  static const Map<String, String> fieldLabels = {
    'institucion': 'Institución',
    'procedencia': 'Procedencia',
    'etnia': 'Etnia',
    'indigena': 'Indígena',
    'escolaridad': 'Escolaridad',
    'remitidaOtraInst': 'Remitida Otra Inst.',
    'abortos': 'Abortos',
    'ectopicos': 'Ectópicos',
    'numControles': 'No. Controles',
    'viaParto': 'Vía Parto',
    'semanasOcurrencia': 'Semanas Ocurrencia',
    'ocurrenciaGestacion': 'Ocurrencia Gestación',
    'estadoObstetrico': 'Estado Obstétrico',
    'peso': 'Peso (Kg)',
    'altura': 'Altura (cm)',
    'imc': 'IMC',
    'frecuenciaCardiacaIngresoAlta': 'FC Ingreso Alta',
    'fRespiratoriaIngresoAlta': 'FR Ingreso Alta',
    'pasIngresoAlta': 'PAS Ingreso Alta',
    'padIngresoBaja': 'PAD Ingreso Baja',
    'conscienciaIngreso': 'Consciencia Ingreso',
    'hemoglobinaIngreso': 'Hb Ingreso (g/dL)',
    'creatininaIngreso': 'Creatinina Ingreso (mg/dL)',
    'gptIngreso': 'GPT Ingreso (U/L)',
    'manejoEspecificoCirugiaAdicional': 'Manejo: Cirugía Adicional',
    'manejoEspecificoIngresoUado': 'Manejo: Ingreso UADO',
    'manejoEspecificoIngresoUci': 'Manejo: Ingreso UCI',
    'unidadesTransfundidas': 'Unidades Transfundidas',
    'manejoQxLaparotomia': 'Qx: Laparotomía',
    'manejoQxOtra': 'Qx: Otra',
    'desgarroPerineal': 'Desgarro Perineal',
    'suturaPerinealPosparto': 'Sutura Perineal Postparto',
    'tratamientosUadoMonitoreoHemodinamico': 'Tto UADO: Monit. Hemodinámico',
    'tratamientosUadoOxigeno': 'Tto UADO: Oxígeno',
    'tratamientosUadoTransfusiones': 'Tto UADO: Transfusiones',
    'diagPrincipalThe': 'Diag: THE',
    'diagPrincipalHemorragia': 'Diag: Hemorragia',
    'waosProcedimientoQuirurgicoNoProgramado': 'WAOS: Proc. Qx No Programado',
    'waosRoturaUterinaDuranteElParto': 'WAOS: Rotura Uterina',
    'waosLaceracionPerineal3erO4toGrado': 'WAOS: Laceración G3/4',
    'apgar1Minuto': 'APGAR 1 Minuto',
    'fCardiacaEstanciaMax': 'FC Estancia MAX',
    'fCardiacaEstanciaMin': 'FC Estancia MIN',
    'pasEstanciaMin': 'PAS Estancia MIN',
    'padEstanciaMin': 'PAD Estancia MIN',
    'sao2EstanciaMax': 'SaO2 Estancia MAX (%)',
    'hemoglobinaEstanciaMin': 'Hb Estancia MIN (g/dL)',
    'creatininaEstanciaMax': 'Creatinina Est. MAX (mg/dL)',
    'gotAspartatoAminotransferasaMax': 'GOT Est. MAX (U/L)',
    'recuentoPlaquetasPltMin': 'Plaquetas Est. MIN (k/µL)',
    'diasEstancia': 'Días Estancia',
    'desenlaceMaterno2': 'Desenlace Materno Adverso',
    'desenlaceNeonatal': 'Desenlace Neonatal Adverso',
    'timestamp': 'Fecha Registro',
  };

  @override
  State<GestionHistoriaClinicaView> createState() => _GestionHistoriaClinicaViewState();
}

class _GestionHistoriaClinicaViewState extends State<GestionHistoriaClinicaView> {
  final FirestoreService _firestoreService = FirestoreService();
  // Ajusta el formato si prefieres hh:mm a para AM/PM
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy, hh:mm a', 'es_ES');

  void _navigateToAddForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GestionHistoriaClinicaFormScreen(pacienteId: widget.pacienteId),
      ),
    );
  }

  Future<void> _confirmDelete(DatosClinicos dataToDelete) async {
    // ... (código de confirmación sin cambios) ...
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de eliminar este registro clínico del ${_dateFormatter.format(dataToDelete.timestamp.toDate())}? Esta acción no se puede deshacer.',
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
        await _firestoreService.deleteClinicalRecord(widget.pacienteId, dataToDelete.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro eliminado'), backgroundColor: Colors.orange),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToEditForm(DatosClinicos recordToEdit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => GestionHistoriaClinicaFormScreen(
              pacienteId: widget.pacienteId,
              initialData: recordToEdit,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("Building GestionHistoriaClinicaView for pacienteId: ${widget.pacienteId}"); // Log
    return StreamBuilder<List<DatosClinicos>>(
      stream: _firestoreService.getClinicalRecordsStream(widget.pacienteId),
      builder: (context, snapshot) {
        print("StreamBuilder state: ${snapshot.connectionState}"); // Log estado

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print("StreamBuilder error: ${snapshot.error}"); // Log error
          return Center(child: Text('Error al cargar historial: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print("StreamBuilder: No data or empty list."); // Log no data
          // --- Botón para añadir el primer registro ---
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No hay registros de historia clínica.', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir Primer Registro'),
                    onPressed: _navigateToAddForm, // Navega al formulario de creación
                  ),
                ],
              ),
            ),
          );
        }

        // --- Procesamiento y visualización de datos ---
        final clinicalRecords = snapshot.data!;
        print("StreamBuilder received ${clinicalRecords.length} records."); // Log data count

        // Asumiendo que el stream ya viene ordenado por timestamp desc
        final latestRecord = clinicalRecords.first;
        final previousRecords = clinicalRecords.skip(1).toList();
        print("Latest record ID: ${latestRecord.toMap()}"); // Log latest record ID

        return ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            // --- Último Registro (Editable) ---
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16.0),
              child: ExpansionTile(
                key: PageStorageKey('latest_${latestRecord.id}'),
                initiallyExpanded: true,
                leading: const Icon(Icons.article, color: Colors.blueAccent),
                title: Text(
                  // Muestra la fecha formateada del último registro
                  'Último Registro (${_dateFormatter.format(latestRecord.timestamp.toDate())})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.blue),
                      tooltip: 'Editar Último Registro',
                      onPressed: () => _navigateToEditForm(latestRecord),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: 'Eliminar Último Registro',
                      onPressed: () => _confirmDelete(latestRecord),
                    ),
                  ],
                ),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: _buildRecordDetails(latestRecord),
              ),
            ),

            // --- Historial Anterior (Solo Lectura) ---
            if (previousRecords.isNotEmpty)
              ExpansionTile(
                key: const PageStorageKey('history'),
                leading: const Icon(Icons.history, color: Colors.grey),
                title: const Text('Historial Anterior'),
                children:
                    previousRecords.map((record) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: ListTile(
                          dense: true,
                          title: Text(
                            'Registro del ${_dateFormatter.format(record.timestamp.toDate())}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'ID: ${record.id.length > 8 ? record.id.substring(0, 8) : record.id}...',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                            tooltip: 'Ver Detalles',
                            onPressed: () => _showReadOnlyDetailsDialog(context, record),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            // Espacio al final para que el FAB no tape el último elemento si aplica
            const SizedBox(height: 70),
          ],
        );
      },
    );
  }

  // _buildRecordDetails (sin cambios respecto a la versión anterior corregida)
  List<Widget> _buildRecordDetails(DatosClinicos record) {
    final map = record.toMap(); // Usa el toMap corregido
    final fieldsToShow = map.entries.where(
      (e) =>
          e.key != 'id' &&
          e.key != 'pacienteId' &&
          e.key != 'doctorId' &&
          e.key != 'timestamp' &&
          e.value != null,
    );
    // Ordenar alfabéticamente por etiqueta para consistencia
    final sortedFields =
        fieldsToShow.toList()..sort((a, b) {
          final labelA =
              GestionHistoriaClinicaView.fieldLabels[a.key] ??
              a.key
                  .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
                  .capitalizeFirst();
          final labelB =
              GestionHistoriaClinicaView.fieldLabels[b.key] ??
              b.key
                  .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
                  .capitalizeFirst();
          return labelA.compareTo(labelB);
        });

    return sortedFields.map((entry) {
      final label =
          GestionHistoriaClinicaView.fieldLabels[entry.key] ??
          entry.key
              .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
              .capitalizeFirst();
      return _buildInfoRow(label, entry.value);
    }).toList();
  }

  // _showReadOnlyDetailsDialog (sin cambios)
  void _showReadOnlyDetailsDialog(BuildContext context, DatosClinicos record) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Detalle Registro (${_dateFormatter.format(record.timestamp.toDate())})'),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.7,
              child: ListView(shrinkWrap: true, children: _buildRecordDetails(record)),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cerrar')),
            ],
          ),
    );
  }

  // _buildInfoRow (sin cambios)
  Widget _buildInfoRow(String label, dynamic value) {
    String displayValue;
    if (value == null) {
      displayValue = 'No especificado';
    } else if (value is bool) {
      displayValue = value ? 'Sí' : 'No';
    } else if (value is Timestamp) {
      displayValue = _dateFormatter.format(value.toDate());
    } else if (value is DateTime) {
      displayValue = _dateFormatter.format(value);
    } else if (value is double) {
      if (label.toLowerCase().contains('plaquetas')) {
        displayValue = '${value.toStringAsFixed(0)} k/µL';
      } else {
        displayValue = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
      }
    } else if (value is int) {
      if (label.toLowerCase().contains('plaquetas')) {
        displayValue = '${value.toString()} k/µL';
      } else {
        displayValue = value.toString();
      }
    } else if (value is List && value.isEmpty) {
      displayValue = 'Ninguno/a';
    } else if (value is List) {
      displayValue = value.join(', ');
    } else {
      displayValue = value.toString();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(displayValue)),
        ],
      ),
    );
  }
}

// Helper capitalizeFirst (se mantiene igual)
extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}"; // No convertir el resto a minúsculas
  }
}

/* // pages/admin/pacientes/historia_clinica/gestion_historia_clinica_view.dart
// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/modelos.dart';
import '../../../../services/firestore_service.dart';
import 'gestion_historia_clinica_form.dart';

class GestionHistoriaClinicaView extends StatefulWidget {
  final String pacienteId;
  const GestionHistoriaClinicaView({required this.pacienteId, super.key});

  // *** ACTUALIZAR ETIQUETAS ***
  // Deben coincidir con las propiedades del NUEVO modelo DatosClinicos
  static const Map<String, String> fieldLabels = {
    'institucion': 'Institución', 'procedencia': 'Procedencia', 'etnia': 'Etnia',
    'indigena': 'Indígena', 'escolaridad': 'Escolaridad', 'remitidaOtraInst': 'Remitida Otra Inst.',
    'abortos': 'Abortos', 'ectopicos': 'Ectópicos', 'numControles': 'No. Controles',
    'viaParto': 'Vía Parto', 'semanasOcurrencia': 'Semanas Ocurrencia',
    'ocurrenciaGestacion': 'Ocurrencia Gestación', 'estadoObstetrico': 'Estado Obstétrico',
    'peso': 'Peso (Kg)', 'altura': 'Altura (cm)', 'imc': 'IMC',
    'frecuenciaCardiacaIngresoAlta': 'FC Ingreso Alta',
    'fRespiratoriaIngresoAlta': 'FR Ingreso Alta',
    'pasIngresoAlta': 'PAS Ingreso Alta', 'padIngresoBaja': 'PAD Ingreso Baja',
    'conscienciaIngreso': 'Consciencia Ingreso', 'hemoglobinaIngreso': 'Hb Ingreso (g/dL)',
    'creatininaIngreso': 'Creatinina Ingreso (mg/dL)', 'gptIngreso': 'GPT Ingreso (U/L)',
    'manejoEspecificoCirugiaAdicional': 'Manejo: Cirugía Adicional',
    'manejoEspecificoIngresoUado': 'Manejo: Ingreso UADO',
    'manejoEspecificoIngresoUci': 'Manejo: Ingreso UCI',
    'unidadesTransfundidas': 'Unidades Transfundidas', 'manejoQxLaparotomia': 'Qx: Laparotomía',
    'manejoQxOtra': 'Qx: Otra', 'desgarroPerineal': 'Desgarro Perineal',
    'suturaPerinealPosparto': 'Sutura Perineal Postparto',
    'tratamientosUadoMonitoreoHemodinamico': 'Tto UADO: Monit. Hemodinámico',
    'tratamientosUadoOxigeno': 'Tto UADO: Oxígeno',
    'tratamientosUadoTransfusiones': 'Tto UADO: Transfusiones',
    'diagPrincipalThe': 'Diag: THE', 'diagPrincipalHemorragia': 'Diag: Hemorragia',
    'waosProcedimientoQuirurgicoNoProgramado': 'WAOS: Proc. Qx No Programado',
    'waosRoturaUterinaDuranteElParto': 'WAOS: Rotura Uterina',
    'waosLaceracionPerineal3erO4toGrado': 'WAOS: Laceración G3/4',
    'apgar1Minuto': 'APGAR 1 Minuto',
    'fCardiacaEstanciaMax': 'FC Estancia MAX', // Corregido
    'fCardiacaEstanciaMin': 'FC Estancia MIN', // Corregido
    'pasEstanciaMin': 'PAS Estancia MIN', 'padEstanciaMin': 'PAD Estancia MIN',
    'sao2EstanciaMax': 'SaO2 Estancia MAX (%)',
    'hemoglobinaEstanciaMin': 'Hb Estancia MIN (g/dL)',
    'creatininaEstanciaMax': 'Creatinina Est. MAX (mg/dL)',
    'gotAspartatoAminotransferasaMax': 'GOT Est. MAX (U/L)',
    'recuentoPlaquetasPltMin': 'Plaquetas Est. MIN (k/µL)', // k para miles
    'diasEstancia': 'Días Estancia',
    'desenlaceMaterno2': 'Desenlace Materno Adverso',
    'desenlaceNeonatal': 'Desenlace Neonatal Adverso',
    'timestamp': 'Fecha Registro', // Mantenemos timestamp
  };

  @override
  State<GestionHistoriaClinicaView> createState() => _GestionHistoriaClinicaViewState();
}

class _GestionHistoriaClinicaViewState extends State<GestionHistoriaClinicaView> {
  // ... ( _firestoreService, _dateFormatter, _navigateToAddForm, _confirmDelete, _navigateToEditForm se mantienen) ...
  final FirestoreService _firestoreService = FirestoreService();
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy, hh:mm a', 'es_ES');

  void _navigateToAddForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GestionHistoriaClinicaFormScreen(pacienteId: widget.pacienteId),
      ),
    );
  }

  Future<void> _confirmDelete(DatosClinicos dataToDelete) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de eliminar este registro clínico del ${_dateFormatter.format(dataToDelete.timestamp.toDate())}? Esta acción no se puede deshacer.',
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
        await _firestoreService.deleteClinicalRecord(widget.pacienteId, dataToDelete.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro eliminado'), backgroundColor: Colors.orange),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToEditForm(DatosClinicos recordToEdit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => GestionHistoriaClinicaFormScreen(
              pacienteId: widget.pacienteId,
              initialData: recordToEdit,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DatosClinicos>>(
      stream: _firestoreService.getClinicalRecordsStream(widget.pacienteId),
      builder: (context, snapshot) {
        // ... (manejo de loading, error, no data como antes) ...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar historial: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No hay registros de historia clínica. Añade el primero.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir Primer Registro'),
                    onPressed: _navigateToAddForm, // Llama a la función para añadir
                  ),
                ],
              ),
            ),
          );
        }

        final clinicalRecords = snapshot.data!;
        // Asumimos que el stream ya viene ordenado por timestamp desc
        final latestRecord = clinicalRecords.first;
        final previousRecords = clinicalRecords.skip(1).toList();

        return ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            // --- Último Registro (Editable) ---
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16.0),
              child: ExpansionTile(
                key: PageStorageKey('latest_${latestRecord.id}'),
                initiallyExpanded: true,
                leading: const Icon(Icons.article, color: Colors.blueAccent),
                title: Text(
                  'Último Registro (${_dateFormatter.format(latestRecord.timestamp.toDate())})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.blue),
                      tooltip: 'Editar Último Registro',
                      onPressed: () => _navigateToEditForm(latestRecord),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: 'Eliminar Último Registro',
                      onPressed: () => _confirmDelete(latestRecord),
                    ),
                  ],
                ),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: _buildRecordDetails(latestRecord), // Mostrar detalles
              ),
            ),

            // --- Historial Anterior (Solo Lectura) ---
            if (previousRecords.isNotEmpty)
              ExpansionTile(
                key: const PageStorageKey('history'),
                leading: const Icon(Icons.history, color: Colors.grey),
                title: const Text('Historial Anterior'),
                children:
                    previousRecords.map((record) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: ListTile(
                          dense: true,
                          title: Text(
                            'Registro del ${_dateFormatter.format(record.timestamp.toDate())}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            // Mostrar solo el inicio del ID si es muy largo
                            'ID: ${record.id.length > 8 ? record.id.substring(0, 8) : record.id}...',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                            tooltip: 'Ver Detalles',
                            onPressed: () => _showReadOnlyDetailsDialog(context, record),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            const SizedBox(height: 70), // Espacio para FAB si aplica
          ],
        );
      },
    );
  }

  // _buildRecordDetails se mantiene, pero usa el nuevo map de etiquetas
  List<Widget> _buildRecordDetails(DatosClinicos record) {
    final map = record.toMap(); // Usa el toMap corregido
    // Filtrar los campos que SÍ existen en el modelo y no son IDs/timestamp
    final fieldsToShow = map.entries.where(
      (e) =>
          e.key != 'id' &&
          e.key != 'pacienteId' &&
          e.key != 'doctorId' &&
          e.key != 'timestamp' &&
          e.value != null,
    );

    return fieldsToShow.map((entry) {
      // Usar el mapa de etiquetas actualizado
      final label =
          GestionHistoriaClinicaView.fieldLabels[entry.key] ??
          entry.key
              .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
              .capitalizeFirst; // Formato legible por defecto
      // Asegúrate de que el valor sea un tipo que _buildInfoRow pueda manejar
      // Si no, conviértelo a String o maneja el caso.
      final dynamic value = entry.value;

      return _buildInfoRow(label as String, value);
    }).toList();
  }

  // _showReadOnlyDetailsDialog se mantiene igual
  void _showReadOnlyDetailsDialog(BuildContext context, DatosClinicos record) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Detalle Registro (${_dateFormatter.format(record.timestamp.toDate())})'),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.7, // Ajustar altura
              child: ListView(
                // Usar ListView para scroll si es necesario
                shrinkWrap: true,
                children: _buildRecordDetails(record),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cerrar')),
            ],
          ),
    );
  }

  // _buildInfoRow se mantiene igual
  Widget _buildInfoRow(String label, dynamic value) {
    String displayValue;
    if (value == null) {
      displayValue = 'No especificado';
    } else if (value is bool) {
      displayValue = value ? 'Sí' : 'No';
    } else if (value is Timestamp) {
      displayValue = _dateFormatter.format(value.toDate());
    } else if (value is DateTime) {
      displayValue = _dateFormatter.format(value);
    } else if (value is double) {
      // Mostrar k para plaquetas si la etiqueta lo indica
      if (label.toLowerCase().contains('plaquetas')) {
        displayValue = '${value.toStringAsFixed(0)} k/µL';
      } else {
        displayValue = value.toStringAsFixed(
          value.truncateToDouble() == value ? 0 : 2,
        ); // 0 decimales si es entero
      }
    } else if (value is int) {
      if (label.toLowerCase().contains('plaquetas')) {
        displayValue = '${value.toString()} k/µL';
      } else {
        displayValue = value.toString();
      }
    } else if (value is List && value.isEmpty) {
      displayValue = 'Ninguno/a';
    } else if (value is List) {
      displayValue = value.join(', ');
    } else {
      displayValue = value.toString();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180, // Ajustar ancho si es necesario
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(displayValue)),
        ],
      ),
    );
  }
}

// Helper para capitalizar (puedes ponerlo en un archivo utils)
extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
} */

/* // pages/admin/pacientes/historia_clinica/gestion_historia_clinica_view.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Necesario para Timestamp

import '../../../../models/modelos.dart';
import '../../../../services/firestore_service.dart';
import 'gestion_historia_clinica_form.dart'; // El formulario para añadir

class GestionHistoriaClinicaView extends StatefulWidget {
  final String pacienteId; // Solo necesita el ID del paciente

  const GestionHistoriaClinicaView({required this.pacienteId, super.key});

  // Mover el mapa de etiquetas aquí o mantenerlo donde estaba y accederlo
  static const Map<String, String> fieldLabels = {
    /* ... tu mapa de etiquetas ... */
    'institucion': 'Institución', 'procedencia': 'Procedencia', 'etnia': 'Etnia',
    'indigena': 'Indígena', 'escolaridad': 'Escolaridad', 'remitidaOtraInst': 'Remitida Otra Inst.',
    'abortos': 'Abortos', 'ectopicos': 'Ectópicos', 'numControles': 'No. Controles',
    'viaParto': 'Vía Parto', 'semanasOcurrencia': 'Semanas Ocurrencia',
    'ocurrenciaGestacion': 'Ocurrencia Gestación', 'estadoObstetrico': 'Estado Obstétrico',
    'peso': 'Peso (Kg)', 'altura': 'Altura (cm)', 'imc': 'IMC',
    'frecuenciaCardiacaIngresoAlta': 'FC Ingreso Alta',
    'fRespiratoriaIngresoAlta': 'FR Ingreso Alta',
    'pasIngresoAlta': 'PAS Ingreso Alta', 'padIngresoBaja': 'PAD Ingreso Baja',
    'conscienciaIngreso': 'Consciencia Ingreso', 'hemoglobinaIngreso': 'Hb Ingreso (g/dL)',
    'creatininaIngreso': 'Creatinina Ingreso (mg/dL)', 'gptIngreso': 'GPT Ingreso (U/L)',
    'manejoEspecificoCirugiaAdicional': 'Manejo: Cirugía Adicional',
    'manejoEspecificoIngresoUado': 'Manejo: Ingreso UADO',
    'manejoEspecificoIngresoUci': 'Manejo: Ingreso UCI',
    'unidadesTransfundidas': 'Unidades Transfundidas', 'manejoQxLaparotomia': 'Qx: Laparotomía',
    'manejoQxOtra': 'Qx: Otra', 'desgarroPerineal': 'Desgarro Perineal',
    'suturaPerinealPosparto': 'Sutura Perineal Postparto',
    'tratamientosUadoMonitoreoHemodinamico': 'Tto UADO: Monit. Hemodinámico',
    'tratamientosUadoOxigeno': 'Tto UADO: Oxígeno',
    'tratamientosUadoTransfusiones': 'Tto UADO: Transfusiones',
    'diagPrincipalThe': 'Diag: THE', 'diagPrincipalHemorragia': 'Diag: Hemorragia',
    'waosProcedimientoQuirurgicoNoProgramado': 'WAOS: Proc. Qx No Programado',
    'waosRoturaUterinaDuranteElParto': 'WAOS: Rotura Uterina',
    'waosLaceracionPerineal3erO4toGrado': 'WAOS: Laceración G3/4',
    'apgar1Minuto': 'APGAR 1 Minuto', 'fCardiacaEstanciaMax': 'FC Estancia MAX',
    'fCardiacaEstanciaMin': 'FC Estancia MIN', 'pasEstanciaMin': 'PAS Estancia MIN',
    'padEstanciaMin': 'PAD Estancia MIN', 'sao2EstanciaMax': 'SaO2 Estancia MAX (%)',
    'hemoglobinaEstanciaMin': 'Hb Estancia MIN (g/dL)',
    'creatininaEstanciaMax': 'Creatinina Est. MAX (mg/dL)',
    'gotAspartatoAminotransferasaMax': 'GOT Est. MAX (U/L)',
    'recuentoPlaquetasPltMin': 'Plaquetas Est. MIN (/µL)', 'diasEstancia': 'Días Estancia',
    'desenlaceMaterno2': 'Desenlace Materno Adverso',
    'desenlaceNeonatal': 'Desenlace Neonatal Adverso',
    'edad': 'Edad', 'numeroGestaciones': 'Nº Gestaciones', 'fetosMuertos': 'Fetos Muertos',
    'enfermedadEndocrinaMetabolica': 'Enf. Endocrina/Metabólica',
    'enfermedadCardiovascularCerebrovascular': 'Enf. Cardiovascular/Cerebrovascular',
    'enfermedadRenal': 'Enf. Renal',
    'otrasEnfermedades': 'Otras Enfermedades',
    'preeclampsia': 'Preeclampsia',
    'hemorragiaObstetricaSevera': 'Hemorragia Obst. Severa',
    'hemorragiaMasSeveraMM': 'Hemorragia Más Severa (MM)',
    'tipoAfiliacionSS': 'Tipo Afiliación SS', 'semanasPrimerControlPrenatal': 'Semanas 1er Control',
    'codigoMunicipioResidencia': 'Cod. Municipio Res.', 'codigoPrestador': 'Cod. Prestador',
    'estratoSocioeconomico': 'Estrato',
    'eclampsia': 'Eclampsia',
    'terminacionGestacion': 'Terminación Gestación',
    'morbilidadRelacionadaTG': 'Morbilidad Rel. TG',
    'tipoCaso': 'Tipo Caso',
    'numeroCesareas': 'Nº Cesáreas',
    'causaPrincipalMorbilidad': 'Causa Principal Morb.', 'pesoRecienNacido': 'Peso RN (gr)',
    'timestamp': 'Fecha Registro', // Añadir etiqueta para timestamp
  };

  @override
  State<GestionHistoriaClinicaView> createState() => _GestionHistoriaClinicaViewState();
}

class _GestionHistoriaClinicaViewState extends State<GestionHistoriaClinicaView> {
  final FirestoreService _firestoreService = FirestoreService();
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy, HH:mm', 'es_ES');

  // Navega al formulario SIEMPRE en modo creación
  void _navigateToAddForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => GestionHistoriaClinicaFormScreen(
              pacienteId: widget.pacienteId,
              // No se pasa initialData para crear uno nuevo
            ),
      ),
    );
  }

  // Confirmar eliminación (quizás solo del último o ninguno histórico)
  Future<void> _confirmDelete(DatosClinicos dataToDelete) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de eliminar este registro clínico del ${_dateFormatter.format(dataToDelete.timestamp.toDate())}? Esta acción no se puede deshacer.',
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
        await _firestoreService.deleteClinicalRecord(widget.pacienteId, dataToDelete.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro eliminado'), backgroundColor: Colors.orange),
        );
        // El StreamBuilder actualizará la lista
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Función para navegar al formulario en modo EDICIÓN ---
  // Se llamará desde el botón Editar del registro MÁS RECIENTE
  void _navigateToEditForm(DatosClinicos recordToEdit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => GestionHistoriaClinicaFormScreen(
              pacienteId: widget.pacienteId,
              initialData: recordToEdit, // Pasa los datos para editar
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DatosClinicos>>(
      stream: _firestoreService.getClinicalRecordsStream(widget.pacienteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar historial: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                // Envuelve en columna para el botón
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No hay registros de historia clínica. Añade el primero.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir Primer Registro'),
                    onPressed: _navigateToAddForm,
                  ),
                ],
              ),
            ),
          );
        }

        final clinicalRecords = snapshot.data!;
        final latestRecord = clinicalRecords.first; // El más reciente está primero
        final previousRecords = clinicalRecords.skip(1).toList();

        return ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            // --- Último Registro (Editable) ---
            Card(
              elevation: 4, // Destacar más
              margin: const EdgeInsets.only(bottom: 16.0),
              child: ExpansionTile(
                key: PageStorageKey('latest_${latestRecord.id}'), // Key para mantener estado
                initiallyExpanded: true, // Mostrar expandido por defecto
                leading: const Icon(Icons.article, color: Colors.blueAccent),
                title: Text(
                  'Último Registro (${_dateFormatter.format(latestRecord.timestamp.toDate())})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                trailing: Row(
                  // Acciones para el último registro
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.blue),
                      tooltip: 'Editar Último Registro',
                      // Llama a la función de edición
                      onPressed: () => _navigateToEditForm(latestRecord),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: 'Eliminar Último Registro',
                      // Llama a la función de borrado
                      onPressed: () => _confirmDelete(latestRecord),
                    ),
                  ],
                ),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: _buildRecordDetails(latestRecord), // Reusa el helper
              ),
            ),

            // --- Historial Anterior (Solo Lectura) ---
            if (previousRecords.isNotEmpty)
              ExpansionTile(
                key: const PageStorageKey('history'), // Key para mantener estado
                leading: const Icon(Icons.history, color: Colors.grey),
                title: const Text('Historial Anterior'),
                children:
                    previousRecords.map((record) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: ListTile(
                          dense: true,
                          title: Text(
                            'Registro del ${_dateFormatter.format(record.timestamp.toDate())}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'ID: ${record.id.substring(0, 8)}...',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                            tooltip: 'Ver Detalles',
                            onPressed: () => _showReadOnlyDetailsDialog(context, record),
                          ),
                          // No hay botones de editar/borrar aquí
                        ),
                      );
                    }).toList(),
              ),
            const SizedBox(height: 70), // Espacio para el FAB
          ],
        );
      },
    );
  }

  // Helper para construir los detalles de UN registro
  List<Widget> _buildRecordDetails(DatosClinicos record) {
    final map = record.toMap();
    // Filtrar o definir qué campos mostrar
    final fieldsToShow = map.entries.where(
      (e) => e.key != 'id' && e.key != 'pacienteId' && e.key != 'doctorId' && e.value != null,
    );

    return fieldsToShow.map((entry) {
      final label = GestionHistoriaClinicaView.fieldLabels[entry.key] ?? entry.key;
      return _buildInfoRow(label, entry.value); // Usa el helper de formato
    }).toList();
  }

  // Helper para mostrar detalles en un diálogo (solo lectura)
  void _showReadOnlyDetailsDialog(BuildContext context, DatosClinicos record) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Detalle Registro (${_dateFormatter.format(record.timestamp.toDate())})'),
            content: SizedBox(
              // Limitar altura
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.6,
              child: ListView(shrinkWrap: true, children: _buildRecordDetails(record)),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cerrar')),
            ],
          ),
    );
  }

  // Helper para formatear y mostrar una fila de información (sin cambios)
  Widget _buildInfoRow(String label, dynamic value) {
    // ... (igual que antes) ...
    String displayValue;
    if (value == null) {
      displayValue = 'No especificado';
    } else if (value is bool) {
      displayValue = value ? 'Sí' : 'No';
    } else if (value is Timestamp) {
      // Formatear Timestamps
      displayValue = _dateFormatter.format(value.toDate());
    } else if (value is DateTime) {
      // Si acaso llega un DateTime
      displayValue = _dateFormatter.format(value);
    } else if (value is double) {
      displayValue = value.toStringAsFixed(2);
    } else if (value is List && value.isEmpty) {
      displayValue = 'Ninguno/a';
    } else if (value is List) {
      displayValue = value.join(', ');
    } else {
      displayValue = value.toString();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(displayValue)),
        ],
      ),
    );
  }
} */
