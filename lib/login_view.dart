import 'package:flutter/material.dart';
import 'controllers/auth_controller.dart';

class TuFormularioLoginWidget extends StatefulWidget {
  const TuFormularioLoginWidget({super.key});

  @override
  State<TuFormularioLoginWidget> createState() => _TuFormularioLoginWidgetState();
}

class _TuFormularioLoginWidgetState extends State<TuFormularioLoginWidget> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthController _auth = AuthController();

  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });

    String? error;

    if (_isLogin) {
      error = await _auth.iniciarSesion(
        correo: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else {
      if (_nombreController.text.trim().isEmpty) {
        error = "Por favor, ingresa tu nombre.";
      } else {
        error = await _auth.registrarUsuario(
          nombre: _nombreController.text.trim(),
          correo: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. EL CONTENEDOR PRINCIPAL CON LA IMAGEN DE FONDO
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            // Aquí puedes cambiar la URL por la imagen que más te guste
            image: NetworkImage('https://images.unsplash.com/photo-1503387762-592deb58ef4e?q=80&w=2071&auto=format&fit=crop'),
            fit: BoxFit.cover, // Hace que la imagen llene toda la pantalla
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24.0),
              // 2. LA TARJETA CON LIGERA TRANSPARENCIA
              child: Card(
                elevation: 12, // Sombra más pronunciada para resaltar sobre el fondo
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                // Color negro con 80% de opacidad para efecto elegante
                color: Colors.black.withOpacity(0.8),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isLogin ? Icons.architecture : Icons.person_add_outlined,
                        size: 64,
                        color: Colors.tealAccent, // Color que contrasta bien con fondos oscuros
                      ),
                      const SizedBox(height: 24),

                      Text(
                        _isLogin ? "Acceso al Sistema" : "Crear Cuenta",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (!_isLogin) ...[
                        TextField(
                          controller: _nombreController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Nombre completo",
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.person, color: Colors.white70),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.tealAccent),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Correo electrónico",
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.email, color: Colors.white70),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.tealAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Contraseña",
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.password, color: Colors.white70),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.tealAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                            _isLogin ? "Iniciar Sesión" : "Registrarse",
                            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _nombreController.clear();
                            _emailController.clear();
                            _passwordController.clear();
                          });
                        },
                        child: Text(
                          _isLogin
                              ? "¿No tienes cuenta? Regístrate aquí"
                              : "¿Ya tienes cuenta? Inicia sesión",
                          style: const TextStyle(color: Colors.tealAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}