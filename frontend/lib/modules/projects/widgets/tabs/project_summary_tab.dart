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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, provider, f),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildProfitabilityCard(provider, f)),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildCashFlowCard(provider, f),
                          const SizedBox(height: 24),
                          _buildIndirectsBreakdown(provider, f),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildProfitabilityCard(provider, f),
                    const SizedBox(height: 24),
                    _buildCashFlowCard(provider, f),
                    const SizedBox(height: 24),
                    _buildIndirectsBreakdown(provider, f),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProjectDetailsProvider provider, NumberFormat f) {
    final proyecto = provider.proyecto!;
    
    return Card(
      color: const Color(0xFF003366),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: proyecto.logoPath == null
                        ? const Icon(Icons.add_a_photo, color: Colors.white54)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  '$host/api/v1/file?path=${proyecto.logoPath}',
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.broken_image, color: Colors.redAccent),
                                    );
                                  },
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () async {
                                        try {
                                          await provider.removeLogo();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Logo eliminado')),
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
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              proyecto.nombre ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Edit notas can be implemented later or triggered from parent
                        ],
                      ),
                      if (proyecto.notas != null && proyecto.notas.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            proyecto.notas!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildInfoColumn('Cliente', proyecto.cliente ?? 'N/A', Colors.white),
                ),
                Expanded(
                  child: _buildInfoColumn('Ubicación', proyecto.ubicacion ?? 'N/A', Colors.white),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _showChangeEstadoDialog(context, provider),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text(
                              'Estado',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.sync_alt, size: 12, color: Colors.white54),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(proyecto.estado).withValues(alpha: 0.2),
                            border: Border.all(color: _getEstadoColor(proyecto.estado)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            proyecto.estado ?? '',
                            style: TextStyle(
                              color: _getEstadoColor(proyecto.estado),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white24, height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildInfoColumn(
                    'Presupuesto Total',
                    f.format(
                      double.tryParse(proyecto.totalPresupuestoConGlobales?.toString() ?? '0') ?? 0,
                    ),
                    Colors.greenAccent,
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Avance Físico',
                    '${proyecto.porcentajeAvanceTotal ?? 0}%',
                    Colors.blueAccent,
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Ejecutado',
                    f.format(
                      double.tryParse(proyecto.montoEjecutadoTotal?.toString() ?? '0') ?? 0,
                    ),
                    Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeEstadoDialog(BuildContext context, ProjectDetailsProvider provider) async {
    final proyecto = provider.proyecto!;
    List<String> opciones = [];
    String estadoActual = proyecto.estado;

    if (estadoActual == 'Cotización') {
      opciones = ['Activo', 'Cancelado'];
    } else if (estadoActual == 'Activo') {
      opciones = ['Terminado'];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este proyecto ya está finalizado o cancelado.')),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  Widget _buildIndirectsBreakdown(ProjectDetailsProvider provider, NumberFormat f) {
    final proyecto = provider.proyecto!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF003366),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DESGLOSE DE COSTOS INDIRECTOS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildIndirectRow('Supervisión Técnica', proyecto.supervisionTecnica, f),
          _buildIndirectRow('ITBIS', proyecto.itbis, f),
          _buildIndirectRow('Transporte', proyecto.transporte, f),
          _buildIndirectRow('Otros Gastos', proyecto.otrosCostos, f),
        ],
      ),
    );
  }

  Widget _buildIndirectRow(String label, dynamic value, NumberFormat f) {
    final val = double.tryParse(value?.toString() ?? '0') ?? 0;
    if (val == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
            f.format(val),
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitabilityCard(ProjectDetailsProvider provider, NumberFormat f) {
    final proyecto = provider.proyecto!;
    final ingresoNeto = proyecto.ingresoNetoReal ?? 0;

    final double gastosEfectivo = provider.gastos.fold(0, (sum, g) => sum + g.monto);
    final double costosMateriales = provider.consumos.fold(0, (sum, c) => sum + c.total);
    final costoReal = gastosEfectivo + costosMateriales;

    final ganancia = ingresoNeto - costoReal;
    final margen = ingresoNeto > 0 ? (ganancia / ingresoNeto) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF003366),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'ANÁLISIS DE RENTABILIDAD (GANANCIA REAL)',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleStat('Ingreso Neto (Sin ITBIS)', f.format(ingresoNeto)),
              const Text('-', style: TextStyle(color: Colors.white38)),
              _buildSimpleStat(
                'Costos Reales (Gastos + Mat.)',
                f.format(costoReal),
                valueColor: Colors.redAccent,
              ),
            ],
          ),
          const Divider(height: 32, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Utilidad Neta:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(
                    'Margen: ${margen.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
              Text(
                f.format(ganancia),
                style: TextStyle(
                  color: ganancia >= 0 ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowCard(ProjectDetailsProvider provider, NumberFormat f) {
    final proyecto = provider.proyecto!;
    final cobrado = proyecto.totalCobrado ?? 0;
    final ejecutado = proyecto.montoEjecutadoTotal ?? 0;
    final balance = cobrado - ejecutado;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF003366),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'BALANCE DE FONDOS VS EJECUCIÓN',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFlowItem('Cobrado al Cliente', cobrado, Colors.greenAccent, f),
              const Icon(Icons.compare_arrows, color: Colors.white24),
              _buildFlowItem('Valor Construido', ejecutado, Colors.blueAccent, f),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Balance en Manos:', style: TextStyle(color: Colors.white)),
              Text(
                f.format(balance),
                style: TextStyle(
                  color: balance >= 0 ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          if (balance < 0)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                '⚠️ Estás ejecutando más de lo cobrado',
                style: TextStyle(color: Colors.redAccent, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, {Color valueColor = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFlowItem(String label, double value, Color color, NumberFormat f) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
          Text(
            f.format(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String? estado) {
    switch (estado) {
      case 'Cotización':
        return Colors.orange;
      case 'Activo':
        return Colors.greenAccent;
      case 'Terminado':
        return Colors.blueAccent;
      case 'Cancelado':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoColumn(String label, String value, Color valueColor, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 12, color: Colors.white54),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
