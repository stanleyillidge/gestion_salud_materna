const admin = require('firebase-admin');
const path = require('path');
// Asegúrate de tener tu archivo de credenciales de servicio
const serviceAccount = path.join(__dirname, "serviceAccount.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    // databaseURL: "https://<DATABASE_NAME>.firebaseio.com" // Si usas Realtime Database
});

const uid = process.argv[2]; // Obtener UID del argumento de línea de comandos
const makeAdmin = process.argv[3] === 'true'; // 'true' para añadir, cualquier otra cosa para quitar

if (!uid) {
    console.error("Error: Por favor, proporciona el UID del usuario como primer argumento.");
    console.error("Ejemplo: node setAdminClaim.js <user_uid> true");
    process.exit(1);
}

admin.auth().setCustomUserClaims(uid, { superadmin: makeAdmin })
    .then(() => {
        console.log(`Claim 'superadmin' ${makeAdmin ? 'añadido a' : 'quitado de'} ${uid} exitosamente.`);
        process.exit(0);
    })
    .catch((error) => {
        console.error("Error al establecer custom claims:", error);
        process.exit(1);
    });
// node setAdminClaim.js <r5cHUx4oB7aWC2AYKtPGFNLxT2v1> true