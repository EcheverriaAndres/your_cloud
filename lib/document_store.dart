import 'package:your_cloud/models/documento_model.dart';

class DocumentStore {
  // Patrón Singleton: garantiza que siempre usemos la misma instancia
  static final DocumentStore _instance = DocumentStore._internal();
  factory DocumentStore() => _instance;
  DocumentStore._internal();

  // Aquí vive tu lista de documentos usando tu modelo
  List<DocumentoModel> documentos = [];

  // Método actualizado que tu vista está intentando llamar
  void addDocumentos(List<DocumentoModel> docs) {
    documentos.addAll(docs);
  }

  // Método actualizado para eliminar
  void removeDocumentoAt(int index) {
    documentos.removeAt(index);
  }
}