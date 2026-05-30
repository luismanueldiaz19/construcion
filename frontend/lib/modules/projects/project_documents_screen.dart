import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/project_service.dart';
import '../../models/partida.dart';
import '../../core/models/document_model.dart';
import '../../core/repositories/document_repository.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
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
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stfContext, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cabecera Premium
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF003366),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_upload_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Subir Documento',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Planos, evidencias y anexos del proyecto',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Área de Selección de Archivo
                        InkWell(
                          onTap: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                            );
                            if (result != null) {
                              if (result.files.first.size > 15 * 1024 * 1024) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'El archivo supera los 15MB',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }
                              setDialogState(
                                () => pickedFile = result.files.first,
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: pickedFile == null
                                    ? Colors.blue.withOpacity(0.3)
                                    : Colors.green.withOpacity(0.5),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              color: pickedFile == null
                                  ? Colors.blue.withOpacity(0.02)
                                  : Colors.green.withOpacity(0.05),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  pickedFile == null
                                      ? Icons.file_present_rounded
                                      : Icons.check_circle,
                                  size: 48,
                                  color: pickedFile == null
                                      ? Colors.blue.shade300
                                      : Colors.green,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  pickedFile == null
                                      ? 'Seleccionar Archivo'
                                      : pickedFile!.name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: pickedFile == null
                                        ? Colors.blue.shade700
                                        : Colors.green.shade700,
                                  ),
                                ),
                                if (pickedFile == null)
                                  const Text(
                                    'PDF, JPG o PNG (Máx. 15MB)',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          'Detalles del Documento',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre descriptivo *',
                            prefixIcon: const Icon(Icons.title),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedTipo,
                                decoration: InputDecoration(
                                  labelText: 'Tipo',
                                  prefixIcon: const Icon(Icons.category),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'plano',
                                    child: Text('Plano'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'evidencia',
                                    child: Text('Evidencia'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'otro',
                                    child: Text('Otro'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setDialogState(() => selectedTipo = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: categoriaController,
                          decoration: InputDecoration(
                            labelText: 'Área / Categoría',
                            hintText: 'Ej: Estructura, Terminación...',
                            prefixIcon: const Icon(Icons.layers),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<int>(
                          value: selectedPartidaId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Vincular a Partida (Opcional)',
                            prefixIcon: const Icon(Icons.link),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Ninguna'),
                            ),
                            ..._partidas.map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  p.descripcion,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setDialogState(() => selectedPartidaId = v),
                        ),

                        const SizedBox(height: 32),

                        // Botón de Acción
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: isUploading
                                ? null
                                : () async {
                                    if (nombreController.text.isEmpty ||
                                        pickedFile == null) {
                                      ScaffoldMessenger.of(
                                        stfContext,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Nombre y archivo son obligatorios',
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    setDialogState(() => isUploading = true);
                                    try {
                                      await _repository.uploadDocument(
                                        proyectoId: widget.proyectoId,
                                        nombre: nombreController.text,
                                        tipo: selectedTipo,
                                        categoria:
                                            categoriaController.text.isNotEmpty
                                            ? categoriaController.text
                                            : null,
                                        partidaId: selectedPartidaId,
                                        filePath: pickedFile!.path!,
                                      );
                                      if (mounted) {
                                        Navigator.pop(dialogContext);
                                        _loadData();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Documento subido con éxito',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setDialogState(() => isUploading = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          stfContext,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA000),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isUploading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'SUBIR DOCUMENTO',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fDate = DateFormat('dd/MM/yyyy HH:mm');
    final filtered = _filteredDocuments;

    return Scaffold(
      backgroundColor: widget.embedded ? Colors.transparent : AppTheme.backgroundColor,
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
        backgroundColor: AppTheme.accentColor,
        icon: const Icon(Icons.upload_file, color: Colors.black),
        label: const Text(
          'Subir Archivo',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                  '$host/storage/${widget.logoPath}',
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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
                    color: Colors.black.withOpacity(0.05),
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
                        onPressed: () => setState(() => _isGridView = !_isGridView),
                        tooltip: _isGridView ? 'Vista de Lista' : 'Vista de Cuadrícula',
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
        color: color.withOpacity(0.1),
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
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
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
          maxCrossAxisExtent: 350,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          mainAxisExtent: 180,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildDocumentCard(docs[index], fDate, true),
          childCount: docs.length,
        ),
      ),
    );
  }

  Widget _buildDocumentCard(DocumentModel doc, DateFormat fDate, bool isGrid) {
    Color iconColor = Colors.blue;
    IconData iconData = Icons.insert_drive_file;

    if (doc.isPdf) {
      iconColor = Colors.redAccent;
      iconData = Icons.picture_as_pdf;
    } else if (doc.isImage) {
      iconColor = Colors.green;
      iconData = Icons.image;
    }

    final card = Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: isGrid
            ? _buildGridCardContent(doc, fDate, iconData, iconColor)
            : _buildListCardContent(doc, fDate, iconData, iconColor),
      ),
    );

    return card;
  }

  Widget _buildListCardContent(
    DocumentModel doc,
    DateFormat fDate,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        _buildImagePreview(doc, icon, color, size: 50, isGrid: false),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doc.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (doc.categoria != null && doc.categoria!.isNotEmpty)
                Text(
                  doc.categoria!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      doc.tipo.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatFileSize(doc.fileSize),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              if (doc.partida != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Partida: ${doc.partida!.descripcion}',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        _buildActions(doc),
      ],
    );
  }

  Widget _buildGridCardContent(
    DocumentModel doc,
    DateFormat fDate,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildImagePreview(doc, icon, color, size: 45, isGrid: true),
            _buildActions(doc),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          doc.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (doc.categoria != null && doc.categoria!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              doc.categoria!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatFileSize(doc.fileSize),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            Text(
              doc.createdAt != null
                  ? DateFormat('dd MMM').format(doc.createdAt!)
                  : '',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview(
    DocumentModel doc,
    IconData icon,
    Color color, {
    required double size,
    required bool isGrid,
  }) {
    if (doc.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(isGrid ? 8 : 12),
        child: CachedNetworkImage(
          imageUrl: '$host/storage/${doc.filePath}',
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(width: size, height: size, color: Colors.white),
          ),
          errorWidget: (context, url, error) => Container(
            width: size,
            height: size,
            color: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: size * 0.6),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isGrid ? 8 : 12),
      ),
      child: Icon(icon, color: color, size: size * 0.6),
    );
  }

  Widget _buildActions(DocumentModel doc) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.open_in_new, color: Colors.blue, size: 18),
          onPressed: () async {
            final url = Uri.parse('$host/storage/${doc.filePath}');
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.redAccent,
            size: 18,
          ),
          onPressed: () => _deleteDocument(doc),
        ),
      ],
    );
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
