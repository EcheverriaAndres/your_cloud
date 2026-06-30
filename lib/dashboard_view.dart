import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  // 1. Definimos las variables que recibirá la clase
  final String rol;
  final Color color;

  const DashboardView({
    super.key,
    required this.rol,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        // 2. Usamos el color que recibimos
        backgroundColor: color,
        title: Text("Panel ${rol.toUpperCase()}"),
      ),
      body: Center(
        child: Text(
          "Bienvenido, $rol",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
          ),
        ),
      ),
    );
  }
}