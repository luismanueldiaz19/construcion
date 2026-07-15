import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nomina_catalogs_provider.dart';
import '../../../models/nomina_catalogs.dart';

class NominaCatalogsScreen extends StatelessWidget {
  const NominaCatalogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NominaCatalogsProvider(),
      child: const _CatalogsContent(),
    );
  }
}

class _CatalogsContent extends StatefulWidget {
  const _CatalogsContent();

  @override
  State<_CatalogsContent> createState() => _CatalogsContentState();
}

class _CatalogsContentState extends State<_CatalogsContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NominaCatalogsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Configuración de Nómina',
          style: TextStyle(
            color: Color(0xFF1E3A5F),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E3A5F)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E3A5F),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1E3A5F),
          tabs: const [
            Tab(text: 'Departamentos'),
            Tab(text: 'Cargos'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDepartmentsList(context, provider),
                _buildPositionsList(context, provider),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showDepartmentDialog(context);
          } else {
            _showPositionDialog(context, provider.departments);
          }
        },
        backgroundColor: const Color(0xFF1E3A5F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Nuevo Depto' : 'Nuevo Cargo',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDepartmentsList(
    BuildContext context,
    NominaCatalogsProvider provider,
  ) {
    if (provider.departments.isEmpty) {
      return const Center(child: Text('No hay departamentos registrados.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.departments.length,
      itemBuilder: (context, index) {
        final dept = provider.departments[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              dept.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Centro de Costos: ${dept.costCenterCode ?? "N/A"}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showDepartmentDialog(context, department: dept),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPositionsList(
    BuildContext context,
    NominaCatalogsProvider provider,
  ) {
    if (provider.positions.isEmpty) {
      return const Center(child: Text('No hay cargos registrados.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.positions.length,
      itemBuilder: (context, index) {
        final pos = provider.positions[index];
        final deptMatches = provider.departments.where(
          (d) => d.id == pos.departmentId,
        );
        final dept = deptMatches.isNotEmpty ? deptMatches.first : null;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              pos.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(dept?.name ?? 'Sin departamento'),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showPositionDialog(
                context,
                provider.departments,
                position: pos,
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Dialogs ---

  void _showDepartmentDialog(BuildContext context, {Department? department}) {
    final nameCtrl = TextEditingController(text: department?.name);
    final costCenterCtrl = TextEditingController(
      text: department?.costCenterCode,
    );
    final provider = context.read<NominaCatalogsProvider>();

    bool autoGenerate =
        department?.costCenterCode == null ||
        department!.costCenterCode!.isEmpty;

    nameCtrl.addListener(() {
      if (autoGenerate) {
        String name = nameCtrl.text.trim().toUpperCase();
        name = name
            .replaceAll('Á', 'A')
            .replaceAll('É', 'E')
            .replaceAll('Í', 'I')
            .replaceAll('Ó', 'O')
            .replaceAll('Ú', 'U')
            .replaceAll(RegExp(r'[^A-Z]'), '');
        if (name.length >= 3) {
          final generated = '${name.substring(0, 3)}-01';
          if (costCenterCtrl.text != generated) {
            costCenterCtrl.text = generated;
          }
        } else {
          if (costCenterCtrl.text.isNotEmpty) {
            costCenterCtrl.text = '';
          }
        }
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        title: Text(
          department == null ? 'Nuevo Departamento' : 'Editar Departamento',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre del Departamento *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: costCenterCtrl,
              onChanged: (val) => autoGenerate = false,
              decoration: InputDecoration(
                labelText: 'Código Centro de Costos',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                helperText: 'Opcional (Ej. ADM-01)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE31E24),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final success = await provider.saveDepartment({
                'name': nameCtrl.text.trim(),
                'cost_center_code': costCenterCtrl.text.trim().isEmpty
                    ? null
                    : costCenterCtrl.text.trim(),
              }, id: department?.id);
              if (success && mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Guardar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showPositionDialog(
    BuildContext context,
    List<Department> departments, {
    Position? position,
  }) {
    final titleCtrl = TextEditingController(text: position?.title);
    int? selectedDept = position?.departmentId;
    final provider = context.read<NominaCatalogsProvider>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          title: Text(
            position == null ? 'Nuevo Cargo' : 'Editar Cargo',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre del Cargo *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedDept,
                decoration: InputDecoration(
                  labelText: 'Departamento',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Sin departamento'),
                  ),
                  ...departments.map(
                    (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                  ),
                ],
                onChanged: (v) => setStateModal(() => selectedDept = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE31E24),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final success = await provider.savePosition({
                  'title': titleCtrl.text.trim(),
                  'department_id': selectedDept,
                }, id: position?.id);
                if (success && mounted) Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
