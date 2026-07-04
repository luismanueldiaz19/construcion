import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'catalog_view.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Catálogo de Cuentas'),
        elevation: 0,
      ),
      body: const CatalogView(),
    );
  }
}
