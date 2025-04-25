// lista_pacientes.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../models/modelos.dart';
import '../../../services/firestore_service.dart';

class ListaPacientes extends StatefulWidget {
  const ListaPacientes({super.key});

  @override
  ListaPacientesState createState() => ListaPacientesState();
}

class ListaPacientesState extends State<ListaPacientes> {
  List<Usuario> pacientes = [];
  List<Usuario> filteredPacientes = [];
  String searchQuery = '';
  late UserDataGridSource userDataGridSource;
  final dataGridController = DataGridController();

  @override
  void initState() {
    super.initState();
    userDataGridSource = UserDataGridSource([]);
    _loadPacientes();
  }

  void _loadPacientes() {
    // Escucha el stream de pacientes (usuarios con rol 'paciente')
    FirestoreService().getAllpacientesStream().listen(
      (users) {
        setState(() {
          pacientes = users;
          _filterPacientes();
        });
      },
      onError: (e) {
        if (kDebugMode) print('Error cargando pacientes: $e');
      },
    );
  }

  void _filterPacientes() {
    final q = searchQuery.toLowerCase();
    setState(() {
      filteredPacientes =
          pacientes.where((u) {
            final nombre = u.displayName.toLowerCase();
            final email = u.email.toLowerCase();
            final id = u.uid.toLowerCase();
            // Filtrado por nombre, email o ID
            if (q.isNotEmpty && !nombre.contains(q) && !email.contains(q) && !id.contains(q)) {
              return false;
            }
            return true;
          }).toList();
      userDataGridSource.updateDataGridRows(filteredPacientes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Pacientes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                searchQuery = v;
                _filterPacientes();
              },
            ),
          ),
          Expanded(
            child: SfDataGrid(
              source: userDataGridSource,
              controller: dataGridController,
              allowSorting: true,
              columnWidthMode: ColumnWidthMode.fill,
              columns: <GridColumn>[
                GridColumn(
                  columnName: 'displayName',
                  label: Container(
                    padding: const EdgeInsets.all(8.0),
                    alignment: Alignment.center,
                    child: const Text('Nombre'),
                  ),
                ),
                GridColumn(
                  columnName: 'email',
                  label: Container(
                    padding: const EdgeInsets.all(8.0),
                    alignment: Alignment.center,
                    child: const Text('Email'),
                  ),
                ),
                GridColumn(
                  columnName: 'uid',
                  label: Container(
                    padding: const EdgeInsets.all(8.0),
                    alignment: Alignment.center,
                    child: const Text('ID'),
                  ),
                ),
                // Si luego quieres añadir columnas de DatosClinicos:
                // GridColumn(columnName: 'institucion', label: Text('Institución')),
                // GridColumn(columnName: 'procedencia', label: Text('Procedencia')),
                // etc.
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navega a pantalla de alto nivel para crear paciente
        },
        tooltip: 'Añadir Paciente',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class UserDataGridSource extends DataGridSource {
  List<DataGridRow> _rows = [];

  UserDataGridSource(List<Usuario> usuarios) {
    updateDataGridRows(usuarios);
  }

  void updateDataGridRows(List<Usuario> usuarios) {
    _rows =
        usuarios.map<DataGridRow>((u) {
          // Extraer el primer DatosClinicos si lo necesitas:
          // final datos = u.datosClinicos?.first;
          return DataGridRow(
            cells: [
              DataGridCell<String>(columnName: 'displayName', value: u.displayName),
              DataGridCell<String>(columnName: 'email', value: u.email),
              DataGridCell<String>(columnName: 'uid', value: u.uid),
              // Ejemplo usando DatosClinicos:
              // DataGridCell<String>(columnName: 'institucion', value: datos?.institucion ?? ''),
              // DataGridCell<String>(columnName: 'procedencia', value: datos?.procedencia ?? ''),
            ],
          );
        }).toList();
    notifyListeners();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells:
          row.getCells().map<Widget>((cell) {
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8.0),
              child: Text(cell.value.toString()),
            );
          }).toList(),
    );
  }
}

/* // ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../models/modelos.dart';
import 'nuevo_paciente.dart';

Color _getStatusColor(String status) {
  switch (status) {
    case 'Active':
      return Colors.green[100]!;
    case 'Pending':
      return Colors.orange[100]!;
    case 'Banned':
      return Colors.red[100]!;
    case 'Rejected':
      return Colors.grey[300]!;
    default:
      return Colors.grey[100]!;
  }
}

class ListaPacientes extends StatefulWidget {
  const ListaPacientes({super.key});

  @override
  ListaPacientesState createState() => ListaPacientesState();
}

class ListaPacientesState extends State<ListaPacientes> {
  List<Paciente> pacientes = [];
  Map<String, Set<String>> uniqueValues = {};
  List<Widget> filterRows = [];
  List<Paciente> filteredPacientes = [];
  String searchQuery = '';
  String selectedRole = 'Todos';
  String selectedStatus = 'Todos';
  bool sortAscending = true;
  DataGridController dataGridController = DataGridController();
  UserDataGridSource userDataGridSource = UserDataGridSource([]);

  @override
  void initState() {
    super.initState();
    uniqueValues = {};
    pacientes = [];
    dataGridController = DataGridController();
    userDataGridSource = UserDataGridSource([]);
    _filterPacientes();
  }

  void _filterPacientes() {
    if (kDebugMode) {
      print(['Grupo Sanguineo', selectedStatus]);
      print(['nacionalidad', selectedRole]);
      print(['nombre', searchQuery]);
    }
    setState(() {
      filteredPacientes =
          pacientes.where((paciente) {
            // Filtra por el término de búsqueda
            if (searchQuery != '' &&
                !paciente.nombre!.toLowerCase().contains(searchQuery.toLowerCase()) &&
                !paciente.telefono!.contains(searchQuery) &&
                !paciente.documentoIdentidad!.contains(searchQuery)) {
              return false;
            }

            // Filtra por la nacionalidad seleccionada (si no es 'Todos')
            if (selectedRole != 'Todos' && paciente.nacionalidad != selectedRole) {
              return false;
            }

            // Filtra por el grupo sanguíneo seleccionado (si no es 'Todos')
            if (selectedStatus != 'Todos' && paciente.grupoSanguineo != selectedStatus) {
              return false;
            }

            // Si todos los filtros pasan, incluye al paciente
            return true;
          }).toList();
      userDataGridSource.updateDataGridRows(filteredPacientes);
    });
  }

  // --------------------------------
  /* Widget _buildFilterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        /* Container(
          height: smallView ? null : 56,
          margin: const EdgeInsets.only(top: 10.0, bottom: 5.0),
          padding: EdgeInsets.only(
              top: smallView ? 0 : 5.0, bottom: smallView ? 0 : 5.0, left: 10.0, right: 10.0),
          decoration: BoxDecoration(
            border: Border.all(width: 0.6),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: DropdownButton<String>(
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(10.0),
            value: selectedRole,
            items: <String>[
              'Todos',
              'Executive',
              'Intern',
              'Telesale',
              'Full Stack Designer',
              'Backend Developer'
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                selectedRole = newValue!;
                _filterPacientes();
              });
            },
          ),
        ),
        Container(
          height: smallView ? null : 56,
          margin: const EdgeInsets.only(top: 10.0, bottom: 5.0, left: 10.0, right: 10.0),
          padding: EdgeInsets.only(
              top: smallView ? 0 : 5.0, bottom: smallView ? 0 : 5.0, left: 10.0, right: 10.0),
          decoration: BoxDecoration(
            border: Border.all(width: 0.6),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: DropdownButton<String>(
            underline: const SizedBox(),
            value: selectedStatus,
            items: <String>['Todos', 'Active', 'Pending', 'Banned', 'Rejected'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                selectedStatus = newValue!;
                _filterPacientes();
              });
            },
          ),
        ), */
        Container(
          height: smallView ? null : 56,
          margin: const EdgeInsets.only(top: 10.0, bottom: 5.0),
          padding: EdgeInsets.only(
              top: smallView ? 0 : 5.0, bottom: smallView ? 0 : 5.0, left: 10.0, right: 10.0),
          decoration: BoxDecoration(
            border: Border.all(width: 0.6),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: DropdownButton<String>(
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(10.0),
            value: selectedRole,
            items: getUniqueValues('nacionalidad').map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                selectedRole = newValue!;
                _filterPacientes();
              });
            },
          ),
        ),
        Container(
          height: smallView ? null : 56,
          margin: const EdgeInsets.only(top: 10.0, bottom: 5.0, left: 10.0, right: 10.0),
          padding: EdgeInsets.only(
              top: smallView ? 0 : 5.0, bottom: smallView ? 0 : 5.0, left: 10.0, right: 10.0),
          decoration: BoxDecoration(
            border: Border.all(width: 0.6),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: DropdownButton<String>(
            underline: const SizedBox(),
            value: selectedStatus,
            items: getUniqueValues('grupoSanguineo').map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                selectedStatus = newValue!;
                _filterPacientes();
              });
            },
          ),
        ),
      ],
    );
  } */

  List<Widget> _buildFilterRow() {
    if (kDebugMode) {
      print(['nacionalidades', getUniqueValues('nacionalidad')]);
      print(['Grupos Sanguineos', getUniqueValues('grupoSanguineo')]);
    }
    filterRows = [];
    setState(() {
      filterRows.add(
        _buildDropdownButton('Nacionalidad', getUniqueValues('nacionalidad'), selectedRole, (
          newValue,
        ) {
          setState(() {
            selectedRole = newValue!;
            // if (kDebugMode) {
            //   print(['nacionalidad', selectedRole]);
            // }
            _filterPacientes();
          });
        }),
      );
      filterRows.add(
        _buildDropdownButton('Grupo Sanguineo', getUniqueValues('grupoSanguineo'), selectedRole, (
          newValue,
        ) {
          setState(() {
            selectedStatus = newValue!;
            // if (kDebugMode) {
            //   print(['Grupo Sanguineo', selectedStatus]);
            // }
            _filterPacientes();
          });
        }),
      );
    });
    return filterRows;
  }

  Widget _buildDropdownButton(
    String label,
    List<String> items,
    String selectedValue,
    Function(String?) onChanged,
  ) {
    return Container(
      height: smallView ? null : 56,
      margin: const EdgeInsets.only(top: 10.0, bottom: 5.0, left: 10.0, right: 10.0),
      padding: EdgeInsets.only(
        top: smallView ? 0 : 5.0,
        bottom: smallView ? 0 : 5.0,
        left: 10.0,
        right: 10.0,
      ),
      decoration: BoxDecoration(
        border: Border.all(width: 0.6),
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: DropdownButton<String>(
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(10.0),
        value: selectedValue,
        items:
            items.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // Obtener valores únicos de los campos deseados
  List<String> getUniqueValues(String field) {
    uniqueValues[field] = {'Todos'};
    for (Paciente paciente in pacientes) {
      uniqueValues[field]!.add(paciente.toJson()[field]);
      /* switch (field) {
        case 'nacionalidad':
          uniqueValues.add(paciente.nacionalidad);
          break;
        case 'grupoSanguineo':
          uniqueValues.add(paciente.grupoSanguineo);
          break;
        case 'factorRH':
          uniqueValues.add(paciente.factorRH);
          break;
        default:
          break;
      } */
    }
    return uniqueValues[field]!.toList();
  }

  // --------------------------------
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
            _filterPacientes();
          });
        },
        decoration: const InputDecoration(
          labelText: 'Search',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.search),
        ),
      ),
    );
  }

  Widget _buildSelectedChips() {
    List<Widget> chips = [];

    if (selectedRole != 'Todos') {
      chips.add(
        Chip(
          label: Text('Role: $selectedRole'),
          onDeleted: () {
            setState(() {
              selectedRole = 'Todos';
              _filterPacientes();
            });
          },
        ),
      );
    }

    if (selectedStatus != 'Todos') {
      chips.add(
        Chip(
          label: Text(
            'Status: $selectedStatus',
            style: const TextStyle(
              // fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _getStatusColor(selectedStatus),
          onDeleted: () {
            setState(() {
              selectedStatus = 'Todos';
              _filterPacientes();
            });
          },
        ),
      );
    }

    return Wrap(spacing: 8.0, runSpacing: 8.0, children: chips);
  }

  Future<void> loadSpreadsheet() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null) {
      File file = File(result.files.single.path!);
      var bytes = file.readAsBytesSync();
      var decoder = SpreadsheetDecoder.decodeBytes(bytes);

      for (var table in decoder.tables.keys) {
        for (var row in decoder.tables[table]!.rows.skip(1)) {
          /* for (int i = 0; i < row.length; i++) {
            if (row[i] != null) {
              if (kDebugMode) {
                print([i, row[i]]);
              }
            }
          } */
          // Convert date cells to DateTime objects
          DateTime? fechaNacimiento = _parseDate(row[1]);
          DateTime? fechaUltimaMenstruacion = _parseDate(row[12]);
          DateTime? fechaProbableParto = _parseDate(row[14]);

          /* if (kDebugMode) {
            print([
              fechaNacimiento,
              fechaUltimaMenstruacion,
              fechaProbableParto,
            ]);
          } */

          if (fechaNacimiento != null &&
              fechaUltimaMenstruacion != null &&
              fechaProbableParto != null) {
            Paciente paciente = Paciente(
              id: row[3],
              nombre: row[0],
              fechaNacimiento: fechaNacimiento,
              nacionalidad: row[2],
              documentoIdentidad: row[3],
              direccion: row[4],
              telefono: row[5],
              email: row[6],
              grupoSanguineo: row[7],
              factorRH: row[8],
              alergias: List<String>.from(row[9].split(',')),
              enfermedadesPreexistentes: List<String>.from(row[10].split(',')),
              medicamentos: List<String>.from(row[11].split(',')),
              fechaUltimaMenstruacion: fechaUltimaMenstruacion,
              semanasGestacion: row[13],
              fechaProbableParto: fechaProbableParto,
              numeroGestaciones: row[15],
              numeroPartosVaginales: row[16],
              numeroCesareas: row[17],
              abortos: row[18],
              embarazoMultiple: row[19],
              coordenadas: GeoPoint(double.parse(row[20]), double.parse(row[21])),
            );
            setState(() {
              pacientes.add(paciente);
              // _filterPacientes();
            });
          } else {
            // Handle cases where date parsing fails
            if (kDebugMode) {
              print('Error parsing date for row: ${row.join(', ')}');
            }
          }
        }
      }
    }
    setState(() {
      _filterPacientes();
    });
    _buildFilterRow();
  }

  // Helper function to parse date cells
  DateTime? _parseDate(dynamic cell) {
    if (cell is ex.DateCellValue) {
      // If it's a ex.DateCellValue, use its properties directly
      return DateTime(cell.year, cell.month, cell.day);
    } else if (cell is int) {
      // If it's an integer, assume it's a serial date number
      // Convert the serial date number to a DateTime object
      return DateTime.fromMillisecondsSinceEpoch((cell - 25569) * 86400000, isUtc: true);
    } else if (cell is String) {
      // If it's a string, try parsing it as a date
      try {
        return DateTime.parse(cell);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing date: $e');
        }
        return null;
      }
    }
    return null;
  }

  Future<void> exportSpreadsheet() async {
    var excel = ex.Excel.createExcel();
    ex.Sheet sheetObject = excel['Pacientes'];

    sheetObject.appendRow([
      ex.TextCellValue('Nombre'),
      ex.TextCellValue('Fecha de Nacimiento'),
      ex.TextCellValue('Nacionalidad'),
      ex.TextCellValue('Documento de Identidad'),
      ex.TextCellValue('Direccion'),
      ex.TextCellValue('Telefono'),
      ex.TextCellValue('Email'),
      ex.TextCellValue('Grupo Sanguíneo'),
      ex.TextCellValue('Factor RH'),
      ex.TextCellValue('Alergias'),
      ex.TextCellValue('Enfermedades Preexistentes'),
      ex.TextCellValue('Medicamentos'),
      ex.TextCellValue('Fecha Ultima Menstruacion'),
      ex.TextCellValue('Semanas de Gestacion'),
      ex.TextCellValue('Fecha Probable de Parto'),
      ex.TextCellValue('Numero de Gestaciones'),
      ex.TextCellValue('Numero de Partos Vaginales'),
      ex.TextCellValue('Numero de Cesareas'),
      ex.TextCellValue('Numero de Abortos'),
      ex.TextCellValue('Embarazo Multiple'),
      ex.TextCellValue('Latitud'),
      ex.TextCellValue('Longitud'),
    ]);

    for (Paciente paciente in pacientes) {
      sheetObject.appendRow([
        ex.TextCellValue(paciente.nombre!),
        ex.TextCellValue(paciente.fechaNacimiento!.toIso8601String()),
        ex.TextCellValue(paciente.nacionalidad!),
        ex.TextCellValue(paciente.documentoIdentidad!),
        ex.TextCellValue(paciente.direccion!),
        ex.TextCellValue(paciente.telefono!),
        ex.TextCellValue(paciente.email ?? ''),
        ex.TextCellValue(paciente.grupoSanguineo ?? ''),
        ex.TextCellValue(paciente.factorRH ?? ''),
        ex.TextCellValue(paciente.alergias?.join(', ') ?? ''),
        ex.TextCellValue(paciente.enfermedadesPreexistentes?.join(', ') ?? ''),
        ex.TextCellValue(paciente.medicamentos?.join(', ') ?? ''),
        // ex.TextCellValue(paciente.fechaUltimaMenstruacion.toIso8601String()),
        ex.DateCellValue(
          year: paciente.fechaUltimaMenstruacion?.year ?? 0,
          month: paciente.fechaUltimaMenstruacion?.month ?? 0,
          day: paciente.fechaUltimaMenstruacion?.day ?? 0,
        ),
        ex.IntCellValue(paciente.semanasGestacion ?? 0),
        // ex.TextCellValue(paciente.fechaProbableParto.toIso8601String()),
        ex.DateCellValue(
          year: paciente.fechaProbableParto?.year ?? 0,
          month: paciente.fechaProbableParto?.month ?? 0,
          day: paciente.fechaProbableParto?.day ?? 0,
        ),
        ex.IntCellValue(paciente.numeroGestaciones ?? 0),
        ex.IntCellValue(paciente.numeroPartosVaginales ?? 0),
        ex.IntCellValue(paciente.numeroCesareas ?? 0),
        ex.IntCellValue(paciente.abortos ?? 0),
        ex.BoolCellValue(paciente.embarazoMultiple ?? false ? true : false),
        ex.DoubleCellValue(paciente.coordenadas?.latitude ?? 0),
        ex.DoubleCellValue(paciente.coordenadas?.longitude ?? 0),
      ]);
    }

    Directory directory = await getApplicationDocumentsDirectory();
    String path = '${directory.path}/Pacientes.xlsx';
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Exportacion completada: $path')));
  }

  //-----------------------------------------
  // Método para mostrar los botones de edición y eliminación
  void _showEditDeleteButtons(int index) {
    // Crea los botones
    final editButton = FloatingActionButton(
      heroTag: 'editButton',
      onPressed: () {
        // Navega a la página de edición con los datos del paciente seleccionado
        // ... (Implementa tu lógica de navegación)
      },
      child: const Icon(Icons.edit),
    );

    final deleteButton = FloatingActionButton(
      heroTag: 'deleteButton',
      onPressed: () {
        // Muestra un cuadro de diálogo de confirmación antes de eliminar
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Eliminar Paciente'),
              content: const Text('¿Estás seguro de que quieres eliminar este paciente?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    // Elimina el paciente de Firestore
                    // ... (Implementa tu lógica de eliminación)
                    Navigator.of(context).pop();
                  },
                  child: const Text('Eliminar'),
                ),
              ],
            );
          },
        );
      },
      child: const Icon(Icons.delete),
    );

    // Posiciona los botones debajo de la fila seleccionada
    setState(() {
      // Usa la propiedad showOverlay de SfDataGrid
      showOverlay = true;
    });
  }

  // Método para ocultar los botones de edición y eliminación
  void _hideEditDeleteButtons() {
    setState(() {
      // Usa la propiedad showOverlay de SfDataGrid
      showOverlay = false;
    });
  }

  // Variable para controlar la visibilidad del overlay
  bool showOverlay = false;
  //-----------------------------------------
  List<bool> groupFilters = [false, false, false, false];
  agrupar(bool estado, String campo) {
    if (estado) {
      userDataGridSource.addColumnGroup(ColumnGroup(name: campo, sortGroupRows: true));
    } else {
      ColumnGroup? group = userDataGridSource.groupedColumns.firstWhere(
        (element) => element.name == campo,
      );
      userDataGridSource.removeColumnGroup(group);
      // grupoDataSource.clearColumnGroups();
    }
  }

  //-----------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Pacientes')),
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            smallView ? _buildSearchField() : const SizedBox(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                !smallView
                    ? ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: smallView ? size.width : 400),
                      child: _buildSearchField(),
                    )
                    : const SizedBox(),
                smallView ? const SizedBox() : const SizedBox(width: 10.0),
                // _buildFilterRow(),
                // Row(children: filterRows),
                /* !smallView ? _buildSelectedChips() : const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      selectedRole = 'Todos';
                      selectedStatus = 'Todos';
                      _filterPacientes();
                    });
                  },
                ), */
                SizedBox(
                  height: 60,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: smallView ? size.width * 0.92 : 400,
                        child: Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          // crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('Agrupar:'),
                            const SizedBox(width: 10),
                            ChoiceChip(
                              onSelected: (a) {
                                setState(() {
                                  groupFilters[0] = a;
                                  agrupar(groupFilters[0], 'nacionalidad');
                                });
                              },
                              labelPadding: EdgeInsets.all(0),
                              visualDensity: VisualDensity(
                                horizontal: VisualDensity.minimumDensity,
                                vertical: VisualDensity.minimumDensity,
                              ),
                              selected: groupFilters[0],
                              label: const Text('Nacionalidad'),
                            ),
                            const SizedBox(width: 10),
                            ChoiceChip(
                              onSelected: (a) {
                                setState(() {
                                  groupFilters[1] = a;
                                  agrupar(groupFilters[1], 'grupoSanguineo');
                                });
                              },
                              visualDensity: VisualDensity(
                                horizontal: VisualDensity.minimumDensity,
                                vertical: VisualDensity.minimumDensity,
                              ),
                              selected: groupFilters[1],
                              label: const Text('Grupo Sanguineo'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            smallView ? _buildSelectedChips() : const SizedBox(width: 8.0),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const Text('Numero de pacientes: '),
                  Text(
                    '${filteredPacientes.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SfDataGrid(
                // allowSwiping: true,
                allowFiltering: true,
                allowSorting: true,
                allowMultiColumnSorting: true,
                allowExpandCollapseGroup: true,
                navigationMode: GridNavigationMode.cell,
                gridLinesVisibility: GridLinesVisibility.horizontal,
                headerGridLinesVisibility: GridLinesVisibility.horizontal,
                source: userDataGridSource,
                selectionMode: SelectionMode.single,
                columnWidthMode: ColumnWidthMode.auto,
                controller: dataGridController,
                groupCaptionTitleFormat: '{ColumnName} : {Key} - {ItemsCount} Item(s)',
                onSelectionChanged: (List<DataGridRow> addedRows, List<DataGridRow> removedRows) {
                  if (kDebugMode) {
                    print([addedRows.length, removedRows.length]);
                  }
                  if (addedRows.isNotEmpty) {
                    final index = userDataGridSource.rows.indexOf(addedRows.first);
                    if (kDebugMode) {
                      print(
                        'Selected user: ${userDataGridSource.dataGridRows[index].getCells()[0].value}',
                      );
                    }
                    // Show the edit/delete buttons when a row is selected
                    _showEditDeleteButtons(index);
                  } else {
                    // Hide the buttons when no row is selected
                    _hideEditDeleteButtons();
                  }
                },
                onSwipeStart: (details) {
                  if (details.swipeDirection == DataGridRowSwipeDirection.startToEnd) {
                    details.setSwipeMaxOffset(150);
                  } else if (details.swipeDirection == DataGridRowSwipeDirection.endToStart) {
                    details.setSwipeMaxOffset(0);
                  }
                  return true;
                },
                columns: <GridColumn>[
                  GridColumn(
                    columnName: 'nombre',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Nombre'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'fechaNacimiento',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Fecha de Nacimiento'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'nacionalidad',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Nacionalidad'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'documentoIdentidad',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Documento'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'direccion',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Direccion'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'telefono',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Telefono'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'email',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Email'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'grupoSanguineo',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Grupo Sanguíneo'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'factorRH',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Factor RH'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'alergias',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Alergias'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'enfermedadesPreexistentes',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Enfermedades Preexistentes'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'medicamentos',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Medicamentos'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'fechaUltimaMenstruacion',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Fecha Última Menstruacion'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'semanasGestacion',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Semanas de Gestacion'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'fechaProbableParto',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Fecha Probable de Parto'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'numeroGestaciones',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Número de Gestaciones'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'numeroPartosVaginales',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Número de Partos Vaginales'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'numeroCesareas',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Número de Cesáreas'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'numeroAbortos',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Número de Abortos'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'embarazoMultiple',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Embarazo Múltiple'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                  GridColumn(
                    columnName: 'coordenadas',
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: const Text('Coordenadas'),
                    ),
                    autoFitPadding:
                        smallView
                            ? const EdgeInsets.symmetric(horizontal: 10.0)
                            : const EdgeInsets.symmetric(horizontal: 32.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: SpeedDial(
        // animatedIcon: AnimatedIcons.menu_close,
        // animatedIconTheme: IconThemeData(size: 22.0),
        // / This is ignored if animatedIcon is non null
        // child: Text("open"),
        // activeChild: Text("close"),
        icon: Icons.add,
        activeIcon: Icons.close,
        spacing: 3,
        mini: false,
        // openCloseDial: isDialOpen,
        childPadding: const EdgeInsets.all(5),
        spaceBetweenChildren: 4,
        dialRoot: (ctx, open, toggleChildren) {
          return FloatingActionButton(
            // backgroundColor: secondary,
            // shape: const CircleBorder(),
            heroTag: null,
            onPressed: toggleChildren,
            child: const Icon(Icons.menu),
          );
        },
        buttonSize: const Size(56.0, 56.0), // it's the SpeedDial size which defaults to 56 itself
        // iconTheme: IconThemeData(size: 22),
        label: const Text("Open"), // The label of the main button.
        /// The active label of the main button, Defaults to label if not specified.
        activeLabel: const Text("Close"),

        /// Transition Builder between label and activeLabel, defaults to FadeTransition.
        // labelTransitionBuilder: (widget, animation) => ScaleTransition(scale: animation,child: widget),
        /// The below button size defaults to 56 itself, its the SpeedDial childrens size
        childrenButtonSize: const Size(56.0, 56.0),
        visible: true,
        direction: SpeedDialDirection.up,
        switchLabelPosition: false,

        /// If true user is forced to close dial manually
        closeManually: false,

        /// If false, backgroundOverlay will not be rendered.
        renderOverlay: true,
        // overlayColor: Colors.black,
        // overlayOpacity: 0.5,
        onOpen: () => debugPrint('OPENING DIAL'),
        onClose: () => debugPrint('DIAL CLOSED'),
        useRotationAnimation: true,
        tooltip: 'Open Speed Dial',
        heroTag: 'speed-dial-hero-tag',
        // foregroundColor: Colors.black,
        // backgroundColor: Colors.white,
        // activeForegroundColor: Colors.red,
        // activeBackgroundColor: Colors.blue,
        elevation: 8.0,
        animationCurve: Curves.elasticInOut,
        isOpenOnStart: false,
        shape: const RoundedRectangleBorder(), //const StadiumBorder(),
        // childMargin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add_box_outlined),
            // backgroundColor: Colors.green,
            // foregroundColor: Colors.white,
            label: 'Añadir paciente',
            onTap: () {
              // Navigate to the CrearPaciente page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NuevoPaciente()),
              );
            },
            // onLongPress: () => debugPrint('Actualiza Horarios'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.dataset_outlined),
            backgroundColor: Colors.green,
            // foregroundColor: Colors.white,
            label: 'Añadir pacientes\nde forma masiva',
            onTap: () async {
              setState(() {
                loadSpreadsheet();
              });
            },
          ),
        ],
      ),
    );
  }
}

class UserDataGridSource extends DataGridSource {
  UserDataGridSource(List<Paciente> pacientes) {
    updateDataGridRows(pacientes);
  }

  List<DataGridRow> dataGridRows = [];

  void updateDataGridRows(List<Paciente> pacientes) {
    dataGridRows =
        pacientes
            .map<DataGridRow>(
              (paciente) => DataGridRow(
                cells: [
                  DataGridCell<String>(columnName: 'nombre', value: paciente.nombre),
                  DataGridCell<DateTime>(
                    columnName: 'fechaNacimiento',
                    value: paciente.fechaNacimiento,
                  ),
                  DataGridCell<String>(columnName: 'nacionalidad', value: paciente.nacionalidad),
                  DataGridCell<String>(
                    columnName: 'documentoIdentidad',
                    value: paciente.documentoIdentidad,
                  ),
                  DataGridCell<String>(columnName: 'direccion', value: paciente.direccion),
                  DataGridCell<String>(columnName: 'telefono', value: paciente.telefono),
                  DataGridCell<String>(columnName: 'email', value: paciente.email ?? ''),
                  DataGridCell<String>(
                    columnName: 'grupoSanguineo',
                    value: paciente.grupoSanguineo,
                  ),
                  DataGridCell<String>(columnName: 'factorRH', value: paciente.factorRH),
                  DataGridCell<String>(
                    columnName: 'alergias',
                    value: paciente.alergias?.join(', ') ?? '',
                  ),
                  DataGridCell<String>(
                    columnName: 'enfermedadesPreexistentes',
                    value: paciente.enfermedadesPreexistentes?.join(', ') ?? '',
                  ),
                  DataGridCell<String>(
                    columnName: 'medicamentos',
                    value: paciente.medicamentos?.join(', ') ?? '',
                  ),
                  DataGridCell<DateTime>(
                    columnName: 'fechaUltimaMenstruacion',
                    value: paciente.fechaUltimaMenstruacion,
                  ),
                  DataGridCell<int>(
                    columnName: 'semanasGestacion',
                    value: paciente.semanasGestacion,
                  ),
                  DataGridCell<DateTime>(
                    columnName: 'fechaProbableParto',
                    value: paciente.fechaProbableParto,
                  ),
                  DataGridCell<int>(
                    columnName: 'numeroGestaciones',
                    value: paciente.numeroGestaciones,
                  ),
                  DataGridCell<int>(
                    columnName: 'numeroPartosVaginales',
                    value: paciente.numeroPartosVaginales,
                  ),
                  DataGridCell<int>(columnName: 'numeroCesareas', value: paciente.numeroCesareas),
                  DataGridCell<int>(columnName: 'numeroAbortos', value: paciente.abortos),
                  DataGridCell<bool>(
                    columnName: 'embarazoMultiple',
                    value: paciente.embarazoMultiple,
                  ),
                  DataGridCell<String>(
                    columnName: 'coordenadas',
                    value: '${paciente.coordenadas?.latitude}, ${paciente.coordenadas?.longitude}',
                  ),
                ],
              ),
            )
            .toList();
    notifyListeners();
  }

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells:
          row.getCells().map<Widget>((cell) {
            return Container(
              alignment: Alignment.center,
              child:
                  cell.columnName == 'status'
                      ? Chip(label: Text(cell.value), backgroundColor: _getStatusColor(cell.value))
                      : Text(cell.value.toString()),
            );
          }).toList(),
    );
  }
} */
