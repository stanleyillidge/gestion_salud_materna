// firestore_service.dart
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/modelos.dart'; // Asegúrate que la ruta sea correcta

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // La Cloud Function ya no es necesaria para esta función específica
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  CollectionReference<Map<String, dynamic>> get _usersCollection => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _pacientesCollection => _db.collection('pacientes');
  // En FirestoreService

  // Helper para borrar subcolecciones (se mantiene igual)
  Future<int> _deleteSubcollectionBatch(String userId, String subcollectionName) async {
    // ... (código del helper como en la respuesta anterior) ...
    if (userId.isEmpty || subcollectionName.isEmpty) {
      print("Error: _deleteSubcollectionBatch requiere userId y subcollectionName válidos.");
      return 0;
    }
    print("  -> Iniciando borrado de subcolección '$subcollectionName' para usuario $userId...");
    final CollectionReference subcollectionRef = _usersCollection
        .doc(userId)
        .collection(subcollectionName);
    int deletedCount = 0;
    const int subBatchLimit = 100; // Límite más pequeño para subcolecciones puede ser prudente
    bool hasMoreDocs = true;
    QuerySnapshot? lastBatchSnapshot;

    while (hasMoreDocs) {
      Query query = subcollectionRef.limit(subBatchLimit);
      if (lastBatchSnapshot != null && lastBatchSnapshot.docs.isNotEmpty) {
        query = query.startAfterDocument(lastBatchSnapshot.docs.last);
      }

      final QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        hasMoreDocs = false;
        print("  -> No hay más documentos en '$subcollectionName' para $userId.");
      } else {
        print(
          "  -> Procesando lote de ${snapshot.docs.length} documentos en '$subcollectionName' para $userId...",
        );
        WriteBatch subBatch = _db.batch();
        for (final doc in snapshot.docs) {
          subBatch.delete(doc.reference);
          deletedCount++;
        }
        try {
          await subBatch.commit();
          print(
            "  -> Lote de ${snapshot.docs.length} documentos de '$subcollectionName' eliminado para $userId.",
          );
          if (snapshot.docs.isNotEmpty) {
            // Solo actualiza si hubo documentos
            lastBatchSnapshot = snapshot;
          }
          // Pequeña pausa
          await Future.delayed(const Duration(milliseconds: 50));
        } catch (e) {
          print("  -> ¡ERROR al borrar lote de '$subcollectionName' para $userId!: $e");
          // Decide si reintentar, abortar o solo loguear y continuar
          // Por ahora, logueamos y continuamos, pero podrías lanzar la excepción
          throw Exception(
            "Error crítico borrando subcolección '$subcollectionName' para $userId: $e",
          );
        }
      }
    }
    print(
      "  -> Finalizado borrado de subcolección '$subcollectionName' para $userId. Total eliminados: $deletedCount",
    );
    return deletedCount;
  }

  // Helper para llamar a CF y borrar Auth (se mantiene igual)
  Future<void> deleteUserAuth(String uid) async {
    // ... (código del helper como en la respuesta anterior) ...
    if (uid.isEmpty) throw ArgumentError("UID no puede estar vacío para borrado Auth");
    try {
      print("  -> Llamando a CF 'manageAuthUser' action: delete, uid: $uid");
      final HttpsCallable callable = _functions.httpsCallable('manageAuthUser');
      // La Cloud Function 'manageAuthUser' con action 'delete'
      // SÓLO debería borrar el usuario de Auth.
      // La limpieza de Firestore ya se hizo aquí.
      final params = {'action': 'delete', 'uid': uid};
      final HttpsCallableResult result = await callable.call({
        'data': params,
      }); // Envolver en 'data'

      if (result.data?['success'] != true) {
        final String errorMessage =
            result.data?['message'] ?? 'La CF reportó un error no especificado al borrar Auth.';
        print("     - Error reportado por Cloud Function al borrar Auth $uid: $errorMessage");
        throw Exception("Error de Cloud Function al borrar Auth: $errorMessage");
      }
      print("     - Usuario Auth $uid eliminado exitosamente (respuesta CF).");
    } on FirebaseFunctionsException catch (e) {
      print(
        "     - Error de Cloud Function ('deleteUserAuth') para $uid: ${e.code} - ${e.message}",
      );
      // Relanzar para que sea capturado por el llamador y contado como error
      throw Exception("Error al contactar el servicio de eliminación Auth: ${e.message ?? e.code}");
    } catch (e) {
      print("     - Error inesperado en deleteUserAuth para $uid: $e");
      // Relanzar para que sea capturado por el llamador y contado como error
      throw Exception("Error inesperado al intentar eliminar el usuario Auth: ${e.toString()}");
    }
  }

  /// Borra usuarios de Firestore (incluyendo subcolecciones 'clinical_records')
  /// y luego llama a una Cloud Function para borrar de Firebase Auth.
  /// EXCEPTO aquellos cuyos IDs estén en `uidsToKeep`.
  ///
  /// ¡¡ADVERTENCIA!! Operación destructiva. Usar con extrema precaución.
  Future<Map<String, int>> deleteAllUsersExcept(List<String> uidsToKeep) async {
    // ... (Implementación COMPLETA de esta función como se mostró en la respuesta ANTERIOR a la última)
    // Incluye el bucle principal, la llamada a _deleteSubcollectionBatch,
    // el commit del mainBatch, y la llamada a deleteUserAuth para cada ID borrado de Firestore.
    // ...
    print('--- INICIANDO BORRADO MASIVO COMPLETO (Firestore + Auth) ---');
    print('¡ADVERTENCIA! ESTA ACCIÓN ES IRREVERSIBLE.');
    if (uidsToKeep.isEmpty) {
      print('ERROR CRÍTICO: La lista de IDs a mantener está vacía. Abortando borrado masivo.');
      return {'mainDocsDeleted': 0, 'subDocsDeleted': 0, 'authDeleted': 0, 'errors': 1};
    }
    print('Usuarios a MANTENER (${uidsToKeep.length}): ${uidsToKeep.join(', ')}');
    print('Confirmación asumida (debe implementarse en la UI). Procediendo...');

    int mainDocsDeletedCount = 0;
    int subDocsDeletedCount = 0;
    int authDeletionAttempts = 0;
    int authDeletionSuccesses = 0;
    int firestoreErrorCount = 0;
    int authErrorCount = 0;

    const int batchLimit = 200; // Reducir un poco el límite por la complejidad añadida
    WriteBatch mainBatch = _db.batch();
    int batchCounter = 0;
    bool moreDocs = true;
    DocumentSnapshot? lastVisibleDoc;
    List<String> idsInCurrentBatch = []; // IDs de usuarios en el batch actual de Firestore

    final Set<String> keepSet = uidsToKeep.toSet();

    while (moreDocs) {
      print('Obteniendo siguiente lote de documentos principales...');
      Query query = _usersCollection.orderBy(FieldPath.documentId).limit(batchLimit);
      if (lastVisibleDoc != null) {
        query = query.startAfterDocument(lastVisibleDoc);
      }

      try {
        final QuerySnapshot snapshot = await query.get();

        if (snapshot.docs.isEmpty) {
          print('No hay más documentos principales para procesar.');
          moreDocs = false;
        } else {
          print('Procesando ${snapshot.docs.length} documentos principales...');
          if (snapshot.docs.isNotEmpty) {
            lastVisibleDoc = snapshot.docs.last;
          } else {
            lastVisibleDoc = null; // Asegurar que sea null si no hay más docs
          }

          for (final doc in snapshot.docs) {
            final userId = doc.id;
            if (!keepSet.contains(userId)) {
              print('  * Procesando para borrar: $userId');

              // 1. Borrar Subcolección 'clinical_records'
              try {
                int deletedSubDocs = await _deleteSubcollectionBatch(userId, 'clinical_records');
                subDocsDeletedCount += deletedSubDocs;
                // Añadir aquí borrado de otras subcolecciones si es necesario
              } catch (e) {
                print(
                  "  -> ERROR borrando subcolección 'clinical_records' para $userId: $e. Se continuará.",
                );
                firestoreErrorCount++;
              }

              // 2. Añadir Documento Principal al Batch de Firestore
              mainBatch.delete(doc.reference);
              idsInCurrentBatch.add(userId);
              batchCounter++;
              print('  - Marcado documento principal para borrar: $userId');

              // 3. Ejecutar Batch de Firestore si alcanza el límite
              if (batchCounter >= batchLimit) {
                print('--> Ejecutando batch Firestore (límite $batchLimit alcanzado)...');
                try {
                  await mainBatch.commit();
                  print(
                    '--> Batch Firestore ejecutado. ${idsInCurrentBatch.length} documentos principales.',
                  );
                  mainDocsDeletedCount += idsInCurrentBatch.length;

                  // 4. Llamar a Cloud Function para borrar Auth DESPUÉS de commit exitoso
                  print('--> Intentando borrar usuarios de Auth para el lote...');
                  for (String idToDelete in idsInCurrentBatch) {
                    authDeletionAttempts++;
                    try {
                      await deleteUserAuth(idToDelete);
                      print("  - Solicitud CF delete enviada para Auth UID: $idToDelete");
                      authDeletionSuccesses++;
                    } catch (e) {
                      print("  - ERROR llamando a CF delete para Auth UID $idToDelete: $e");
                      authErrorCount++;
                    }
                    await Future.delayed(const Duration(milliseconds: 100)); // Pausa
                  }
                  print('--> Borrado Auth para lote finalizado.');
                } catch (e) {
                  print('--> ¡ERROR al ejecutar batch Firestore!: $e');
                  firestoreErrorCount++;
                } finally {
                  mainBatch = _db.batch();
                  batchCounter = 0;
                  idsInCurrentBatch.clear();
                  await Future.delayed(const Duration(milliseconds: 200));
                }
              } // Fin if batchCounter >= batchLimit
            } else {
              print('  - MANTENIENDO: $userId');
            }
          } // Fin for docs
        } // Fin else snapshot.docs.isNotEmpty
      } catch (e) {
        print('¡ERROR obteniendo lote de documentos principales!: $e');
        firestoreErrorCount++;
        await Future.delayed(const Duration(seconds: 2));
      }
    } // Fin while moreDocs

    // Commit final del batch Firestore si quedan operaciones
    if (batchCounter > 0) {
      print('--> Ejecutando batch final Firestore ($batchCounter operaciones)...');
      try {
        await mainBatch.commit();
        print(
          '--> Batch final Firestore ejecutado. ${idsInCurrentBatch.length} documentos principales.',
        );
        mainDocsDeletedCount += idsInCurrentBatch.length;

        print('--> Intentando borrar usuarios de Auth para el lote final...');
        for (String idToDelete in idsInCurrentBatch) {
          authDeletionAttempts++;
          try {
            await deleteUserAuth(idToDelete);
            print("  - Solicitud CF delete enviada para Auth UID: $idToDelete");
            authDeletionSuccesses++;
          } catch (e) {
            print("  - ERROR llamando a CF delete para Auth UID $idToDelete: $e");
            authErrorCount++;
          }
          await Future.delayed(const Duration(milliseconds: 100));
        }
        print('--> Borrado Auth para lote finalizado.');
      } catch (e) {
        print('--> ¡ERROR al ejecutar batch final Firestore!: $e');
        firestoreErrorCount++;
      }
    }

    print('--- BORRADO MASIVO COMPLETO FINALIZADO ---');
    print('Documentos Principales (users) Eliminados: $mainDocsDeletedCount');
    print('Documentos Subcolección (clinical_records) Eliminados: $subDocsDeletedCount');
    print('Intentos de Borrado Auth (CF): $authDeletionAttempts');
    print('Borrado Auth Exitoso (CF): $authDeletionSuccesses');
    print('Errores Firestore (main/sub): $firestoreErrorCount');
    print('Errores Borrado Auth (CF): $authErrorCount');

    return {
      'mainDocsDeleted': mainDocsDeletedCount,
      'subDocsDeleted': subDocsDeletedCount,
      'authDeleted': authDeletionSuccesses,
      'errors': firestoreErrorCount + authErrorCount,
    };
  }

  // En FirestoreService

  /// Borra los documentos de Firestore (colección 'users' y subcolección 'clinical_records')
  /// para todos los usuarios con el rol 'paciente', EXCEPTO los IDs en `uidsToKeep`.
  /// NO afecta a Firebase Authentication.
  ///
  /// ¡¡ADVERTENCIA!! Operación destructiva en Firestore. Usar con precaución.
  Future<Map<String, int>> deleteFirestorePatientsExcept(List<String> uidsToKeep) async {
    // ... (Implementación COMPLETA de esta función como se mostró en la respuesta ANTERIOR)
    // Incluye el bucle principal filtrando por rol 'paciente', la llamada
    // a _deleteSubcollectionBatch y el commit del mainBatch. NO llama a deleteUserAuth.
    // ...
    print('--- INICIANDO BORRADO MASIVO *FIRESTORE* PARA PACIENTES ---');
    print('Usuarios de AUTHENTICATION NO serán afectados.');
    if (uidsToKeep.isEmpty) {
      print('ERROR CRÍTICO: La lista de IDs a mantener está vacía. Abortando borrado.');
      return {'patientsDeleted': 0, 'clinicalRecordsDeleted': 0, 'errors': 1};
    }
    print('Pacientes a MANTENER (${uidsToKeep.length}): ${uidsToKeep.join(', ')}');
    print('Confirmación asumida (UI debe confirmar). Procediendo...');

    int patientsDeletedCount = 0;
    int clinicalRecordsDeletedCount = 0;
    int errorCount = 0;

    const int batchLimit = 400; // Límite para el batch principal
    WriteBatch mainBatch = _db.batch();
    int batchCounter = 0;
    bool moreDocs = true;
    DocumentSnapshot? lastVisibleDoc;

    final Set<String> keepSet = uidsToKeep.toSet();

    while (moreDocs) {
      print('Obteniendo lote de documentos de pacientes...');
      // Query específica para PACIENTES
      Query query = _pacientesCollection.orderBy(FieldPath.documentId).limit(batchLimit);

      if (lastVisibleDoc != null) {
        query = query.startAfterDocument(lastVisibleDoc);
      }

      try {
        final QuerySnapshot snapshot = await query.get();

        if (snapshot.docs.isEmpty) {
          print('No hay más documentos de pacientes para procesar.');
          moreDocs = false;
        } else {
          print('Procesando ${snapshot.docs.length} documentos de pacientes...');
          if (snapshot.docs.isNotEmpty) {
            lastVisibleDoc = snapshot.docs.last;
          } else {
            lastVisibleDoc = null; // Asegurar que sea null si no hay más docs
          }

          for (final doc in snapshot.docs) {
            final userId = doc.id;

            if (!keepSet.contains(userId)) {
              print('  * Preparando para borrar paciente Firestore: $userId');

              // 1. Borrar Subcolección 'clinical_records' (y otras si aplica)
              try {
                int deletedSubDocs = await _deleteSubcollectionBatch(userId, 'clinical_records');
                clinicalRecordsDeletedCount += deletedSubDocs;
                // Añadir aquí borrado de otras subcolecciones si es necesario
                // int deletedRecomendations = await _deleteSubcollectionBatch(userId, 'recomendations'); // Ejemplo
                // int deletedConsultations = await _deleteSubcollectionBatch(userId, 'ai_consultations'); // Ejemplo
              } catch (e) {
                print(
                  "  -> ERROR borrando subcolecciones para $userId: $e. Abortando borrado para este usuario.",
                );
                errorCount++;
                continue; // Saltar al siguiente usuario si fallan las subcolecciones
              }

              // 2. Añadir Documento Principal al Batch de Firestore
              mainBatch.delete(doc.reference);
              batchCounter++;
              print('  - Marcado documento principal del paciente para borrar: $userId');

              // 3. Ejecutar Batch de Firestore si alcanza el límite
              if (batchCounter >= batchLimit) {
                print('--> Ejecutando batch Firestore (límite $batchLimit alcanzado)...');
                try {
                  await mainBatch.commit();
                  patientsDeletedCount += batchCounter; // Sumar los borrados en este batch
                  print(
                    '--> Batch Firestore ejecutado. $batchCounter pacientes procesados en este lote.',
                  );
                } catch (e) {
                  print('--> ¡ERROR al ejecutar batch Firestore!: $e');
                  errorCount++;
                  // Podrías intentar guardar los IDs que fallaron para reintentar
                } finally {
                  // Resetear siempre el batch y contador
                  mainBatch = _db.batch();
                  batchCounter = 0;
                  await Future.delayed(const Duration(milliseconds: 100)); // Pausa
                }
              }
            } else {
              print('  - MANTENIENDO Paciente Firestore: $userId');
            }
          } // Fin for docs
        } // Fin else snapshot.docs.isNotEmpty
      } catch (e) {
        print('¡ERROR obteniendo lote de documentos de pacientes!: $e');
        errorCount++;
        await Future.delayed(const Duration(seconds: 1)); // Pausa antes de reintentar
      }
    } // Fin while moreDocs

    // Commit final del batch Firestore si quedan operaciones
    if (batchCounter > 0) {
      print('--> Ejecutando batch final Firestore ($batchCounter pacientes)...');
      try {
        await mainBatch.commit();
        patientsDeletedCount += batchCounter; // Sumar los borrados en el último batch
        print('--> Batch final Firestore ejecutado.');
      } catch (e) {
        print('--> ¡ERROR al ejecutar batch final Firestore!: $e');
        errorCount++;
      }
    }

    print('--- BORRADO MASIVO *FIRESTORE* PARA PACIENTES FINALIZADO ---');
    print('Documentos Principales (pacientes en /users) Eliminados: $patientsDeletedCount');
    print('Documentos Subcolección (clinical_records) Eliminados: $clinicalRecordsDeletedCount');
    print('Errores Encontrados: $errorCount');

    return {
      'patientsDeleted': patientsDeletedCount,
      'clinicalRecordsDeleted': clinicalRecordsDeletedCount,
      'errors': errorCount,
    };
  }

  // --- Resto de métodos del servicio (como getUserStream, addClinicalRecord, etc.) ---
  // ... (mantener los otros métodos que no están relacionados con el borrado masivo de Auth)
  /// *** NUEVO: Stream para un usuario específico por UID ***
  /// Escucha cambios en tiempo real para un documento de usuario.
  Stream<Usuario?> getUserStream(String userId) {
    if (userId.isEmpty) {
      // Retorna un stream que emite null si el ID está vacío
      return Stream.value(null);
    }
    return _usersCollection
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            try {
              return Usuario.fromFirestore(snapshot);
            } catch (e) {
              print('Error parseando usuario en stream (ID: $userId): $e');
              return null; // Devuelve null si hay error de parseo
            }
          } else {
            return null; // Devuelve null si el documento no existe
          }
        })
        .handleError((error) {
          print('Error en getUserStream (ID: $userId): $error');
          // Podrías retornar un Stream.error o un stream con null
          return null;
        });
  }

  // --- Gestión de Pacientes (Usuarios con rol paciente) ---

  /// Stream de pacientes (Usuario) asignados a un doctor específico.
  Stream<List<Usuario>> getDoctorpacientesStream(String doctorId) {
    return _usersCollection
        .where('roles', arrayContains: 'paciente')
        .where('pacienteProfile.doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Usuario.fromFirestore(doc)).toList())
        .handleError((error) {
          print('Error en getDoctorpacientesStream: $error');
          return <Usuario>[];
        });
  }

  /// Stream de todos los pacientes.
  Stream<List<Usuario>> getAllpacientesStream() {
    return _usersCollection
        .where('roles', arrayContains: 'paciente')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Usuario.fromFirestore(doc)).toList())
        .handleError((error) {
          print('Error en getAllpacientesStream: $error');
          return <Usuario>[];
        });
  }

  /// Stream de pacientes sin asignación de doctor.
  Stream<List<Usuario>> getUnassignedpacientesStream() {
    return _usersCollection
        .where('roles', arrayContains: 'paciente')
        .where('pacienteProfile.doctorId', isNull: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Usuario.fromFirestore(doc)).toList())
        .handleError((error) {
          print('Error en getUnassignedpacientesStream: $error');
          return <Usuario>[];
        });
  }

  /// Obtiene detalle del paciente como [Usuario].
  Future<Usuario?> getpacienteDetails(String pacienteId) async {
    try {
      final doc = await _usersCollection.doc(pacienteId).get();
      return doc.exists ? Usuario.fromFirestore(doc) : null;
    } catch (e) {
      print('Error getpacienteDetails: $e');
      return null;
    }
  }

  /// Asigna un doctor al perfil de paciente (actualiza campo en pacienteProfile).
  Future<void> assignDoctorTopaciente(String pacienteId, String doctorId) async {
    try {
      await _usersCollection.doc(pacienteId).update({'pacienteProfile.doctorId': doctorId});
      print('Doctor $doctorId asignado a paciente $pacienteId');
    } catch (e) {
      print('Error assignDoctorTopaciente: $e');
      throw Exception('Error al asignar doctor: $e');
    }
  }

  /// Elimina la asignación de doctor del paciente.
  Future<void> removeDoctorAssignment(String pacienteId) async {
    try {
      await _usersCollection.doc(pacienteId).update({
        'pacienteProfile.doctorId': FieldValue.delete(), // Elimina el campo
      });
      print('Asignación de doctor removida para paciente $pacienteId');
    } catch (e) {
      print('Error removeDoctorAssignment: $e');
      throw Exception('Error al quitar asignación: $e');
    }
  }

  // --- Gestión de Doctores ---

  /// Stream de todos los usuarios con rol doctor.
  Stream<List<Usuario>> getAllDoctorsStream() {
    return _usersCollection
        .where('roles', arrayContains: 'doctor')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Usuario.fromFirestore(doc)).toList())
        .handleError((error) {
          print('Error en getAllDoctorsStream: $error');
          return <Usuario>[];
        });
  }

  // --- Gestión de Admins ---

  /// Stream de todos los usuarios con rol admin.
  Stream<List<Usuario>> getAllAdminsStream() {
    return _usersCollection
        .where('roles', arrayContains: 'admin')
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((doc) {
                    try {
                      return Usuario.fromFirestore(doc);
                    } catch (e) {
                      print("Error parsing admin document ID: ${doc.id}");
                      print("Doc data: ${doc.data()}");
                      print("Error details: $e");
                      return null;
                    }
                  })
                  .whereType<Usuario>()
                  .toList(),
        )
        .handleError((error) {
          print('Error en getAllAdminsStream (handleError): $error');
          return <Usuario>[];
        });
  }

  // --- Gestión de Roles ---

  /// Actualiza la lista de roles de un usuario en Firestore.
  Future<void> updateUserRole(String userId, String newRole) async {
    print('ADVERTENCIA: Actualizando sólo la lista de roles en Firestore para $userId a $newRole.');
    try {
      await _usersCollection.doc(userId).update({
        'roles': [newRole], // Sobrescribe la lista de roles con el nuevo rol
      });
      print('Roles actualizados en Firestore para $userId: [$newRole]');
    } catch (e) {
      print('Error updateUserRole: $e');
      throw Exception('Error al actualizar rol en Firestore: $e');
    }
  }

  // --- Gestión de Citas ---

  Stream<List<Cita>> getAppointmentsStream({
    String? pacienteId,
    String? doctorId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _db.collection('citas').orderBy('fecha', descending: true);
    if (pacienteId != null) query = query.where('pacienteId', isEqualTo: pacienteId);
    if (doctorId != null) query = query.where('doctorId', isEqualTo: doctorId);
    if (startDate != null)
      query = query.where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    if (endDate != null) {
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query = query.where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }
    return query
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return Cita.fromJson(data);
              }).toList(),
        )
        .handleError((error) {
          print('Error en getAppointmentsStream: $error');
          return <Cita>[];
        });
  }

  Future<DocumentReference> createAppointment(Cita cita) async {
    try {
      return await _db.collection('citas').add(cita.toJson());
    } catch (e) {
      print('Error createAppointment: $e');
      throw Exception('Error al crear cita: $e');
    }
  }

  Future<void> updateAppointment(String citaId, Map<String, dynamic> updateData) async {
    try {
      if (updateData.containsKey('fecha') && updateData['fecha'] is DateTime) {
        updateData['fecha'] = Timestamp.fromDate(updateData['fecha']);
      }
      await _db.collection('citas').doc(citaId).update(updateData);
    } catch (e) {
      print('Error updateAppointment: $e');
      throw Exception('Error al actualizar cita: $e');
    }
  }

  Future<void> deleteAppointment(String citaId) async {
    try {
      await _db.collection('citas').doc(citaId).delete();
    } catch (e) {
      print('Error deleteAppointment: $e');
      throw Exception('Error al eliminar cita: $e');
    }
  }

  // --- Gestión de Recomendaciones en usuario ---

  /// Stream de recomendaciones recibidas para un paciente.
  Stream<List<Recomendacion>> getRecomendacionesStream(String pacienteId) {
    return _usersCollection
        .doc(pacienteId)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          return (data?['recomendacionesRecibidas'] as List?)
                  ?.map((m) => Recomendacion.fromJson(m as Map<String, dynamic>))
                  .toList() ??
              <Recomendacion>[];
        })
        .handleError((error) {
          print('Error en getRecomendacionesStream: $error');
          return <Recomendacion>[];
        });
  }

  /// Guarda una nueva recomendación en el array de recibidas del paciente.
  Future<void> saveRecomendacion(String pacienteId, Recomendacion recomendacion) async {
    try {
      await _usersCollection.doc(pacienteId).update({
        'recomendacionesRecibidas': FieldValue.arrayUnion([recomendacion.toJson()]),
      });
    } catch (e) {
      print('Error saveRecomendacion: $e');
      throw Exception('Error al guardar recomendación: $e');
    }
  }

  /// Elimina una recomendación del array de recibidas.
  Future<void> deleteRecomendacion(String pacienteId, Recomendacion recomendacion) async {
    try {
      // Importante: arrayRemove necesita el objeto EXACTO para eliminarlo.
      // Asegúrate que recomendacion.toJson() produzca el mismo mapa que se guardó.
      await _usersCollection.doc(pacienteId).update({
        'recomendacionesRecibidas': FieldValue.arrayRemove([recomendacion.toJson()]),
      });
    } catch (e) {
      print('Error deleteRecomendacion: $e');
      throw Exception('Error al eliminar recomendación: $e');
    }
  }

  // --- Gestión de Logs de Consultas IA ---
  Future<void> saveAIConsultationLog({
    required String pacienteId,
    required String doctorId,
    required String inputPrompt, // <-- CAMBIO: Ahora es el prompt formateado
    required String modelResponse, // La respuesta parseada (Bajo, Moderado, etc. o error)
    required String modelName, // Nombre del endpoint
    required String proyectId,
    required String location,
  }) async {
    if (pacienteId.isEmpty) throw ArgumentError('pacienteId es requerido');
    try {
      // Colección dentro del documento del usuario
      await _usersCollection.doc(pacienteId).collection('ai_consultations').add({
        'doctorId': doctorId,
        'timestamp': FieldValue.serverTimestamp(),
        'inputPrompt': inputPrompt, // Guardar el texto exacto enviado al modelo
        'modelResponse': modelResponse, // Guardar la respuesta parseada
        'modelVersion': modelName, // Guardar el ID/nombre del endpoint
        'proyectId': proyectId,
        'location': location,
      });
      print('Log de consulta IA guardado para paciente $pacienteId');
    } catch (e) {
      print('Error saveAIConsultationLog: $e');
      // No relanzar excepción aquí para no interrumpir el flujo principal si solo falla el log
      // throw Exception('Error al guardar log IA: $e');
    }
  }

  // ... (resto de los métodos de FirestoreService sin cambios) ...
  Stream<QuerySnapshot<Map<String, dynamic>>> getAIConsultationsStream(String pacienteId) {
    if (pacienteId.isEmpty) {
      print("Advertencia: getAIConsultationsStream llamado con pacienteId vacío.");
      return Stream.value(
        FirebaseFirestore.instance.collection('empty').snapshots()
            as QuerySnapshot<Map<String, dynamic>>,
      ); // Devuelve stream vacío
    }
    return _usersCollection
        .doc(pacienteId)
        .collection('ai_consultations')
        .orderBy('timestamp', descending: true) // Ordenar por fecha, más recientes primero
        .snapshots() // Devuelve un stream de QuerySnapshot
        .handleError((error) {
          // Manejar errores en el stream
          print("Error en getAIConsultationsStream para paciente $pacienteId: $error");
          // Puedes devolver un stream de error o un snapshot vacío
          // throw error; // O relanzar si quieres que el StreamBuilder muestre error
          return FirebaseFirestore.instance.collection('empty').snapshots();
        });
  }

  // --- Gestión de Historia Clínica (Subcolección) -----------------------
  /// Stream para obtener registros clínicos ordenados por fecha.
  /// Stream para obtener registros clínicos ordenados por fecha.
  Stream<List<DatosClinicos>> getClinicalRecordsStream(String pacienteId) {
    if (pacienteId.isEmpty) {
      print("Advertencia: getClinicalRecordsStream llamado con pacienteId vacío.");
      return Stream.value([]); // Devuelve stream vacío si no hay ID
    }
    print("Obteniendo stream para: users/$pacienteId/clinical_records"); // Log para verificar path

    return _usersCollection // Usa la referencia a la colección principal
        .doc(pacienteId)
        .collection('clinical_records') // Nombre EXACTO de la subcolección
        .orderBy('timestamp', descending: true) // Campo EXACTO para ordenar
        .snapshots()
        .map((snapshot) {
          print(
            "Stream recibió ${snapshot.docs.length} documentos para $pacienteId",
          ); // Log de cuántos docs llegan
          return snapshot.docs
              .map((doc) {
                try {
                  // El factory necesita el ID del documento y parsear el timestamp
                  print("Parseando doc ID: ${doc.id}"); // Log del ID que se parsea
                  return DatosClinicos.fromMap(doc.data(), doc.id);
                } catch (e) {
                  print("Error parseando DatosClinicos Doc ID ${doc.id}: $e");
                  print("Datos del documento con error: ${doc.data()}");
                  // Decide cómo manejar el error: devolver null y filtrar, o lanzar
                  // Devolver null es más seguro para que la UI no falle completamente
                  return null;
                }
              })
              .whereType<DatosClinicos>() // Filtra los nulls si hubo errores de parseo
              .toList();
        })
        .handleError((error) {
          print('Error en getClinicalRecordsStream para $pacienteId: $error');
          return <DatosClinicos>[]; // Devolver lista vacía en caso de error del stream
        });
  }

  /// Añade un nuevo registro clínico a la subcolección.
  Future<void> addClinicalRecord(String pacienteId, DatosClinicos record) async {
    if (pacienteId.isEmpty) throw ArgumentError("userId no puede estar vacío");
    try {
      final dataToSave = record.toMap();
      // ASEGURAR QUE EL TIMESTAMP SEA DE SERVIDOR AL CREAR
      dataToSave['timestamp'] = FieldValue.serverTimestamp();

      await _db
          .collection('users')
          .doc(pacienteId)
          .collection('clinical_records')
          .add(dataToSave); // add() genera ID automático

      print('Nuevo registro clínico añadido para paciente $pacienteId');
    } catch (e) {
      print('Error addClinicalRecord: $e');
      throw Exception('Error al añadir registro clínico: $e');
    }
  }

  /// Elimina un registro clínico específico (USAR CON PRECAUCIÓN).
  Future<void> deleteClinicalRecord(String pacienteId, String recordId) async {
    if (pacienteId.isEmpty || recordId.isEmpty) {
      throw ArgumentError("IDs no pueden estar vacíos");
    }
    try {
      await _db
          .collection('users')
          .doc(pacienteId)
          .collection('clinical_records')
          .doc(recordId)
          .delete();
      print('Registro clínico $recordId eliminado para paciente $pacienteId');
    } catch (e) {
      print('Error deleteClinicalRecord: $e');
      throw Exception('Error al eliminar registro clínico: $e');
    }
  }

  /// *** NUEVO: Actualiza un registro clínico existente en la subcolección. ***
  ///
  /// Recibe el ID del paciente, el ID del registro clínico específico y un mapa
  /// con los campos y valores a actualizar.
  Future<void> updateClinicalRecord(
    String pacienteId,
    String recordId,
    Map<String, dynamic> updateData,
  ) async {
    // Validación básica de IDs
    if (pacienteId.isEmpty || recordId.isEmpty) {
      throw ArgumentError("Paciente ID y Record ID no pueden estar vacíos para la actualización.");
    }
    // Validación básica de datos (evitar actualización vacía)
    if (updateData.isEmpty) {
      print("Advertencia: Se intentó actualizar el registro clínico $recordId sin datos.");
      return; // No hacer nada si no hay datos para actualizar
    }

    print("Actualizando registro clínico $recordId para paciente $pacienteId...");

    try {
      // Referencia directa al documento específico en la subcolección
      final DocumentReference recordRef = _usersCollection
          .doc(pacienteId)
          .collection('clinical_records') // Nombre EXACTO de tu subcolección
          .doc(recordId);

      // Crear una copia del mapa para evitar modificar el original y sanitizar
      final Map<String, dynamic> dataToUpdate = Map.from(updateData);

      // --- Sanitización y Transformación (Opcional pero Recomendado) ---
      // 1. Remover campos que no deberían actualizarse (como IDs o timestamp original)
      dataToUpdate.remove('id'); // El ID del documento no se actualiza
      dataToUpdate.remove('pacienteId'); // Generalmente no cambia
      dataToUpdate.remove('doctorId'); // Podría cambiar, pero usualmente no en este contexto
      dataToUpdate.remove('timestamp'); // No actualizar el timestamp de creación

      // 2. Convertir DateTime a Timestamp si es necesario para algún campo específico
      //    (Ejemplo si tuvieras un campo 'fechaUltimaModificacion' como DateTime)
      // dataToUpdate.forEach((key, value) {
      //   if (value is DateTime) {
      //     dataToUpdate[key] = Timestamp.fromDate(value);
      //   }
      // });

      // 3. Añadir un campo de 'ultimaActualizacion' es buena práctica
      dataToUpdate['lastUpdated'] = FieldValue.serverTimestamp();

      // Verificar si queda algo por actualizar después de remover campos
      if (dataToUpdate.isEmpty) {
        print(
          "Advertencia: No hay campos válidos para actualizar en el registro $recordId después de la sanitización.",
        );
        return;
      }

      // Realizar la actualización en Firestore
      await recordRef.update(dataToUpdate);

      print('Registro clínico $recordId actualizado exitosamente para paciente $pacienteId.');
    } on FirebaseException catch (e) {
      // Capturar errores específicos de Firestore
      print(
        'Error de Firestore al actualizar registro clínico $recordId: ${e.code} - ${e.message}',
      );
      throw Exception('Error de Firestore al actualizar: ${e.message}');
    } catch (e) {
      // Capturar otros errores inesperados
      print('Error inesperado al actualizar registro clínico $recordId: $e');
      throw Exception('Error inesperado al actualizar registro clínico: ${e.toString()}');
    }
  }

  // --- Gestión de Eliminación de Usuarios (vía Cloud Function) ---
  // Esta función AHORA SÓLO llama a la CF para el borrado completo.
  // La función anterior `deleteAllUsersExcept` es para borrado MASIVO SÓLO de Firestore.
  Future<void> deleteUser(String userId, String profileType) async {
    print('***********************************************************');
    print(
      'Solicitando eliminación COMPLETA (Auth + Firestore) para $userId (Tipo: $profileType) vía Cloud Function.',
    );
    print('***********************************************************');
    if (userId.isEmpty) throw ArgumentError("El userId no puede estar vacío para la eliminación.");

    try {
      final HttpsCallable callable = _functions.httpsCallable('manageAuthUser');
      // La CF 'manageAuthUser' debe manejar la eliminación en Auth y LLAMAR a 'cleanFirestoreProfile'
      final params = {'action': 'delete', 'uid': userId};
      final HttpsCallableResult result = await callable.call({
        'data': params,
      }); // Envolver en 'data'

      if (result.data?['success'] == true) {
        print("Usuario $userId y perfiles asociados eliminados exitosamente (respuesta CF).");
        // No es necesario eliminar de 'users' aquí, la CF ya lo hace a través de cleanFirestoreProfile.
      } else {
        final String errorMessage =
            result.data?['message'] ?? 'La Cloud Function reportó un error no especificado.';
        print("Error reportado por Cloud Function al eliminar $userId: $errorMessage");
        throw Exception("Error de Cloud Function al eliminar usuario: $errorMessage");
      }
    } on FirebaseFunctionsException catch (e) {
      print("Error de Cloud Function ('deleteUser') para $userId: ${e.code} - ${e.message}");
      throw Exception("Error al contactar el servicio de eliminación: ${e.message ?? e.code}");
    } catch (e) {
      print("Error inesperado en deleteUser para $userId: $e");
      throw Exception("Error inesperado al intentar eliminar el usuario: ${e.toString()}");
    }
  }
}
