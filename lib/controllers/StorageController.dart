import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StorageController {
  // Obtenemos el cliente de Supabase ya inicializado
  final supabase = Supabase.instance.client;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> subirArchivo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dwg', 'pdf', 'dxf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        Uint8List fileBytes = result.files.single.bytes!;
        String fileName = result.files.single.name;

        // 1. Subir a Supabase (Bucket llamado 'Storage')
        await supabase.storage.from('Storage').uploadBinary(
          fileName,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );

        // 2. Obtener URL pública
        final String url = supabase.storage.from('Storage').getPublicUrl(fileName);

        // 3. Registrar en Firestore para que el contador de tu Dashboard se actualice
        await _db.collection('documentos').add({
          'nombre': fileName,
          'url': url,
          'fecha': FieldValue.serverTimestamp(),
        });

        print("¡Archivo subido con éxito!");
      }
    } catch (e) {
      print("Error al subir: $e");
    }
  }
}