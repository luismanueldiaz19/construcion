import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'journal_view.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Libro Diario (Asientos)'),
        elevation: 0,
      ),
      body: const JournalView(),
    );
  }
}
