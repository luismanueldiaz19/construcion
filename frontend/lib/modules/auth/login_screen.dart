import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/auth_provider.dart';
import '../../core/constants.dart';
import '../../main.dart';
import '../../widgets/app_alert.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../home/screens/home_screen.dart';
import 'forgot_password_screen.dart';

/// Pantalla de inicio de sesión inspirada en el diseño asimétrico moderno
/// con tarjeta flotante blanca minimalista, fondo corporativo y composición editorial.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      // Navigator.of(context).pushReplacement(
      //   PageRouteBuilder(
      //     pageBuilder: (context, animation, secondaryAnimation) =>
      //         const MainLayout(),
      //     transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      //         FadeTransition(opacity: animation, child: child),
      //     transitionDuration: const Duration(milliseconds: 600),
      //   ),
      // );

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );

      //HomeScreen
    }
  }

  void _autofillCredentials() {
    FocusScope.of(context).unfocus();
    setState(() {
      _usernameController.text = "ludeveloper";
      _passwordController.text = "199512";
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      body: Stack(
        children: [
          // 1. Capa base con background.png y velo luminoso
          Positioned.fill(
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xFFE4EBF2)),
            ),
          ),
          // Positioned.fill(
          //   child: BackdropFilter(
          //     filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          //     child: Container(
          //       decoration: BoxDecoration(
          //         gradient: LinearGradient(
          //           begin: Alignment.topLeft,
          //           end: Alignment.bottomRight,
          //           colors: [
          //             const Color(0xFFE8EEF5).withValues(alpha: 0.92),
          //             const Color(0xFFF4F7FA).withValues(alpha: 0.95),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),

          // 2. Elementos decorativos circulares de fondo (estilo referencia)
          const _BackgroundDecorativeCircles(),

          // 3. Contenedor principal con los 2 modos de pantalla
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [_buildFloatingCard()],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lado izquierdo para Desktop: Titular con tipografía editorial y arte corporativo compacto
  Widget _buildHeroSide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logotipo corporativo superior compacto
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              logoPath,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.construction,
                color: AppTheme.accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'NEO PROJECT',
              style: TextStyle(
                color: Color(0xFF1A1C1E),
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Titular con énfasis compacto en "Construcción Inteligente"
        const Text(
          'El estándar en',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w300,
            color: Color(0xFF2C3E50),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Construcción Inteligente',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1C1E),
                letterSpacing: 0.2,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 2.5,
              width: 65,
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        const Text(
          'Automatice el control de obras, presupuestos, contabilidad\ne inventarios de manera ágil y centralizada.',
          style: TextStyle(
            fontSize: 12.0,
            color: Color(0xFF5A6A80),
            height: 1.45,
          ),
        ),

        const SizedBox(height: 18),

        // Composición gráfica temática compacta
        Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64748B).withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/edificion_contruccion.png',
                  width: 62,
                  height: 62,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 62,
                    height: 62,
                    color: const Color(0xFF1A1C1E),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: Colors.white54,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plataforma Operativa ERP',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1E),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Acceso seguro para ingenieros, administradores y personal contable de la constructora.',
                      style: TextStyle(
                        fontSize: 11.0,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Encabezado para la vista móvil
  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          logoPath,
          height: 100,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.construction,
            color: AppTheme.accentColor,
            size: 26,
          ),
        ),

        const SizedBox(height: 6),
        const Text(
          'Gestión de Construcción',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  /// Tarjeta blanca flotante minimalista con el formulario
  Widget _buildFloatingCard() {
    final authProvider = Provider.of<AuthProvider>(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMobileHeader(),
            const SizedBox(height: 16),

            // Banner de error en caso de credenciales incorrectas
            if (authProvider.errorMessage != null) ...[
              AppAlert(
                type: AppAlertType.error,
                message: authProvider.errorMessage!,
                isDark: false,
              ),
              const SizedBox(height: 12),
            ],

            // Etiqueta superior y campo de usuario
            const Text(
              'Usuario',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            AppTextField(
              controller: _usernameController,
              hintText: 'Usuario',
              prefixIconData: Icons.person_outline_rounded,
              isDark: false,
              borderRadius: 10,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'El nombre de usuario es obligatorio';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Etiqueta superior y campo de contraseña
            const Text(
              'Contraseña',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            AppTextField(
              controller: _passwordController,
              hintText: '••••••••',
              prefixIconData: Icons.lock_outline_rounded,
              isPassword: true,
              isDark: false,
              borderRadius: 10,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'La contraseña es obligatoria';
                }
                if (val.length < 6) {
                  return 'Mínimo 6 caracteres';
                }
                return null;
              },
              onFieldSubmitted: (_) => _handleLogin(),
            ),

            const SizedBox(height: 10),

            // Fila: Recordarme y ¿Olvidó contraseña?
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (val) {
                          setState(() {
                            _rememberMe = val ?? false;
                          });
                        },
                        activeColor: AppTheme.accentColor,
                        checkColor: Colors.white,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Recordarme',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                  ),
                  child: const Text(
                    '¿Olvidó contraseña?',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Botón principal de acceso con loading integrado
            AppButton(
              text: 'INGRESAR AL SISTEMA',
              isFullWidth: true,
              size: AppButtonSize.standard,
              variant: AppButtonVariant.primary,
              borderRadius: 10,
              isLoading: authProvider.isLoading,
              onPressed: _handleLogin,
            ),

            const SizedBox(height: 14),

            // Atajo de desarrollo para rellenar credenciales rápidamente
            Center(
              child: TextButton.icon(
                onPressed: _autofillCredentials,
                icon: const Icon(
                  Icons.vpn_key_outlined,
                  size: 13,
                  color: Color(0xFF94A3B8),
                ),
                label: const Text(
                  'Rellenar credenciales de prueba',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 26),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aros decorativos geométricos en el fondo (como en la referencia)
class _BackgroundDecorativeCircles extends StatelessWidget {
  const _BackgroundDecorativeCircles();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Círculo grande superior derecho
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 480,
              height: 480,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
                  width: 32,
                ),
              ),
            ),
          ),
          // Círculo concéntrico izquierdo
          Positioned(
            bottom: -150,
            left: -120,
            child: Container(
              width: 540,
              height: 540,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                  width: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
