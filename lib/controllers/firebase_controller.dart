import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/documento_model.dart';

class FirebaseController {
  // Instancia de la base de datos NoSQL Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // CONTROLADOR: Insertar metadatos del documento en la colección NoSQL
  Future<bool> insertarDocumento(DocumentoModel nuevoDoc) async {
    try {
      // Accede a la colección 'documentos' (si no existe, Firebase la crea automáticamente)
      await _firestore.collection('documentos').add(nuevoDoc.toJson());

      print("¡Sincronización exitosa con Firebase Cloud Firestore!");
      return true;
    } catch (e) {
      print("Error al guardar en el motor NoSQL de Firebase: $e");
      return false;
    }
  }
}