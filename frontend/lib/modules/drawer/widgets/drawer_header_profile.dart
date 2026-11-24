import 'package:flutter/material.dart';

/// Encabezado premium del Drawer idéntico al diseño de UX Pilot.
/// Incluye perfil de usuario con avatar, nombre, cargo, botón de colapso «,
/// buscador de módulos integrado y botón de código QR en rojo corporativo.
class DrawerHeaderProfile extends StatelessWidget {
  final String userName;
  final String userRole;
  final String? avatarUrl;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onCollapse;
  final VoidCallback? onQrPressed;

  const DrawerHeaderProfile({
    super.key,
    required this.userName,
    required this.userRole,
    this.avatarUrl,
    required this.searchController,
    required this.onSearchChanged,
    this.onCollapse,
    this.onQrPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Dark slate premium
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Acento circular orgánico borgoña/carmesí de fondo en la esquina superior derecha
          Positioned(
            right: -25,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF881337).withValues(alpha: 0.45), // Deep rose / burgundy
                    const Color(0xFF0F172A).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fila de Perfil de Usuario + Botón de colapso «
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar cuadrado redondeado (10px)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.0,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: avatarUrl != null && avatarUrl!.isNotEmpty
                          ? Image.network(
                              avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildAvatarFallback(),
                            )
                          : _buildAvatarFallback(),
                    ),
                    const SizedBox(width: 12),

                    // Nombre y Rol/Empresa
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userRole,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Botón de colapso «
                    if (onCollapse != null)
                      Material(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: onCollapse,
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.keyboard_double_arrow_left_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Fila de Buscador integrado + Botón QR rojo
                Row(
                  children: [
                    // Campo de búsqueda compacto
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: onSearchChanged,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Buscar módulo...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11.5,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            suffixIcon: searchController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      searchController.clear();
                                      onSearchChanged('');
                                    },
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 15,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botón QR en rojo corporativo (#E31E24)
                    Material(
                      color: const Color(0xFFE31E24),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: onQrPressed,
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFF272F3D),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 26,
        color: Color(0xFFCBD5E1),
      ),
    );
  }
}
