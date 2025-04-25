// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

late Size size;
MediaQueryData? mediaQueryData;
TextScaler? scale;

bool login = false;
bool smallView = false;
bool mediumView = false;
bool largeView = false;

getSizeView(BuildContext context) {
  size = MediaQuery.of(context).size;
  mediaQueryData = MediaQuery.of(context);
  scale = mediaQueryData!.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.09);
  smallView = size.width < 450;
  mediumView = ((size.width > 450) && (size.width < 850));
  largeView = size.width > 850;
  if (kDebugMode) {
    print(['Main', 'size.width', size.width, 'size.height', size.height]);
  }
  if (kDebugMode) {
    print(['smallView', smallView, 'mediumView', mediumView, 'largeView', largeView]);
  }
}

//---------------
// Reutilizar el parser helper (asegúrate que esté accesible, copiado aquí por si acaso)
class FirestoreParser {
  static String? parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim().isEmpty ? null : value.trim();
    return value.toString();
  }

  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value.trim().replaceFirst(',', '.'));
    return null;
  }

  static bool? parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final l = value.trim().toLowerCase();
      if (l == 'true' || l == 'si' || l == '1') return true;
      if (l == 'false' || l == 'no' || l == '0') return false;
    }
    return null;
  }

  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value.trim());
    return null;
  }

  static GeoPoint? parseGeoPoint(dynamic value) {
    if (value is GeoPoint) return value;
    if (value is Map) {
      final lat = parseDouble(value['latitude']);
      final lon = parseDouble(value['longitude']);
      if (lat != null && lon != null) return GeoPoint(lat, lon);
    }
    return null;
  }

  static List<T>? parseList<T>(dynamic listData, T Function(dynamic) fromItem) {
    if (listData is List) {
      return listData
          .map((item) {
            try {
              return fromItem(item);
            } catch (e) {
              print("Error parseando item lista: $e");
              return null;
            }
          })
          .whereType<T>()
          .toList();
    }
    return null;
  }
}

// Enum para el tipo de recomendación
enum TipoRecomendacion {
  general, // Consejos, cuidados, etc.
  tratamiento, // Fisioterapia, procedimiento, etc.
  medicamento, // Prescripción farmacológica
  otro, // Si necesitas más categorías
}

class Recomendacion {
  final String? id; // ID del documento en Firestore (subcolección)
  final String pacienteId; // ID del paciente al que pertenece
  final String doctorId; // ID del doctor que la creó
  final DateTime timestamp; // Fecha y hora de creación
  final TipoRecomendacion tipo; // Tipo de recomendación
  final String descripcion; // Descripción general

  // Campos específicos para Medicamentos
  final String? medicamentoNombre;
  final String? dosis;
  final String? frecuencia;
  final String? duracion;

  // Campos específicos para Tratamientos (ejemplo)
  final String? detallesTratamiento;

  Recomendacion({
    this.id,
    required this.pacienteId,
    required this.doctorId,
    required this.timestamp,
    required this.tipo,
    required this.descripcion,
    this.medicamentoNombre,
    this.dosis,
    this.frecuencia,
    this.duracion,
    this.detallesTratamiento,
  }) {
    // Validaciones (opcional pero útil)
    if (tipo == TipoRecomendacion.medicamento &&
        (medicamentoNombre == null || dosis == null || frecuencia == null)) {
      // Podrías lanzar un error o solo imprimir una advertencia
      print("Advertencia: Recomendación 'medicamento' creada sin datos farmacológicos clave.");
    }
  }

  // --- Factory fromFirestore ---
  factory Recomendacion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Parsear el tipo desde el string guardado en Firestore
    TipoRecomendacion tipoParsed = TipoRecomendacion.general; // Default
    String? tipoString = FirestoreParser.parseString(data['tipo']);
    if (tipoString != null) {
      try {
        // Busca el enum cuyo nombre coincide con el string guardado
        tipoParsed = TipoRecomendacion.values.firstWhere(
          (e) => e.name == tipoString, // Comparar con enum.name
          orElse: () {
            print("TipoRecomendacion '$tipoString' no reconocido, usando 'general'.");
            return TipoRecomendacion.general;
          },
        );
      } catch (e) {
        print("Error parseando TipoRecomendacion: $tipoString - $e");
      }
    }

    return Recomendacion(
      id: doc.id,
      pacienteId:
          FirestoreParser.parseString(data['pacienteId']) ?? 'ID_PACIENTE_DESCONOCIDO', // Requerido
      doctorId:
          FirestoreParser.parseString(data['doctorId']) ?? 'ID_DOCTOR_DESCONOCIDO', // Requerido
      timestamp: FirestoreParser.parseDateTime(data['timestamp']) ?? DateTime.now(), // Requerido
      tipo: tipoParsed,
      descripcion:
          FirestoreParser.parseString(data['descripcion']) ?? 'Sin descripción', // Requerido
      medicamentoNombre: FirestoreParser.parseString(data['medicamentoNombre']),
      dosis: FirestoreParser.parseString(data['dosis']),
      frecuencia: FirestoreParser.parseString(data['frecuencia']),
      duracion: FirestoreParser.parseString(data['duracion']),
      detallesTratamiento: FirestoreParser.parseString(data['detallesTratamiento']),
    );
  }

  /// Factory para crear Recomendacion a partir de un JSON (Map)
  factory Recomendacion.fromJson(Map<String, dynamic> json) {
    // Parsear el tipo de recomendación desde su nombre
    final tipoParsed = TipoRecomendacion.values.firstWhere(
      (e) => e.name == (json['tipo'] as String),
      orElse: () => TipoRecomendacion.general,
    );

    return Recomendacion(
      id: json['id'] as String?,
      pacienteId: json['pacienteId'] as String,
      doctorId: json['doctorId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      tipo: tipoParsed,
      descripcion: json['descripcion'] as String,
      medicamentoNombre: json['medicamentoNombre'] as String?,
      dosis: json['dosis'] as String?,
      frecuencia: json['frecuencia'] as String?,
      duracion: json['duracion'] as String?,
      detallesTratamiento: json['detallesTratamiento'] as String?,
    );
  }

  /// Para serializar de vuelta a JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'pacienteId': pacienteId,
      'doctorId': doctorId,
      'timestamp': timestamp.toIso8601String(),
      'tipo': tipo.name,
      'descripcion': descripcion,
      if (medicamentoNombre != null) 'medicamentoNombre': medicamentoNombre,
      if (dosis != null) 'dosis': dosis,
      if (frecuencia != null) 'frecuencia': frecuencia,
      if (duracion != null) 'duracion': duracion,
      if (detallesTratamiento != null) 'detallesTratamiento': detallesTratamiento,
    };
  }

  // Helper para visualización rápida
  String get tipoDisplay => tipo.name[0].toUpperCase() + tipo.name.substring(1);
  String get timestampDisplay => DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
}

class Cita {
  final String? id;
  final String? titulo;
  final String nombrePaciente; // Podría ser mejor guardar pacienteId
  final DateTime fecha;
  // --- NUEVOS CAMPOS SUGERIDOS ---
  final String? pacienteId;
  final String? doctorId;

  Cita({
    this.id,
    this.titulo,
    required this.nombrePaciente, // Mantener por compatibilidad o quitar
    required this.fecha,
    this.pacienteId, // Añadir
    this.doctorId, // Añadir
  });

  // Método copyWith: Crea una nueva instancia de Cita copiando la actual,
  // pero permitiendo reemplazar algunos de sus valores.
  // Útil para crear objetos inmutables modificados.
  Cita copiarCon({String? id, String? titulo, String? nombrePaciente, DateTime? fecha}) {
    return Cita(
      // Si el nuevo 'id' es nulo, usa el 'id' de la instancia actual ('this.id')
      id: id ?? this.id,
      // Si el nuevo 'titulo' es nulo, usa el 'titulo' de la instancia actual
      titulo: titulo ?? this.titulo,
      // Si el nuevo 'nombrePaciente' es nulo, usa el 'nombrePaciente' de la instancia actual
      nombrePaciente: nombrePaciente ?? this.nombrePaciente,
      // Si la nueva 'fecha' es nula, usa la 'fecha' de la instancia actual
      fecha: fecha ?? this.fecha,
    );
  }

  // --- fromJson Actualizado ---
  factory Cita.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['fecha'] is Timestamp) {
      parsedDate = (json['fecha'] as Timestamp).toDate();
    } else if (json['fecha'] is String) {
      parsedDate = DateTime.tryParse(json['fecha']);
    }

    if (json['nombrePaciente'] == null || parsedDate == null) {
      throw FormatException("Los campos 'nombrePaciente' y 'fecha' (válida) son requeridos.");
    }

    return Cita(
      id: json['id'] as String?,
      titulo: json['titulo'] as String?,
      nombrePaciente: json['nombrePaciente'] as String,
      fecha: parsedDate,
      // Parsear nuevos campos
      pacienteId: json['pacienteId'] as String?,
      doctorId: json['doctorId'] as String?,
    );
  }

  // --- toJson Actualizado ---
  Map<String, dynamic> toJson() {
    return {
      // No incluir 'id' al crear/actualizar
      'titulo': titulo,
      'nombrePaciente': nombrePaciente, // Considera cambiar a pacienteId
      'fecha': Timestamp.fromDate(fecha), // GUARDAR COMO TIMESTAMP
      'pacienteId': pacienteId, // Guardar IDs
      'doctorId': doctorId,
    };
  }

  // --- Opcional: Métodos de igualdad y hashCode ---
  // Es buena práctica sobreescribirlos si vas a comparar instancias
  // o usarlas en colecciones como Set o Map.

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Cita &&
        other.id == id &&
        other.titulo == titulo &&
        other.nombrePaciente == nombrePaciente &&
        other.fecha == fecha;
  }

  @override
  int get hashCode {
    return id.hashCode ^ titulo.hashCode ^ nombrePaciente.hashCode ^ fecha.hashCode;
  }

  // --- Opcional: Método toString para representación legible ---
  @override
  String toString() {
    return 'Cita(id: $id, titulo: $titulo, nombrePaciente: $nombrePaciente, fecha: $fecha)';
  }
}

class Horario {
  String id;
  String diaSemana;
  String horaInicio;
  String horaFin;

  Horario({
    required this.id,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
  });

  // Método para convertir una instancia de Horario a un mapa (JSON)
  Map<String, dynamic> toJson() {
    return {'id': id, 'diaSemana': diaSemana, 'horaInicio': horaInicio, 'horaFin': horaFin};
  }

  // Método para crear una instancia de Horario a partir de un mapa (JSON)
  factory Horario.fromJson(Map<String, dynamic> json) {
    return Horario(
      id: json['id'],
      diaSemana: json['diaSemana'],
      horaInicio: json['horaInicio'],
      horaFin: json['horaFin'],
    );
  }
}

//------------------------
/// Definición de los roles disponibles en la aplicación.
enum UserRole { admin, doctor, paciente }

/// Clase que representa al usuario unificado con múltiples perfiles.
class Usuario {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final List<UserRole> roles;

  /// Perfiles opcionales, sólo presentes si el usuario tiene ese rol activo.
  final AdminProfile? adminProfile;
  final DoctorProfile? doctorProfile;
  final PacienteProfile? pacienteProfile;

  /// Entidades de negocio relacionadas
  final List<Recomendacion>? recomendacionesRecibidas;
  final List<Recomendacion>? recomendacionesEmitidas;
  final List<Cita>? citas;
  // final List<DatosClinicos>? datosClinicos;

  Usuario({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.roles,
    this.adminProfile,
    this.doctorProfile,
    this.pacienteProfile,
    this.recomendacionesRecibidas,
    this.recomendacionesEmitidas,
    this.citas,
    // this.datosClinicos,
  });

  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    if (kDebugMode) {
      print([data, doc.id]);
    }
    List<UserRole> roles = [];
    if (data['roles'] is List) {
      roles =
          (data['roles'] as List)
              .map((r) {
                switch (r) {
                  case 'admin':
                    return UserRole.admin;
                  case 'doctor':
                    return UserRole.doctor;
                  case 'paciente':
                    return UserRole.paciente;
                  default:
                    return null;
                }
              })
              .whereType<UserRole>()
              .toList();
    }

    // Declara las variables de perfil como nullables fuera de los ifs
    AdminProfile? adminProfile;
    DoctorProfile? doctorProfile;
    PacienteProfile? pacienteProfile;

    // Intenta parsear AdminProfile
    if (roles.contains(UserRole.admin) && data['adminProfile'] != null) {
      // Verifica que sea un Map antes de intentar castear y parsear
      if (data['adminProfile'] is Map) {
        try {
          // Casteo seguro a Map<String, dynamic>
          adminProfile = AdminProfile.fromMap(data['adminProfile'] as Map<String, dynamic>);
        } catch (e) {
          // Error DENTRO de AdminProfile.fromMap (probablemente un campo null/faltante)
          if (kDebugMode) {
            print("Error parsing adminProfile for user ${doc.id}: $e");
          }
          // adminProfile permanecerá null
        }
      } else {
        // El campo existe pero no es un Map
        if (kDebugMode) {
          print(
            "Warning: adminProfile data for user ${doc.id} is not a Map: ${data['adminProfile'].runtimeType}",
          );
        }
        // adminProfile permanecerá null
      }
    }

    // Intenta parsear DoctorProfile
    if (roles.contains(UserRole.doctor) && data['doctorProfile'] != null) {
      if (data['doctorProfile'] is Map) {
        try {
          doctorProfile = DoctorProfile.fromMap(data['doctorProfile'] as Map<String, dynamic>);
        } catch (e) {
          if (kDebugMode) {
            print("Error parsing doctorProfile for user ${doc.id}: $e");
          }
          // doctorProfile permanecerá null
        }
      } else {
        if (kDebugMode) {
          print(
            "Warning: doctorProfile data for user ${doc.id} is not a Map: ${data['doctorProfile'].runtimeType}",
          );
        }
        // doctorProfile permanecerá null
      }
    }

    // Intenta parsear PacienteProfile
    if (roles.contains(UserRole.paciente) && data['pacienteProfile'] != null) {
      if (data['pacienteProfile'] is Map) {
        try {
          pacienteProfile = PacienteProfile.fromMap(
            data['pacienteProfile'] as Map<String, dynamic>,
          );
        } catch (e) {
          if (kDebugMode) {
            print("Error parsing pacienteProfile for user ${doc.id}: $e");
          }
          // pacienteProfile permanecerá null
        }
      } else {
        if (kDebugMode) {
          print(
            "Warning: pacienteProfile data for user ${doc.id} is not a Map: ${data['pacienteProfile'].runtimeType}",
          );
        }
        // pacienteProfile permanecerá null
      }
    }

    // Relaciones de negocio
    List<Recomendacion>? recsEmit =
        (data['recomendacionesEmitidas'] as List?)
            ?.map((m) => Recomendacion.fromJson(m as Map<String, dynamic>))
            .toList();
    List<Recomendacion>? recsRecib =
        (data['recomendacionesRecibidas'] as List?)
            ?.map((m) => Recomendacion.fromJson(m as Map<String, dynamic>))
            .toList();
    List<Cita>? citas =
        (data['citas'] as List?)?.map((m) => Cita.fromJson(m as Map<String, dynamic>)).toList();
    // List<DatosClinicos>? datosClinicos =
    //     (data['datosClinicos'] as List?)
    //         ?.map((m) => DatosClinicos.fromMap(m as Map<String, dynamic>, m['id'] as String))
    //         .toList();

    return Usuario(
      uid: doc.id,
      email: FirestoreParser.parseString(data['email']) ?? '', // Usa el parser
      displayName: FirestoreParser.parseString(data['displayName']) ?? 'Usuario sin nombre',
      photoUrl: FirestoreParser.parseString(data['photoUrl']), // El parser devuelve null si falla
      roles: roles,
      adminProfile: adminProfile,
      doctorProfile: doctorProfile,
      pacienteProfile: pacienteProfile,
      recomendacionesEmitidas: recsEmit,
      recomendacionesRecibidas: recsRecib,
      citas: citas,
      // datosClinicos: datosClinicos,
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = {
      'email': email,
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'roles': roles.map((r) => r.name).toList(),
      'recomendacionesEmitidas': recomendacionesEmitidas?.map((r) => r.toJson()).toList(),
      'recomendacionesRecibidas': recomendacionesRecibidas?.map((r) => r.toJson()).toList(),
      'citas': citas?.map((c) => c.toJson()).toList(),
      // 'datosClinicos': datosClinicos?.map((d) => d.toMap()).toList(),
    };
    if (adminProfile != null) map['adminProfile'] = adminProfile!.toMap();
    if (doctorProfile != null) map['doctorProfile'] = doctorProfile!.toMap();
    if (pacienteProfile != null) map['pacienteProfile'] = pacienteProfile!.toMap();
    return map;
  }
}

//-------------------------------

// --- Enum para Tipos de Acción ---
enum TipoAccionAdmin {
  crearUsuario,
  actualizarUsuario,
  eliminarUsuario,
  deshabilitarUsuario,
  habilitarUsuario,
  asignarDoctor,
  quitarDoctor,
  actualizarConfiguracion,
  otro, // Para acciones no estándar
}

// Helper para convertir String a Enum y viceversa (importante para Firestore)
String tipoAccionAdminToString(TipoAccionAdmin tipo) => tipo.name; // Usa .name en Dart >= 2.15

TipoAccionAdmin tipoAccionAdminFromString(String? nombre) {
  if (nombre == null) return TipoAccionAdmin.otro;
  // Busca por nombre (sensible a mayúsculas/minúsculas si no usas .toLowerCase())
  return TipoAccionAdmin.values.firstWhere(
    (e) => e.name.toLowerCase() == nombre.toLowerCase(),
    orElse: () => TipoAccionAdmin.otro, // Valor por defecto si no coincide
  );
}

// --- Modelo para el Registro de Acciones ---
class RegistroAccionAdmin {
  final String? id; // ID del documento de log (opcional)
  final String adminUid; // UID del admin que realizó la acción
  final TipoAccionAdmin tipoAccion; // Tipo de acción realizada
  final DateTime timestamp; // Fecha y hora de la acción
  final List<String>? uidsObjetivo; // Lista de UIDs afectados (si aplica)
  final String? tipoObjetivo; // Tipo del recurso afectado (ej: 'paciente', 'doctor', 'config')
  final String descripcion; // Descripción detallada
  final Map<String, dynamic>? detalles; // Datos adicionales (ej: datos cambiados)

  RegistroAccionAdmin({
    this.id,
    required this.adminUid,
    required this.tipoAccion,
    required this.timestamp,
    this.uidsObjetivo,
    this.tipoObjetivo,
    required this.descripcion,
    this.detalles,
  });

  // --- Constructor desde Firestore Map ---
  factory RegistroAccionAdmin.fromMap(Map<String, dynamic> map, [String? documentId]) {
    DateTime? parseOptionalDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    List<String>? parseOptionalStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e?.toString()).whereType<String>().toList();
      }
      return null;
    }

    return RegistroAccionAdmin(
      id: documentId ?? map['id'] as String?, // Usa ID del documento si se pasa
      adminUid: map['adminUid'] as String? ?? 'UID_Admin_Desconocido',
      tipoAccion: tipoAccionAdminFromString(map['tipoAccion'] as String?),
      timestamp: parseOptionalDate(map['timestamp']) ?? DateTime.now(), // Valor por defecto
      uidsObjetivo: parseOptionalStringList(map['uidsObjetivo']),
      tipoObjetivo: map['tipoObjetivo'] as String?,
      descripcion: map['descripcion'] as String? ?? 'Sin descripción',
      // Casteo seguro para detalles
      detalles:
          map['detalles'] != null && map['detalles'] is Map
              ? Map<String, dynamic>.from(map['detalles'])
              : null,
    );
  }

  // --- Método para convertir a Firestore Map ---
  Map<String, dynamic> toMap() {
    return {
      // No incluimos 'id' porque es el ID del documento
      'adminUid': adminUid,
      'tipoAccion': tipoAccionAdminToString(tipoAccion), // Guarda el nombre del enum
      'timestamp': Timestamp.fromDate(timestamp), // Guarda como Timestamp
      if (uidsObjetivo != null && uidsObjetivo!.isNotEmpty) 'uidsObjetivo': uidsObjetivo,
      if (tipoObjetivo != null) 'tipoObjetivo': tipoObjetivo,
      'descripcion': descripcion,
      if (detalles != null && detalles!.isNotEmpty) 'detalles': detalles,
    };
  }
}

// --- Modelo AdminProfile Actualizado ---
class AdminProfile {
  final String uid; // ID del usuario/admin (debe coincidir con Usuario.uid)

  // --- Campos Específicos del Admin ---
  final String rol; // Puede ser 'admin' o 'superadmin'
  final DateTime creationDate; // Fecha de creación del perfil admin
  final String? createdBy; // UID del usuario que creó este admin (opcional)
  final List<String>? permisos; // Lista de permisos específicos (opcional)

  // OPCIÓN 1: Lista embebida (Menos escalable si hay muchos logs)
  // final List<RegistroAccionAdmin>? actionLogs;

  // OPCIÓN 2: No incluir logs aquí, se manejarán en una subcolección separada.
  // Esta es generalmente la mejor opción para logs.

  AdminProfile({
    required this.uid,
    required this.rol,
    required this.creationDate,
    this.createdBy,
    this.permisos,
    // this.actionLogs, // Descomentar si eliges la Opción 1
  });

  // --- Constructor desde Firestore Map ---
  factory AdminProfile.fromMap(Map<String, dynamic> map) {
    DateTime? parseOptionalDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    List<String>? parseOptionalStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e?.toString()).whereType<String>().toList();
      }
      return null;
    }

    // OPCIÓN 1: Parsear logs embebidos
    /*
    List<RegistroAccionAdmin>? parseActionLogs(dynamic value) {
      if (value is List) {
        return value.map((item) {
          if (item is Map) {
            try {
              return RegistroAccionAdmin.fromMap(Map<String, dynamic>.from(item));
            } catch (e) {
              if (kDebugMode) print("Error parsing AdminActionLog item: $e");
              return null; // O manejar el error de otra forma
            }
          }
          return null;
        }).whereType<RegistroAccionAdmin>().toList();
      }
      return null;
    }
    */

    return AdminProfile(
      uid: map['uid'] as String? ?? '', // Asumir que uid no está en el mapa
      rol: map['rol'] as String? ?? 'admin', // Rol por defecto 'admin' si falta
      creationDate: parseOptionalDate(map['creationDate']) ?? DateTime.now(), // Fecha por defecto
      createdBy: map['createdBy'] as String?,
      permisos: parseOptionalStringList(map['permisos']),
      // actionLogs: parseActionLogs(map['actionLogs']), // Descomentar para Opción 1
    );
  }

  // --- Constructor desde DocumentSnapshot ---
  factory AdminProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['uid'] = doc.id; // Añadir el ID del documento
    return AdminProfile.fromMap(data);
  }

  // --- Método para convertir a Firestore Map ---
  Map<String, dynamic> toMap() {
    return {
      // uid usualmente no se guarda dentro del documento
      'rol': rol,
      'creationDate': Timestamp.fromDate(creationDate), // Guarda como Timestamp
      if (createdBy != null) 'createdBy': createdBy,
      if (permisos != null && permisos!.isNotEmpty) 'permisos': permisos,
      // OPCIÓN 1: Guardar logs embebidos
      /*
      if (actionLogs != null && actionLogs!.isNotEmpty)
        'actionLogs': actionLogs!.map((log) => log.toMap()).toList(),
      */
    };
  }

  // Alias toJson
  Map<String, dynamic> toJson() => toMap();
}

//-------------------------------
class DoctorProfile {
  final String uid; // ID del usuario/doctor (debe coincidir con Usuario.uid)

  // --- Información Profesional ---
  final String licenseNumber; // Número de licencia (requerido)
  final List<String> specialties; // Lista de especialidades (requerido)
  final List<Horario> horarios; // Lista de horarios disponibles (requerido)
  final int? anosExperiencia; // Años de experiencia (opcional)

  // --- Datos Adicionales (Opcionales, pueden solaparse con Usuario) ---
  final String? nombre; // Nombre específico del perfil (puede diferir de displayName)
  final String? telefono; // Teléfono de contacto profesional
  final String? email; // Email de contacto profesional (puede diferir del de Auth)
  final String? fotoPerfilURL; // URL de foto específica del perfil
  final double? rating; // Calificación promedio (si aplica)
  // Puedes añadir otros campos como consultorio, biografía, etc.

  DoctorProfile({
    required this.uid,
    required this.licenseNumber,
    required this.specialties,
    required this.horarios,
    this.anosExperiencia,
    this.nombre,
    this.telefono,
    this.email,
    this.fotoPerfilURL,
    this.rating,
  });

  // --- Constructor desde Firestore Map ---
  factory DoctorProfile.fromMap(Map<String, dynamic> map) {
    // Helper para parsear listas de Strings de forma segura
    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value
            .map((e) => e?.toString().trim())
            .where((s) => s != null && s.isNotEmpty)
            .cast<String>()
            .toList();
      }
      return []; // Devuelve lista vacía si no es una lista válida
    }

    // Helper para parsear lista de Horarios
    List<Horario> parseHorarioList(dynamic value) {
      if (value is List) {
        List<Horario> parsedList = [];
        for (var item in value) {
          if (item is Map) {
            try {
              // Asegúrate que las claves sean String antes de pasar a fromJson
              parsedList.add(Horario.fromJson(Map<String, dynamic>.from(item)));
            } catch (e) {
              if (kDebugMode) {
                print("Error parsing Horario item: $e - Item: $item");
              }
            }
          }
        }
        return parsedList;
      }
      return []; // Devuelve lista vacía si no es válida
    }

    // Helper para parsear enteros de forma segura
    int? parseOptionalInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value.trim());
      if (kDebugMode) {
        print("Warning: Couldn't parse int value: $value (Type: ${value.runtimeType})");
      }
      return null;
    }

    // Helper para parsear doubles de forma segura
    double? parseOptionalDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble(); // Permite enteros
      if (value is String) return double.tryParse(value.trim());
      if (kDebugMode) {
        print("Warning: Couldn't parse double value: $value (Type: ${value.runtimeType})");
      }
      return null;
    }

    return DoctorProfile(
      // Asumimos que el uid no está DENTRO del mapa del perfil, sino que es el ID del documento
      // Si SÍ lo guardas dentro, añade: uid: map['uid'] as String? ?? '',
      uid: map['uid'] ?? '', // O lee desde el DocumentSnapshot ID si es posible
      licenseNumber: map['licenseNumber'] as String? ?? 'N/A', // Valor por defecto si falta
      specialties: parseStringList(map['specialties']), // Usa el helper
      horarios: parseHorarioList(map['horarios']), // Usa el helper
      anosExperiencia: parseOptionalInt(map['anosExperiencia']), // Usa el helper
      nombre: map['nombre'] as String?,
      telefono: map['telefono'] as String?,
      email: map['email'] as String?,
      fotoPerfilURL: map['fotoPerfilURL'] as String?,
      rating: parseOptionalDouble(map['rating']), // Usa el helper
    );
  }

  // --- Constructor desde DocumentSnapshot ---
  // Útil si obtienes el perfil directamente
  factory DoctorProfile.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    // Añade el ID del documento al mapa antes de pasarlo a fromMap
    data['uid'] = doc.id;
    return DoctorProfile.fromMap(data);
  }

  // --- Método para convertir a Firestore Map ---
  Map<String, dynamic> toMap() {
    return {
      // uid usualmente no se guarda dentro del documento
      'licenseNumber': licenseNumber,
      'specialties': specialties, // Guardar como lista de strings
      'horarios': horarios.map((h) => h.toJson()).toList(), // Convertir cada Horario a mapa
      if (anosExperiencia != null) 'anosExperiencia': anosExperiencia,
      if (nombre != null) 'nombre': nombre,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      if (fotoPerfilURL != null) 'fotoPerfilURL': fotoPerfilURL,
      if (rating != null) 'rating': rating,
      // Considera añadir 'profileLastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // Alias toJson
  Map<String, dynamic> toJson() => toMap();

  // Opcional: fromJson si lees de JSON no-Firestore
  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    // Puede necesitar lógica diferente para parsear horarios si no son mapas
    return DoctorProfile.fromMap(json);
  }
}

class PacienteProfile {
  final String uid; // ID del usuario/paciente (debe coincidir con Usuario.uid)

  // --- Datos Demográficos Específicos ---
  // Aunque Usuario tiene displayName, el perfil puede tener un 'nombre' clínico
  final String? nombre;
  final DateTime? fechaNacimiento;
  final String? nacionalidad;
  final String? documentoIdentidad;
  final String? direccion;
  final String? telefono; // Podría ser diferente del de Auth

  // --- Datos Clínicos ---
  final String? grupoSanguineo;
  final String? factorRH;
  final List<String>? alergias;
  final List<String>? enfermedadesPreexistentes;
  final List<String>? medicamentos; // Medicamentos actuales que toma

  // --- Datos Obstétricos ---
  final DateTime? fechaUltimaMenstruacion;
  final int? semanasGestacion;
  final DateTime? fechaProbableParto;
  final int? numeroGestaciones;
  final int? numeroPartosVaginales;
  final int? numeroCesareas;
  final int? abortos;
  final bool? embarazoMultiple;

  // --- Ubicación ---
  final GeoPoint? coordenadas;

  // --- Médico Asignado ---
  final String? doctorId; // UID del doctor asignado

  PacienteProfile({
    required this.uid,
    this.nombre,
    this.fechaNacimiento,
    this.nacionalidad,
    this.documentoIdentidad,
    this.direccion,
    this.telefono,
    this.grupoSanguineo,
    this.factorRH,
    this.alergias,
    this.enfermedadesPreexistentes,
    this.medicamentos,
    this.fechaUltimaMenstruacion,
    this.semanasGestacion,
    this.fechaProbableParto,
    this.numeroGestaciones,
    this.numeroPartosVaginales,
    this.numeroCesareas,
    this.abortos,
    this.embarazoMultiple,
    this.coordenadas,
    this.doctorId,
    required String email,
  });

  // --- Constructor desde Firestore Map ---
  factory PacienteProfile.fromMap(Map<String, dynamic> map) {
    // Helper para parsear Timestamps o Strings a DateTime de forma segura
    DateTime? parseOptionalDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      if (kDebugMode) {
        print("Warning: Couldn't parse date value: $value (Type: ${value.runtimeType})");
      }
      return null;
    }

    // Helper para parsear listas de Strings de forma segura
    List<String>? parseOptionalStringList(dynamic value) {
      if (value is List) {
        // Filtra para asegurar que solo sean strings y no nulos/vacíos
        return value
            .map((e) => e?.toString().trim())
            .where((s) => s != null && s.isNotEmpty)
            .cast<String>()
            .toList();
      }
      return null;
    }

    // Helper para parsear enteros de forma segura
    int? parseOptionalInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt(); // Permite doubles si vienen de JSON
      if (value is String) return int.tryParse(value.trim());
      if (kDebugMode) {
        print("Warning: Couldn't parse int value: $value (Type: ${value.runtimeType})");
      }
      return null;
    }

    // Helper para parsear booleanos de forma segura
    bool? parseOptionalBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is String) {
        final lower = value.toLowerCase().trim();
        if (lower == 'true') return true;
        if (lower == 'false') return false;
      }
      if (value is int) return value == 1; // Común en algunas bases de datos
      if (kDebugMode) {
        print("Warning: Couldn't parse bool value: $value (Type: ${value.runtimeType})");
      }
      return null;
    }

    return PacienteProfile(
      // Aceptar 'pacienteId' o 'uid' como clave para el ID
      uid: map['uid'] as String? ?? map['pacienteId'] as String? ?? '',
      nombre: map['nombre'] as String?,
      fechaNacimiento: parseOptionalDate(map['fechaNacimiento']),
      nacionalidad: map['nacionalidad'] as String?,
      documentoIdentidad: map['documentoIdentidad'] as String?,
      direccion: map['direccion'] as String?,
      telefono: map['telefono'] as String?,
      grupoSanguineo: map['grupoSanguineo'] as String?,
      factorRH: map['factorRH'] as String?,
      alergias: parseOptionalStringList(map['alergias']),
      enfermedadesPreexistentes: parseOptionalStringList(map['enfermedadesPreexistentes']),
      medicamentos: parseOptionalStringList(map['medicamentos']),
      fechaUltimaMenstruacion: parseOptionalDate(map['fechaUltimaMenstruacion']),
      semanasGestacion: parseOptionalInt(map['semanasGestacion']),
      fechaProbableParto: parseOptionalDate(map['fechaProbableParto']),
      numeroGestaciones: parseOptionalInt(map['numeroGestaciones']),
      numeroPartosVaginales: parseOptionalInt(map['numeroPartosVaginales']),
      numeroCesareas: parseOptionalInt(map['numeroCesareas']),
      // Asegúrate que la key coincida con la usada en toMap/formulario
      abortos: parseOptionalInt(map['numeroAbortos'] ?? map['abortos']),
      embarazoMultiple: parseOptionalBool(map['embarazoMultiple']),
      // Asume que se guarda como GeoPoint. Si no, necesitarías parsearlo desde Map
      coordenadas: map['coordenadas'] as GeoPoint?,
      doctorId: map['doctorId'] as String?,
      email: '', // Campo para médico asignado
    );
  }

  // --- Método para convertir a Firestore Map ---
  Map<String, dynamic> toMap() {
    return {
      // 'uid' usualmente es el ID del documento, no se guarda dentro
      if (nombre != null) 'nombre': nombre,
      if (fechaNacimiento != null) 'fechaNacimiento': Timestamp.fromDate(fechaNacimiento!),
      if (nacionalidad != null) 'nacionalidad': nacionalidad,
      if (documentoIdentidad != null) 'documentoIdentidad': documentoIdentidad,
      if (direccion != null) 'direccion': direccion,
      if (telefono != null) 'telefono': telefono,
      if (grupoSanguineo != null) 'grupoSanguineo': grupoSanguineo,
      if (factorRH != null) 'factorRH': factorRH,
      if (alergias != null && alergias!.isNotEmpty) 'alergias': alergias,
      if (enfermedadesPreexistentes != null && enfermedadesPreexistentes!.isNotEmpty)
        'enfermedadesPreexistentes': enfermedadesPreexistentes,
      if (medicamentos != null && medicamentos!.isNotEmpty) 'medicamentos': medicamentos,
      if (fechaUltimaMenstruacion != null)
        'fechaUltimaMenstruacion': Timestamp.fromDate(fechaUltimaMenstruacion!),
      if (semanasGestacion != null) 'semanasGestacion': semanasGestacion,
      if (fechaProbableParto != null) 'fechaProbableParto': Timestamp.fromDate(fechaProbableParto!),
      if (numeroGestaciones != null) 'numeroGestaciones': numeroGestaciones,
      if (numeroPartosVaginales != null) 'numeroPartosVaginales': numeroPartosVaginales,
      if (numeroCesareas != null) 'numeroCesareas': numeroCesareas,
      // Usa la misma key consistente
      if (abortos != null) 'numeroAbortos': abortos,
      if (embarazoMultiple != null) 'embarazoMultiple': embarazoMultiple,
      if (coordenadas != null) 'coordenadas': coordenadas,
      if (doctorId != null) 'doctorId': doctorId,
      // Considera añadir un campo 'lastUpdated' si es útil
      // 'profileLastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // Alias toJson para consistencia si lo usas en otros lugares
  Map<String, dynamic> toJson() => toMap();

  // Opcional: Constructor fromJson (si lees desde JSON que no sea Firestore)
  // Si la estructura JSON es idéntica a la de Firestore, puedes reutilizar fromMap
  factory PacienteProfile.fromJson(Map<String, dynamic> json) {
    // Aquí podrías necesitar lógica de parseo diferente si el JSON no usa Timestamps/GeoPoints
    // Por simplicidad, asumimos que la estructura es igual o que se pre-procesa
    return PacienteProfile.fromMap(json);
  }
}

/// Clase para Datos Clínicos del diccionario.
class JsonDataParser {
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      if (value.trim().isEmpty) return null;
      // Quita comas si se usan como separador de miles (aunque no parece ser el caso aquí)
      // value = value.replaceAll(',', '');
      return int.tryParse(value.trim());
    }
    return null;
  }

  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.trim().isEmpty) return null;
      // Reemplaza coma decimal por punto
      final formattedValue = value.trim().replaceAll(',', '.');
      return double.tryParse(formattedValue);
    }
    return null;
  }

  static bool? parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1; // Asume 1=true, 0=false
    if (value is String) {
      final l = value.trim().toLowerCase();
      if (l == 'true' || l == 'si' || l == '1') return true;
      if (l == 'false' || l == 'no' || l == '0') return false;
    }
    return null; // No se pudo parsear
  }

  static String? parseString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      final parsedDate = DateTime.tryParse(value.trim());
      return parsedDate ?? DateTime.tryParse(value); // Intenta parsear como DateTime
    }
    return null; // No se pudo parsear
  }

  static Timestamp? parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);
    if (value is String) {
      final parsedDate = DateTime.tryParse(value.trim());
      return parsedDate != null ? Timestamp.fromDate(parsedDate) : null;
    }
    return null; // No se pudo parsear
  }

  static GeoPoint? parseGeoPoint(dynamic value) {
    if (value == null) return null;
    if (value is GeoPoint) return value;
    if (value is Map<String, dynamic>) {
      final latitude = parseDouble(value['latitude']);
      final longitude = parseDouble(value['longitude']);
      if (latitude != null && longitude != null) {
        return GeoPoint(latitude, longitude);
      }
    }
    return null; // No se pudo parsear
  }

  static List<String>? parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e?.toString().trim()).whereType<String>().toList();
    }
    return null; // No se pudo parsear
  }

  static List<int>? parseIntList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => parseInt(e)).whereType<int>().toList();
    }
    return null; // No se pudo parsear
  }

  static List<double>? parseDoubleList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => parseDouble(e)).whereType<double>().toList();
    }
    return null; // No se pudo parsear
  }
}

class DatosClinicos {
  final String id; // ID único del registro
  final String pacienteId;
  final String doctorId;
  final Timestamp timestamp;

  // --- CAMPOS DEL JSON DE EJEMPLO ---
  final String? institucion; // "Institución"
  final String? procedencia; // "PROCEDENCIA"
  final String? etnia; // "ETNIA"
  final bool? indigena; // "INDIGENA" (parseado de 0/1)
  final String? escolaridad; // "ESCOLARIDAD"
  final bool? remitidaOtraInst; // "REMITIDA_OTRA_INST" (parseado de 0/1)
  final int? abortos; // "ABORTOS"
  final int? ectopicos; // "ECTOPICOS"
  final int? numControles; // "NUM_CONTROLES"
  final String? viaParto; // "VIA_PARTO"
  final int? semanasOcurrencia; // "SEMANAS_OCURRENCIA"
  final String? ocurrenciaGestacion; // "OCURRENCIA_GESTACION"
  final String? estadoObstetrico; // "ESTADO_OBSTETRICO"
  final double? peso; // "PESO" (parseado de String/num)
  final int? altura; // "ALTURA" (es int en el JSON)
  final double? imc; // "IMC" (parseado de String con coma)
  final int? frecuenciaCardiacaIngresoAlta; // "FRECUENCIA_CARDIACA_INGRESO_ALTA"
  final int? fRespiratoriaIngresoAlta; // "F_RESPIRATORIA_INGRESO_ALTA"
  final int? pasIngresoAlta; // "PAS_INGRESO_ALTA"
  final int? padIngresoBaja; // "PAD_INGRESO_BAJA"
  final String? conscienciaIngreso; // "CONSCIENCIA_INGRESO"
  final double? hemoglobinaIngreso; // "HEMOGLOBINA_INGRESO" (parseado de String con coma)
  final double? creatininaIngreso; // "CREATININA_INGRESO" (parseado de String con coma)
  final double? gptIngreso; // "GPT_INGRESO" (parseado de String/num)
  final bool?
  manejoEspecificoCirugiaAdicional; // "MANEJO_ESPECIFICO_Cirugía_adicional" (parseado 0/1)
  final bool? manejoEspecificoIngresoUado; // "MANEJO_ESPECIFICO_Ingreso_a_UADO" (parseado 0/1)
  final bool? manejoEspecificoIngresoUci; // "MANEJO_ESPECIFICO_Ingreso_a_UCI" (parseado 0/1)
  final int? unidadesTransfundidas; // "UNIDADES_TRANSFUNDIDAS"
  final bool? manejoQxLaparotomia; // "MANEJO_QX_LAPAROTOMIA" (parseado 0/1)
  final bool? manejoQxOtra; // "MANEJO_QX_OTRA" (parseado 0/1)
  final bool? desgarroPerineal; // "DESGARRO_PERINEAL" (parseado "Si"/"No")
  final bool? suturaPerinealPosparto; // "SUTURA_PERINEAL_POSPARTO" (parseado "Si"/"No")
  final bool?
  tratamientosUadoMonitoreoHemodinamico; // "TRATAMIENTOS_UADO_Monitoreo_hemodinámico" (0/1)
  final bool? tratamientosUadoOxigeno; // "TRATAMIENTOS_UADO_Oxígeno" (0/1)
  final bool? tratamientosUadoTransfusiones; // "TRATAMIENTOS_UADO_Transfusiones" (0/1)
  final bool? diagPrincipalThe; // "DIAG_PRINCIPAL_THE" (0/1)
  final bool? diagPrincipalHemorragia; // "DIAG_PRINCIPAL_HEMORRAGIA" (0/1)
  final bool?
  waosProcedimientoQuirurgicoNoProgramado; // "WAOS_Procedimiento_quirúrgico_no_programado" (0/1)
  final bool? waosRoturaUterinaDuranteElParto; // "WAOS_Rotura_uterina_durante_el_parto" (0/1)
  final bool?
  waosLaceracionPerineal3erO4toGrado; // "WAOS_laceracion_perineal_de_3er_o_4to_grado" (0/1)
  final int? apgar1Minuto; // "APGAR_1MINUTO"
  final int? fCardiacaEstanciaMax; // Mapeado desde "F_CARIDIACA_ESTANCIA_MIN"
  final int? fCardiacaEstanciaMin; // Mapeado desde "F_CARDIACA_ESTANCIA_MIN" (la segunda)
  final int? pasEstanciaMin; // "PAS_ESTANCIA_MIN"
  final int? padEstanciaMin; // "PAD_ESTANCIA_MIN"
  final int? sao2EstanciaMax; // "SaO2_ESTANCIA_MAX"
  final double? hemoglobinaEstanciaMin; // "HEMOGLOBINA_ESTANCIA_MIN"
  final double? creatininaEstanciaMax; // "CREATININA_ESTANCIA_MAX"
  final double? gotAspartatoAminotransferasaMax; // "GOT_Aspartato_aminotransferasa_max"
  final int? recuentoPlaquetasPltMin; // "Recuento_de_plaquetas_-_PLT___min"
  final int? diasEstancia; // "DIAS_ESTANCIA"
  final bool? desenlaceMaterno2; // "DESENLACE_MATERNO2"
  final bool? desenlaceNeonatal; // "DESENLACE_NEONATAL"

  DatosClinicos({
    required this.id,
    required this.pacienteId,
    required this.doctorId,
    required this.timestamp,
    // Constructor con todas las propiedades (solo las existentes)
    this.institucion,
    this.procedencia,
    this.etnia,
    this.indigena,
    this.escolaridad,
    this.remitidaOtraInst,
    this.abortos,
    this.ectopicos,
    this.numControles,
    this.viaParto,
    this.semanasOcurrencia,
    this.ocurrenciaGestacion,
    this.estadoObstetrico,
    this.peso,
    this.altura,
    this.imc,
    this.frecuenciaCardiacaIngresoAlta,
    this.fRespiratoriaIngresoAlta,
    this.pasIngresoAlta,
    this.padIngresoBaja,
    this.conscienciaIngreso,
    this.hemoglobinaIngreso,
    this.creatininaIngreso,
    this.gptIngreso,
    this.manejoEspecificoCirugiaAdicional,
    this.manejoEspecificoIngresoUado,
    this.manejoEspecificoIngresoUci,
    this.unidadesTransfundidas,
    this.manejoQxLaparotomia,
    this.manejoQxOtra,
    this.desgarroPerineal,
    this.suturaPerinealPosparto,
    this.tratamientosUadoMonitoreoHemodinamico,
    this.tratamientosUadoOxigeno,
    this.tratamientosUadoTransfusiones,
    this.diagPrincipalThe,
    this.diagPrincipalHemorragia,
    this.waosProcedimientoQuirurgicoNoProgramado,
    this.waosRoturaUterinaDuranteElParto,
    this.waosLaceracionPerineal3erO4toGrado,
    this.apgar1Minuto,
    this.fCardiacaEstanciaMax,
    this.fCardiacaEstanciaMin,
    this.pasEstanciaMin,
    this.padEstanciaMin,
    this.sao2EstanciaMax,
    this.hemoglobinaEstanciaMin,
    this.creatininaEstanciaMax,
    this.gotAspartatoAminotransferasaMax,
    this.recuentoPlaquetasPltMin,
    this.diasEstancia,
    this.desenlaceMaterno2,
    this.desenlaceNeonatal,
  });

  // Factory fromMap (actualizado en la corrección anterior)
  factory DatosClinicos.fromMap(Map<String, dynamic> map, String id) {
    // Usar el parser específico para manejar los tipos de datos
    return DatosClinicos(
      id: id,
      pacienteId: JsonDataParser.parseString(map['pacienteId']) ?? '',
      doctorId: JsonDataParser.parseString(map['doctorId']) ?? '',
      // Asegurarse de que el timestamp se parsea correctamente desde Firestore
      timestamp: JsonDataParser.parseTimestamp(map['timestamp']) ?? Timestamp.now(),

      // Mapeo usando claves JSON (si cargaste datos JSON)
      // O usando nombres de propiedad (si guardaste con el toMap corregido)
      // *** IMPORTANTE: Asegúrate que las claves usadas aquí coincidan
      // con cómo guardaste los datos en Firestore ***
      institucion: JsonDataParser.parseString(map['institucion'] ?? map['Institución']),
      procedencia: JsonDataParser.parseString(map['procedencia'] ?? map['PROCEDENCIA']),
      etnia: JsonDataParser.parseString(map['etnia'] ?? map['ETNIA']),
      indigena: JsonDataParser.parseBool(map['indigena'] ?? map['INDIGENA']),
      escolaridad: JsonDataParser.parseString(map['escolaridad'] ?? map['ESCOLARIDAD']),
      remitidaOtraInst: JsonDataParser.parseBool(
        map['remitidaOtraInst'] ?? map['REMITIDA_OTRA_INST'],
      ),
      abortos: JsonDataParser.parseInt(map['abortos'] ?? map['ABORTOS']),
      ectopicos: JsonDataParser.parseInt(map['ectopicos'] ?? map['ECTOPICOS']),
      numControles: JsonDataParser.parseInt(map['numControles'] ?? map['NUM_CONTROLES']),
      viaParto: JsonDataParser.parseString(map['viaParto'] ?? map['VIA_PARTO']),
      semanasOcurrencia: JsonDataParser.parseInt(
        map['semanasOcurrencia'] ?? map['SEMANAS_OCURRENCIA'],
      ),
      ocurrenciaGestacion: JsonDataParser.parseString(
        map['ocurrenciaGestacion'] ?? map['OCURRENCIA_GESTACION'],
      ),
      estadoObstetrico: JsonDataParser.parseString(
        map['estadoObstetrico'] ?? map['ESTADO_OBSTETRICO'],
      ),
      peso: JsonDataParser.parseDouble(map['peso'] ?? map['PESO']),
      altura: JsonDataParser.parseInt(map['altura'] ?? map['ALTURA']),
      imc: JsonDataParser.parseDouble(map['imc'] ?? map['IMC']),
      frecuenciaCardiacaIngresoAlta: JsonDataParser.parseInt(
        map['frecuenciaCardiacaIngresoAlta'] ?? map['FRECUENCIA_CARDIACA_INGRESO_ALTA'],
      ),
      fRespiratoriaIngresoAlta: JsonDataParser.parseInt(
        map['fRespiratoriaIngresoAlta'] ?? map['F_RESPIRATORIA_INGRESO_ALTA'],
      ),
      pasIngresoAlta: JsonDataParser.parseInt(map['pasIngresoAlta'] ?? map['PAS_INGRESO_ALTA']),
      padIngresoBaja: JsonDataParser.parseInt(map['padIngresoBaja'] ?? map['PAD_INGRESO_BAJA']),
      conscienciaIngreso: JsonDataParser.parseString(
        map['conscienciaIngreso'] ?? map['CONSCIENCIA_INGRESO'],
      ),
      hemoglobinaIngreso: JsonDataParser.parseDouble(
        map['hemoglobinaIngreso'] ?? map['HEMOGLOBINA_INGRESO'],
      ),
      creatininaIngreso: JsonDataParser.parseDouble(
        map['creatininaIngreso'] ?? map['CREATININA_INGRESO'],
      ),
      gptIngreso: JsonDataParser.parseDouble(map['gptIngreso'] ?? map['GPT_INGRESO']),
      manejoEspecificoCirugiaAdicional: JsonDataParser.parseBool(
        map['manejoEspecificoCirugiaAdicional'] ?? map['MANEJO_ESPECIFICO_Cirugía_adicional'],
      ),
      manejoEspecificoIngresoUado: JsonDataParser.parseBool(
        map['manejoEspecificoIngresoUado'] ?? map['MANEJO_ESPECIFICO_Ingreso_a_UADO'],
      ),
      manejoEspecificoIngresoUci: JsonDataParser.parseBool(
        map['manejoEspecificoIngresoUci'] ?? map['MANEJO_ESPECIFICO_Ingreso_a_UCI'],
      ),
      unidadesTransfundidas: JsonDataParser.parseInt(
        map['unidadesTransfundidas'] ?? map['UNIDADES_TRANSFUNDIDAS'],
      ),
      manejoQxLaparotomia: JsonDataParser.parseBool(
        map['manejoQxLaparotomia'] ?? map['MANEJO_QX_LAPAROTOMIA'],
      ),
      manejoQxOtra: JsonDataParser.parseBool(map['manejoQxOtra'] ?? map['MANEJO_QX_OTRA']),
      desgarroPerineal: JsonDataParser.parseBool(
        map['desgarroPerineal'] ?? map['DESGARRO_PERINEAL'],
      ),
      suturaPerinealPosparto: JsonDataParser.parseBool(
        map['suturaPerinealPosparto'] ?? map['SUTURA_PERINEAL_POSPARTO'],
      ),
      tratamientosUadoMonitoreoHemodinamico: JsonDataParser.parseBool(
        map['tratamientosUadoMonitoreoHemodinamico'] ??
            map['TRATAMIENTOS_UADO_Monitoreo_hemodinámico'],
      ),
      tratamientosUadoOxigeno: JsonDataParser.parseBool(
        map['tratamientosUadoOxigeno'] ?? map['TRATAMIENTOS_UADO_Oxígeno'],
      ),
      tratamientosUadoTransfusiones: JsonDataParser.parseBool(
        map['tratamientosUadoTransfusiones'] ?? map['TRATAMIENTOS_UADO_Transfusiones'],
      ),
      diagPrincipalThe: JsonDataParser.parseBool(
        map['diagPrincipalThe'] ?? map['DIAG_PRINCIPAL_THE'],
      ),
      diagPrincipalHemorragia: JsonDataParser.parseBool(
        map['diagPrincipalHemorragia'] ?? map['DIAG_PRINCIPAL_HEMORRAGIA'],
      ),
      waosProcedimientoQuirurgicoNoProgramado: JsonDataParser.parseBool(
        map['waosProcedimientoQuirurgicoNoProgramado'] ??
            map['WAOS_Procedimiento_quirúrgico_no_programado'],
      ),
      waosRoturaUterinaDuranteElParto: JsonDataParser.parseBool(
        map['waosRoturaUterinaDuranteElParto'] ?? map['WAOS_Rotura_uterina_durante_el_parto'],
      ),
      waosLaceracionPerineal3erO4toGrado: JsonDataParser.parseBool(
        map['waosLaceracionPerineal3erO4toGrado'] ??
            map['WAOS_laceracion_perineal_de_3er_o_4to_grado'],
      ),
      apgar1Minuto: JsonDataParser.parseInt(map['apgar1Minuto'] ?? map['APGAR_1MINUTO']),
      fCardiacaEstanciaMax: JsonDataParser.parseInt(
        map['fCardiacaEstanciaMax'] ?? map['F_CARIDIACA_ESTANCIA_MIN'],
      ), // Revisa claves JSON
      fCardiacaEstanciaMin: JsonDataParser.parseInt(
        map['fCardiacaEstanciaMin'] ?? map['F_CARDIACA_ESTANCIA_MIN'],
      ), // Revisa claves JSON
      pasEstanciaMin: JsonDataParser.parseInt(map['pasEstanciaMin'] ?? map['PAS_ESTANCIA_MIN']),
      padEstanciaMin: JsonDataParser.parseInt(map['padEstanciaMin'] ?? map['PAD_ESTANCIA_MIN']),
      sao2EstanciaMax: JsonDataParser.parseInt(map['sao2EstanciaMax'] ?? map['SaO2_ESTANCIA_MAX']),
      hemoglobinaEstanciaMin: JsonDataParser.parseDouble(
        map['hemoglobinaEstanciaMin'] ?? map['HEMOGLOBINA_ESTANCIA_MIN'],
      ),
      creatininaEstanciaMax: JsonDataParser.parseDouble(
        map['creatininaEstanciaMax'] ?? map['CREATININA_ESTANCIA_MAX'],
      ),
      gotAspartatoAminotransferasaMax: JsonDataParser.parseDouble(
        map['gotAspartatoAminotransferasaMax'] ?? map['GOT_Aspartato_aminotransferasa_max'],
      ),
      recuentoPlaquetasPltMin: JsonDataParser.parseInt(
        map['recuentoPlaquetasPltMin'] ?? map['Recuento_de_plaquetas_-_PLT___min'],
      ),
      diasEstancia: JsonDataParser.parseInt(map['diasEstancia'] ?? map['DIAS_ESTANCIA']),
      desenlaceMaterno2: JsonDataParser.parseBool(
        map['desenlaceMaterno2'] ?? map['DESENLACE_MATERNO2'],
      ),
      desenlaceNeonatal: JsonDataParser.parseBool(
        map['desenlaceNeonatal'] ?? map['DESENLACE_NEONATAL'],
      ),
    );
  }

  // *** NUEVO Factory fromFirestore ***
  /// Crea una instancia de [DatosClinicos] a partir de un [DocumentSnapshot] de Firestore.
  factory DatosClinicos.fromFirestore(DocumentSnapshot doc) {
    // Extrae el mapa de datos del snapshot. Asegúrate de castearlo correctamente.
    // Usamos `?? {}` para evitar errores si `data()` es null (aunque no debería si `doc.exists`).
    final data = (doc.data() ?? {}) as Map<String, dynamic>;
    // Llama al factory `fromMap` existente, pasando el mapa de datos y el ID del documento.
    return DatosClinicos.fromMap(data, doc.id);
  }

  // toMap actualizado para usar los nombres de propiedad como claves (corregido antes)
  Map<String, dynamic> toMap() {
    return {
      'pacienteId': pacienteId,
      'doctorId': doctorId,
      'timestamp': timestamp,
      // --- Campos usando nombres de propiedad como claves ---
      if (institucion != null) 'institucion': institucion,
      if (procedencia != null) 'procedencia': procedencia,
      if (etnia != null) 'etnia': etnia,
      if (indigena != null) 'indigena': indigena,
      if (escolaridad != null) 'escolaridad': escolaridad,
      if (remitidaOtraInst != null) 'remitidaOtraInst': remitidaOtraInst,
      if (abortos != null) 'abortos': abortos,
      if (ectopicos != null) 'ectopicos': ectopicos,
      if (numControles != null) 'numControles': numControles,
      if (viaParto != null) 'viaParto': viaParto,
      if (semanasOcurrencia != null) 'semanasOcurrencia': semanasOcurrencia,
      if (ocurrenciaGestacion != null) 'ocurrenciaGestacion': ocurrenciaGestacion,
      if (estadoObstetrico != null) 'estadoObstetrico': estadoObstetrico,
      if (peso != null) 'peso': peso,
      if (altura != null) 'altura': altura,
      if (imc != null) 'imc': imc,
      if (frecuenciaCardiacaIngresoAlta != null)
        'frecuenciaCardiacaIngresoAlta': frecuenciaCardiacaIngresoAlta,
      if (fRespiratoriaIngresoAlta != null) 'fRespiratoriaIngresoAlta': fRespiratoriaIngresoAlta,
      if (pasIngresoAlta != null) 'pasIngresoAlta': pasIngresoAlta,
      if (padIngresoBaja != null) 'padIngresoBaja': padIngresoBaja,
      if (conscienciaIngreso != null) 'conscienciaIngreso': conscienciaIngreso,
      if (hemoglobinaIngreso != null) 'hemoglobinaIngreso': hemoglobinaIngreso,
      if (creatininaIngreso != null) 'creatininaIngreso': creatininaIngreso,
      if (gptIngreso != null) 'gptIngreso': gptIngreso,
      if (manejoEspecificoCirugiaAdicional != null)
        'manejoEspecificoCirugiaAdicional': manejoEspecificoCirugiaAdicional,
      if (manejoEspecificoIngresoUado != null)
        'manejoEspecificoIngresoUado': manejoEspecificoIngresoUado,
      if (manejoEspecificoIngresoUci != null)
        'manejoEspecificoIngresoUci': manejoEspecificoIngresoUci,
      if (unidadesTransfundidas != null) 'unidadesTransfundidas': unidadesTransfundidas,
      if (manejoQxLaparotomia != null) 'manejoQxLaparotomia': manejoQxLaparotomia,
      if (manejoQxOtra != null) 'manejoQxOtra': manejoQxOtra,
      if (desgarroPerineal != null) 'desgarroPerineal': desgarroPerineal,
      if (suturaPerinealPosparto != null) 'suturaPerinealPosparto': suturaPerinealPosparto,
      if (tratamientosUadoMonitoreoHemodinamico != null)
        'tratamientosUadoMonitoreoHemodinamico': tratamientosUadoMonitoreoHemodinamico,
      if (tratamientosUadoOxigeno != null) 'tratamientosUadoOxigeno': tratamientosUadoOxigeno,
      if (tratamientosUadoTransfusiones != null)
        'tratamientosUadoTransfusiones': tratamientosUadoTransfusiones,
      if (diagPrincipalThe != null) 'diagPrincipalThe': diagPrincipalThe,
      if (diagPrincipalHemorragia != null) 'diagPrincipalHemorragia': diagPrincipalHemorragia,
      if (waosProcedimientoQuirurgicoNoProgramado != null)
        'waosProcedimientoQuirurgicoNoProgramado': waosProcedimientoQuirurgicoNoProgramado,
      if (waosRoturaUterinaDuranteElParto != null)
        'waosRoturaUterinaDuranteElParto': waosRoturaUterinaDuranteElParto,
      if (waosLaceracionPerineal3erO4toGrado != null)
        'waosLaceracionPerineal3erO4toGrado': waosLaceracionPerineal3erO4toGrado,
      if (apgar1Minuto != null) 'apgar1Minuto': apgar1Minuto,
      if (fCardiacaEstanciaMax != null) 'fCardiacaEstanciaMax': fCardiacaEstanciaMax,
      if (fCardiacaEstanciaMin != null) 'fCardiacaEstanciaMin': fCardiacaEstanciaMin,
      if (pasEstanciaMin != null) 'pasEstanciaMin': pasEstanciaMin,
      if (padEstanciaMin != null) 'padEstanciaMin': padEstanciaMin,
      if (sao2EstanciaMax != null) 'sao2EstanciaMax': sao2EstanciaMax,
      if (hemoglobinaEstanciaMin != null) 'hemoglobinaEstanciaMin': hemoglobinaEstanciaMin,
      if (creatininaEstanciaMax != null) 'creatininaEstanciaMax': creatininaEstanciaMax,
      if (gotAspartatoAminotransferasaMax != null)
        'gotAspartatoAminotransferasaMax': gotAspartatoAminotransferasaMax,
      if (recuentoPlaquetasPltMin != null) 'recuentoPlaquetasPltMin': recuentoPlaquetasPltMin,
      if (diasEstancia != null) 'diasEstancia': diasEstancia,
      if (desenlaceMaterno2 != null) 'desenlaceMaterno2': desenlaceMaterno2,
      if (desenlaceNeonatal != null) 'desenlaceNeonatal': desenlaceNeonatal,
    };
  }
}

class ConsultaIA {
  final String id;
  final String nivelRiesgo;
  final DateTime timestamp; // Este campo ahora es requerido
  final String inputDetails; // Resumen, para no sobrecargar la vista
  final String modelVersion; // Texto completo de la respuesta
  final String proyectId;
  final String location;
  ConsultaIA({
    required this.id,
    required this.nivelRiesgo,
    required this.timestamp,
    required this.inputDetails,
    required this.modelVersion,
    required this.proyectId,
    required this.location,
  });

  factory ConsultaIA.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    // Manejo del campo timestamp con validación
    final timestampValue = data['timestamp'];
    DateTime timestamp;
    if (timestampValue is Timestamp) {
      timestamp = timestampValue.toDate();
    } else {
      // Manejo de error si el campo timestamp no es del tipo esperado
      print(
        "Advertencia: El campo timestamp no es un Timestamp en el documento ${doc.id}. Usando DateTime.now().",
      );
      timestamp = DateTime.now(); // O podrías usar otro valor por defecto
    }
    return ConsultaIA(
      id: doc.id,
      nivelRiesgo: data['modelResponse'] ?? 'Desconocido',
      timestamp: timestamp, // Usar el valor parseado
      inputDetails: data['inputPrompt'] ?? 'Sin detalles', // Ajusta esto
      modelVersion: data['modelVersion'] ?? 'Sin detalles', // Ajusta esto
      proyectId: data['proyectId'] ?? 'Sin ID de proyecto',
      location: data['location'] ?? 'Sin ubicación', // Ajusta esto
    );
  }
}
