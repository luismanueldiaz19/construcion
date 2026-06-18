import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/users_provider.dart';
import 'widgets/register_user_dialog.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UsersProvider>(context, listen: false).fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFFE31E24);
    final isMobile = MediaQuery.of(context).size.width <= 850;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestión de Usuarios',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1E),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const RegisterUserDialog(),
                  );

                  if (result == true) {
                    if (!context.mounted) return;
                    Provider.of<UsersProvider>(
                      context,
                      listen: false,
                    ).fetchUsers();
                  }
                },
                icon: const Icon(
                  Icons.person_add_alt_1_outlined,
                  color: Colors.white,
                ),
                label: const Text(
                  'Nuevo Usuario',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Consumer<UsersProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.errorMessage != null) {
                    return Center(
                      child: Text(
                        provider.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    );
                  }

                  if (provider.users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            size: 80,
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay usuarios registrados',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFF1A1C1E).withValues(alpha: 0.05),
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'ID',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Nombre',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Usuario',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Correo Electrónico',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Acciones',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: provider.users.map((user) {
                          return DataRow(
                            cells: [
                              DataCell(Text(user['id']?.toString() ?? '')),
                              DataCell(Text(user['name']?.toString() ?? '')),
                              DataCell(
                                Text(user['username']?.toString() ?? ''),
                              ),
                              DataCell(Text(user['email']?.toString() ?? '')),
                              DataCell(
                                Row(
                                  children: [
                                    if (user['username'] == 'ludeveloper')
                                      const IconButton(
                                        icon: Icon(
                                          Icons.admin_panel_settings,
                                          color: Colors.grey,
                                        ),
                                        onPressed: null,
                                        tooltip:
                                            'Admin principal (No se puede eliminar)',
                                      )
                                    else
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Eliminar Usuario',
                                              ),
                                              content: Text(
                                                '¿Estás seguro de eliminar a ${user['name']}?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text(
                                                    'Cancelar',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                  onPressed: () async {
                                                    Navigator.pop(context);
                                                    final success =
                                                        await provider
                                                            .deleteUser(
                                                              user['id'],
                                                            );
                                                    if (success &&
                                                        context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Usuario eliminado',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: const Text(
                                                    'Eliminar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
