import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants.dart';
import '../../providers/project_details_provider.dart';

class ProjectSummaryTab extends StatelessWidget {
  const ProjectSummaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectDetailsProvider>(context);
    final f = NumberFormat.currency(symbol: '\$');

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [_buildHeader(context, provider, f)],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ProjectDetailsProvider provider,
    NumberFormat f,
  ) {
    final proyecto = provider.proyecto!;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP ROW: Logo and Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogo(context, provider),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proyecto.nombre ?? '',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (proyecto.notas != null &&
                          proyecto.notas.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            proyecto.notas!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // MIDDLE ROW: Client, Location, Status
            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn(
                    'Cliente',
                    proyecto.cliente ?? 'N/A',
                    Colors.black87,
                    icon: Icons.person_outline,
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Ubicación',
                    proyecto.ubicacion ?? 'N/A',
                    Colors.black87,
                    icon: Icons.location_on_outlined,
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _showChangeEstadoDialog(context, provider),
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Estado',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(
                              proyecto.estado,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            proyecto.estado ?? '',
                            style: TextStyle(
                              color: _getEstadoColor(proyecto.estado),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade100, height: 1),
            const SizedBox(height: 24),
            // BOTTOM ROW: Financials
            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn(
                    'Presupuesto Total',
                    f.format(
                      double.tryParse(
                            proyecto.totalPresupuestoConGlobales?.toString() ??
                                '0',
                          ) ??
                          0,
                    ),
                    Colors.green.shade700,
                    valueFontSize: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, ProjectDetailsProvider provider) {
    final proyecto = provider.proyecto!;
    return GestureDetector(
      onTap: () async {
        try {
          await provider.pickAndUploadLogo();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logo actualizado correctamente')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        }
      },
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: proyecto.logoPath == null
            ? Icon(
                Icons.add_a_photo_outlined,
                color: Colors.grey.shade300,
                size: 32,
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      '$host/api/v1/file?path=${proyecto.logoPath}',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.grey.shade300,
                          ),
                        );
                      },
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            try {
                              await provider.removeLogo();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Logo eliminado'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _showChangeEstadoDialog(
    BuildContext context,
    ProjectDetailsProvider provider,
  ) async {
    final proyecto = provider.proyecto!;
    List<String> opciones = [];
    String estadoActual = proyecto.estado;

    if (estadoActual == 'Cotización') {
      opciones = ['Activo', 'Cancelado'];
    } else if (estadoActual == 'Activo') {
      opciones = ['Terminado'];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este proyecto ya está finalizado o cancelado.'),
        ),
      );
      return;
    }

    final nuevoEstado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado del Proyecto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: opciones
              .map(
                (e) => ListTile(
                  title: Text(e),
                  onTap: () => Navigator.pop(context, e),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (nuevoEstado != null) {
      try {
        await provider.cambiarEstado(nuevoEstado);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Proyecto actualizado a: $nuevoEstado')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Color _getEstadoColor(String? estado) {
    switch (estado) {
      case 'Cotización':
        return Colors.orange.shade700;
      case 'Activo':
        return Colors.green.shade700;
      case 'Terminado':
        return Colors.blue.shade700;
      case 'Cancelado':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildInfoColumn(
    String label,
    String value,
    Color valueColor, {
    IconData? icon,
    double valueFontSize = 16,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: valueFontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
