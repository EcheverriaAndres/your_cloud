import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:your_cloud/document_store.dart';
import 'package:your_cloud/models/documento_model.dart';

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
final AuthController auth = AuthController();


class _DashboardAdminViewState extends State<DashboardAdminView> {
  int _selectedIndex = 0;

  // Instanciamos la memoria global
  final DocumentStore _docStore = DocumentStore();

  // Función para seleccionar archivos y convertirlos a tu modelo
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        // Mapeamos los archivos seleccionados a tu DocumentoModel
        List<DocumentoModel> nuevosDocumentos = result.files.map((file) {
          return DocumentoModel(
            nombre: file.name,
            categoria: "Sin categoría",
            fechaRegistro: DateTime.now(),
            archivoFisico: file,
          );
        }).toList();

        setState(() {
          _docStore.addDocumentos(nuevosDocumentos);
        });
      }
    } catch (e) {
      debugPrint("Error al seleccionar archivos: $e");
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
                      await auth.cerrarSesion();
                    },
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _pickFiles, // Llamamos a la función
                label: const Text("Subir Documento"),
                icon: const Icon(Icons.upload_file),
                backgroundColor: Colors.redAccent,
              ),
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
              "Documentos Recientes",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildFileList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    // Leemos directamente de la memoria global _docStore
    if (_docStore.documentos.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(
          child: Text(
            "No hay documentos cargados aún.\nUsa el botón para subir archivos.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _docStore.documentos.length,
      itemBuilder: (context, index) {
        final doc = _docStore.documentos[index];

        String sizeText = "Desconocido";
        if (doc.archivoFisico != null) {
          final kb = doc.archivoFisico!.size / 1024;
          sizeText = kb > 1024
              ? "${(kb / 1024).toStringAsFixed(2)} MB"
              : "${kb.toStringAsFixed(2)} KB";
        }

        return Card(
          color: const Color(0xFF1A1A1A),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEC640F),
              child: Icon(Icons.insert_drive_file, color: Colors.white, size: 20),
            ),
            title: Text(
                doc.nombre,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
            ),
            subtitle: Text(
                "${doc.categoria} • $sizeText",
                style: const TextStyle(color: Colors.white54)
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: "Eliminar de la lista",
              onPressed: () {
                setState(() {
                  _docStore.removeDocumentoAt(index);
                });
              },
            ),
          ),
        );
      },
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



class MainClienteView extends StatelessWidget {
  const MainClienteView({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. INICIALIZAMOS EL AUTH AQUÍ PARA QUE EL BOTÓN FUNCIONE
    // final AuthController auth = AuthController(); // Descomenta esto si usas tu AuthController

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Fondo oscuro YurCloud
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 1,
        shadowColor: const Color(0xFFEC640F).withOpacity(0.2), // Sombra sutil naranja
        title: const Text(
          "YURCLOUD // PANEL DE CLIENTE",
          style: TextStyle(fontSize: 14, letterSpacing: 1.2, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: "Cerrar sesión",
            onPressed: () async {
              await auth.cerrarSesion();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de bienvenida
            const Text(
              "Resumen del Proyecto",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Revisa el progreso de tus diseños, estados financieros y aprueba entregables.",
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 24),

            // --- MÓDULO 1: ESTADO FINANCIERO (MOCKUP) ---
            _buildResumenFinanciero(),
            const SizedBox(height: 24),

            // --- MÓDULO 2: LÍNEA DE TIEMPO (MOCKUP) ---
            const Text(
              "Estado de Fases",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildLineaDeTiempo(),
            const SizedBox(height: 32),

            // --- MÓDULO 3: ENTREGABLES Y APROBACIÓN ---
            const Text(
              "Planos para Revisión",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Lista de Planos (Hacemos un ListView enrollable dentro del Scroll)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              itemBuilder: (context, index) {
                // Definimos dos imágenes de arquitectura e ingeniería diferentes para simular realismo
                String urlPlano = index == 0
                    ? "https://imgproxy.domestika.org/unsafe/w:820/plain/src://content-items/014/514/975/07.PLANTA_page-0001-original.jpg?1699116917" // Foto de planos técnicos
                    : "https://i.ytimg.com/vi/b2XMdoA_GDM/maxresdefault.jpg"; // Foto de render/casa moderna

                return _buildPlanoCard(
                  context: context,
                  titulo: index == 0 ? "Plano Arquitectónico - Piso 1" : "Render Fachada Principal",
                  fecha: "11 de Julio, 2026",
                  urlImagen: urlPlano,

                );

              },

            ),

          ],
        ),
      ),
    );

  }

  // --- FUNCIÓN PARA MOSTRAR LA IMAGEN EN GRANDE CON ZOOM ---
  void _mostrarImagenAmpliada(BuildContext context, String urlImagen, String titulo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Fondo transparente para que resalte la imagen
          insetPadding: const EdgeInsets.all(16), // Margen exterior
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Contenedor principal de la imagen con bordes redondeados
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEC640F), width: 1), // Borde naranja
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título del plano en la parte superior
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
                      child: Text(
                        titulo,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Widget mágico: Permite hacer Zoom y moverse por la imagen
                    Flexible(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: InteractiveViewer(
                          panEnabled: true, // Permite moverse
                          minScale: 1.0,
                          maxScale: 4.0, // Permite acercar hasta 4 veces su tamaño
                          child: Image.network(
                            urlImagen,
                            fit: BoxFit.contain, // Ajusta la imagen sin recortarla
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Botón de cerrar en la esquina superior derecha
              Positioned(
                top: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  radius: 18,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(), // Cierra la ventana emergente
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  // --- WIDGET PARA LA TARJETA FINANCIERA ---
  Widget _buildResumenFinanciero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDatoFinanciero("Costo Total", "\$2,500.00", Colors.white),
          _buildDatoFinanciero("Abonado", "\$1,250.00", Colors.greenAccent),
          _buildDatoFinanciero("Saldo Pendiente", "\$1,250.00", const Color(0xFFEC640F)),
        ],
      ),
    );
  }

  Widget _buildDatoFinanciero(String titulo, String monto, Color colorMonto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(monto, style: TextStyle(color: colorMonto, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- WIDGET PARA LA LÍNEA DE TIEMPO ---
  Widget _buildLineaDeTiempo() {
    return Row(
      children: [
        _buildPaso(true, "Diseño"),
        _buildLinea(true),
        _buildPaso(true, "Dibujo"),
        _buildLinea(false),
        _buildPaso(false, "Revisión"),
        _buildLinea(false),
        _buildPaso(false, "Entrega"),
      ],
    );
  }

  Widget _buildPaso(bool completado, String titulo) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: completado ? const Color(0xFFEC640F) : Colors.white10,
          child: Icon(
            completado ? Icons.check : Icons.circle,
            size: 16,
            color: completado ? Colors.white : Colors.white24,
          ),
        ),
        const SizedBox(height: 8),
        Text(titulo, style: TextStyle(color: completado ? Colors.white : Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildLinea(bool completado) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24), // Para alinear con los círculos
        color: completado ? const Color(0xFFEC640F) : Colors.white10,
      ),
    );
  }


  Widget _buildPlanoCard({
    required BuildContext context,
    required String titulo,
    required String fecha,
    required String urlImagen, // Añadimos este parámetro para cambiar la foto según el plano
  }) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEC640F), width: 0.3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Alinea arriba para que la imagen se acomode bien
              children: [
                // CONTENEDOR DE LA IMAGEN REALISTA
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      urlImagen,
                      fit: BoxFit.cover,
                      // Si la imagen falla por falta de internet, muestra un icono de respaldo
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, color: Colors.white30);
                      },
                      // Muestra un indicador de carga mientras baja de internet
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEC640F)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text("Subido el: $fecha", style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.remove_red_eye, size: 16),
                  label: const Text("Ver"),
                  onPressed: () {
                    // ¡AQUÍ LLAMAMOS A LA MAGIA!
                    _mostrarImagenAmpliada(context, urlImagen, titulo);
                  },
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(color: Colors.white10, height: 1),
            ),
            // BOTONES DE APROBACIÓN
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Has solicitado cambios al equipo. Se habilitará el chat."), backgroundColor: Colors.redAccent),
                    );
                  },
                  icon: const Icon(Icons.edit_note, color: Colors.redAccent),
                  label: const Text("Solicitar Cambios", style: TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("¡Plano aprobado con éxito! El proyecto avanza a la siguiente fase."), backgroundColor: Colors.green),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("Aprobar"),
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

          // Lista de planos (Usamos Expanded para que ocupe el resto del espacio disponible)
          Expanded(
            child: ListView.builder(
              itemCount: 3, // Número de planos asignados
              itemBuilder: (context, index) {
                return _buildPlanoAsignadoCard(
                  titulo: "Plano Arquitectónico - Fase ${index + 1}",
                  estado: "Pendiente de revisión",
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

  // --- WIDGET PARA LOS PLANOS ASIGNADOS ---
  Widget _buildPlanoAsignadoCard({required String titulo, required String estado}) {
    return Card(
      color: const Color(0xFF0D0D0D),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.draw, color: Colors.blueAccent),
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
          icon: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          onPressed: () {
            // Lógica para abrir el plano
          },
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET DEL CHAT DE PROYECTO (CON BOTÓN DE VACIADO)
// ==========================================
class ChatProyectoWidget extends StatefulWidget {
  const ChatProyectoWidget({super.key});

  @override
  State<ChatProyectoWidget> createState() => _ChatProyectoWidgetState();
}

class _ChatProyectoWidgetState extends State<ChatProyectoWidget> {
  final TextEditingController _mensajeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- FUNCIÓN PARA BORRAR TODO EL CHAT ---
  void _borrarChat() async {
    try {
      // Obtiene todos los mensajes actuales
      final coleccion = _firestore.collection('chat_proyecto');
      final snapshot = await coleccion.get();

      // Crea un lote (batch) para borrar todo en un solo movimiento
      WriteBatch batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      // Aplica los cambios en Firebase
      await batch.commit();
      print("YurCloud_Debug: Chat vaciado por completo.");
    } catch (e) {
      print("YurCloud_Debug: Error al vaciar el chat: $e");
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
      respuestaBot = "¡Hola! Soy el asistente de YurCloud. ¿En qué te puedo ayudar con tus planos?";
    }
    else if (mensajeLower.contains("plano") || mensajeLower.contains("revisar") || mensajeLower.contains("arquitecto")) {
      respuestaBot = "He notificado al Arquitecto. En breve ingresará a la plataforma para revisar tu entrega.";
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
                  String remitente = mensaje['remitente'] ?? 'Usuario';
                  String texto = mensaje['texto'] ?? '';
                  bool esMio = remitente == _auth.currentUser?.email;

                  return Align(
                    alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                            Text(remitente, style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                          ],
                          Text(texto, style: const TextStyle(color: Colors.white, fontSize: 15)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Barra para escribir
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Color(0xFF0D0D0D),
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mensajeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Escribe un mensaje al equipo...",
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