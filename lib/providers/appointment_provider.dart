import 'package:flutter/foundation.dart';
import '../models/modelos.dart';

/// Proveedor de estado para gestionar citas y médicos (usuarios con rol doctor).
class AppointmentProvider with ChangeNotifier {
  // --- Gestión de Citas ---
  final List<Cita> _citas = [];
  List<Cita> get citas => List.unmodifiable(_citas);

  /// Agrega una nueva cita.
  void agregarCita(Cita cita) {
    _citas.add(cita);
    notifyListeners();
  }

  /// Edita una cita existente, buscando por su ID.
  void editarCita(Cita citaActualizada) {
    final index = _citas.indexWhere((c) => c.id == citaActualizada.id);
    if (index != -1) {
      _citas[index] = citaActualizada;
      if (kDebugMode) print('Cita actualizada: ${_citas[index].toJson()}');
      notifyListeners();
    } else if (kDebugMode) {
      print('Error: No se encontró la cita con id ${citaActualizada.id}');
    }
  }

  /// Elimina una cita según su ID.
  void eliminarCita(String id) {
    _citas.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// Obtiene todas las citas de un paciente.
  List<Cita> getCitasPorPaciente(String pacienteId) =>
      _citas.where((c) => c.pacienteId == pacienteId).toList();

  /// Obtiene todas las citas de un doctor.
  List<Cita> getCitasPorDoctor(String doctorId) =>
      _citas.where((c) => c.doctorId == doctorId).toList();

  // --- Gestión de Médicos (Usuarios con rol doctor) ---
  final List<Usuario> _medicos = [];
  List<Usuario> get medicos => _medicos.where((u) => u.roles.contains(UserRole.doctor)).toList();

  /// Agrega un usuario que sea doctor.
  void agregarMedico(Usuario usuario) {
    if (usuario.roles.contains(UserRole.doctor)) {
      _medicos.add(usuario);
      notifyListeners();
    } else if (kDebugMode) {
      print('Usuario ${usuario.uid} no tiene rol doctor.');
    }
  }

  /// Edita datos de un doctor existente, buscando por UID.
  void editarMedico(Usuario usuarioActualizado) {
    final index = _medicos.indexWhere((u) => u.uid == usuarioActualizado.uid);
    if (index != -1) {
      _medicos[index] = usuarioActualizado;
      notifyListeners();
    } else if (kDebugMode) {
      print('Error: No se encontró el doctor con uid ${usuarioActualizado.uid}');
    }
  }

  /// Elimina un doctor según su UID.
  void eliminarMedico(String uid) {
    _medicos.removeWhere((u) => u.uid == uid);
    notifyListeners();
  }
}

/* import 'package:flutter/foundation.dart';
import '../models/modelos.dart';

class AppointmentProvider with ChangeNotifier {
  // Lista privada de citas. El guion bajo indica que es privada.
  final List<Cita> _citas = [];

  // Getter público para acceder a la lista de citas de forma segura (solo lectura).
  List<Cita> get citas => _citas; // Devuelve una copia o una vista inmutable si prefieres

  // Método para añadir una nueva cita a la lista.
  void agregarCita(Cita cita) {
    // Añade la nueva cita a la lista interna.
    _citas.add(cita);
    // Notifica a los 'listeners' (widgets que escuchan) que el estado ha cambiado.
    notifyListeners();
  }

  // Método para editar una cita existente.
  void editarCita(Cita citaActualizada) {
    // Busca el índice de la cita que tenga el mismo ID que la cita actualizada.
    final indice = _citas.indexWhere((c) => c.id == citaActualizada.id);
    // Si se encontró la cita (el índice no es -1).
    if (indice != -1) {
      // Reemplaza la cita antigua en esa posición con la cita actualizada.
      _citas[indice] = citaActualizada;
      // Imprime en consola (solo en modo debug) la cita que se está actualizando.
      // Usa el método aJson() de la clase Cita traducida.
      if (kDebugMode) {
        print('Actualizando cita: ${_citas[indice].toJson()}');
      }
      // Notifica a los listeners sobre el cambio.
      notifyListeners();
    } else {
      // Opcional: Manejar el caso en que la cita a editar no se encuentre.
      if (kDebugMode) {
        print('Error: No se encontró la cita con id ${citaActualizada.id} para editar.');
      }
    }
  }

  // Método para eliminar una cita usando su ID.
  void eliminarCita(String id) {
    // Elimina de la lista todas las citas cuyo ID coincida con el ID proporcionado.
    _citas.removeWhere((cita) => cita.id == id);
    // Notifica a los listeners sobre el cambio.
    notifyListeners();
  }

  // --- Gestión de Médicos (Asumiendo que tienes una clase Medico) ---

  // Lista privada de médicos.
  final List<Doctor> _medicos = [];

  // Getter público para la lista de médicos.
  List<Doctor> get medicos => _medicos;

  // Método para añadir un nuevo médico.
  void agregarMedico(Doctor medico) {
    _medicos.add(medico);
    notifyListeners();
  }

  // Añade métodos para editarMedico, eliminarMedico si los necesitas.
  // void editarMedico(Medico medicoActualizado) { ... }
  // void eliminarMedico(String id) { ... }
} */
