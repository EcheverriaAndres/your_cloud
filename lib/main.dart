import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'controllers/firebase_controller.dart';
import 'models/documento_model.dart';
import 'controllers/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lista_documentos.dart';
import 'auth_gate.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDDSFLV8kIRfh-yV_LZzoyFdHBhs3N1Bvw",
      authDomain: "yurcloud-3c0ef.firebaseapp.com",
      projectId: "yurcloud-3c0ef",
      storageBucket: "yurcloud-3c0ef.firebasestorage.app",
      messagingSenderId: "333818719358",
      appId: "1:333818719358:web:37114f5e005793e6a3fc2f",

    ),

  );


  runApp(const YurCloudApp());
}

class YurCloudApp extends StatelessWidget {
  const YurCloudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YurCloud',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xff0d0d0d),
        primaryColor: const Color(0xFFFF6D00),
      ),

      home: const AuthGate(),
    );
  }
}

class MainDashboardView extends StatefulWidget {
  const MainDashboardView({super.key});

  @override
  State<MainDashboardView> createState() => _MainDashboardViewState();
}

class _MainDashboardViewState extends State<MainDashboardView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedCategory = 'Planos BIM';

  final FirebaseController _firebaseController = FirebaseController();

  // ================= VARIABLES PARA EL LOGIN =================
  final AuthController _authController = AuthController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreLoginController = TextEditingController();
  bool _isLoading = false;
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nombreLoginController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ================= MENU LATERAL FIJO (Izquierda) =================
          Container(
            width: 260,
            color: const Color(0xff161616),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'YurCloud',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFF6D00)),
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 16),
                _buildMenuOption('Dashboard', Icons.dashboard_rounded, true),
                _buildMenuOption('Planos e Informes', Icons.folder_open_rounded, false),
                _buildMenuOption('Métricas', Icons.analytics_outlined, false),
                _buildMenuOption('Configuración', Icons.settings_outlined, false),
              ],
            ),
          ),

          // ================= CONTENIDO PRINCIPAL (Derecha) =================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra Superior Interna
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Panel de Indexación Técnica',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      StreamBuilder<User?>(
                        stream: FirebaseAuth.instance.authStateChanges(),
                        builder: (context, snapshot) {

                          if (snapshot.hasData) {
                            final user = snapshot.data!;

                            // 1. Lógica inteligente para definir el nombre a mostrar
                            final nombreMostrar = user.displayName ?? user.email?.split('@')[0] ?? 'Usuario';

                            return Row(
                              children: [
                                Text(
                                  "Hola, $nombreMostrar", // 2. Usamos la variable aquí
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 10),
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFFF6D00),
                                  child: Text(
                                    nombreMostrar[0].toUpperCase(), // 3. Usamos la inicial aquí
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                                  tooltip: 'Cerrar sesión',
                                  onPressed: () async {
                                    await _authController.cerrarSesion();
                                  },
                                ),
                              ],
                            );
                          }

                          return InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () {
                              _mostrarDialogoLogin(context);
                            },
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor:
                              const Color(0xFFFF6D00).withOpacity(0.2),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFFFF6D00),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Tarjetas Rápidas de Estados (KPIs)
                  Row(
                    children: [
                      _buildStatCard('Total Planos', '24', Icons.architecture_rounded, Colors.blue),
                      const SizedBox(width: 20),
                      _buildStatCard('Modelos 3D', '12', Icons.view_in_ar_rounded, Colors.purple),
                      const SizedBox(width: 20),
                      _buildStatCard('Informes', '8', Icons.description_rounded, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Contenedor del Formulario
                  Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xff161616),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Ingreso de Metadatos (NoSQL Firestore)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del Documento / Plano',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.insert_drive_file_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor ingresa un nombre válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: <String>['Planos BIM', 'Informes Técnicos', 'Modelos 3D', 'Otros']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCategory = newValue!;
                              });
                            },
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6D00),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                            label: const Text(
                              'Sincronizar con Firebase',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final nuevoDocumento = DocumentoModel(
                                  nombre: _nameController.text,
                                  categoria: _selectedCategory,
                                  fechaRegistro: DateTime.now(),
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Subiendo datos a Firestore...'),
                                    backgroundColor: Colors.blueGrey,
                                  ),
                                );

                                bool exito = await _firebaseController.insertarDocumento(nuevoDocumento);

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(exito ? '¡Guardado correctamente en la nube!' : 'Error con Firestore.'),
                                      backgroundColor: exito ? Colors.green : Colors.redAccent,
                                    ),
                                  );
                                  if (exito) _nameController.clear();
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Constructor de opciones de menú fijas
  Widget _buildMenuOption(String title, IconData icon, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF6D00).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Icon(icon, color: isActive ? const Color(0xFFFF6D00) : Colors.grey),
          title: Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          dense: true,
        ),
      ),
    );
  }

  // Tarjetas estadísticas de la sección superior
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xff161616),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ================= VENTANA FLOTANTE DE LOGIN / REGISTRO CORREGIDA =================
  void _mostrarDialogoLogin(BuildContext context) {
    bool isLogin = true;

    showDialog(
      context: context,
      barrierDismissible: false, // Evita que se cierre al tocar afuera mientras carga
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: const Color(0xff1f1f1f),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    Icon(
                        isLogin ? Icons.lock_person_rounded : Icons.person_add_rounded,
                        color: const Color(0xFFFF6D00)
                    ),
                    const SizedBox(width: 10),
                    Text(
                        isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLogin
                          ? 'Ingresa tus credenciales para acceder a la base de datos.'
                          : 'Regístrate para obtener acceso al sistema.',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 20),

                    if (!isLogin) ...[
                      TextField(
                        controller: _nombreLoginController,
                        decoration: InputDecoration(
                          labelText: 'Nombre Completo',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.password_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: _isLoading ? null : () {
                        setState(() {
                          isLogin = !isLogin;
                        });
                      },
                      child: Text(
                        isLogin
                            ? '¿No tienes cuenta? Regístrate aquí'
                            : '¿Ya tienes cuenta? Inicia sesión',
                        style: const TextStyle(color: Color(0xFFFF6D00)),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6D00),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading ? null : () async {
                      // 1. Guardamos las referencias antes del cambio de estado asíncrono
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);

                      setState(() => _isLoading = true);

                      String? error;

                      // Lógica de Registro
                      if (!isLogin) {
                        error = await _authController.registrarUsuario(
                          nombre: _nombreLoginController.text.trim(),
                          correo: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );
                      }
                      // Lógica de Login
                      else {
                        error = await _authController.iniciarSesion(
                          correo: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );
                      }

                      setState(() => _isLoading = false);

                      // 2. Usamos las referencias guardadas de forma segura
                      if (error == null) {
                        navigator.pop(); // Esto cerrará la ventana flotante con total seguridad

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(isLogin ? '¡Bienvenido de nuevo!' : '¡Cuenta creada con éxito!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Limpiamos los campos
                        _emailController.clear();
                        _passwordController.clear();
                        _nombreLoginController.clear();
                      } else {
                        messenger.showSnackBar(
                          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                        isLogin ? 'Ingresar' : 'Registrarse',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              );
            }
        );
      },
    );
  }
}