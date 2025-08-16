/* eslint-disable linebreak-style */
const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Inicializa Firebase Admin SDK (se hace automáticamente en Cloud Functions)
admin.initializeApp();

/**
 * Verifica si el usuario que llama tiene el claim 'superadmin'.
 * @param {functions.https.CallableContext} data Contexto de la llamada.
 * @throws {functions.https.HttpsError} Si el usuario no está autenticado
 * o si no es superadmin.
 */
const checkSuperAdmin = (data) => {
  // Asegurarse de que el usuario esté autenticado
  if (!data.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "La función debe ser llamada por un usuario autenticado.",
    );
  }
  // Verificar el custom claim 'superadmin'
  const isSuperAdmin = data.auth.token.superadmin === true;
  const isAdmin = data.auth.token.admin === true;
  if (!isSuperAdmin && !isAdmin) {
    functions.logger.warn(
        "Acceso denegado: El usuario no es superadmin ni admin.", {
          uid: data.auth.uid,
        });
    throw new functions.https.HttpsError(
        "permission-denied",
        "Permiso denegado. Se requiere rol de superadmin.",
    );
  }
  const logData = {uid: data.auth.uid};
  functions.logger.info("Acceso superadmin concedido.", logData);
};

/**
 * Cloud Function Callable para gestionar usuarios de Firebase Auth.
 * Requiere rol de superadmin.
 *
 * @param {object} data Datos enviados desde el cliente.
 * @param {string} data.action Acción a realizar ('list', 'get', 'update',
 * 'delete').
 * @param {string} [data.uid] UID del usuario (requerido para 'get', 'update',
 * 'delete').
 * @param {object} [data.updateData] Datos para actualizar (requerido para
 * 'update').
 * @param {number} [data.pageSize] Tamaño de página para 'list'.
 * @param {string} [data.pageToken] Token de página para 'list'.
 * @param {functions.https.CallableContext} context Contexto de la llamada.
 * @returns {Promise<object>} Resultado de la operación.
 */
exports.manageAuthUser = functions.https.onCall(async (data, context) => {
  // 1. Verificar permisos de Superadmin
  checkSuperAdmin(data);

  const {
    action = data.data.action,
    // Para get, update, delete
    uid = data.auth.uid,
    // Para create { email, password, displayName, phoneNumber?,
    // photoURL?, profileType ('doctor'|'paciente'), profileData? }
    createData= data.data.createData,
    // Para update { email?, phoneNumber?, disabled?, displayName? }
    updateData= data.data.updateData,
    pageSize = data.data.pageSize,
    pageToken,
  } = data;

  functions.logger.info("manageAuthUser:", {
    action,
    uid,
    pageSize,
    pageToken,
    invokingUid: data.auth.uid,
    hasCreateData: !!createData,
    hasUpdateData: !!updateData,
  });
  // Log inicial para ver qué llega
  functions.logger.info(
      "manageAuthUser Accion:", data.data.action);
  functions.logger.info(
      "manageAuthUser Data:", data);
  functions.logger.info(
      "Contexto de Autenticación Recibido:", data.auth); // <-- ¡IMPORTANTE!

  functions.logger.info(
      "UID del usuario autenticado:", data.auth.uid); // Log si sí hay auth

  try {
    switch (data.data.action) {
      case "create": {
        if (!data.data.createData) {
          throw new functions.https.HttpsError(
              "invalid-argument",
              "Se requiere 'createData'.",
          );
        }

        const {
          email,
          password,
          displayName,
          phoneNumber,
          photoURL,
          profileType,
          profileData = {},
        } = data.data.createData;
        functions.logger.info("createData:", {
          email,
          password,
          displayName,
          phoneNumber,
          photoURL,
          profileType,
          profileData,
        });
        const validProfileTypes = ["doctor", "paciente", "admin"];
        const callerIsSuperAdmin = data.auth.token.superadmin === true;

        if (!email || !password || !profileType ||
            !validProfileTypes.includes(profileType)) {
          throw new functions.https.HttpsError(
              "invalid-argument",
              "Faltan campos o profileType inválido.",
          );
        }
        // Solo Superadmin puede crear Admins
        if (profileType === "admin" && !callerIsSuperAdmin) {
          throw new functions.https.HttpsError(
              "permission-denied",
              "Solo Superadmin puede crear Admins.",
          );
        }

        functions.logger.info("Creando usuario Auth:", {
          email,
          displayName,
          profileType,
        });
        const userToCreate = {
          email,
          password,
          displayName,
          disabled: false,
          ...(phoneNumber && {phoneNumber}),
          ...(photoURL && {photoURL}),
        };
        const userRecord = await admin.auth().createUser(userToCreate);
        functions.logger.info("Usuario Auth creado:", {uid: userRecord.uid});

        // --- Asignación de Claims y/o Perfil Firestore ---
        const claimsToSet = {
          // Asignar el rol principal
          role: profileType,
          // NO asignar 'superadmin' aquí. Debe hacerse manualmente.
        };

        functions.logger.info(
            `Asignando claims ${JSON.stringify(claimsToSet)} a:`,
            {uid: userRecord.uid},
        );
        await admin.auth().setCustomUserClaims(userRecord.uid, claimsToSet);

        /*// --- Crear perfil en Firestore SOLO para Doctores y Pacientes ---
        if (profileType === "doctor" || profileType === "paciente") {
          const profileCollection = profileType === "doctor" ?
              "doctores" : "pacientes";
          const firestoreProfileData = {
            nombre: displayName || email,
            email: email,
            fechaCreacion: admin.firestore.FieldValue.serverTimestamp(),
            ...profileData,
          };
          functions.logger.info(
              `Creando perfil en Firestore (${profileCollection}):`,
              {uid: userRecord.uid},
          );
          await admin.firestore()
              .collection(profileCollection)
              .doc(userRecord.uid)
              .set(firestoreProfileData);
          functions.logger.info("Perfil Firestore creado.");
        } else {
          functions.logger.info("Perfil Firestore no creado para rol 'admin'.");
        }*/

        return {
          success: true,
          message: `Usuario ${userRecord.uid} (${email}) con rol ` +
              `'${profileType}' creado exitosamente.`,
          uid: userRecord.uid,
        };
      } // Fin case "create"

      // --- Casos list, get,
      // update, delete (sin cambios necesarios para esta corrección) ---
      case "list": {
        const listUsersResult = await admin.auth().listUsers(
            pageSize, pageToken);
        const users = listUsersResult.users.map((userRecord) => ({
          uid: userRecord.uid,
          email: userRecord.email,
          displayName: userRecord.displayName,
          photoURL: userRecord.photoURL,
          phoneNumber: userRecord.phoneNumber,
          disabled: userRecord.disabled,
          creationTime: userRecord.metadata.creationTime,
          lastSignInTime: userRecord.metadata.lastSignInTime,
          providerData: userRecord.providerData.map((p) => ({
            providerId: p.providerId,
            email: p.email,
          })),
          customClaims: userRecord.customClaims,
        }));
        return {users, nextPageToken: listUsersResult.pageToken};
      }

      case "get": {
        if (!uid) {
          throw new functions.https.HttpsError(
              "invalid-argument",
              "UID requerido.",
          );
        }
        const userRecord = await admin.auth().getUser(uid);
        return {
          uid: userRecord.uid,
          photoURL: userRecord.photoURL,
          phoneNumber: userRecord.phoneNumber,
          disabled: userRecord.disabled,
          creationTime: userRecord.metadata.creationTime,
          lastSignInTime: userRecord.metadata.lastSignInTime,
          providerData: userRecord.providerData.map((p) => ({
            providerId: p.providerId,
            email: p.email,
          })),
          customClaims: userRecord.customClaims,
        };
      }

      case "update": {
        if (!uid) {
          throw new functions.https.HttpsError(
              "invalid-argument", "UID requerido.");
        }
        if (!updateData) {
          throw new functions.https.HttpsError(
              "invalid-argument",
              "updateData requerido.",
          );
        }

        let targetUser;
        try {
          targetUser = await admin.auth().getUser(uid);
        } catch (error) {
          if (error.code === "auth/user-not-found") {
            throw new functions.https.HttpsError(
                "not-found",
                "Usuario no existe.",
            );
          }
          throw error;
        }

        const targetClaims = targetUser.customClaims || {};
        const targetIsSuperAdmin = targetClaims.superadmin === true;
        const targetIsAdmin = targetClaims.admin === true ||
            targetClaims.role === "admin";
        const callerIsSuperAdmin = data.auth.token.superadmin === true;

        if (updateData.disabled !== undefined) {
          if (targetIsSuperAdmin) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "Superadmin no puede ser deshabilitado.",
            );
          }
          if (targetIsAdmin && !callerIsSuperAdmin) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "Solo Superadmin puede deshabilitar Admins.",
            );
          }
        }

        const allowedUpdates = {};
        if (updateData.email !== undefined) {
          allowedUpdates.email = updateData.email;
        }
        if (updateData.phoneNumber !== undefined) {
          allowedUpdates.phoneNumber = updateData.phoneNumber;
        }
        if (updateData.disabled !== undefined) {
          allowedUpdates.disabled = updateData.disabled;
        }
        if (updateData.displayName !== undefined) {
          allowedUpdates.displayName = updateData.displayName;
        }

        if (Object.keys(allowedUpdates).length === 0) {
          throw new functions.https.HttpsError(
              "invalid-argument", "Campos inválidos.");
        }

        functions.logger.info(
            "Actualizando Auth:", {uid, updates: allowedUpdates});
        await admin.auth().updateUser(uid, allowedUpdates);
        return {success: true, message: `Usuario ${uid} actualizado.`};
      }

      case "delete": {
        if (!uid) {
          throw new functions.https.HttpsError(
              "invalid-argument", "UID requerido.");
        }

        let targetUserToDelete;
        try {
          targetUserToDelete = await admin.auth().getUser(uid);
        } catch (error) {
          if (error.code === "auth/user-not-found") {
            functions.logger.warn(
                "Usuario Auth no encontrado, limpiando Firestore:",
                {uid},
            );
            await cleanFirestoreProfile(uid);
            return {
              success: true,
              message: `Perfiles Firestore para ${uid} eliminados. ` +
                  "Usuario Auth no encontrado.",
            };
          }
          throw error;
        }

        const targetClaims = targetUserToDelete.customClaims || {};
        const targetIsSuperAdmin = targetClaims.superadmin === true;
        const targetIsAdmin = targetClaims.admin === true ||
            targetClaims.role === "admin";
        const callerIsSuperAdmin = data.auth.token.superadmin === true;

        if (targetIsSuperAdmin) {
          throw new functions.https.HttpsError(
              "permission-denied",
              "Superadmin no puede ser eliminado.",
          );
        }

        if (targetIsAdmin && !callerIsSuperAdmin) {
          throw new functions.https.HttpsError(
              "permission-denied",
              "Solo Superadmin puede eliminar Admins.",
          );
        }

        functions.logger.warn("Eliminando Auth:", {uid});
        await admin.auth().deleteUser(uid);
        await cleanFirestoreProfile(uid);
        return {
          success: true,
          message: `Usuario ${uid} y perfiles asociados eliminados.`,
        };
      }

      case "bulkDeleteExcept": {
        checkSuperAdmin(data);

        const excludedUIDs = data.data.excludedUIDs;
        if (!Array.isArray(excludedUIDs)) {
          throw new functions.https.HttpsError(
              "invalid-argument",
              "'excludedUIDs' debe ser una lista de UID válidos.",
          );
        }

        let nextPageToken = undefined;
        const deletedUIDs = [];

        do {
          const result = await admin.auth().listUsers(1000, nextPageToken);
          nextPageToken = result.pageToken;

          for (const user of result.users) {
            const uid = user.uid;

            // No borrar si está en la lista de exclusión
            if (excludedUIDs.includes(uid)) {
              continue;
            }

            // No permitir eliminar superadmins
            const claims = user.customClaims || {};
            const isSuperAdmin = claims.superadmin === true;
            if (isSuperAdmin) {
              functions.logger.warn("Usuario superadmin no eliminado:", {uid});
              continue;
            }

            try {
              await admin.auth().deleteUser(uid);
              await cleanFirestoreProfile(uid);
              deletedUIDs.push(uid);
              functions.logger.info("Usuario eliminado:", {uid});
            } catch (error) {
              functions.logger.error("Error eliminando usuario:", {uid, error});
            }
          }
        } while (nextPageToken);

        return {
          success: true,
          message: `Se eliminaron ${deletedUIDs.length} usuarios.`,
          deletedUIDs,
        };
      }

      default:
        throw new functions.https.HttpsError(
            "invalid-argument", `Acción desconocida: ${data.data.action}`);
    }
  } catch (error) {
    functions.logger.error(
        `Error en manageAuthUser (${data.data.action}) para UID ` +
        `${uid || "N/A"}:`, error,
    );

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    if (error.code && error.code.startsWith("auth/")) {
      const message = `Error Auth: ${error.message}`;
      let code = "internal";

      if (error.code === "auth/email-already-exists") {
        code = "already-exists";
      } else if (error.code === "auth/user-not-found") {
        code = "not-found";
      }

      throw new functions.https.HttpsError(code, message, error.code);
    }

    throw new functions.https.HttpsError(
        "internal",
        "Ocurrió un error interno.",
        error.message,
    );
  }
});

// --- Helper cleanFirestoreProfile (sin cambios) ---
/**
 * Cleans up the Firestore profiles for a given user.
 *
 * @param {string} uid - The user ID.
 * @return {Promise<void>}
 * A promise that resolves when the profiles are cleaned.
 */
async function cleanFirestoreProfile(uid) {
  functions.logger.info("Limpiando Firestore:", {uid});
  const firestore = admin.firestore();
  const batch = firestore.batch();
  batch.delete(firestore.collection("doctores").doc(uid));
  batch.delete(firestore.collection("pacientes").doc(uid));
  // batch.delete(firestore.collection('admins').doc(uid));
  try {
    await batch.commit();
    functions.logger.info("Firestore limpiado:", {uid});
  } catch (error) {
    functions.logger.error("Error limpiando Firestore:", {uid, error});
  }
}
