// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';

class AutocompleteInputText extends StatefulWidget {
  List<String> data;
  final String labelText;
  AutocompleteInputText({
    required this.data,
    required this.labelText,
    super.key,
  });

  @override
  AutocompleteInputTextState createState() => AutocompleteInputTextState();
}

class AutocompleteInputTextState extends State<AutocompleteInputText> {
  List<String> data = [
    'Maní',
    'Nueces de árbol',
    'Mariscos',
    'Pescado',
    'Leche',
    'Huevos',
    'Soya',
    'Trigo',
    'Frutas',
    'Legumbres',
    'Polvo',
    'Ácaros del polvo',
    'Polen',
    'Moho',
    'Caspa de animales',
    'Penicilina',
    'AINEs',
    'Medicamentos anticonvulsivos',
    'Vacunas y sueros',
    'Níquel',
    'Látex',
    'Fragancias',
    'Conservantes',
    'Detergentes',
    'Tintes para el cabello',
    'Productos para la piel',
    'Veneno de insectos',
    'Esporas de hongos'
  ];

  List<String> _filtereddata = [];
  final List<String> _selecteddata = [];

  TextEditingController _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtereddata = data;
  }

  void _filterdata(String query) {
    setState(() {
      _filtereddata =
          data.where((alergia) => alergia.toLowerCase().contains(query.toLowerCase())).toList();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('data Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Autocomplete<String>(
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
              fieldViewBuilder: (BuildContext context,
                  TextEditingController fieldTextEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted) {
                _textFieldController = fieldTextEditingController; // Asignar el controlador
                return TextField(
                  controller: _textFieldController,
                  focusNode: focusNode,
                  onChanged: (value) {
                    _filterdata(value);
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'data',
                    border: const OutlineInputBorder(),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Wrap(
                        spacing: 8.0,
                        children: _selecteddata
                            .map((alergia) => Chip(
                                  label: Text(alergia),
                                  onDeleted: () {
                                    _removeAlergia(alergia);
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                    suffixIcon: _textFieldController.text.isNotEmpty &&
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
              optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options) {
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
                            child: ListTile(
                              title: Text(option),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
