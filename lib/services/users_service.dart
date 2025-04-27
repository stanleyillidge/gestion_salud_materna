// D:\proyectos\gestion_salud_materna\lib\services\users_service.dart

// ... (otros imports y código existente) ...

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/modelos.dart';

class UsersService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Cambiado a minúscula por convención

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

  /// Actualiza un usuario en Auth y su perfil unificado en Firestore.
  Future<Map<String, dynamic>> updateUserWithProfile(
    String uid,
    Map<String, dynamic> updateData,
  ) async {
    if (uid.isEmpty) throw ArgumentError("UID no puede estar vacío para actualizar");
    if (updateData.isEmpty) {
      print("Advertencia: Intento de actualización sin datos para UID $uid.");
      return {'success': true, 'message': 'No se proporcionaron datos para actualizar.'};
    }

    // 1. Preparar datos para Auth (vía Cloud Function)
    final authUpdateData = <String, dynamic>{};
    if (updateData.containsKey('email') && updateData['email'] != null) {
      // Considera la seguridad al cambiar email. Puede requerir re-autenticación.
      // La Cloud Function debería manejar esto idealmente. Por ahora, lo pasamos.
      // IMPORTANTE: En esta implementación, el campo email está deshabilitado en el form.
      // authUpdateData['email'] = updateData['email'];
    }
    if (updateData.containsKey('displayName') && updateData['displayName'] != null) {
      authUpdateData['displayName'] = updateData['displayName'];
    }
    // NOTA: La contraseña NO se actualiza aquí. Es un flujo separado.
    // Puedes añadir lógica para 'photoURL' o 'disabled' si es necesario aquí o en la CF.

    // 2. Preparar datos para Firestore
    final firestoreUpdateData = <String, dynamic>{};
    if (updateData.containsKey('displayName') && updateData['displayName'] != null) {
      firestoreUpdateData['displayName'] = updateData['displayName'];
    }
    // Email no se actualiza en Firestore si no cambia en Auth.
    // Roles generalmente no se cambian en edición simple, pero podrías añadir lógica si fuera necesario.

    // Actualizar el perfil específico
    if (updateData.containsKey('profileData') && updateData['profileData'] is Map) {
      final profileData = updateData['profileData'] as Map<String, dynamic>;
      final profileType = updateData['profileType'] as String?; // Obtener el tipo de perfil

      if (profileType != null) {
        // Usamos notación de puntos para actualizar campos DENTRO del perfil
        profileData.forEach((key, value) {
          // Convertir DateTime a Timestamp ANTES de guardar
          if (value is DateTime) {
            firestoreUpdateData['${profileType}Profile.$key'] = Timestamp.fromDate(value);
          } else if (value is GeoPoint) {
            // Asegurar que GeoPoint se guarda correctamente
            firestoreUpdateData['${profileType}Profile.$key'] = value;
          } else if (value != null) {
            // Solo actualizar si no es null
            // Convierte listas de strings correctamente
            if (key == 'alergias' ||
                key == 'enfermedadesPreexistentes' ||
                key == 'medicamentos' ||
                key == 'specialties') {
              if (value is List && value.every((item) => item is String)) {
                firestoreUpdateData['${profileType}Profile.$key'] = value;
              } else {
                print("Advertencia: El campo '$key' no es una lista de Strings válida, se omite.");
              }
            } else {
              firestoreUpdateData['${profileType}Profile.$key'] = value;
            }
          } else {
            // Si el valor es null en el form, podemos decidir eliminar el campo en Firestore
            // firestoreUpdateData['${profileType}Profile.$key'] = FieldValue.delete();
            // O simplemente no lo incluimos en la actualización para que mantenga su valor actual si existe
          }
        });
        // Asegúrate que el UID en el perfil (si existe) no se sobrescriba incorrectamente
        firestoreUpdateData.remove('${profileType}Profile.uid');
      }
    }
    // Añadir timestamp de última actualización
    firestoreUpdateData['lastUpdated'] = FieldValue.serverTimestamp();

    try {
      // 3. Llamar a Cloud Function para actualizar Auth (SI HAY DATOS PARA AUTH)
      Map<String, dynamic> cfResult = {
        'success': true,
        'message': 'No se requirió actualización de Auth.',
      };
      if (authUpdateData.isNotEmpty) {
        print("Llamando a CF 'manageAuthUser' con action: update, uid: $uid");
        final callable = _functions.httpsCallable('manageAuthUser');
        // Envuelve en 'data' si tu CF espera esa estructura
        final result = await callable.call({
          'data': {'action': 'update', 'uid': uid, 'updateData': authUpdateData},
        });
        cfResult = Map<String, dynamic>.from(result.data);
        print("Respuesta CF 'update': $cfResult");
        if (cfResult['success'] != true) {
          throw Exception(
            cfResult['message'] ?? 'Error desconocido de Cloud Function al actualizar Auth.',
          );
        }
      }

      // 4. Actualizar documento en Firestore (SI HAY DATOS PARA FIRESTORE)
      if (firestoreUpdateData.isNotEmpty) {
        print("Actualizando Firestore para $uid con: $firestoreUpdateData");
        await _usersCollection.doc(uid).update(firestoreUpdateData);
        print("Firestore actualizado para $uid");
      } else {
        print("No hay datos para actualizar en Firestore para $uid.");
      }

      // 5. Devolver resultado combinado o de la CF
      return {
        'success': true,
        'message': cfResult['message'] ?? 'Usuario actualizado (Firestore/Auth)',
        'uid': uid, // Devolver uid puede ser útil
      };
    } on FirebaseFunctionsException catch (e) {
      print("Error CF 'updateUserWithProfile': ${e.code} - ${e.message} - ${e.details}");
      // Puedes intentar deshacer cambios en Firestore si Auth falló, aunque es complejo.
      throw Exception("Error al actualizar usuario (Auth): ${e.message}");
    } on FirebaseException catch (e) {
      print("Error Firestore 'updateUserWithProfile': ${e.code} - ${e.message}");
      throw Exception("Error al actualizar perfil en base de datos: ${e.message}");
    } catch (e) {
      print("Error desconocido en updateUserWithProfile para $uid: $e");
      throw Exception("Error inesperado al actualizar usuario.");
    }
  }

  // ... (método deleteUserAndProfile y otros métodos existentes) ...
  /// Elimina un usuario de Auth y su documento unificado en Firestore.
  Future<Map<String, dynamic>> deleteUserAndProfile(String uid, String profileType) async {
    if (uid.isEmpty) throw ArgumentError("UID no puede estar vacío");
    try {
      // 1. Eliminar Auth via CF (La CF DEBE llamar a la limpieza de Firestore también)
      print("Llamando a CF 'manageAuthUser' para ELIMINACIÓN COMPLETA, uid: $uid");
      final callable = _functions.httpsCallable('manageAuthUser');
      // La CF debe encargarse de borrar Auth y luego borrar el doc de Firestore
      final result = await callable.call({
        'data': {'action': 'delete', 'uid': uid},
      });

      print("Respuesta CF 'delete': ${result.data}");

      if (result.data?['success'] != true) {
        throw Exception(
          result.data?['message'] ?? 'Error desconocido de Cloud Function al eliminar.',
        );
      }

      // 2. (Opcional) Verificar que el documento ya no existe en Firestore (la CF debería haberlo hecho)
      // final docExists = (await _usersCollection.doc(uid).get()).exists;
      // if (docExists) {
      //    print("Advertencia: El documento Firestore para $uid aún existe después de llamar a la CF de borrado.");
      // }

      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      print("Error CF 'deleteUserAndProfile': ${e.code} - ${e.message} - ${e.details}");
      throw Exception("Error al eliminar usuario (CF): ${e.message}");
    } catch (e) {
      print("Error desconocido en deleteUserAndProfile: $e");
      throw Exception("Error inesperado al eliminar usuario.");
    }
  }
}

/* // users_service.dart
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
 */
