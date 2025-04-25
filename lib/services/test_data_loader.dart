// lib/services/test_data_loader.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:uuid/uuid.dart'; // Ya no es necesario generar ID aquí si Firestore lo hace
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Alias para Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Para Timestamp

import '../models/modelos.dart'; // Importa TODOS tus modelos
import 'firestore_service.dart';
import 'users_service.dart'; // Importa UsersService

class TestDataLoader {
  final UsersService _usersService;
  final FirestoreService _firestoreService;
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance; // Para obtener doctorId actual
  // final Uuid _uuid = const Uuid(); // No necesario si usamos add() en Firestore

  TestDataLoader(this._usersService, this._firestoreService);

  Future<void> loadClinicalDataFromJson(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    int successCount = 0;
    int errorCount = 0;
    List<String> errors = [];
    int userCounter = 0; // Contador de usuarios

    try {
      // 1. Cargar el archivo JSON desde assets
      final String jsonString = await rootBundle.loadString(
        'funciones/datos_nuevos_con_riesgo_ponderado_critico_modif.json',
      );
      // 2. Decodificar el JSON en una lista de mapas
      final List<dynamic> jsonDataList = jsonDecode(jsonString);

      messenger.showSnackBar(
        SnackBar(content: Text('Iniciando carga de ${jsonDataList.length} registros...')),
      );
      await Future.delayed(const Duration(seconds: 1));

      // 3. Iterar sobre cada registro del JSON
      /* for (var jsonData in jsonDataList) {
        if (jsonData is Map<String, dynamic>) {
          // crea un contador de usuario para cada registro
          userCounter++; // Incrementa el contador de usuario
          final String recordIdentifier =
              jsonData['ID']?.toString() ?? 'Desconocido'; // Para logging
          try {
            // 4. Crear Usuario Ficticio (Auth + Firestore inicial)
            // Usar un identificador único del JSON si existe, o generar uno
            final fakeEmail = 'paciente_test_$userCounter@saludmaterna.com';
            final fakePassword = '123456789'; // Contraseña ficticia
            final fakeDisplayName = 'Paciente Test $recordIdentifier';

            final createUserData = {
              'email': fakeEmail,
              'password': fakePassword,
              'displayName': fakeDisplayName,
              'profileType': 'paciente', // Siempre creamos pacientes aquí
              'profileData': {
                // Datos iniciales MÍNIMOS para PacienteProfile
                'nombre': fakeDisplayName,
                // Puedes añadir otros campos básicos del JSON si coinciden y son necesarios
                // 'nacionalidad': jsonData['NACIONALIDAD'], // Ejemplo
              },
            };

            // Crea el usuario en Auth y el documento base en 'users'
            final userCreationResult = await _usersService.createUserWithProfile(createUserData);
            final newUserUid = userCreationResult['uid'] as String?;

            if (newUserUid == null || newUserUid.isEmpty) {
              throw Exception(
                "No se pudo obtener UID del usuario creado para registro $recordIdentifier",
              );
            }

            // 5. Parsear datos clínicos del JSON actual
            // El factory fromMap debe estar actualizado para manejar las claves JSON
            // No necesitamos generar ID aquí, Firestore lo hará con add()
            // Pasamos un ID temporal o vacío, ya que no se usará al guardar con add()
            final datosClinicosParsed = DatosClinicos.fromMap(jsonData, ''); // ID temporal

            // 6. Crear el objeto DatosClinicos FINAL para guardar en la subcolección
            // Aseguramos que tenga pacienteId y doctorId correctos.
            // El timestamp será añadido por el servicio al guardar.
            final datosClinicosParaGuardar = DatosClinicos(
              id: '', // El ID real lo dará Firestore al usar add()
              pacienteId: newUserUid, // El ID del usuario recién creado
              doctorId: _auth.currentUser?.uid ?? 'CARGA_MASIVA', // Quien carga los datos
              timestamp: Timestamp.now(), // Placeholder, el servicio usará serverTimestamp
              // Copia todas las demás propiedades parseadas
              institucion: datosClinicosParsed.institucion,
              procedencia: datosClinicosParsed.procedencia,
              etnia: datosClinicosParsed.etnia,
              indigena: datosClinicosParsed.indigena,
              escolaridad: datosClinicosParsed.escolaridad,
              remitidaOtraInst: datosClinicosParsed.remitidaOtraInst,
              abortos: datosClinicosParsed.abortos,
              ectopicos: datosClinicosParsed.ectopicos,
              numControles: datosClinicosParsed.numControles,
              viaParto: datosClinicosParsed.viaParto,
              semanasOcurrencia: datosClinicosParsed.semanasOcurrencia,
              ocurrenciaGestacion: datosClinicosParsed.ocurrenciaGestacion,
              estadoObstetrico: datosClinicosParsed.estadoObstetrico,
              peso: datosClinicosParsed.peso,
              altura: datosClinicosParsed.altura,
              imc: datosClinicosParsed.imc,
              frecuenciaCardiacaIngresoAlta: datosClinicosParsed.frecuenciaCardiacaIngresoAlta,
              fRespiratoriaIngresoAlta: datosClinicosParsed.fRespiratoriaIngresoAlta,
              pasIngresoAlta: datosClinicosParsed.pasIngresoAlta,
              padIngresoBaja: datosClinicosParsed.padIngresoBaja,
              conscienciaIngreso: datosClinicosParsed.conscienciaIngreso,
              hemoglobinaIngreso: datosClinicosParsed.hemoglobinaIngreso,
              creatininaIngreso: datosClinicosParsed.creatininaIngreso,
              gptIngreso: datosClinicosParsed.gptIngreso,
              manejoEspecificoCirugiaAdicional:
                  datosClinicosParsed.manejoEspecificoCirugiaAdicional,
              manejoEspecificoIngresoUado: datosClinicosParsed.manejoEspecificoIngresoUado,
              manejoEspecificoIngresoUci: datosClinicosParsed.manejoEspecificoIngresoUci,
              unidadesTransfundidas: datosClinicosParsed.unidadesTransfundidas,
              manejoQxLaparotomia: datosClinicosParsed.manejoQxLaparotomia,
              manejoQxOtra: datosClinicosParsed.manejoQxOtra,
              desgarroPerineal: datosClinicosParsed.desgarroPerineal,
              suturaPerinealPosparto: datosClinicosParsed.suturaPerinealPosparto,
              tratamientosUadoMonitoreoHemodinamico:
                  datosClinicosParsed.tratamientosUadoMonitoreoHemodinamico,
              tratamientosUadoOxigeno: datosClinicosParsed.tratamientosUadoOxigeno,
              tratamientosUadoTransfusiones: datosClinicosParsed.tratamientosUadoTransfusiones,
              diagPrincipalThe: datosClinicosParsed.diagPrincipalThe,
              diagPrincipalHemorragia: datosClinicosParsed.diagPrincipalHemorragia,
              waosProcedimientoQuirurgicoNoProgramado:
                  datosClinicosParsed.waosProcedimientoQuirurgicoNoProgramado,
              waosRoturaUterinaDuranteElParto: datosClinicosParsed.waosRoturaUterinaDuranteElParto,
              waosLaceracionPerineal3erO4toGrado:
                  datosClinicosParsed.waosLaceracionPerineal3erO4toGrado,
              apgar1Minuto: datosClinicosParsed.apgar1Minuto,
              fCardiacaEstanciaMax: datosClinicosParsed.fCardiacaEstanciaMax,
              fCardiacaEstanciaMin: datosClinicosParsed.fCardiacaEstanciaMin,
              pasEstanciaMin: datosClinicosParsed.pasEstanciaMin,
              padEstanciaMin: datosClinicosParsed.padEstanciaMin,
              sao2EstanciaMax: datosClinicosParsed.sao2EstanciaMax,
              hemoglobinaEstanciaMin: datosClinicosParsed.hemoglobinaEstanciaMin,
              creatininaEstanciaMax: datosClinicosParsed.creatininaEstanciaMax,
              gotAspartatoAminotransferasaMax: datosClinicosParsed.gotAspartatoAminotransferasaMax,
              recuentoPlaquetasPltMin: datosClinicosParsed.recuentoPlaquetasPltMin,
              diasEstancia: datosClinicosParsed.diasEstancia,
              desenlaceMaterno2: datosClinicosParsed.desenlaceMaterno2,
              desenlaceNeonatal: datosClinicosParsed.desenlaceNeonatal,
              edad: datosClinicosParsed.edad,
              numeroGestaciones: datosClinicosParsed.numeroGestaciones,
              fetosMuertos: datosClinicosParsed.fetosMuertos,
              enfermedadEndocrinaMetabolica: datosClinicosParsed.enfermedadEndocrinaMetabolica,
              enfermedadCardiovascularCerebrovascular:
                  datosClinicosParsed.enfermedadCardiovascularCerebrovascular,
              enfermedadRenal: datosClinicosParsed.enfermedadRenal,
              otrasEnfermedades: datosClinicosParsed.otrasEnfermedades,
              preeclampsia: datosClinicosParsed.preeclampsia,
              hemorragiaObstetricaSevera: datosClinicosParsed.hemorragiaObstetricaSevera,
              hemorragiaMasSeveraMM: datosClinicosParsed.hemorragiaMasSeveraMM,
              tipoAfiliacionSS: datosClinicosParsed.tipoAfiliacionSS,
              semanasPrimerControlPrenatal: datosClinicosParsed.semanasPrimerControlPrenatal,
              codigoMunicipioResidencia: datosClinicosParsed.codigoMunicipioResidencia,
              codigoPrestador: datosClinicosParsed.codigoPrestador,
              estratoSocioeconomico: datosClinicosParsed.estratoSocioeconomico,
              eclampsia: datosClinicosParsed.eclampsia,
              terminacionGestacion: datosClinicosParsed.terminacionGestacion,
              morbilidadRelacionadaTG: datosClinicosParsed.morbilidadRelacionadaTG,
              tipoCaso: datosClinicosParsed.tipoCaso,
              numeroCesareas: datosClinicosParsed.numeroCesareas,
              causaPrincipalMorbilidad: datosClinicosParsed.causaPrincipalMorbilidad,
              pesoRecienNacido: datosClinicosParsed.pesoRecienNacido,
            );

            // 7. *** LLAMADA AL NUEVO MÉTODO DEL SERVICIO ***
            // Guarda el registro en la subcolección del usuario recién creado
            await _firestoreService.addClinicalRecord(newUserUid, datosClinicosParaGuardar);

            successCount++;
            // print('Usuario $newUserUid y registro clínico para $recordIdentifier creados.');
            print(
              'Usuario $userCounter (UID: $newUserUid) y registro clínico para $recordIdentifier creados.',
            );
          } catch (e) {
            errorCount++;
            final errorMsg = 'Error procesando registro ID $recordIdentifier: ${e.toString()}';
            print(errorMsg);
            errors.add(errorMsg);
            // Considera si quieres detener la carga en caso de error o continuar
          }
        } else {
          errorCount++;
          errors.add('Error: Elemento en JSON no es un mapa válido.');
        }
        // Opcional: Pausa breve para no saturar
        // await Future.delayed(const Duration(milliseconds: 50));
      } */
      // for (var jsonData in jsonDataList) {
      for (var i = 0; i < 10; i++) {
        final jsonData = jsonDataList[i];
        if (jsonData is Map<String, dynamic>) {
          userCounter++;
          final String recordIdentifier =
              jsonData['ID']?.toString() ?? userCounter.toString(); // Usa contador si ID falta
          try {
            // ... (creación de usuario ficticio como antes) ...
            final fakeEmail = 'paciente_test_$recordIdentifier@saludmaterna.com';
            final fakePassword = '123456789'; // Usa una contraseña más segura incluso para tests
            final fakeDisplayName = 'Paciente Test $recordIdentifier';

            final createUserData = {
              'email': fakeEmail,
              'password': fakePassword,
              'displayName': fakeDisplayName,
              'profileType': 'paciente',
              'profileData': {
                'nombre': fakeDisplayName,
                // ... otros datos si son necesarios ...
              },
            };

            final userCreationResult = await _usersService.createUserWithProfile(createUserData);
            final newUserUid = userCreationResult['uid'] as String?;

            if (newUserUid == null || newUserUid.isEmpty) {
              throw Exception(
                "No se pudo obtener UID del usuario creado para registro $recordIdentifier",
              );
            }

            // 5. Parsear datos clínicos del JSON usando el factory CORRECTO
            final datosClinicosParsed = DatosClinicos.fromMap(
              jsonData,
              '',
            ); // ID temporal, Firestore lo asignará

            // 6. Crear el objeto FINAL con IDs correctos
            final datosClinicosParaGuardar = DatosClinicos(
              id: '', // Firestore asignará el ID
              pacienteId: newUserUid,
              doctorId: _auth.currentUser?.uid ?? 'CARGA_MASIVA',
              timestamp: Timestamp.now(), // Será reemplazado por serverTimestamp en el servicio
              // --- Asignar propiedades parseadas ---
              institucion: datosClinicosParsed.institucion,
              procedencia: datosClinicosParsed.procedencia,
              etnia: datosClinicosParsed.etnia,
              indigena: datosClinicosParsed.indigena,
              escolaridad: datosClinicosParsed.escolaridad,
              remitidaOtraInst: datosClinicosParsed.remitidaOtraInst,
              abortos: datosClinicosParsed.abortos,
              ectopicos: datosClinicosParsed.ectopicos,
              numControles: datosClinicosParsed.numControles,
              viaParto: datosClinicosParsed.viaParto,
              semanasOcurrencia: datosClinicosParsed.semanasOcurrencia,
              ocurrenciaGestacion: datosClinicosParsed.ocurrenciaGestacion,
              estadoObstetrico: datosClinicosParsed.estadoObstetrico,
              peso: datosClinicosParsed.peso,
              altura: datosClinicosParsed.altura,
              imc: datosClinicosParsed.imc,
              frecuenciaCardiacaIngresoAlta: datosClinicosParsed.frecuenciaCardiacaIngresoAlta,
              fRespiratoriaIngresoAlta: datosClinicosParsed.fRespiratoriaIngresoAlta,
              pasIngresoAlta: datosClinicosParsed.pasIngresoAlta,
              padIngresoBaja: datosClinicosParsed.padIngresoBaja,
              conscienciaIngreso: datosClinicosParsed.conscienciaIngreso,
              hemoglobinaIngreso: datosClinicosParsed.hemoglobinaIngreso,
              creatininaIngreso: datosClinicosParsed.creatininaIngreso,
              gptIngreso: datosClinicosParsed.gptIngreso,
              manejoEspecificoCirugiaAdicional:
                  datosClinicosParsed.manejoEspecificoCirugiaAdicional,
              manejoEspecificoIngresoUado: datosClinicosParsed.manejoEspecificoIngresoUado,
              manejoEspecificoIngresoUci: datosClinicosParsed.manejoEspecificoIngresoUci,
              unidadesTransfundidas: datosClinicosParsed.unidadesTransfundidas,
              manejoQxLaparotomia: datosClinicosParsed.manejoQxLaparotomia,
              manejoQxOtra: datosClinicosParsed.manejoQxOtra,
              desgarroPerineal: datosClinicosParsed.desgarroPerineal,
              suturaPerinealPosparto: datosClinicosParsed.suturaPerinealPosparto,
              tratamientosUadoMonitoreoHemodinamico:
                  datosClinicosParsed.tratamientosUadoMonitoreoHemodinamico,
              tratamientosUadoOxigeno: datosClinicosParsed.tratamientosUadoOxigeno,
              tratamientosUadoTransfusiones: datosClinicosParsed.tratamientosUadoTransfusiones,
              diagPrincipalThe: datosClinicosParsed.diagPrincipalThe,
              diagPrincipalHemorragia: datosClinicosParsed.diagPrincipalHemorragia,
              waosProcedimientoQuirurgicoNoProgramado:
                  datosClinicosParsed.waosProcedimientoQuirurgicoNoProgramado,
              waosRoturaUterinaDuranteElParto: datosClinicosParsed.waosRoturaUterinaDuranteElParto,
              waosLaceracionPerineal3erO4toGrado:
                  datosClinicosParsed.waosLaceracionPerineal3erO4toGrado,
              apgar1Minuto: datosClinicosParsed.apgar1Minuto,
              fCardiacaEstanciaMax: datosClinicosParsed.fCardiacaEstanciaMax,
              fCardiacaEstanciaMin: datosClinicosParsed.fCardiacaEstanciaMin,
              pasEstanciaMin: datosClinicosParsed.pasEstanciaMin,
              padEstanciaMin: datosClinicosParsed.padEstanciaMin,
              sao2EstanciaMax: datosClinicosParsed.sao2EstanciaMax,
              hemoglobinaEstanciaMin: datosClinicosParsed.hemoglobinaEstanciaMin,
              creatininaEstanciaMax: datosClinicosParsed.creatininaEstanciaMax,
              gotAspartatoAminotransferasaMax: datosClinicosParsed.gotAspartatoAminotransferasaMax,
              recuentoPlaquetasPltMin: datosClinicosParsed.recuentoPlaquetasPltMin,
              diasEstancia: datosClinicosParsed.diasEstancia,
              desenlaceMaterno2: datosClinicosParsed.desenlaceMaterno2,
              desenlaceNeonatal: datosClinicosParsed.desenlaceNeonatal,
            );

            // 7. Guardar en subcolección
            await _firestoreService.addClinicalRecord(newUserUid, datosClinicosParaGuardar);

            successCount++;
            print(
              'Usuario $userCounter (UID: $newUserUid) y reg. clínico $recordIdentifier creados.',
            );
          } catch (e) {
            // ... (manejo de errores como antes) ...
            errorCount++;
            final errorMsg = 'Error procesando registro ID $recordIdentifier: ${e.toString()}';
            print(errorMsg);
            errors.add(errorMsg);
          }
        } else {
          errorCount++;
          errors.add(
            'Error: Elemento JSON no es un mapa válido. Índice: ${jsonDataList.indexOf(jsonData)}',
          );
        }
        await Future.delayed(const Duration(milliseconds: 20)); // Pausa opcional
      }

      // 8. Mostrar resultado final
      String summaryMessage = 'Carga completada. Éxito: $successCount, Errores: $errorCount.';
      if (errorCount > 0) {
        summaryMessage += '\nVer consola para detalles de errores.';
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(summaryMessage),
          duration: const Duration(seconds: 5),
          backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      // ... (manejo error general como antes) ...
      print('Error general durante la carga masiva: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al cargar archivo o proceso general: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
