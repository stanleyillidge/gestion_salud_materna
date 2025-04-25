// users_service.dart
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;

// Importa TODOS tus modelos necesarios
import '../models/modelos.dart';

class UsersService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  ); // Ajusta tu región
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // Referencia a la colección unificada de usuarios
  CollectionReference<Map<String, dynamic>> get _usersCollection => _firestore.collection('users');

  // --- Llamadas a Cloud Function para Auth (Sin cambios) ---

  /// Obtiene una lista paginada de usuarios de Firebase Auth.
  Future<Map<String, dynamic>> listAuthUsers({int pageSize = 50, String? pageToken}) async {
    try {
      print("Llamando a CF 'manageAuthUser' con action: list");
      final HttpsCallable callable = _functions.httpsCallable('manageAuthUser');
      final params = <String, dynamic>{
        'action': 'list',
        'pageSize': pageSize,
        if (pageToken != null) 'pageToken': pageToken,
      };
      final HttpsCallableResult result = await callable.call({'data': params});
      print("Respuesta CF 'list': ${result.data?.keys ?? 'sin datos'}");
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print("Error CF 'listAuthUsers': ${e.code} - ${e.message} - ${e.details}");
      throw Exception("Error al listar usuarios: ${e.message}");
    } catch (e) {
      print("Error desconocido en listAuthUsers: $e");
      throw Exception("Error inesperado al listar usuarios.");
    }
  }

  /// Obtiene detalles de un usuario de Firebase Auth.
  Future<Map<String, dynamic>> getAuthUser(String uid) async {
    if (uid.isEmpty) throw ArgumentError("UID no puede estar vacío");
    try {
      print("Llamando a CF 'manageAuthUser' con action: get, uid: $uid");
      final HttpsCallable callable = _functions.httpsCallable('manageAuthUser');
      final params = {'action': 'get', 'uid': uid};
      final HttpsCallableResult result = await callable.call({'data': params});
      print("Respuesta CF 'get': ${result.data?.keys ?? 'sin datos'}");
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print("Error CF 'getAuthUser': ${e.code} - ${e.message} - ${e.details}");
      throw Exception("Error al obtener usuario Auth: ${e.message}");
    } catch (e) {
      print("Error desconocido en getAuthUser: $e");
      throw Exception("Error inesperado al obtener usuario Auth.");
    }
  }

  // --- Gestión de Usuario Unificado ---

  /// Obtiene el perfil unificado de Usuario desde Firestore.
  Future<Usuario?> getUser(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists ? Usuario.fromFirestore(doc) : null;
    } catch (e) {
      print("Error obteniendo perfil de Usuario $uid: $e");
      return null;
    }
  }

  /// Stream de todos los usuarios unificados.
  Stream<List<Usuario>> getAllUsersStream() {
    return _usersCollection
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Usuario.fromFirestore(doc)).toList())
        .handleError((error) {
          print("Error en getAllUsersStream: $error");
          return <Usuario>[];
        });
  }

  // --- Creación, actualización y eliminación de Usuario y perfiles ---

  /// Crea un nuevo usuario en Auth y su perfil unificado en Firestore.
  Future<Map<String, dynamic>> createUserWithProfile(Map<String, dynamic> createData) async {
    if (!createData.containsKey('email') ||
        !createData.containsKey('password') ||
        !createData.containsKey('profileType')) {
      throw ArgumentError("Faltan datos esenciales (email, password, profileType)");
    }
    try {
      // 1. Crear usuario Auth via CF
      print("Llamando a CF 'manageAuthUser' con action: create");
      final callable = _functions.httpsCallable('manageAuthUser');
      final result = await callable.call({'action': 'create', 'createData': createData});
      final uid = result.data['uid'] as String;

      // 2. Sanitizar datos y preparar documento unificado
      final sanitized = <String, dynamic>{
        'email': createData['email'],
        if (createData['displayName'] != null) 'displayName': createData['displayName'],
        'roles': [createData['profileType']],
      };

      switch (createData['profileType']) {
        case 'doctor':
          sanitized['doctorProfile'] = createData['profileData'] ?? {};
          break;
        case 'paciente':
          sanitized['pacienteProfile'] = createData['profileData'] ?? {};
          break;
        case 'admin':
          sanitized['adminProfile'] = createData['profileData'] ?? {};
          break;
        default:
      }

      // 3. Guardar en colección 'users'
      await _usersCollection.doc(uid).set(sanitized);
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      print("Error CF 'createUserWithProfile': ${e.code} - ${e.message} - ${e.details}");
      throw Exception("Error al crear usuario: ${e.message}");
    } catch (e) {
      print("Error desconocido en createUserWithProfile: $e");
      throw Exception("Error inesperado al crear usuario.");
    }
  }

  /// Actualiza datos de un usuario en Auth y en Firestore unificado.
  Future<Map<String, dynamic>> updateAuthUser(
    String uid,
    String profileType,
    Map<String, dynamic> updateData,
  ) async {
    if (uid.isEmpty) throw ArgumentError("UID no puede estar vacío");
    if (updateData.isEmpty) throw ArgumentError("Se requieren datos para actualizar");
    try {
      // 1. Actualizar Auth via CF
      print("Llamando a CF 'manageAuthUser' con action: update, uid: $uid");
      final callable = _functions.httpsCallable('manageAuthUser');
      final result = await callable.call({
        'action': 'update',
        'uid': uid,
        'updateData': updateData,
      });

      // 2. Preparar datos Firestore unificado
      final sanitized = <String, dynamic>{};
      if (updateData.containsKey('displayName')) {
        sanitized['displayName'] = updateData['displayName'];
      }
      if (updateData.containsKey('email')) sanitized['email'] = updateData['email'];

      // Mantener rol y perfiles
      sanitized['roles'] = FieldValue.arrayUnion([profileType]);
      if (updateData.containsKey('profileData')) {
        final key =
            profileType == 'doctor'
                ? 'doctorProfile'
                : profileType == 'paciente'
                ? 'pacienteProfile'
                : 'adminProfile';
        sanitized[key] = updateData['profileData'];
      }

      await _usersCollection.doc(uid).update(sanitized);
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      print("Error CF 'updateAuthUser': ${e.code} - ${e.message} - ${e.details}");
      throw Exception("Error al actualizar usuario Auth: ${e.message}");
    } catch (e) {
      print("Error desconocido en updateAuthUser: $e");
      throw Exception("Error inesperado al actualizar usuario Auth.");
    }
  }

  /// Elimina un usuario de Auth y su documento unificado en Firestore.
  Future<Map<String, dynamic>> deleteUserAndProfile(String uid, String profileType) async {
    if (uid.isEmpty) throw ArgumentError("UID no puede estar vacío");
    try {
      // 1. Eliminar Auth via CF
      print("Llamando a CF 'manageAuthUser' con action: delete, uid: $uid");
      final callable = _functions.httpsCallable('manageAuthUser');
      final result = await callable.call({'action': 'delete', 'uid': uid});

      // 2. Eliminar documento unificado
      await _usersCollection.doc(uid).delete();
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      print("Error CF 'deleteUserAndProfile': ${e.code} - ${e.message} - ${e.details}");
      throw Exception("Error al eliminar usuario: ${e.message}");
    } catch (e) {
      print("Error desconocido en deleteUserAndProfile: $e");
      throw Exception("Error inesperado al eliminar usuario.");
    }
  }

  // --- Métodos existentes de gestión de citas y recomendaciones se mantienen ---
  Stream<List<Cita>> getAppointmentsStream({
    String? pacienteId,
    String? doctorId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore.collection('citas').orderBy('fecha', descending: true);
    if (pacienteId != null) query = query.where('pacienteId', isEqualTo: pacienteId);
    if (doctorId != null) query = query.where('doctorId', isEqualTo: doctorId);
    if (startDate != null) {
      query = query.where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query = query.where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }
    return query
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return Cita.fromJson(data);
              }).toList(),
        )
        .handleError((error) {
          print("Error en getAppointmentsStream: $error");
          return <Cita>[];
        });
  }

  Future<DocumentReference> createAppointment(Cita cita) async {
    try {
      return await _firestore.collection('citas').add(cita.toJson());
    } catch (e) {
      print("Error createAppointment: $e");
      throw Exception("Error al crear cita: ${e.toString()}");
    }
  }

  Future<void> updateAppointment(String citaId, Map<String, dynamic> updateData) async {
    try {
      if (updateData.containsKey('fecha') && updateData['fecha'] is DateTime) {
        updateData['fecha'] = Timestamp.fromDate(updateData['fecha']);
      }
      await _firestore.collection('citas').doc(citaId).update(updateData);
    } catch (e) {
      print("Error updateAppointment: $e");
      throw Exception("Error al actualizar cita: ${e.toString()}");
    }
  }

  Future<void> deleteAppointment(String citaId) async {
    try {
      await _firestore.collection('citas').doc(citaId).delete();
    } catch (e) {
      print("Error deleteAppointment: $e");
      throw Exception("Error al eliminar cita: ${e.toString()}");
    }
  }

  Stream<List<Recomendacion>> getRecomendacionesStream(String pacienteId) {
    return _firestore
        .collection('pacientes')
        .doc(pacienteId)
        .collection('recomendaciones')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Recomendacion.fromFirestore(doc)).toList())
        .handleError((error) {
          print("Error en getRecomendacionesStream: $error");
          return <Recomendacion>[];
        });
  }

  Future<DocumentReference> saveRecomendacion(Recomendacion recomendacion) async {
    try {
      return await _firestore
          .collection('pacientes')
          .doc(recomendacion.pacienteId)
          .collection('recomendaciones')
          .add(recomendacion.toJson());
    } catch (e) {
      print("Error saveRecomendacion: $e");
      throw Exception("Error al guardar recomendación: ${e.toString()}");
    }
  }

  Future<void> deleteRecomendacion(String pacienteId, String recomendacionId) async {
    try {
      await _firestore
          .collection('pacientes')
          .doc(pacienteId)
          .collection('recomendaciones')
          .doc(recomendacionId)
          .delete();
    } catch (e) {
      print("Error deleteRecomendacion: $e");
      throw Exception("Error al eliminar recomendación: ${e.toString()}");
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAIConsultationsStream(String pacienteId) {
    if (pacienteId.isEmpty) {
      print("Advertencia: getAIConsultationsStream llamado con pacienteId vacío.");
      return FirebaseFirestore.instance.collection('empty').snapshots();
    }
    return _firestore
        .collection('pacientes')
        .doc(pacienteId)
        .collection('ai_consultations')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
