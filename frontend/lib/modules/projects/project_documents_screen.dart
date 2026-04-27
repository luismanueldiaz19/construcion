import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class ProjectDocumentsScreen extends StatefulWidget {
  final int proyectoId;
  final String proyectoNombre;

  const ProjectDocumentsScreen({
    super.key,
    required this.proyectoId,
    required this.proyectoNombre,
  });

  @override
  State<ProjectDocumentsScreen> createState() => _ProjectDocumentsScreenState();
}

class _ProjectDocumentsScreenState extends State<ProjectDocumentsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _documentos = [];
  List<dynamic> _partidas = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final docs = await _apiService.getDocumentosProyecto(widget.proyectoId);
      final parts = await _apiService.getPartidas(widget.proyectoId);
      print('Partidas cargadas para documentos: $parts');
      setState(() {
        _documentos = docs;
        _partidas = parts;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      }
    }
  }

  void _showUploadDialog() {
    final nombreController = TextEditingController();
    final categoriaController = TextEditingController();
    String selectedTipo = 'otro';
    int? selectedPartidaId;
    PlatformFile? pickedFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Subir Documento / Plano'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del archivo',
                    hintText: 'Ej: Plano Eléctrico 1er Nivel',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'plano', child: Text('Plano')),
                    DropdownMenuItem(
                      value: 'evidencia',
                      child: Text('Evidencia'),
                    ),
                    DropdownMenuItem(value: 'otro', child: Text('Otro')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedTipo = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoriaController,
                  decoration: const InputDecoration(
                    labelText: 'Categoría / Área',
                    hintText: 'Ej: Cocina, Sala, Azotea...',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedPartidaId,
                  decoration: InputDecoration(
                    labelText: 'Vincular a Partida (Opcional)',
                    hintText: _isLoading
                        ? 'Cargando partidas...'
                        : (_partidas.isEmpty
                              ? 'No hay partidas en este proyecto'
                              : 'Seleccione una partida'),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Ninguna')),
                    ..._partidas.map(
                      (p) => DropdownMenuItem(
                        value: p['id'],
                        child: Text(
                          p['descripcion'] ??
                              p['nombre'] ??
                              'Partida #${p['id']}',
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => selectedPartidaId = v),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                    );
                    if (result != null) {
                      if (result.files.first.size > 15 * 1024 * 1024) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('El archivo supera los 15MB'),
                            ),
                          );
                        }
                        return;
                      }
                      setDialogState(() => pickedFile = result.files.first);
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    pickedFile == null
                        ? 'Seleccionar Archivo'
                        : 'Cambiar Archivo',
                  ),
                ),
                if (pickedFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Seleccionado: ${pickedFile!.name}',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: pickedFile == null || nombreController.text.isEmpty
                  ? null
                  : () async {
                      Navigator.pop(context);
                      setState(() => _isLoading = true);
                      try {
                        await _apiService.uploadDocumento(
                          proyectoId: widget.proyectoId,
                          nombre: nombreController.text,
                          tipo: selectedTipo,
                          categoria: categoriaController.text.isNotEmpty
                              ? categoriaController.text
                              : null,
                          partidaId: selectedPartidaId,
                          filePath: pickedFile!.path!,
                        );
                        _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Archivo subido con éxito'),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => _isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
              child: const Text('Subir'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documentos: ${widget.proyectoNombre}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: _showUploadDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadDialog,
        child: const Icon(Icons.upload_file),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documentos.isEmpty
          ? const Center(child: Text('No hay documentos cargados.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _documentos.length,
              itemBuilder: (context, index) {
                final doc = _documentos[index];
                final isPdf =
                    doc['file_extension'].toString().toLowerCase() == 'pdf';

                return Card(
                  child: ListTile(
                    leading: Icon(
                      isPdf ? Icons.picture_as_pdf : Icons.image,
                      color: isPdf ? Colors.red : Colors.blue,
                    ),
                    title: Text(
                      doc['nombre'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tipo: ${doc['tipo'].toString().toUpperCase()} | Cat: ${doc['categoria'] ?? "N/A"}',
                        ),
                        if (doc['partida'] != null)
                          Text(
                            'Vinculado a: ${doc['partida']['descripcion']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.green),
                          onPressed: () async {
                            final url = Uri.parse(
                              _apiService.baseUrl.replaceFirst(
                                    '/api/v1',
                                    '/storage/',
                                  ) +
                                  doc['file_path'],
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Eliminar'),
                                content: const Text(
                                  '¿Está seguro de eliminar este documento?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Sí'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _apiService.deleteDocumento(doc['id']);
                              _loadData();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
