import 'package:flutter/material.dart';
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



// Importa tu AuthController aquí
// import 'auth_controller.dart';

class DashboardAdminView extends StatefulWidget {
  const DashboardAdminView({super.key});

  @override
  State<DashboardAdminView> createState() => _DashboardAdminViewState();
}
final AuthController auth = AuthController();

class _DashboardAdminViewState extends State<DashboardAdminView> {
  // Controlador de autenticación (simulado para el ejemplo)
  // final AuthController auth = AuthController();

  // Variable para controlar la pestaña activa
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Fondo negro principal
      body: Row(
        children: [
          // 1. MENÚ LATERAL (Sidebar)
          _buildSidebar(),

          // 2. CONTENIDO PRINCIPAL
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
                  // Botón Cerrar Sesión

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
                onPressed: () {
                  // Lógica para subir archivos
                },
                label: const Text("Subir Documento"),
                icon: const Icon(Icons.upload_file),
                backgroundColor: Colors.redAccent,
              ),
              // Aquí mostramos el contenido dependiendo de la opción seleccionada
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
      color: const Color(0xFF0D0D0D), // Un negro ligeramente más claro que el fondo para que resalte
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la app
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Text(
              "YurCloud",
              style: TextStyle(
                color: Color(0xFFEC640F), // Naranja de tu diseño original
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          const SizedBox(height: 16),

          // Opciones del menú
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
            // Fondo ligeramente naranja si está seleccionado
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

  // --- WIDGETS DEL CONTENIDO PRINCIPAL ---

  Widget _buildBodyContent() {
    // Si la opción seleccionada no es el Dashboard (0), puedes mostrar otras vistas
    if (_selectedIndex != 0) {
      return Center(
        child: Text(
            "Contenido en construcción...",
            style: TextStyle(color: Colors.white54, fontSize: 18)
        ),
      );
    }

    // Tu vista original del Dashboard
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

          // Fila de Indicadores (Cards)
          Row(
            children: [
              _buildMetricCard("Proyectos Activos", "14", Icons.layers),
              _buildMetricCard("Planos Validados", "1,240", Icons.verified),
              _buildMetricCard("Eficiencia", "94.2%", Icons.attach_money),
            ],
          ),
        ],
      ),
    );
  }

  // Widget pequeño para las tarjetas
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
              Icon(icon, color: Colors.black54, size: 28), // Ajustado para que contraste mejor
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




class  MainClienteView extends StatelessWidget {
  const  MainClienteView({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. INICIALIZAMOS EL AUTH AQUÍ PARA QUE EL BOTÓN FUNCIONE
    final AuthController auth = AuthController();

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Fondo oscuro YurCloud
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 1,
        shadowColor: const Color(0xFFEC640F).withOpacity(0.2), // Sombra sutil naranja
        title: const Text(
          "YURCLOUD // MIS PLANOS",
          style: TextStyle(fontSize: 14, letterSpacing: 1.2, color: Colors.white),
        ),
        actions: [
          // Botón Cerrar Sesión corregido
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: "Cerrar sesión",
            onPressed: () async {
              await auth.cerrarSesion();
              // Si necesitas redirigir al login manualmente, descomenta esto:
              // if (context.mounted) {
              //   Navigator.of(context).pushReplacementNamed('/login');
              // }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de bienvenida
            const Text(
              "Planos Disponibles",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Aquí puedes visualizar los documentos y planos subidos por tu dibujante.",
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 32),

            // Lista de Planos
            Expanded(
              child: ListView.builder(
                itemCount: 4, // Aquí pondrás la longitud de tu lista de Firebase/BD
                itemBuilder: (context, index) {
                  // Generamos unas tarjetas de ejemplo
                  return _buildPlanoCard(
                    titulo: "Proyecto Estructural - Revisión ${index + 1}",
                    fecha: "29 de Junio, 2026",
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET PARA LA TARJETA DEL PLANO ---

  Widget _buildPlanoCard({required String titulo, required String fecha}) {
    return Card(
      color: const Color(0xFF1A1A1A), // Un gris muy oscuro para contrastar con el fondo negro
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Le damos un borde naranja muy delgadito para mantener la identidad visual
        side: const BorderSide(color: Color(0xFFEC640F), width: 0.3),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEC640F),
          child: Icon(Icons.picture_as_pdf, color: Colors.white),
        ),
        title: Text(
          titulo,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            "Subido el: $fecha",
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        trailing: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white10,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.remove_red_eye, size: 18),
          label: const Text("Ver Plano"),
          onPressed: () {
            // Lógica para abrir el PDF o la imagen del plano
          },
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
  // Inicializamos el controlador de autenticación para evitar la línea roja
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
                  // Botón Cerrar Sesión funcionando correctamente
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    tooltip: "Cerrar sesión",
                    onPressed: () async {
                      await auth.cerrarSesion();
                      // if (context.mounted) {
                      //   Navigator.of(context).pushReplacementNamed('/login');
                      // }
                    },
                  ),
                ],
              ),

              // Botón flotante para que el dibujante suba sus entregas
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  // Lógica para subir archivos/planos
                },
                label: const Text("Subir Revisión"),
                icon: const Icon(Icons.cloud_upload),
                backgroundColor: const Color(0xFFEC640F), // Naranja YurCloud
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
          _buildMenuItem(1, "Chat de Proyecto", Icons.forum_outlined),
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
    if (_selectedIndex != 0) {
      return Center(
        child: Text(
            "Sección en construcción...",
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
            // Lógica para abrir el plano y trabajar en él
          },
        ),
      ),
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