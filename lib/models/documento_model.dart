import 'dart:convert';
import 'package:file_picker/file_picker.dart'; // Importante agregar esto

class DocumentoModel {
  final String? id;
  final String nombre;
  final String categoria;
  final DateTime fechaRegistro;

  // NUEVO: Propiedad para mantener el archivo real en memoria
  final PlatformFile? archivoFisico;

  DocumentoModel({
    this.id,
    required this.nombre,
    required this.categoria,
    required this.fechaRegistro,
    this.archivoFisico, // Añadido al constructor
  });

  // Convierte un objeto de Flutter a un mapa JSON listo para MongoDB
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'nombre': nombre,
      'categoria': categoria,
      'fecha_registro': fechaRegistro.toIso8601String(),
      // archivoFisico NO se incluye aquí, se enviará por separado
    };
  }

  // Convierte un JSON recibido de MongoDB a un objeto de Flutter
  factory DocumentoModel.fromJson(Map<String, dynamic> json) {
    return DocumentoModel(
      id: json['_id'] as String?,
      nombre: json['nombre'] as String,
      categoria: json['categoria'] as String,
      fechaRegistro: DateTime.parse(json['fecha_registro'] as String),
    );
  }
}