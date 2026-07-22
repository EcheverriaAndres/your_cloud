import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:your_cloud/document_store.dart';
import 'package:your_cloud/models/documento_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'controllers/auth_controller.dart';


class DashboardSelector extends StatelessWidget {
  final String uid;

  const DashboardSelector({
    super.key,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final AuthController authController = AuthController();

    return FutureBuilder<String>(
      future: authController.obtenerRolUsuario(uid),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {

        // Mientras carga el rol
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si ocurrió un error
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                "Error al verificar permisos.\n${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Si no existe información
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: Text("No se encontró información del usuario."),
            ),
          );
        }

        final String rol = snapshot.data!;

        switch (rol) {
          case 'cliente':
            return const MainClienteView();

          case 'dibujante':
            return const DashboardDibujanteView();

          case 'arquitecto':
            return const DashboardArquitectoView();

          case 'admin':
            return const DashboardAdminView();

          default:
            return Scaffold(
              body: Center(
                child: Text(
                  "Rol '$rol' no reconocido.",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            );
        }
      },
    );
  }
}

//======================================================
// DASHBOARD ADMIN
//======================================================


class DashboardAdminView extends StatefulWidget {
  const DashboardAdminView({super.key});

  @override
  State<DashboardAdminView> createState() => _DashboardAdminViewState();
}

class _DashboardAdminViewState extends State<DashboardAdminView> {
  int _selectedIndex = 0;

  // Función para seleccionar archivos y subirlos a Supabase Storage
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subiendo archivo(s) a Supabase Storage...'),
            backgroundColor: Color(0xFFEC640F),
            duration: Duration(seconds: 4),
          ),
        );

        final String usuarioActual = FirebaseAuth.instance.currentUser?.email ?? 'Arquitecto / Admin';
        final DateTime ahora = DateTime.now();

        for (var file in result.files) {
          if (file.path != null) {
            File archivoFisico = File(file.path!);
            String nombreArchivo = file.name;

            // Limpiamos el nombre y añadimos marca de tiempo única prefijada con el responsable opcionalmente
            String nombreLimpio = nombreArchivo.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_');
            String rutaSupabase = '${ahora.millisecondsSinceEpoch}_$nombreLimpio';

            // Subida a Supabase (Bucket: 'archivos_proyecto')
            await Supabase.instance.client.storage
                .from('archivos_proyecto')
                .upload(rutaSupabase, archivoFisico);
          }
        }

        if (mounted) {
          setState(() {}); // Refresca la vista para mostrar los nuevos archivos de Supabase
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Archivos subidos a Supabase con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error al subir archivos a Supabase: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en la subida: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                    "YURCLOUD // PANEL DE CONTROL",
                    style: TextStyle(fontSize: 14, letterSpacing: 1.2, color: Colors.white)
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: "Cerrar sesión",
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ],
              ),
              floatingActionButton: _selectedIndex == 1
                  ? FloatingActionButton.extended(
                onPressed: _pickFiles,
                label: const Text("Subir Plano / Informe"),
                icon: const Icon(Icons.upload_file),
                backgroundColor: const Color(0xFFEC640F),
              )
                  : null,
              body: _buildBodyContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: const Color(0xFF0D0D0D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Text(
              "YurCloud",
              style: TextStyle(
                color: Color(0xFFEC640F),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          const SizedBox(height: 16),
          _buildMenuItem(0, "Dashboard", Icons.grid_view_rounded),
          _buildMenuItem(1, "Planos e Informes", Icons.folder_outlined),
          _buildMenuItem(2, "Métricas", Icons.bar_chart_outlined),
          _buildMenuItem(3, "Configuración", Icons.settings_outlined),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon) {
    bool isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEC640F).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFFEC640F) : Colors.white54,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_selectedIndex == 1) {
      return _buildPlanosInformesSupabaseView();
    }

    if (_selectedIndex != 0) {
      return const Center(
        child: Text(
            "Contenido en construcción...",
            style: TextStyle(color: Colors.white54, fontSize: 18)
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              "Panel de Control General",
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              _buildMetricCard("Proyectos Activos", "14", Icons.layers),
              _buildMetricCard("Planos Validados", "1,240", Icons.verified),
              _buildMetricCard("Eficiencia", "94.2%", Icons.attach_money),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
              "Acceso Rápido",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)
          ),
          const SizedBox(height: 16),
          const Text(
            "Selecciona 'Planos e Informes' en el menú lateral para gestionar la documentación completa alojada en Supabase.",
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // --- SECCIÓN: PLANOS E INFORMES LEYENDO DIRECTAMENTE DESDE SUPABASE STORAGE ---
  Widget _buildPlanosInformesSupabaseView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Planos e Informes (Supabase Storage)",
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            "Listado de documentos técnicos con fecha de modificación y origen en la nube.",
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<FileObject>>(
              future: Supabase.instance.client.storage
                  .from('archivos_proyecto')
                  .list(path: ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFEC640F)));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error al conectar con Supabase: ${snapshot.error}",
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Center(
                      child: Text(
                        "No hay archivos almacenados en el bucket 'archivos_proyecto'.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ),
                  );
                }

                final archivos = snapshot.data!;

                return ListView.builder(
                  itemCount: archivos.length,
                  itemBuilder: (context, index) {
                    final archivo = archivos[index];
                    if (archivo.name.isEmpty) return const SizedBox.shrink();

                    // Limpieza del nombre para visualización (removiendo prefijos numéricos de tiempo si los hay)
                    String nombreMostrar = archivo.name;
                    if (nombreMostrar.contains('_')) {
                      // Opcional: extrae la parte posterior al timestamp de subida
                      nombreMostrar = nombreMostrar.substring(nombreMostrar.indexOf('_') + 1);
                    }

                    // Intentar extraer fecha del archivo desde los metadatos de Supabase si existen, o usar createdAt
                    String fechaModificacion = "Fecha reciente";
                    if (archivo.createdAt != null) {
                      try {
                        DateTime dt = DateTime.parse(archivo.createdAt!).toLocal();
                        fechaModificacion = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} a las ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                      } catch (_) {}
                    }

                    // URL pública para ver o descargar el archivo
                    final String urlPublica = Supabase.instance.client.storage
                        .from('archivos_proyecto')
                        .getPublicUrl(archivo.name);

                    return Card(
                      color: const Color(0xFF141414),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEC640F).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.architecture_rounded, color: Color(0xFFEC640F), size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nombreMostrar,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  const Row(
                                    children: [
                                      Icon(Icons.person_outline_rounded, color: Color(0xFFEC640F), size: 14),
                                      SizedBox(width: 6),
                                      Text(
                                        "Responsable: Equipo de Arquitectura",
                                        style: TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, color: Colors.white54, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Subido / Modificado: $fechaModificacion",
                                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white24),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.visibility_outlined, size: 16),
                              label: const Text("Ver Archivo", style: TextStyle(fontSize: 12)),
                              onPressed: () async {
                                final Uri uri = Uri.parse(urlPublica);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              tooltip: "Eliminar de Supabase",
                              onPressed: () async {
                                try {
                                  await Supabase.instance.client.storage
                                      .from('archivos_proyecto')
                                      .remove([archivo.name]);
                                  setState(() {}); // Actualiza la lista en pantalla
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Archivo eliminado correctamente."), backgroundColor: Colors.redAccent),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint("Error al eliminar: $e");
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        color: const Color(0xFFEC640F),
        margin: const EdgeInsets.only(right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.black54, size: 28),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
//======================================================
// DASHBOARD CLIENTE
//======================================================




class MainClienteView extends StatefulWidget {
  const MainClienteView({super.key});

  @override
  State<MainClienteView> createState() => _MainClienteViewState();
}

class _MainClienteViewState extends State<MainClienteView> {
  final TextEditingController _mensajeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _chatMinimizado = false;

  void _enviarMensaje() async {
    if (_mensajeController.text.trim().isEmpty) return;

    final String texto = _mensajeController.text.trim();
    final String usuario = _auth.currentUser?.email ?? 'Cliente';

    _mensajeController.clear();

    try {
      await _firestore.collection('chat_proyecto').add({
        'texto': texto,
        'remitente': usuario,
        'esCorreccion': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _responderComoBot(texto);
    } catch (e) {
      print("YurCloud_Debug: Error al enviar mensaje: $e");
    }
  }

  void _responderComoBot(String mensajeUsuario) async {
    String respuestaBot = "";
    String mensajeLower = mensajeUsuario.toLowerCase();

    if (mensajeLower.contains("hola")) {
      respuestaBot = "¡Hola! Soy el asistente de YurCloud. ¿Tienes dudas sobre tus planos o finanzas?";
    } else if (mensajeLower.contains("plano") || mensajeLower.contains("revisar")) {
      respuestaBot = "He notificado al equipo técnico sobre tu consulta respecto a los planos.";
    } else {
      respuestaBot = "Entendido. He registrado tu mensaje en la bitácora del proyecto.";
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      await _firestore.collection('chat_proyecto').add({
        'texto': respuestaBot,
        'remitente': 'Asistente YurCloud',
        'esCorreccion': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("YurCloud_Debug: Error en respuesta del bot: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String projectId = _auth.currentUser?.uid ?? 'default_project';
    final String userEmail = _auth.currentUser?.email ?? 'Cliente YurCloud';

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEC640F).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud_outlined, color: Color(0xFFEC640F), size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              "YURCLOUD // PANEL DE CLIENTE",
              style: TextStyle(fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _chatMinimizado ? Icons.chat_bubble_outline_rounded : Icons.chat_rounded,
              color: _chatMinimizado ? Colors.white54 : const Color(0xFFEC640F),
            ),
            tooltip: _chatMinimizado ? "Abrir Chat" : "Minimizar Chat",
            onPressed: () {
              setState(() {
                _chatMinimizado = !_chatMinimizado;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
            tooltip: "Cerrar sesión",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('proyectos').doc(projectId).snapshots(),
        builder: (context, projectSnapshot) {
          double costoTotal = 2500.00;
          double abonado = 1250.00;
          int faseActual = 2;

          if (projectSnapshot.hasData && projectSnapshot.data!.exists) {
            final data = projectSnapshot.data!.data() as Map<String, dynamic>;
            costoTotal = (data['costoTotal'] ?? 2500.00).toDouble();
            abonado = (data['abonado'] ?? 1250.00).toDouble();
            faseActual = data['faseActual'] ?? 2;
          }

          double saldoPendiente = costoTotal - abonado;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- COLUMNA IZQUIERDA: CONTENIDO PRINCIPAL REDISEÑADO ---
              Expanded(
                flex: _chatMinimizado ? 1 : 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta de Bienvenida Dinámica con Perfil
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFF141414), const Color(0xFF1F1209)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEC640F).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xFFEC640F),
                              child: Text(
                                userEmail.isNotEmpty ? userEmail[0].toUpperCase() : "C",
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Bienvenido a tu panel de gestión",
                                    style: TextStyle(color: Colors.white54, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    userEmail,
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.withOpacity(0.4)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                                  SizedBox(width: 6),
                                  Text("Proyecto Activo", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      const Text(
                        "Estado Financiero",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // MÓDULO 1: ESTADO FINANCIERO DINÁMICO Y MODERNO
                      _buildResumenFinanciero(costoTotal, abonado, saldoPendiente),
                      const SizedBox(height: 32),

                      const Text(
                        "Progreso de Fases",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // MÓDULO 2: LÍNEA DE TIEMPO
                      _buildLineaDeTiempo(faseActual),
                      const SizedBox(height: 36),

                      const Text(
                        "Planos para Revisión",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      FutureBuilder<List<FileObject>>(
                        future: Supabase.instance.client.storage
                            .from('archivos_proyecto')
                            .list(path: ''),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(color: Color(0xFFEC640F)),
                              ),
                            );
                          }

                          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF111111),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: const Center(
                                child: Text('No hay planos listos para revisión todavía.', style: TextStyle(color: Colors.white54, fontSize: 14)),
                              ),
                            );
                          }

                          final archivos = snapshot.data!;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: archivos.length,
                            itemBuilder: (context, index) {
                              final archivo = archivos[index];
                              if (archivo.name.isEmpty) return const SizedBox.shrink();

                              String nombreMostrar = archivo.name;
                              if (nombreMostrar.contains('_')) {
                                nombreMostrar = nombreMostrar.substring(nombreMostrar.indexOf('_') + 1);
                              }

                              bool esEditado = nombreMostrar.toLowerCase().contains('v2') ||
                                  nombreMostrar.toLowerCase().contains('editado') ||
                                  nombreMostrar.toLowerCase().contains('cambio') ||
                                  archivo.name.startsWith('v2_');

                              final String urlPublica = Supabase.instance.client.storage
                                  .from('archivos_proyecto')
                                  .getPublicUrl(archivo.name);

                              return _buildPlanoCard(
                                context: context,
                                titulo: nombreMostrar,
                                urlArchivo: urlPublica,
                                esEditado: esEditado,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // --- COLUMNA DERECHA: CHAT EN VIVO ---
              if (!_chatMinimizado)
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A0A0A),
                      border: Border(left: BorderSide(color: Colors.white12)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.white12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.forum_outlined, color: Color(0xFFEC640F), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    "Chat y Bitácora",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _chatMinimizado = true;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('chat_proyecto')
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(color: Color(0xFFEC640F)));
                              }
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text("Sin mensajes en el chat aún.", style: TextStyle(color: Colors.white54, fontSize: 13)),
                                );
                              }

                              final mensajes = snapshot.data!.docs;

                              return ListView.builder(
                                reverse: true,
                                padding: const EdgeInsets.all(16),
                                itemCount: mensajes.length,
                                itemBuilder: (context, index) {
                                  var mensaje = mensajes[index];
                                  final data = mensaje.data() as Map<String, dynamic>;
                                  String remitente = data['remitente'] ?? 'Usuario';
                                  String texto = data['texto'] ?? '';
                                  bool esMio = remitente == _auth.currentUser?.email;
                                  bool tieneArchivo = data['esCorreccion'] == true;
                                  String? urlArchivo = data['archivoUrl'];

                                  return Align(
                                    alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      constraints: const BoxConstraints(maxWidth: 280),
                                      decoration: BoxDecoration(
                                        color: tieneArchivo
                                            ? Colors.blue.withOpacity(0.15)
                                            : (esMio ? const Color(0xFFEC640F) : const Color(0xFF161616)),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: tieneArchivo ? Colors.blueAccent : (esMio ? Colors.transparent : Colors.white10),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (!esMio)
                                            Text(remitente, style: const TextStyle(color: Color(0xFFEC640F), fontSize: 10, fontWeight: FontWeight.bold)),
                                          if (!esMio) const SizedBox(height: 4),
                                          Text(texto, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                          if (tieneArchivo && urlArchivo != null) ...[
                                            const SizedBox(height: 8),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blueAccent,
                                                foregroundColor: Colors.white,
                                                minimumSize: const Size(double.infinity, 30),
                                                elevation: 0,
                                              ),
                                              icon: const Icon(Icons.download, size: 14),
                                              label: const Text("Descargar Versión V2", style: TextStyle(fontSize: 11)),
                                              onPressed: () async {
                                                final Uri uri = Uri.parse(urlArchivo);
                                                if (await canLaunchUrl(uri)) {
                                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                }
                                              },
                                            ),
                                          ]
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: const Color(0xFF0F0F0F),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _mensajeController,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: "Escribe un mensaje...",
                                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                                    filled: true,
                                    fillColor: const Color(0xFF1A1A1A),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                backgroundColor: const Color(0xFFEC640F),
                                radius: 20,
                                child: IconButton(
                                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                                  onPressed: _enviarMensaje,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // --- TARJETAS FINANCIERAS DINÁMICAS Y MODERNAS ---
  Widget _buildResumenFinanciero(double costoTotal, double abonado, double saldoPendiente) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _buildDatoFinanciero("Costo Total", "\$${costoTotal.toStringAsFixed(2)}", Colors.white, Icons.account_balance_wallet_outlined)),
          Container(height: 40, width: 1, color: Colors.white10),
          Expanded(child: _buildDatoFinanciero("Abonado", "\$${abonado.toStringAsFixed(2)}", Colors.greenAccent, Icons.check_circle_outline)),
          Container(height: 40, width: 1, color: Colors.white10),
          Expanded(child: _buildDatoFinanciero("Saldo Pendiente", "\$${saldoPendiente.toStringAsFixed(2)}", const Color(0xFFEC640F), Icons.pending_outlined)),
        ],
      ),
    );
  }

  Widget _buildDatoFinanciero(String titulo, String monto, Color colorMonto, IconData icono) {
    return Column(
      children: [
        Icon(icono, color: colorMonto.withOpacity(0.8), size: 20),
        const SizedBox(height: 6),
        Text(titulo, style: const TextStyle(color: Colors.white54, fontSize: 11), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(monto, style: TextStyle(color: colorMonto, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ],
    );
  }

  // --- LÍNEA DE TIEMPO DINÁMICA ---
  Widget _buildLineaDeTiempo(int faseActual) {
    List<String> fases = ["Diseño", "Dibujo", "Revisión", "Entrega"];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: List.generate(fases.length * 2 - 1, (index) {
          if (index.isEven) {
            int pasoIndex = index ~/ 2;
            bool completado = pasoIndex <= faseActual;
            return _buildPaso(completado, fases[pasoIndex]);
          } else {
            int lineaIndex = index ~/ 2;
            bool completadoLinea = lineaIndex < faseActual;
            return _buildLinea(completadoLinea);
          }
        }),
      ),
    );
  }

  Widget _buildPaso(bool completado, String titulo) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: completado ? const Color(0xFFEC640F) : Colors.white10,
            child: Icon(
              completado ? Icons.check : Icons.circle,
              size: 14,
              color: completado ? Colors.white : Colors.white24,
            ),
          ),
          const SizedBox(height: 6),
          Text(titulo, style: TextStyle(color: completado ? Colors.white : Colors.white38, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLinea(bool completado) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: completado ? const Color(0xFFEC640F) : Colors.white10,
    );
  }

  Widget _buildPlanoCard({
    required BuildContext context,
    required String titulo,
    required String urlArchivo,
    required bool esEditado,
  }) {
    final Color colorBorde = esEditado ? Colors.blueAccent : const Color(0xFFEC640F);

    return Card(
      color: const Color(0xFF111111),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorBorde.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Center(
                    child: Icon(
                      esEditado ? Icons.update_rounded : Icons.picture_as_pdf_rounded,
                      color: esEditado ? Colors.blueAccent : Colors.redAccent,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (esEditado)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                          ),
                          child: const Text(
                            "✨ VERSIÓN V2 ACTUALIZADA",
                            style: TextStyle(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        esEditado ? "Modificado recientemente por el equipo" : "Estado: Pendiente de revisión",
                        style: TextStyle(color: esEditado ? Colors.blue.shade200 : Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text("Ver", style: TextStyle(fontSize: 12)),
                  onPressed: () async {
                    final Uri uri = Uri.parse(urlArchivo);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(color: Colors.white10, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final emailCliente = FirebaseAuth.instance.currentUser?.email ?? 'Cliente';
                    try {
                      await FirebaseFirestore.instance.collection('chat_proyecto').add({
                        'texto': '⚠️ SOLICITUD DE EDICIÓN: Revisar el plano "$titulo".',
                        'remitente': emailCliente,
                        'esCorreccion': false,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Solicitud enviada al arquitecto."), backgroundColor: Colors.redAccent),
                      );
                    } catch (e) {
                      print("Error: $e");
                    }
                  },
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.redAccent, size: 18),
                  label: const Text("Solicitar Cambios", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final emailCliente = FirebaseAuth.instance.currentUser?.email ?? 'Cliente';
                    try {
                      await FirebaseFirestore.instance.collection('chat_proyecto').add({
                        'texto': '✅ APROBADO: El plano "$titulo" ha sido aprobado.',
                        'remitente': emailCliente,
                        'esCorreccion': false,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("¡Plano aprobado con éxito!"), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      print("Error: $e");
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text("Aprobar", style: TextStyle(fontSize: 12)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
//======================================================
// DASHBOARD DIBUJANTE
//======================================================



class DashboardDibujanteView extends StatefulWidget {
  const DashboardDibujanteView({super.key});

  @override
  State<DashboardDibujanteView> createState() => _DashboardDibujanteViewState();
}

class _DashboardDibujanteViewState extends State<DashboardDibujanteView> {
  // Inicializamos el controlador de autenticación
  final AuthController auth = AuthController();

  // Controla la pestaña activa del menú lateral
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Fondo negro YurCloud
      body: Row(
        children: [
          // 1. MENÚ LATERAL (Estilo Admin)
          _buildSidebar(),

          // 2. CONTENIDO PRINCIPAL
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                    "YURCLOUD // PANEL DE DIBUJANTE",
                    style: TextStyle(fontSize: 14, letterSpacing: 1.2, color: Colors.white)
                ),
                actions: [
                  // Botón Cerrar Sesión
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    tooltip: "Cerrar sesión",
                    onPressed: () async {
                      await auth.cerrarSesion();
                    },
                  ),
                ],
              ),


              body: _buildBodyContent(),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DEL MENÚ LATERAL ---

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: const Color(0xFF0D0D0D), // Gris muy oscuro
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la app en el menú
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Text(
              "YurCloud",
              style: TextStyle(
                color: Color(0xFFEC640F),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          const SizedBox(height: 16),

          // Opciones adaptadas para el dibujante
          _buildMenuItem(0, "Mis Asignaciones", Icons.architecture),
          _buildMenuItem(1, "Chat de Proyecto", Icons.chat),
          _buildMenuItem(2, "Configuración", Icons.settings_outlined),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon) {
    bool isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEC640F).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFFEC640F) : Colors.white54,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  // --- CONTENIDO PRINCIPAL ---

  Widget _buildBodyContent() {
    // Si el usuario seleccionó "Chat de Proyecto"
    if (_selectedIndex == 1) {
      return const ChatProyectoWidget();
    }
    // Si el usuario seleccionó "Configuración"
    else if (_selectedIndex == 2) {
      return const Center(
        child: Text(
            "Configuración en construcción...",
            style: TextStyle(color: Colors.white54, fontSize: 18)
        ),
      );
    }

    // Por defecto (índice 0): "Mis Asignaciones"
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              "Hola, Arquitecto",
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 24),

          // 1. SECCIÓN: Mensaje Fijado / Instrucciones
          _buildMensajeFijado(),

          const SizedBox(height: 32),

          // 2. SECCIÓN: Planos Asignados
          const Text(
              "Planos Designados",
              style: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w600)
          ),
          const SizedBox(height: 16),

          // Lista dinámica conectada a Supabase Storage
          Expanded(
            child: FutureBuilder<List<FileObject>>(
              future: Supabase.instance.client.storage
                  .from('archivos_proyecto')
                  .list(path: ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFEC640F)));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar planos: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay planos asignados todavía.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                final archivos = snapshot.data!;

                return ListView.builder(
                  itemCount: archivos.length,
                  itemBuilder: (context, index) {
                    final archivo = archivos[index];
                    final nombreCompleto = archivo.name;

                    // Ignorar si por alguna razón viene una carpeta vacía
                    if (nombreCompleto.isEmpty) return const SizedBox.shrink();

                    // Limpiamos la marca de tiempo numérica del inicio (ej: 1784587001055_plano.pdf -> plano.pdf)
                    String nombreMostrar = nombreCompleto;
                    if (nombreCompleto.contains('_')) {
                      nombreMostrar = nombreCompleto.substring(nombreCompleto.indexOf('_') + 1);
                    }

                    // Obtenemos la URL pública directamente de Supabase para este archivo
                    final String urlPublica = Supabase.instance.client.storage
                        .from('archivos_proyecto')
                        .getPublicUrl(nombreCompleto);

                    return _buildPlanoAsignadoCard(
                      titulo: nombreMostrar,
                      estado: "Disponible para revisión",
                      urlArchivo: urlPublica,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  // --- WIDGET PARA EL MENSAJE FIJADO ---
  Widget _buildMensajeFijado() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEC640F).withOpacity(0.5), width: 1),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.push_pin, color: Color(0xFFEC640F), size: 20),
              SizedBox(width: 10),
              Text(
                  "Mensaje Fijado del Administrador",
                  style: TextStyle(color: Color(0xFFEC640F), fontWeight: FontWeight.bold)
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "Por favor, priorizar las correcciones estructurales del Proyecto A. "
                "El cliente necesita la revisión antes del viernes. Si hay dudas, usar el chat de proyecto.",
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }


  Widget _buildPlanoAsignadoCard({
    required String titulo,
    required String estado,
    required String urlArchivo,
  }) {
    return Card(
        color: const Color(0xFF0D0D0D),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEC640F).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.architecture, color: Color(0xFFEC640F)),
          ),
          title: Text(
            titulo,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              estado,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.download, color: Colors.white70, size: 20),
            tooltip: "Descargar plano",
            onPressed: () async {
              final Uri uri = Uri.parse(urlArchivo);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se pudo abrir el archivo para descarga')),
                );
              }
            },
          ),
        ),
    );
  }
}




//CHAT BOT //

class ChatProyectoWidget extends StatefulWidget {
  const ChatProyectoWidget({super.key});

  @override
  State<ChatProyectoWidget> createState() => _ChatProyectoWidgetState();
}

class _ChatProyectoWidgetState extends State<ChatProyectoWidget> {
  final TextEditingController _mensajeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _subiendoArchivo = false;

  // --- FUNCIÓN PARA BORRAR TODO EL CHAT ---
  void _borrarChat() async {
    try {
      final coleccion = _firestore.collection('chat_proyecto');
      final snapshot = await coleccion.get();

      WriteBatch batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print("YurCloud_Debug: Chat vaciado por completo.");
    } catch (e) {
      print("YurCloud_Debug: Error al vaciar el chat: $e");
    }
  }

  // --- FUNCIÓN PARA SUBIR PLANO CORREGIDO DESDE EL CHAT (ESTILO GEMINI) ---
  void _adjuntarYSubirPlano() async {
    try {
      // Usamos withData: true para garantizar que en escritorio (Windows) se obtengan los bytes correctamente
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        if (!mounted) return;
        setState(() {
          _subiendoArchivo = true;
        });

        final fileBytes = result.files.single.bytes!;
        final originalName = result.files.single.name;

        // Clave: Añadimos "v2_" para que el sistema detecte la nueva versión corregida
        final fileNameStorage = 'v2_$originalName';

        // 1. Subir a Supabase Storage
        await Supabase.instance.client.storage
            .from('archivos_proyecto')
            .uploadBinary(
          fileNameStorage,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );

        // 2. Obtener URL pública para descargar desde el chat
        final String urlPublica = Supabase.instance.client.storage
            .from('archivos_proyecto')
            .getPublicUrl(fileNameStorage);

        final String usuario = _auth.currentUser?.email ?? 'Dibujante';

        // 3. Enviar a Firestore como un mensaje especial con archivo adjunto y bandera de corrección
        await _firestore.collection('chat_proyecto').add({
          'texto': '✨ [VERSIÓN CORREGIDA]: He subido una actualización del plano: "$originalName". Ya está disponible en la sección de revisión.',
          'remitente': usuario,
          'archivoUrl': urlPublica,
          'nombreArchivo': originalName,
          'esCorreccion': true,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        setState(() {
          _subiendoArchivo = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Plano corregido subido y notificado con éxito!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("YurCloud_Debug: Error al subir archivo adjunto: $e");

      if (!mounted) return;
      setState(() {
        _subiendoArchivo = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al subir el archivo: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _enviarMensaje() async {
    if (_mensajeController.text.trim().isEmpty) return;

    final String texto = _mensajeController.text.trim();
    final String usuario = _auth.currentUser?.email ?? 'Usuario del Equipo';

    _mensajeController.clear();

    try {
      await _firestore.collection('chat_proyecto').add({
        'texto': texto,
        'remitente': usuario,
        'esCorreccion': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _responderComoBot(texto);
    } catch (e) {
      print("YurCloud_Debug: Error al enviar mensaje: $e");
    }
  }

  // --- FUNCIÓN DEL BOT (ACTUALIZADA CON SUPABASE) ---
  void _responderComoBot(String mensajeUsuario) async {
    String respuestaBot = "";
    String mensajeLower = mensajeUsuario.toLowerCase();

    // 1. Detección de planos en Supabase
    if (mensajeLower.contains("disponible") ||
        mensajeLower.contains("ajustar") ||
        mensajeLower.contains("edición") ||
        mensajeLower.contains("edicion") ||
        mensajeLower.contains("cuáles") ||
        mensajeLower.contains("cuales") ||
        mensajeLower.contains("mostrar") ||
        mensajeLower.contains("ver los planos")) {

      try {
        final List<FileObject> archivos = await Supabase.instance.client.storage
            .from('archivos_proyecto')
            .list(path: '');

        if (archivos.isEmpty) {
          respuestaBot = "Actualmente no hay planos subidos en el sistema para edición.";
        } else {
          respuestaBot = "Estos sindican los planos disponibles para ajuste o revisión:\n\n";
          for (var archivo in archivos) {
            if (archivo.name.isNotEmpty) {
              String nombreMostrar = archivo.name;
              if (nombreMostrar.contains('_')) {
                nombreMostrar = nombreMostrar.substring(nombreMostrar.indexOf('_') + 1);
              }
              respuestaBot += "📄 $nombreMostrar\n";
            }
          }
        }
      } catch (e) {
        respuestaBot = "Intenté buscar los planos, pero hubo un error de conexión con la nube.";
        print("YurCloud_Debug: Error del bot al buscar en Supabase: $e");
      }
    }
    // 2. Otras respuestas
    else if (mensajeLower.contains("hola")) {
      respuestaBot = "¡Hola! Soy el asistente de YurCloud. ¿En qué te puedo ayudar con tus planos?";
    }
    else if (mensajeLower.contains("plano") || mensajeLower.contains("revisar") || mensajeLower.contains("arquitecto")) {
      respuestaBot = "He notificado al equipo técnico. En breve ingresará a la plataforma para revisar tu entrega.";
    }
    else if (mensajeLower.contains("gracias")) {
      respuestaBot = "¡Con gusto! El proyecto sigue su curso de manera correcta.";
    }
    else {
      respuestaBot = "Entendido. He registrado tu mensaje en la bitácora de seguimiento del proyecto.";
    }

    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      await _firestore.collection('chat_proyecto').add({
        'texto': respuestaBot,
        'remitente': 'Asistente YurCloud',
        'esCorreccion': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("YurCloud_Debug: Error en respuesta del bot: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- BARRA DE HERRAMIENTAS DEL CHAT (BOTÓN BORRAR) ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _borrarChat,
                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 20),
                label: const Text(
                    "Limpiar Chat",
                    style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500)
                ),
              ),
            ],
          ),
        ),

        // Área de mensajes
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('chat_proyecto')
                .orderBy('timestamp', descending: true)
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
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: mensajes.length,
                itemBuilder: (context, index) {
                  var mensaje = mensajes[index];
                  final data = mensaje.data() as Map<String, dynamic>;
                  String remitente = data['remitente'] ?? 'Usuario';
                  String texto = data['texto'] ?? '';
                  bool esMio = remitente == _auth.currentUser?.email;

                  // Verificamos si es un mensaje de corrección subido por el dibujante
                  bool tieneArchivo = data.containsKey('esCorreccion') && (data['esCorreccion'] == true);
                  String? urlArchivo = tieneArchivo ? data['archivUrl'] ?? data['archivoUrl'] : null;

                  return Align(
                    alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      constraints: const BoxConstraints(maxWidth: 340),
                      decoration: BoxDecoration(
                        // Cambio dinámico de color si es corrección (Tono azulado/verdoso con borde destacado)
                        color: tieneArchivo
                            ? Colors.blue.withOpacity(0.25)
                            : (esMio ? const Color(0xFFEC640F) : const Color(0xFF1E293B)),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(esMio ? 16 : 0),
                          bottomRight: Radius.circular(esMio ? 0 : 16),
                        ),
                        border: tieneArchivo
                            ? Border.all(color: Colors.blueAccent, width: 1.5)
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tieneArchivo) ...[
                            Row(
                              children: const [
                                Icon(Icons.verified, color: Colors.blueAccent, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  "✨ NUEVA VERSIÓN / CORREGIDO",
                                  style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                          ],
                          if (!esMio && !tieneArchivo) ...[
                            Text(remitente, style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                          ],
                          Text(texto, style: const TextStyle(color: Colors.white, fontSize: 15)),

                          // Si incluye un archivo corregido, muestra automáticamente el botón de descarga
                          if (tieneArchivo && urlArchivo != null) ...[
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 36),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text("Descargar Versión Corregida"),
                              onPressed: () async {
                                final Uri uri = Uri.parse(urlArchivo);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Barra para escribir y adjuntar (Estilo Gemini)
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Color(0xFF0D0D0D),
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              // Botón de adjuntar archivo (Clip tipo Gemini)
              IconButton(
                icon: _subiendoArchivo
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Color(0xFFEC640F), strokeWidth: 2),
                )
                    : const Icon(Icons.attach_file, color: Color(0xFFEC640F)),
                tooltip: "Adjuntar plano corregido (Versión 2)",
                onPressed: _subiendoArchivo ? null : _adjuntarYSubirPlano,
              ),
              const SizedBox(width: 8),

              // Campo de texto
              Expanded(
                child: TextField(
                  controller: _mensajeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Escribe un mensaje o adjunta un plano...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 24,
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
    );
  }
}
//======================================================
// DASHBOARD ARQUITECTO
//======================================================

class DashboardArquitectoView extends StatelessWidget {
  const DashboardArquitectoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      appBar: AppBar(
        title: const Text("Arquitecto"),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "Panel del Arquitecto",
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}