import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatProyectoView extends StatefulWidget {
  const ChatProyectoView({super.key});

  @override
  State<ChatProyectoView> createState() => _ChatProyectoViewState();
}

class _ChatProyectoViewState extends State<ChatProyectoView> {
  final TextEditingController _mensajeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Función para enviar el mensaje a Firebase
  void _enviarMensaje() async {
    if (_mensajeController.text.trim().isEmpty) return;

    final String texto = _mensajeController.text.trim();
    final String usuario = _auth.currentUser?.email ?? 'Usuario del Equipo';

    _mensajeController.clear(); // Limpiamos el campo

    // 1. Guardamos TU mensaje en Firebase
    await _firestore.collection('chat_proyecto').add({
      'texto': texto,
      'remitente': usuario,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Activamos la respuesta automática del Chatbot
    _responderComoBot(texto);
  }

  // --- NUEVA FUNCIÓN PARA EL CHATBOT ---
  void _responderComoBot(String mensajeUsuario) async {
    String respuestaBot = "";
    String mensajeLower = mensajeUsuario.toLowerCase(); // Convertimos a minúsculas para evaluar fácil

    // 3. Evaluamos palabras clave para dar respuestas predeterminadas
    if (mensajeLower.contains("hola")) {
      respuestaBot = "¡Hola! Soy el asistente de YurCloud. ¿En qué te puedo ayudar con tus planos?";
    }
    else if (mensajeLower.contains("plano") || mensajeLower.contains("revisar") || mensajeLower.contains("arquitecto")) {
      respuestaBot = "He notificado al Arquitecto. En breve ingresará a la plataforma para revisar tu entrega.";
    }
    else if (mensajeLower.contains("gracias")) {
      respuestaBot = "¡Con gusto! El proyecto sigue su curso.";
    }
    else if (mensajeLower.contains("error") || mensajeLower.contains("problema")) {
      respuestaBot = "He registrado el reporte. Por favor, sube una captura a la sección de 'Planos e Informes'.";
    }
    else {
      // Respuesta por defecto si no reconoce palabras
      respuestaBot = "Entendido. He registrado tu mensaje en la bitácora del proyecto.";
    }

    // 4. Simulamos que el bot está "pensando/escribiendo" por 1.5 segundos
    await Future.delayed(const Duration(milliseconds: 1500));

    // 5. El Bot envía su respuesta a Firebase
    await _firestore.collection('chat_proyecto').add({
      'texto': respuestaBot,
      'remitente': 'Asistente YurCloud', // Este nombre hará que salga a la izquierda
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Fondo oscuro de tu app
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text("Chat de Proyecto", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Color(0xFFEC640F)), // Icono naranja
      ),
      body: Column(
        children: [
          // 1. Área donde se muestran los mensajes (StreamBuilder escucha en tiempo real)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chat_proyecto')
                  .orderBy('timestamp', descending: true) // Los más nuevos abajo
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFEC640F)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No hay mensajes aún. ¡Escribe el primero!",
                        style: TextStyle(color: Colors.white54)),
                  );
                }

                final mensajes = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Empieza desde abajo hacia arriba
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) {
                    var mensaje = mensajes[index];
                    bool esMio = mensaje['remitente'] == _auth.currentUser?.email;

                    return _BurbujaMensaje(
                      texto: mensaje['texto'],
                      remitente: mensaje['remitente'],
                      esMio: esMio,
                    );
                  },
                );
              },
            ),
          ),

          // 2. Campo de texto para escribir
          Container(
            padding: const EdgeInsets.all(12.0),
            color: const Color(0xFF0F0F0F),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Escribe un mensaje...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFFEC640F),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _enviarMensaje,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para las burbujas de chat
class _BurbujaMensaje extends StatelessWidget {
  final String texto;
  final String remitente;
  final bool esMio;

  const _BurbujaMensaje({
    required this.texto,
    required this.remitente,
    required this.esMio,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: esMio ? const Color(0xFFEC640F) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(esMio ? 16 : 0),
            bottomRight: Radius.circular(esMio ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!esMio) ...[
              Text(remitente, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
            ],
            Text(texto, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}