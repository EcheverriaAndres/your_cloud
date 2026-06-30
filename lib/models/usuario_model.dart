class UsuarioModel {
  final String uid;
  final String nombre;
  final String rol;

  UsuarioModel({required this.uid, required this.nombre, required this.rol});

  factory UsuarioModel.fromMap(String id, Map<String, dynamic> data) {
    return UsuarioModel(
      uid: id,
      nombre: data['nombre'] ?? '',
      rol: data['rol'] ?? 'lector', // Rol restrictivo por defecto
    );
  }
}