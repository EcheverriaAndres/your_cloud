import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================= 1. REGISTRAR USUARIO =================
  Future<String?> registrarUsuario({
    required String nombre,
    required String correo,
    required String password,
  }) async {
    try {
      // A. Crear el usuario en Firebase Authentication
      UserCredential credencial = await _auth.createUserWithEmailAndPassword(
        email: correo,
        password: password,
      );

      // B. Actualizar el nombre para que la interfaz lo vea de inmediato
      await credencial.user!.updateDisplayName(nombre);

      // C. Guardar en Firestore (Aislado para que no bloquee el cierre de ventana si falla)
      try {
        await _db.collection('usuarios').doc(credencial.user!.uid).set({
          'nombre': nombre,
          'correo': correo,
          'fechaRegistro': DateTime.now(),
          'rol': 'cliente',
        });
      } catch (e) {
        print("Advertencia: El usuario se creó, pero falló Firestore: $e");
        // No retornamos error aquí, permitimos que el proceso siga como "exitoso"
      }

      return null; // Null significa que el registro en Auth fue un éxito

    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return 'La contraseña es muy débil (mínimo 6 caracteres).';
      if (e.code == 'email-already-in-use') return 'Este correo ya está registrado.';
      return 'Error de Firebase: ${e.message}';
    } catch (e) {
      return 'Error inesperado al registrar el usuario.';
    }
  }

  // ================= 2. INICIAR SESIÓN (La función que faltaba) =================
  Future<String?> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: correo,
        password: password,
      );
      return null; // Null significa éxito
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        return 'Correo o contraseña incorrectos.';
      }
      return 'Error al iniciar sesión: ${e.message}';
    } catch (e) {
      return 'Error inesperado al iniciar sesión.';
    }
  }

  // ================= 3. CERRAR SESIÓN =================
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  Future<String> obtenerRolUsuario(String uid) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (doc.exists) {
        // Asegúrate de que el campo en tu base de datos se llame 'rol'
        return doc.get('rol') ?? 'cliente';
      }
    } catch (e) {
      print("Error obteniendo rol: $e");
    }
    return 'cliente'; // Por defecto, si algo falla, es cliente
  }

}
