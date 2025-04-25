import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/modelos.dart';
import '../../../services/firestore_service.dart';

class RecomendacionFormScreen extends StatefulWidget {
  final String pacienteId;
  const RecomendacionFormScreen({required this.pacienteId, super.key});

  @override
  State<RecomendacionFormScreen> createState() => _RecomendacionFormScreenState();
}

class _RecomendacionFormScreenState extends State<RecomendacionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  TipoRecomendacion _selectedTipo = TipoRecomendacion.general;
  final _descripcionCtrl = TextEditingController();
  final _medNameCtrl = TextEditingController();
  final _dosisCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  final _durCtrl = TextEditingController();
  final _tratCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _medNameCtrl.dispose();
    _dosisCtrl.dispose();
    _freqCtrl.dispose();
    _durCtrl.dispose();
    _tratCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);

    final rec = Recomendacion(
      pacienteId: widget.pacienteId,
      doctorId: FirebaseAuth.instance.currentUser?.uid ?? '',
      timestamp: DateTime.now(),
      tipo: _selectedTipo,
      descripcion: _descripcionCtrl.text.trim(),
      medicamentoNombre:
          _selectedTipo == TipoRecomendacion.medicamento ? _medNameCtrl.text.trim() : null,
      dosis: _selectedTipo == TipoRecomendacion.medicamento ? _dosisCtrl.text.trim() : null,
      frecuencia: _selectedTipo == TipoRecomendacion.medicamento ? _freqCtrl.text.trim() : null,
      duracion: _selectedTipo == TipoRecomendacion.medicamento ? _durCtrl.text.trim() : null,
      detallesTratamiento:
          _selectedTipo == TipoRecomendacion.tratamiento ? _tratCtrl.text.trim() : null,
    );

    try {
      await FirestoreService().saveRecomendacion(widget.pacienteId, rec);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recomendación guardada'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir Recomendación')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<TipoRecomendacion>(
                value: _selectedTipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo *',
                  border: OutlineInputBorder(),
                ),
                items:
                    TipoRecomendacion.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.name[0].toUpperCase() + t.name.substring(1)),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _selectedTipo = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa descripción' : null,
              ),
              const SizedBox(height: 12),
              if (_selectedTipo == TipoRecomendacion.medicamento) ...[
                TextFormField(
                  controller: _medNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Medicamento *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dosisCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dosis *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _freqCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Frecuencia *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _durCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Duración',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (_selectedTipo == TipoRecomendacion.tratamiento) ...[
                TextFormField(
                  controller: _tratCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Detalles Tratamiento',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                child: Text(_isSaving ? 'Guardando...' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
