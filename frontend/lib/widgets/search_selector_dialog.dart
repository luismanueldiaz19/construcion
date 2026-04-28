import 'package:flutter/material.dart';

class SearchSelectorDialog extends StatefulWidget {
  final String title;
  final List<dynamic> items;
  final String Function(dynamic) displayMapper;
  final String? Function(dynamic)? subtitleMapper;

  final VoidCallback? onAdd;

  const SearchSelectorDialog({
    super.key,
    required this.title,
    required this.items,
    required this.displayMapper,
    this.subtitleMapper,
    this.onAdd,
  });

  @override
  State<SearchSelectorDialog> createState() => _SearchSelectorDialogState();
}

class _SearchSelectorDialogState extends State<SearchSelectorDialog> {
  late List<dynamic> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
  }

  void _filter(String query) {
    setState(() {
      _filteredItems = widget.items.where((item) {
        final text = widget.displayMapper(item).toLowerCase();
        final subtitle = widget.subtitleMapper?.call(item)?.toLowerCase() ?? '';
        final code = item['codigo']?.toString().toLowerCase() ?? '';
        return text.contains(query.toLowerCase()) || 
               subtitle.contains(query.toLowerCase()) ||
               code.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seleccionar ${widget.title}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF003366)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron resultados',
                            style: TextStyle(color: Colors.grey[500], fontSize: 16),
                          ),
                          if (widget.onAdd != null) ...[
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: widget.onAdd,
                              icon: const Icon(Icons.add),
                              label: Text('Agregar nuevo ${widget.title}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003366),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: _filteredItems.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              final title = widget.displayMapper(item);
                              final subtitle = widget.subtitleMapper?.call(item);

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                title: Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)) : null,
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: () => Navigator.pop(context, item['id']),
                                hoverColor: Colors.blue[50],
                              );
                            },
                          ),
                        ),
                        if (widget.onAdd != null) ...[
                          const Divider(),
                          TextButton.icon(
                            onPressed: widget.onAdd,
                            icon: const Icon(Icons.add_circle),
                            label: Text('Crear nuevo ${widget.title}'),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
