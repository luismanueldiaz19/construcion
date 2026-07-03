import 'package:flutter/material.dart';

class MetricInfoButton extends StatelessWidget {
  final String title;
  final String definition;
  final String formula;
  final String source;

  const MetricInfoButton({
    super.key,
    required this.title,
    required this.definition,
    required this.formula,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline, color: Colors.blueGrey, size: 20),
      tooltip: 'Información sobre $title',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSection('¿Qué significa?', definition),
                  const SizedBox(height: 12),
                  _buildSection('Fórmula de cálculo', formula),
                  const SizedBox(height: 12),
                  _buildSection('Origen de los datos', source),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(content, style: TextStyle(color: Colors.grey[800], height: 1.4)),
      ],
    );
  }
}
