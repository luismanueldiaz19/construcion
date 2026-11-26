import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/project_service.dart';
import '../../models/partida.dart';
import '../../core/models/document_model.dart';
import '../../core/repositories/document_repository.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../core/utils/image_compressor.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_text_field.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class ProjectDocumentsScreen extends StatefulWidget {
  final int proyectoId;
  final String proyectoNombre;
  final String? logoPath;
  final bool embedded;

  const ProjectDocumentsScreen({
    super.key,
    required this.proyectoId,
    required this.proyectoNombre,
    this.logoPath,
    this.embedded = false,
  });

  @override
  State<ProjectDocumentsScreen> createState() => _ProjectDocumentsScreenState();
}

class _ProjectDocumentsScreenState extends State<ProjectDocumentsScreen> {
  final DocumentRepository _repository = DocumentRepository();
  final ProjectService _projectService = ProjectService();

  bool _isLoading = true;
  List<DocumentModel> _documentos = [];
  List<Partida> _partidas = [];

  // Filtros y Vista
  String _searchQuery = '';
  String _selectedTipo = 'todos';
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final docs = await _repository.getDocumentsByProject(widget.proyectoId);
      final parts = await _projectService.getPartidas(widget.proyectoId);

      if (mounted) {
        setState(() {
          _documentos = docs;
          _partidas = parts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Lógica de Filtrado
  List<DocumentModel> get _filteredDocuments {
    return _documentos.where((doc) {
      final matchesSearch =
          doc.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (doc.categoria?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      final matchesTipo = _selectedTipo == 'todos' || doc.tipo == _selectedTipo;
      return matchesSearch && matchesTipo;
    }).toList();
  }

  int get _totalSizeBytes {
    return _documentos.fold(0, (sum, doc) => sum + doc.fileSize);
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    double size = bytes.toDouble();
    int suffixIndex = 0;
    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }
    return "${size.toStringAsFixed(1)} ${suffixes[suffixIndex]}";
  }

  void _showUploadDialog() {
    final nombreController = TextEditingController();
    final categoriaController = TextEditingController();
    String selectedTipo = 'otro';
    int? selectedPartidaId;
    PlatformFile? pickedFile;
    Uint8List? previewBytes;
    bool isImage = false;
    bool isPdf = false;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stfContext, setDialogState) {
          Future<void> pickFromCamera() async {
            final XFile? image = await ImageCompressor.pickAndCompressImage(
              source: ImageSource.camera,
              imageQuality: 80,
              maxWidth: 1600,
              maxHeight: 1600,
            );
            if (image == null) return;

            final bytes = await image.readAsBytes();
            final size = await image.length();
            setDialogState(() {
              pickedFile = PlatformFile(
                name: image.name,
                size: size,
                path: image.path,
                bytes: bytes,
              );
              previewBytes = bytes;
              isImage = true;
              isPdf = false;
              selectedTipo = 'evidencia';
              if (nombreController.text.trim().isEmpty) {
                final nowStr = DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(DateTime.now());
                nombreController.text = 'Foto de obra ($nowStr)';
              }
            });
          }

          Future<void> pickFromGallery() async {
            final XFile? image = await ImageCompressor.pickAndCompressImage(
              source: ImageSource.gallery,
              imageQuality: 80,
              maxWidth: 1600,
              maxHeight: 1600,
            );
            if (image == null) return;

            final bytes = await image.readAsBytes();
            final size = await image.length();
            setDialogState(() {
              pickedFile = PlatformFile(
                name: image.name,
                size: size,
                path: image.path,
                bytes: bytes,
              );
              previewBytes = bytes;
              isImage = true;
              isPdf = false;
              selectedTipo = 'evidencia';
              if (nombreController.text.trim().isEmpty) {
                String clean = image.name.replaceAll(
                  RegExp(r'\.[a-zA-Z0-9]+$'),
                  '',
                );
                if (clean.startsWith('image_picker_') ||
                    clean.startsWith('scaled_') ||
                    clean.startsWith('IMG_')) {
                  final nowStr = DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(DateTime.now());
                  clean = 'Evidencia ($nowStr)';
                }
                nombreController.text = clean;
              }
            });
          }

          Future<void> pickFromFilePicker() async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
              withData: true,
            );
            if (result == null || result.files.isEmpty) return;
            final file = result.files.first;
            final ext = file.extension?.toLowerCase() ?? '';

            if (file.size > 15 * 1024 * 1024) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El archivo supera los 15MB permitidos.'),
                    backgroundColor: Color(0xFFDC2626),
                  ),
                );
              }
              return;
            }

            final bool fileIsImage = [
              'jpg',
              'jpeg',
              'png',
              'webp',
            ].contains(ext);
            final bool fileIsPdf = ext == 'pdf';

            setDialogState(() {
              pickedFile = file;
              previewBytes = fileIsImage ? file.bytes : null;
              isImage = fileIsImage;
              isPdf = fileIsPdf;
              if (fileIsPdf) {
                selectedTipo = 'plano';
              } else if (fileIsImage) {
                selectedTipo = 'evidencia';
              }
              if (nombreController.text.trim().isEmpty) {
                final clean = file.name.replaceAll(
                  RegExp(r'\.[a-zA-Z0-9]+$'),
                  '',
                );
                nombreController.text = clean;
              }
            });
          }

          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
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
                            Icons.cloud_upload_rounded,
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
                                'SUBIR DOCUMENTO / FOTO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 1.5),
                              Text(
                                widget.proyectoNombre,
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
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  ),

                  // Contenido Scrollable
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Selector de Archivo / Foto
                          const Text(
                            'SELECCIONAR ARCHIVO O FOTO *',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (pickedFile == null)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPickerCard(
                                    icon: Icons.camera_alt_rounded,
                                    title: 'Cámara',
                                    subtitle: 'Foto en vivo',
                                    color: const Color(0xFFE31E24),
                                    onTap: pickFromCamera,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildPickerCard(
                                    icon: Icons.photo_library_rounded,
                                    title: 'Galería',
                                    subtitle: 'Foto comprimida',
                                    color: const Color(0xFF2563EB),
                                    onTap: pickFromGallery,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildPickerCard(
                                    icon: Icons.picture_as_pdf_rounded,
                                    title: 'Documento',
                                    subtitle: 'PDF o Plano',
                                    color: const Color(0xFF0F766E),
                                    onTap: pickFromFilePicker,
                                  ),
                                ),
                              ],
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: isImage && previewBytes != null
                                        ? Image.memory(
                                            previewBytes!,
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 52,
                                            height: 52,
                                            color: const Color(0xFFE2E8F0),
                                            child: Icon(
                                              isPdf
                                                  ? Icons.picture_as_pdf_rounded
                                                  : Icons.description_rounded,
                                              color: isPdf
                                                  ? const Color(0xFFDC2626)
                                                  : const Color(0xFF0F172A),
                                              size: 26,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pickedFile!.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: Color(0xFF0F172A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Text(
                                              _formatFileSize(pickedFile!.size),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (isImage)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 1.5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF16A34A,
                                                  ).withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.bolt_rounded,
                                                      size: 12,
                                                      color: Color(0xFF16A34A),
                                                    ),
                                                    SizedBox(width: 2),
                                                    Text(
                                                      'Comprimido',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Color(
                                                          0xFF16A34A,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Cambiar archivo',
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: Color(0xFF64748B),
                                      ),
                                      splashRadius: 16,
                                      onPressed: () {
                                        setDialogState(() {
                                          pickedFile = null;
                                          previewBytes = null;
                                          isImage = false;
                                          isPdf = false;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 14),

                          // 2. Nombre descriptivo
                          AppTextField(
                            controller: nombreController,
                            labelText: 'NOMBRE DESCRIPTIVO *',
                            hintText:
                                'Ej. Plano estructural Nivel 1, Foto vaciado...',
                            prefixIconData: Icons.title_rounded,
                          ),
                          const SizedBox(height: 14),

                          // 3. Tipo de Documento
                          AppDropdown<String>(
                            labelText: 'TIPO DE ARCHIVO *',
                            value: selectedTipo,
                            isExpanded: true,
                            prefixIconData: Icons.category_outlined,
                            items: const [
                              DropdownMenuItem(
                                value: 'plano',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.architecture_rounded,
                                      size: 16,
                                      color: Color(0xFF64748B),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Plano / Esquema técnico',
                                      style: TextStyle(fontSize: 12.5),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'evidencia',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.photo_camera_rounded,
                                      size: 16,
                                      color: Color(0xFF64748B),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Evidencia fotográfica',
                                      style: TextStyle(fontSize: 12.5),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'otro',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 16,
                                      color: Color(0xFF64748B),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Otro documento / Anexo',
                                      style: TextStyle(fontSize: 12.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() => selectedTipo = v);
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          // 4. Área / Categoría
                          AppTextField(
                            controller: categoriaController,
                            labelText: 'ÁREA / CATEGORÍA (OPCIONAL)',
                            hintText: 'Ej. Estructura, Terminación, Fachada...',
                            prefixIconData: Icons.layers_outlined,
                          ),
                          const SizedBox(height: 14),

                          // 5. Vincular a Partida
                          AppDropdown<int?>(
                            labelText: 'VINCULAR A PARTIDA (OPCIONAL)',
                            value: selectedPartidaId,
                            isExpanded: true,
                            prefixIconData: Icons.account_tree_outlined,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text(
                                  'Ninguna (General del proyecto)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              ..._partidas.map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(
                                    p.descripcion,
                                    style: const TextStyle(fontSize: 12.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => selectedPartidaId = v),
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
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                        const SizedBox(width: 10),
                        AppButton(
                          text: 'Subir Documento',
                          icon: Icons.cloud_upload_rounded,
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.standard,
                          isLoading: isUploading,
                          onPressed: () async {
                            if (pickedFile == null) {
                              ScaffoldMessenger.of(stfContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Por favor seleccione una foto o archivo para subir.',
                                  ),
                                  backgroundColor: Color(0xFFDC2626),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            if (nombreController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(stfContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'El nombre descriptivo es obligatorio.',
                                  ),
                                  backgroundColor: Color(0xFFDC2626),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(dialogContext);

                            setDialogState(() => isUploading = true);
                            try {
                              await _repository.uploadDocument(
                                proyectoId: widget.proyectoId,
                                nombre: nombreController.text.trim(),
                                tipo: selectedTipo,
                                categoria:
                                    categoriaController.text.trim().isNotEmpty
                                    ? categoriaController.text.trim()
                                    : null,
                                partidaId: selectedPartidaId,
                                file: pickedFile!,
                              );
                              if (mounted) {
                                navigator.pop();
                                _loadData();
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '✅ Documento subido y optimizado con éxito',
                                    ),
                                    backgroundColor: Color(0xFF16A34A),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => isUploading = false);
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error al subir documento: $e',
                                    ),
                                    backgroundColor: const Color(0xFFDC2626),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPickerCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fDate = DateFormat('dd/MM/yyyy HH:mm');
    final filtered = _filteredDocuments;

    return Scaffold(
      backgroundColor: widget.embedded
          ? Colors.transparent
          : AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          if (!widget.embedded) _buildSliverAppBar(),
          _buildFiltersAndStats(),
          _isLoading
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(50),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              : filtered.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : _isGridView
              ? _buildGridView(filtered, fDate)
              : _buildListView(filtered, fDate),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadDialog,
        backgroundColor: const Color(0xFFE31E24),
        icon: const Icon(
          Icons.add_photo_alternate_rounded,
          color: Colors.white,
          size: 20,
        ),
        label: const Text(
          'Subir Documento / Foto',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.proyectoNombre,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 4.0,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppTheme.primaryColor),
            if (widget.logoPath != null)
              Opacity(
                opacity: 0.5,
                child: Image.network(
                  '$host/api/v1/file?path=${widget.logoPath}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: FlutterLogo(size: 80)),
                ),
              )
            else
              Opacity(
                opacity: 0.1,
                child: Center(child: FlutterLogo(size: 80)),
              ),
            // Gradiente para mejorar legibilidad
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          onPressed: () => setState(() => _isGridView = !_isGridView),
          tooltip: _isGridView ? 'Vista de Lista' : 'Vista de Cuadrícula',
        ),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
      ],
    );
  }

  Widget _buildFiltersAndStats() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.embedded ? Colors.transparent : Colors.white,
          boxShadow: widget.embedded
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.embedded) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Planos y Documentación',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                        onPressed: () =>
                            setState(() => _isGridView = !_isGridView),
                        tooltip: _isGridView
                            ? 'Vista de Lista'
                            : 'Vista de Cuadrícula',
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadData,
                        tooltip: 'Recargar',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: const InputDecoration(
                        hintText: 'Buscar por nombre o categoría...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildStatBadge(
                  Icons.storage,
                  'Espacio: ${_formatFileSize(_totalSizeBytes)}',
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', 'todos'),
                  _buildFilterChip('Planos', 'plano'),
                  _buildFilterChip('Evidencias', 'evidencia'),
                  _buildFilterChip('Otros', 'otro'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedTipo == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (s) => setState(() => _selectedTipo = value),
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron documentos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otros filtros o sube un nuevo archivo',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<DocumentModel> docs, DateFormat fDate) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildDocumentCard(docs[index], fDate, false),
          childCount: docs.length,
        ),
      ),
    );
  }

  Widget _buildGridView(List<DocumentModel> docs, DateFormat fDate) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 380,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          mainAxisExtent: 155,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildDocumentCard(docs[index], fDate, true),
          childCount: docs.length,
        ),
      ),
    );
  }

  Widget _buildDocumentCard(DocumentModel doc, DateFormat fDate, bool isGrid) {
    if (isGrid) {
      return _buildGridCard(doc);
    }
    return _buildListCard(doc);
  }

  Widget _buildGridCard(DocumentModel doc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Mitad del cuadro: Foto / Imagen (o vista previa de plano)
          Expanded(
            flex: 5,
            child: InkWell(
              onTap: () => _openDocument(doc),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (doc.isImage)
                    CachedNetworkImage(
                      imageUrl: '$host/storage/${doc.filePath}',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade200,
                        highlightColor: Colors.grey.shade100,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(
                          Icons.broken_image_rounded,
                          color: Color(0xFF94A3B8),
                          size: 32,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: doc.isPdf
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFF1F5F9),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            doc.isPdf
                                ? Icons.picture_as_pdf_rounded
                                : Icons.insert_drive_file_rounded,
                            color: doc.isPdf
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF0F172A),
                            size: 36,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            doc.isPdf ? 'PDF / PLANO' : doc.tipo.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: doc.isPdf
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Overlay botón ampliar
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. El otro lado: Botones e Información
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila superior: Tipo y Botones
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getTipoColor(doc.tipo).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          doc.tipo.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: _getTipoColor(doc.tipo),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildIconButton(
                        icon: Icons.open_in_new_rounded,
                        color: const Color(0xFF2563EB),
                        tooltip: 'Abrir / Ver',
                        onTap: () => _openDocument(doc),
                      ),
                      const SizedBox(width: 4),
                      _buildIconButton(
                        icon: Icons.delete_outline_rounded,
                        color: const Color(0xFFDC2626),
                        tooltip: 'Eliminar',
                        onTap: () => _deleteDocument(doc),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Nombre descriptivo
                  Text(
                    doc.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (doc.categoria != null && doc.categoria!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      doc.categoria!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const Spacer(),

                  if (doc.partida != null) ...[
                    Text(
                      'Partida: ${doc.partida!.descripcion}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE31E24),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Tamaño y fecha
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatFileSize(doc.fileSize),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        doc.createdAt != null
                            ? DateFormat('dd MMM').format(doc.createdAt!)
                            : '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(DocumentModel doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview en miniatura generosa (80x80)
            SizedBox(
              width: 80,
              child: InkWell(
                onTap: () => _openDocument(doc),
                child: doc.isImage
                    ? CachedNetworkImage(
                        imageUrl: '$host/storage/${doc.filePath}',
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey.shade100),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(
                            Icons.broken_image_rounded,
                            size: 24,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      )
                    : Container(
                        color: doc.isPdf
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFF1F5F9),
                        child: Center(
                          child: Icon(
                            doc.isPdf
                                ? Icons.picture_as_pdf_rounded
                                : Icons.insert_drive_file_rounded,
                            color: doc.isPdf
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF0F172A),
                            size: 32,
                          ),
                        ),
                      ),
              ),
            ),
            // Detalles e info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _getTipoColor(doc.tipo).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            doc.tipo.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: _getTipoColor(doc.tipo),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            doc.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (doc.categoria != null && doc.categoria!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        doc.categoria!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatFileSize(doc.fileSize),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          doc.createdAt != null
                              ? DateFormat('dd MMM yyyy, HH:mm')
                                  .format(doc.createdAt!)
                              : '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Botones de acción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  _buildIconButton(
                    icon: Icons.open_in_new_rounded,
                    color: const Color(0xFF2563EB),
                    tooltip: 'Abrir / Ver',
                    onTap: () => _openDocument(doc),
                  ),
                  const SizedBox(width: 6),
                  _buildIconButton(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFDC2626),
                    tooltip: 'Eliminar',
                    onTap: () => _deleteDocument(doc),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'plano':
        return const Color(0xFF2563EB); // Azul
      case 'evidencia':
        return const Color(0xFF16A34A); // Verde
      default:
        return const Color(0xFF64748B); // Gris
    }
  }

  void _openDocument(DocumentModel doc) async {
    if (doc.isImage) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: '$host/storage/${doc.filePath}',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final url = Uri.parse('$host/storage/${doc.filePath}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _deleteDocument(DocumentModel doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Documento'),
        content: Text(
          '¿Está seguro de eliminar "${doc.nombre}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _repository.deleteDocument(doc.id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Documento eliminado')));
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }
}
