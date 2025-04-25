// modifica este codigo para que tambien se pueda cargar un paciente existente y editarlo
// ignore_for_file: must_be_immutable
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../models/datos.dart';
import '../../../models/modelos.dart';

class NuevoPaciente extends StatefulWidget {
  const NuevoPaciente({super.key});

  @override
  NuevoPacienteState createState() => NuevoPacienteState();
}

class NuevoPacienteState extends State<NuevoPaciente> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _nacionalidadController = TextEditingController();
  final _documentoIdentidadController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _grupoSanguineoController = TextEditingController();
  final _factorRHController = TextEditingController();
  final _alergiasController = TextEditingController();
  final _enfermedadesPreexistentesController = TextEditingController();
  final _medicamentosController = TextEditingController();
  final _fechaUltimaMenstruacionController = TextEditingController();
  final _semanasGestacionController = TextEditingController();
  final _fechaProbablePartoController = TextEditingController();
  final _numeroGestacionesController = TextEditingController();
  final _numeroPartosVaginalesController = TextEditingController();
  final _numeroCesareasController = TextEditingController();
  final _numeroAbortosController = TextEditingController();
  final _embarazoMultipleController = TextEditingController();
  final _coordenadasController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _fechaNacimientoController.dispose();
    _nacionalidadController.dispose();
    _documentoIdentidadController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _grupoSanguineoController.dispose();
    _factorRHController.dispose();
    _alergiasController.dispose();
    _enfermedadesPreexistentesController.dispose();
    _medicamentosController.dispose();
    _fechaUltimaMenstruacionController.dispose();
    _semanasGestacionController.dispose();
    _fechaProbablePartoController.dispose();
    _numeroGestacionesController.dispose();
    _numeroPartosVaginalesController.dispose();
    _numeroCesareasController.dispose();
    _numeroAbortosController.dispose();
    _embarazoMultipleController.dispose();
    _coordenadasController.dispose();
    super.dispose();
  }

  Future<void> _guardarPaciente() async {
    if (_formKey.currentState!.validate()) {
      // Aquí va la lógica para guardar el paciente
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Paciente')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: constraints.maxWidth > 600 ? _buildTabletLayout() : _buildPhoneLayout(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionTitle('Información Básica'),
        Wrap(
          children: <Widget>[
            _buildTextFormField('Nombre', _nombreController, TextInputType.text),
            _buildTextFormField(
              'Fecha de Nacimiento',
              _fechaNacimientoController,
              TextInputType.datetime,
              isDate: true,
            ),
            _buildTextFormField('Nacionalidad', _nacionalidadController, TextInputType.text),
            _buildTextFormField(
              'Documento de Identidad',
              _documentoIdentidadController,
              TextInputType.text,
              isDocumentId: true,
              mask: '###########',
            ),
          ],
        ),
        _buildSectionTitle('Contacto'),
        Wrap(
          children: <Widget>[
            _buildTextFormField('Dirección', _direccionController, TextInputType.text),
            _buildTextFormField(
              'Teléfono',
              _telefonoController,
              TextInputType.phone,
              isPhoneNumber: true,
              mask: "(###) ### ## ##",
            ),
            _buildTextFormField(
              'Email',
              _emailController,
              TextInputType.emailAddress,
              width: 500,
              isEmail: true,
            ),
          ],
        ),
        _buildSectionTitle('Información Médica'),
        Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: (size.width * 0.5) - 35,
                child: AutocompleteInputText(data: alergias, labelText: 'Alergias'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: (size.width * 0.5) - 35,
                child: AutocompleteInputText(
                  data: enfermedadesPreexistentes,
                  labelText: 'Enfermedades Preexistentes',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: (size.width * 0.5) - 35,
                child: AutocompleteInputText(
                  data: medicamentosDuranteEmbarazo,
                  labelText: 'Medicamentos',
                ),
              ),
            ),
            _buildTextFormField(
              'Fecha Última Menstruación',
              _fechaUltimaMenstruacionController,
              TextInputType.datetime,
              isDate: true,
            ),
            _buildTextFormField(
              'Fecha Probable de Parto',
              _fechaProbablePartoController,
              TextInputType.datetime,
              isDate: true,
            ),
            _buildTextFormField(
              'Grupo Sanguíneo',
              _grupoSanguineoController,
              TextInputType.text,
              width: 250,
            ),
            _buildTextFormField('Factor RH', _factorRHController, TextInputType.text, width: 250),
            _buildTextFormField(
              'Semanas de Gestación',
              _semanasGestacionController,
              TextInputType.number,
              width: 250,
            ),
            _buildTextFormField(
              'Número de Gestaciones',
              _numeroGestacionesController,
              TextInputType.number,
              width: 250,
            ),
            _buildTextFormField(
              'Número de Partos Vaginales',
              _numeroPartosVaginalesController,
              TextInputType.number,
              width: 250,
            ),
            _buildTextFormField(
              'Número de Cesáreas',
              _numeroCesareasController,
              TextInputType.number,
              width: 250,
            ),
            _buildTextFormField(
              'Número de Abortos',
              _numeroAbortosController,
              TextInputType.number,
              width: 250,
            ),
            _buildTextFormField(
              'Embarazo Múltiple (true/false)',
              _embarazoMultipleController,
              TextInputType.text,
              isBoolean: true,
              width: 250,
            ),
            _buildTextFormField(
              'Coordenadas (latitud, longitud)',
              _coordenadasController,
              TextInputType.text,
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildPhoneLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionTitle('Información Básica'),
        _buildTextFormField('Nombre', _nombreController, TextInputType.text),
        _buildTextFormField(
          'Fecha de Nacimiento',
          _fechaNacimientoController,
          TextInputType.datetime,
          isDate: true,
        ),
        _buildTextFormField('Nacionalidad', _nacionalidadController, TextInputType.text),
        _buildTextFormField(
          'Documento de Identidad',
          _documentoIdentidadController,
          TextInputType.text,
          isDocumentId: true,
          mask: '###########',
        ),
        _buildSectionTitle('Contacto'),
        _buildTextFormField('Dirección', _direccionController, TextInputType.text),
        _buildTextFormField(
          'Teléfono',
          _telefonoController,
          TextInputType.phone,
          isPhoneNumber: true,
          mask: "(###) ### ## ##",
        ),
        _buildTextFormField('Email', _emailController, TextInputType.emailAddress, isEmail: true),
        _buildSectionTitle('Información Médica'),
        Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: size.width,
                child: AutocompleteInputText(data: alergias, labelText: 'Alergias'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: size.width,
                child: AutocompleteInputText(
                  data: enfermedadesPreexistentes,
                  labelText: 'Enfermedades Preexistentes',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: size.width,
                child: AutocompleteInputText(
                  data: medicamentosDuranteEmbarazo,
                  labelText: 'Medicamentos',
                ),
              ),
            ),
          ],
        ),
        _buildTextFormField(
          'Fecha Última Menstruación',
          _fechaUltimaMenstruacionController,
          TextInputType.datetime,
          isDate: true,
        ),
        _buildTextFormField(
          'Fecha Probable de Parto',
          _fechaProbablePartoController,
          TextInputType.datetime,
          isDate: true,
        ),
        _buildTextFormField('Grupo Sanguíneo', _grupoSanguineoController, TextInputType.text),
        _buildTextFormField('Factor RH', _factorRHController, TextInputType.text),
        _buildTextFormField(
          'Semanas de Gestación',
          _semanasGestacionController,
          TextInputType.number,
        ),
        _buildTextFormField(
          'Número de Gestaciones',
          _numeroGestacionesController,
          TextInputType.number,
        ),
        _buildTextFormField(
          'Número de Partos Vaginales',
          _numeroPartosVaginalesController,
          TextInputType.number,
        ),
        _buildTextFormField('Número de Cesáreas', _numeroCesareasController, TextInputType.number),
        _buildTextFormField('Número de Abortos', _numeroAbortosController, TextInputType.number),
        _buildTextFormField(
          'Embarazo Múltiple (true/false)',
          _embarazoMultipleController,
          TextInputType.text,
          isBoolean: true,
        ),
        _buildTextFormField(
          'Coordenadas (latitud, longitud)',
          _coordenadasController,
          TextInputType.text,
        ),
        const SizedBox(height: 16.0),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
    );
  }

  /* Widget _buildTextFormField(
      String label, TextEditingController controller, TextInputType keyboardType,
      [double? width]) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: smallView ? size.width : width ?? 350.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          keyboardType: keyboardType,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese $label'.toLowerCase();
            }
            return null;
          },
        ),
      ),
    );
  } */

  Widget _buildTextFormField(
    String label,
    TextEditingController controller,
    TextInputType keyboardType, {
    double? width,
    bool isDate = false,
    bool isPhoneNumber = false,
    bool isDocumentId = false,
    bool isEmail = false,
    String? mask,
    bool isBoolean = false, // Agrega la opción para boolean
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: smallView ? MediaQuery.of(context).size.width : width ?? 350.0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          keyboardType: keyboardType,
          inputFormatters: [
            // Si el tipo de teclado es TextInputType.number, filtra el input
            if (keyboardType == TextInputType.number)
              FilteringTextInputFormatter.digitsOnly
            // Si hay una máscara, aplica la máscara
            else if (mask != null)
              MaskTextInputFormatter(mask: mask)
            // Caso base para otros tipos de teclado, sin filtros
            else
              FilteringTextInputFormatter.allow(
                RegExp('[a-zA-Z0-9 ]'),
              ), // Permite letras, números y espacios
          ],
          onTap:
              isDate
                  ? () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    controller.text =
                        "${pickedDate!.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                  }
                  : isBoolean
                  ? () {
                    // Muestra un diálogo para seleccionar el valor booleano
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Seleccionar valor'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('True'),
                                  onTap: () {
                                    controller.text = 'true';
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  title: const Text('False'),
                                  onTap: () {
                                    controller.text = 'false';
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                    );
                  }
                  : null, // Maneja el caso para boolean
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese $label'.toLowerCase();
            }
            // Validaciones adicionales según el tipo de campo
            if (isPhoneNumber && value.length < 15) {
              return 'Ingrese un número de teléfono válido';
            }
            if (isDocumentId && !RegExp(r'^\d{7,11}$').hasMatch(value)) {
              return 'Ingrese un documento de identidad válido';
            }
            if (isEmail &&
                !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
              return 'Ingrese un email válido';
            }
            if (isBoolean && !['true', 'false'].contains(value.toLowerCase())) {
              return 'Ingrese un valor booleano válido (true o false)';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: ElevatedButton(onPressed: _guardarPaciente, child: const Text('Guardar Paciente')),
    );
  }
}

class AutocompleteInputText extends StatefulWidget {
  List<String> data;
  final String labelText;
  AutocompleteInputText({required this.data, required this.labelText, super.key});

  @override
  AutocompleteInputTextState createState() => AutocompleteInputTextState();
}

class AutocompleteInputTextState extends State<AutocompleteInputText> {
  List<String> _filtereddata = [];
  final List<String> _selecteddata = [];

  TextEditingController _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtereddata = widget.data;
  }

  void _filterdata(String query) {
    setState(() {
      _filtereddata =
          widget.data
              .where((alergia) => alergia.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  void _addAlergia(String alergia) {
    setState(() {
      if (!_selecteddata.contains(alergia)) {
        _selecteddata.add(alergia);
      }
    });
  }

  void _removeAlergia(String alergia) {
    setState(() {
      _selecteddata.remove(alergia);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      // Agregamos LayoutBuilder
      builder: (BuildContext context, BoxConstraints constraints) {
        return Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return _filtereddata.where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            _addAlergia(selection);
            _textFieldController.clear(); // Limpiar el TextField
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            _textFieldController = fieldTextEditingController; // Asignar el controlador
            return TextField(
              controller: _textFieldController,
              focusNode: focusNode,
              onChanged: (value) {
                _filterdata(value);
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: widget.labelText,
                border: const OutlineInputBorder(),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(10.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: smallView ? size.width * 0.5 : 500),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children:
                          _selecteddata
                              .map(
                                (alergia) => Chip(
                                  label: Text(alergia),
                                  onDeleted: () {
                                    _removeAlergia(alergia);
                                  },
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ),
                suffixIcon:
                    _textFieldController.text.isNotEmpty &&
                            !_filtereddata.contains(_textFieldController.text)
                        ? IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (_textFieldController.text.isNotEmpty &&
                                !_filtereddata.contains(_textFieldController.text)) {
                              _addAlergia(_textFieldController.text);
                              _textFieldController.clear(); // Limpiar el TextField
                            }
                          },
                        )
                        : null,
              ),
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<String> onSelected,
            Iterable<String> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200.0),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return GestureDetector(
                        onTap: () {
                          onSelected(option);
                        },
                        child: ListTile(title: Text(option)),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
