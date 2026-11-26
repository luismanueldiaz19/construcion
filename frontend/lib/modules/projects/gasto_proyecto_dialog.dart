import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/gasto_proyecto.dart';
import '../../models/proveedor.dart';
import '../../models/proyecto.dart';
import '../../services/accounting_service.dart';
import '../../services/project_service.dart';
import '../../services/purchase_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/proveedor_dialog.dart';

class GastoProyectoDialog extends StatefulWidget {
  final Proyecto proyecto;
  const GastoProyectoDialog({super.key, required this.proyecto});

  @override
  State<GastoProyectoDialog> createState() => _GastoProyectoDialogState();
}

class _GastoProyectoDialogState extends State<GastoProyectoDialog> {
  final ProjectService _projectService = ProjectService();
  final AccountingService _accountingService = AccountingService();
  final PurchaseService _purchaseService = PurchaseService();

  final _montoController = TextEditingController();
  final _descController = TextEditingController();
  final _searchController = TextEditingController();

  List<dynamic> _cuentasCostos = [];
  List<Proveedor> _proveedores = [];
  List<Proveedor> _proveedoresFiltrados = [];
  List<dynamic> _bancos = [];
  List<dynamic> _subpartidas = [];

  int? _cuentaCostoId;
  int? _proveedorId;
  int? _bancoId;
  int? _subpartidaId;
  String _metodoPago = 'Transferencia';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subpartidas = widget.proyecto.partidas.expand((p) {
      return p.subpartidas.map(
        (s) => {
          'id': s.id,
          'descripcion': s.descripcion,
          'partida_nombre': p.descripcion,
        },
      );
    }).toList();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _accountingService.getCatalogo(),
        _purchaseService.getProveedores(),
        _accountingService.getBancos(),
      ]);
      if (mounted) {
        setState(() {
          // Filtramos cuentas que empiezan con '5' (Costos)
          _cuentasCostos = (results[0] as List<dynamic>)
              .where((c) => c['codigo'].toString().startsWith('5'))
              .toList();

          _proveedores = results[1] as List<Proveedor>;
          _bancos = results[2] as List<dynamic>;
          _isLoading = false;

          if (_bancos.isNotEmpty) {
            _bancoId = _bancos[0]['id'];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos contables: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterProveedores(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _proveedoresFiltrados = [];
      } else {
        final q = query.toLowerCase();
        _proveedoresFiltrados = _proveedores
            .where(
              (p) =>
                  p.name.toLowerCase().contains(q) ||
                  (p.rnc != null && p.rnc!.toLowerCase().contains(q)),
            )
            .toList();
      }
    });
  }

  Future<void> _openCrearProveedor() async {
    await showDialog(
      context: context,
      builder: (ctx) => ProveedorDialog(onSaved: () {}),
    );

    // Recargar proveedores para reflejar el nuevo registro
    try {
      final provs = await _purchaseService.getProveedores();
      if (mounted && provs.isNotEmpty) {
        setState(() {
          _proveedores = provs;
          final last = provs.last;
          _proveedorId = last.id;
          _searchController.text = last.name;
          _proveedoresFiltrados = [];
        });
      }
    } catch (_) {}
  }

  Future<void> _saveGasto() async {
    final montoVal = double.tryParse(_montoController.text.trim());

    if (_proveedorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un Proveedor o Trabajador.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_cuentaCostoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione el Tipo de Gasto (Cuenta).'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (montoVal == null || montoVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese un monto válido mayor a 0.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final cuentaMatch = _cuentasCostos.firstWhere(
        (c) => c['id'] == _cuentaCostoId,
        orElse: () => {'nombre': 'Costo General'},
      );

      await _projectService.createGastoProyecto(
        GastoProyecto(
          proyectoId: widget.proyecto.id!,
          subpartidaId: _subpartidaId,
          proveedorId: _proveedorId,
          cuentaCostoId: _cuentaCostoId,
          monto: montoVal,
          tipoGasto: cuentaMatch['nombre']?.toString() ?? 'Gasto de Proyecto',
          descripcion: _descController.text.trim(),
          fecha: DateTime.now(),
          metodoPago: _metodoPago,
          bancoId: _metodoPago == 'Crédito' ? null : _bancoId,
        ),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Gasto registrado correctamente'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar gasto: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: _isLoading
            ? const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFFE31E24),
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cabecera Moderna Neo ERP
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE31E24),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFE31E24,
                                ).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'REGISTRAR GASTO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 1.5),
                              Text(
                                widget.proyecto.nombre,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                          splashRadius: 18,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Formulario
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Proveedor / Trabajador
                          _buildProveedorSection(),
                          const SizedBox(height: 14),

                          // 2. Tipo de Gasto (Cuenta de Costo)
                          AppDropdown<int>(
                            labelText: 'TIPO DE GASTO (CUENTA DE COSTO) *',
                            value: _cuentaCostoId,
                            isExpanded: true,
                            prefixIconData: Icons.category_outlined,
                            hintText: 'Seleccione cuenta contable...',
                            items: _cuentasCostos.map((c) {
                              final cod = c['codigo']?.toString() ?? '';
                              final nom = c['nombre']?.toString() ?? '';
                              final label = cod.isNotEmpty
                                  ? '$cod - $nom'
                                  : nom;
                              return DropdownMenuItem<int>(
                                value: c['id'] as int,
                                child: Text(
                                  label,
                                  style: const TextStyle(fontSize: 12.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _cuentaCostoId = v),
                          ),
                          const SizedBox(height: 14),

                          // 3. Descripción / Nota
                          AppTextField(
                            controller: _descController,
                            labelText: 'DESCRIPCIÓN / DETALLE (OPCIONAL)',
                            hintText:
                                'Ej. Compra de materiales, mano de obra, etc.',
                            prefixIconData: Icons.notes_rounded,
                          ),
                          const SizedBox(height: 14),

                          // 4. Monto y Método de Pago en Row balanceada
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: AppTextField(
                                  controller: _montoController,
                                  labelText: 'MONTO (RD\$) *',
                                  hintText: '0.00',
                                  prefixIconData:
                                      Icons.monetization_on_outlined,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 5,
                                child: AppDropdown<String>(
                                  labelText: 'MÉTODO DE PAGO',
                                  value: _metodoPago,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Transferencia',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.swap_horiz_rounded,
                                            size: 16,
                                            color: Color(0xFF64748B),
                                          ),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Transferencia',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 12.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Efectivo',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.payments_outlined,
                                            size: 16,
                                            color: Color(0xFF64748B),
                                          ),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Efectivo',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 12.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Cheque',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.receipt_outlined,
                                            size: 16,
                                            color: Color(0xFF64748B),
                                          ),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Cheque',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 12.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Crédito',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.credit_card_outlined,
                                            size: 16,
                                            color: Color(0xFF64748B),
                                          ),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Crédito',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 12.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _metodoPago = v);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),

                          // 5. Cuenta de Origen (Banco) - Solo si no es a crédito
                          if (_metodoPago != 'Crédito') ...[
                            const SizedBox(height: 14),
                            AppDropdown<int>(
                              labelText: 'CUENTA DE ORIGEN / BANCO',
                              value: _bancoId,
                              isExpanded: true,
                              prefixIconData: Icons.account_balance_outlined,
                              items: _bancos.map((b) {
                                return DropdownMenuItem<int>(
                                  value: b['id'] as int,
                                  child: Text(
                                    b['nombre']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 12.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _bancoId = v),
                            ),
                          ],

                          // 6. Partida Relacionada (Opcional)
                          const SizedBox(height: 14),
                          AppDropdown<int?>(
                            labelText: 'PARTIDA / RUBRO ASOCIADO (OPCIONAL)',
                            value: _subpartidaId,
                            isExpanded: true,
                            prefixIconData: Icons.layers_outlined,
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  'Ninguna (Gasto general de la obra)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ..._subpartidas.map(
                                (s) => DropdownMenuItem<int?>(
                                  value: s['id'] as int,
                                  child: Text(
                                    "[${s['partida_nombre']}] ${s['descripcion'] ?? s['nombre']}",
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() => _subpartidaId = v),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Barra de Acciones Inferior
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton(
                          text: 'Cancelar',
                          variant: AppButtonVariant.outlined,
                          size: AppButtonSize.standard,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 10),
                        AppButton(
                          text: 'Guardar Gasto',
                          icon: Icons.check_circle_outline_rounded,
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.standard,
                          isLoading: _isSaving,
                          onPressed: _saveGasto,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProveedorSection() {
    final hasSelected = _proveedorId != null;
    Proveedor? selected;
    if (hasSelected) {
      try {
        selected = _proveedores.firstWhere((p) => p.id == _proveedorId);
      } catch (_) {
        selected = null;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PROVEEDOR / BENEFICIARIO *',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 5),

        if (hasSelected && selected != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 18,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selected.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (selected.rnc != null && selected.rnc!.isNotEmpty)
                        Text(
                          'RNC/Céd: ${selected.rnc}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Cambiar proveedor',
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _proveedorId = null;
                        _searchController.clear();
                        _proveedoresFiltrados = [];
                      });
                    },
                  ),
                ),
              ],
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _searchController,
                  hintText: 'Escriba nombre o RNC...',
                  prefixIconData: Icons.search_rounded,
                  onChanged: _filterProveedores,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Registrar nuevo proveedor',
                child: InkWell(
                  onTap: _openCrearProveedor,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: Color(0xFF0F172A),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Nuevo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_proveedoresFiltrados.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 140),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _proveedoresFiltrados.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final p = _proveedoresFiltrados[index];
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(
                      Icons.storefront_outlined,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    title: Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: p.rnc != null && p.rnc!.isNotEmpty
                        ? Text(
                            'RNC: ${p.rnc}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _proveedorId = p.id;
                        _searchController.text = p.name;
                        _proveedoresFiltrados = [];
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}
