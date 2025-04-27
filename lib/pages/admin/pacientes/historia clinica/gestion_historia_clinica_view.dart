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
  final DateFormat _dateFormatter = DateFormat('EEEE dd MMM yyyy, hh:mm a', 'es_ES');

  // --- MODIFICA _buildRecordDetails ---
  /// Construye una lista de Widgets para mostrar los detalles de un registro clínico.
  /// Adapta el layout (Wrap o Column implícita) según el ancho disponible.
  ///
  /// [record]: El objeto DatosClinicos a mostrar.
  /// [useWideLayout]: Booleano que indica si se debe usar el layout de Wrap.
  /// [itemWidth]: El ancho deseado para cada item en el layout de Wrap.
  List<Widget> _buildRecordDetails(
    DatosClinicos record, {
    required bool useWideLayout,
    double itemWidth = 380.0, // Valor por defecto para Wrap
  }) {
    final map = record.toMap();
    // Filtrar campos a mostrar (excluir IDs y timestamp si no se quiere aquí)
    final fieldsToShow = map.entries.where(
      (e) =>
          e.key != 'id' &&
          e.key != 'pacienteId' &&
          e.key != 'doctorId' &&
          e.key != 'timestamp' && // Generalmente el timestamp se muestra en el título
          e.value != null, // No mostrar campos nulos
    );

    // Ordenar alfabéticamente por etiqueta
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

    // Generar la lista de widgets
    List<Widget> detailWidgets =
        sortedFields.map((entry) {
          final label =
              GestionHistoriaClinicaView.fieldLabels[entry.key] ??
              entry.key
                  .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
                  .capitalizeFirst();

          // Crear la fila de información (Label: Value)
          Widget infoRow = _buildInfoRow(label, entry.value); // Usa tu helper existente

          // Si usamos el layout ancho, envolvemos la fila en un SizedBox con ancho fijo
          if (useWideLayout) {
            return SizedBox(width: itemWidth, child: infoRow);
          } else {
            // Si es layout estrecho, devolvemos la fila directamente
            return infoRow;
          }
        }).toList();

    // Si usamos el layout ancho, envolvemos todo en un Wrap
    if (useWideLayout) {
      const double wrapSpacing = 16.0;
      return [
        // Devolvemos una lista que contiene el Wrap
        Wrap(
          spacing: wrapSpacing,
          runSpacing: wrapSpacing / 2,
          children: detailWidgets, // Los SizedBox que contienen las filas
        ),
      ];
    } else {
      // Si es layout estrecho, devolvemos la lista de filas directamente
      return detailWidgets;
    }
  }

  // _buildInfoRow (Sin cambios necesarios)
  Widget _buildInfoRow(String label, dynamic value) {
    // ... (código existente) ...
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
      // Ajusta formato específico si es necesario (ej. plaquetas)
      if (label.toLowerCase().contains('plaquetas')) {
        displayValue = '${value.toStringAsFixed(0)} k/µL';
      } else if (label.toLowerCase().contains('altura')) {
        displayValue = '${value.toStringAsFixed(0)} cm';
      } else if (label.toLowerCase().contains('peso')) {
        displayValue = '${value.toStringAsFixed(1)} Kg';
      } else {
        displayValue = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
      }
    } else if (value is int) {
      if (label.toLowerCase().contains('plaquetas')) {
        displayValue = '${value.toString()} k/µL';
      } else if (label.toLowerCase().contains('altura')) {
        displayValue = '${value.toString()} cm';
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
            width: 180, // Mantenemos ancho fijo para la etiqueta
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(displayValue)),
        ],
      ),
    );
  }

  // --- MODIFICAR _showReadOnlyDetailsDialog ---
  // Ahora necesita saber si usar el layout ancho
  void _showReadOnlyDetailsDialog(BuildContext context, DatosClinicos record) {
    showDialog(
      context: context,
      builder: (context) {
        // Determinar si la pantalla del diálogo es ancha
        final screenWidth = MediaQuery.of(context).size.width;
        const double dialogBreakpoint = 600.0; // Breakpoint para el diálogo
        final bool useWideDialogLayout = screenWidth >= dialogBreakpoint;

        return AlertDialog(
          title: Text('Detalle Registro (${_dateFormatter.format(record.timestamp.toDate())})'),
          // Ajustar el ancho MÁXIMO del diálogo en pantallas anchas
          // Esto evita que el diálogo sea excesivamente ancho
          insetPadding:
              useWideDialogLayout
                  ? const EdgeInsets.symmetric(horizontal: 50.0, vertical: 24.0)
                  : const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          content: SizedBox(
            // Usar un ancho más controlado para el contenido del diálogo
            width: useWideDialogLayout ? 700 : double.maxFinite, // Ejemplo de ancho
            // Darle un alto máximo para que no ocupe toda la pantalla si hay muchos datos
            height: MediaQuery.of(context).size.height * 0.7,
            child: SingleChildScrollView(
              // Usar SingleChildScrollView para scroll
              child: Column(
                // Usar Column para contener el resultado de _buildRecordDetails
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: _buildRecordDetails(
                  record,
                  useWideLayout: useWideDialogLayout, // Pasar el booleano
                  itemWidth: 320, // Ancho ligeramente menor para items dentro del diálogo
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cerrar')),
          ],
        );
      },
    );
  }

  void _navigateToAddForm() {
    // Para crear la PRIMERA versión
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GestionHistoriaClinicaFormScreen(pacienteId: widget.pacienteId),
      ),
    );
  }

  void _navigateToEditForm(DatosClinicos recordToEdit) {
    // Para EDITAR la ÚLTIMA versión
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => GestionHistoriaClinicaFormScreen(
              pacienteId: widget.pacienteId,
              initialData: recordToEdit, // Pasa los datos para pre-llenar el form
            ),
      ),
    );
  }

  // --- Confirmar borrado (AHORA BORRA LA VERSIÓN SELECCIONADA) ---
  Future<void> _confirmDelete(DatosClinicos dataToDelete) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de eliminar ESTA VERSIÓN del registro clínico del ${_dateFormatter.format(dataToDelete.timestamp.toDate())}? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Eliminar Versión', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // Llama al servicio para borrar el documento específico por su ID
        await _firestoreService.deleteClinicalRecord(widget.pacienteId, dataToDelete.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Versión eliminada'), backgroundColor: Colors.orange),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar versión: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Builds a list of widgets suitable for a Wrap layout, displaying record details.
  List<Widget> _buildWrappedRecordDetails(DatosClinicos record, double itemWidth) {
    final map = record.toMap();
    final fieldsToShow = map.entries.where(
      (e) =>
          e.key != 'id' &&
          e.key != 'pacienteId' &&
          e.key != 'doctorId' &&
          e.key != 'timestamp' && // Excluir timestamp también del wrap principal
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

      // Cada item del Wrap será un SizedBox con ancho fijo conteniendo el _buildInfoRow
      return SizedBox(
        width: itemWidth,
        child: _buildInfoRow(label, entry.value), // Reutiliza el helper de fila
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // ... (código anterior del build) ...
    return StreamBuilder<List<DatosClinicos>>(
      stream: _firestoreService.getClinicalRecordsStream(widget.pacienteId),
      builder: (context, snapshot) {
        // ... (manejo de loading, error, no data) ...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print("StreamBuilder error: ${snapshot.error}");
          return Center(child: Text('Error al cargar historial: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // ... (código para "Añadir Primer Registro") ...
          print("StreamBuilder: No data or empty list.");
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
                    onPressed: _navigateToAddForm,
                  ),
                ],
              ),
            ),
          );
        }

        final clinicalRecords = snapshot.data!;
        final latestRecord = clinicalRecords.first;
        final previousRecords = clinicalRecords.skip(1).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            const double breakpoint = 720.0;
            final bool useWideLayout = constraints.maxWidth >= breakpoint;
            const double wrapItemWidth = 380.0;
            // const double wrapSpacing = 16.0; // ya no se necesita aquí directamente

            return ListView(
              padding: useWideLayout ? const EdgeInsets.all(24.0) : const EdgeInsets.all(8.0),
              children: [
                // --- Último Registro (Editable) ---
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: ExpansionTile(
                    // ... (key, initiallyExpanded, leading, title, trailing sin cambios) ...
                    key: PageStorageKey('latest_${latestRecord.id}'),
                    initiallyExpanded: true,
                    leading: const Icon(Icons.article, color: Colors.blueAccent),
                    title: Text(
                      'Última Versión (${_dateFormatter.format(latestRecord.timestamp.toDate())})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: Colors.blue),
                          tooltip: 'Editar (Creará Nueva Versión)',
                          onPressed: () => _navigateToEditForm(latestRecord),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Eliminar Esta Versión',
                          onPressed: () => _confirmDelete(latestRecord),
                        ),
                      ],
                    ),

                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    // --- PASAR useWideLayout a _buildRecordDetails ---
                    children: _buildRecordDetails(
                      latestRecord,
                      useWideLayout: useWideLayout, // <-- Pasar el booleano
                      itemWidth: wrapItemWidth, // <-- Pasar el ancho para Wrap
                    ),
                    // ------------------------------------------------
                  ),
                ),

                // --- Historial Anterior (Sin cambios aquí) ---
                if (previousRecords.isNotEmpty)
                  ExpansionTile(
                    key: const PageStorageKey('history'),
                    leading: const Icon(Icons.history, color: Colors.grey),
                    title: const Text('Historial de Versiones Anteriores'),
                    children:
                        previousRecords.map((record) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.circle, size: 8, color: Colors.grey),
                            title: Text(
                              'Versión del: ${_dateFormatter.format(record.timestamp.toDate())}',
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 18,
                                color: Colors.grey,
                              ),
                              tooltip: 'Ver Detalles (Solo Lectura)',
                              // Llama al diálogo modificado
                              onPressed: () => _showReadOnlyDetailsDialog(context, record),
                            ),
                            onTap: () => _showReadOnlyDetailsDialog(context, record),
                          );
                        }).toList(),
                  ),

                const SizedBox(height: 70), // Espacio para FAB
              ],
            );
          },
        );
      },
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
