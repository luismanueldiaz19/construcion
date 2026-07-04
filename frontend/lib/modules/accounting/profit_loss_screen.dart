import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'profit_loss_view.dart';

class ProfitLossScreen extends StatelessWidget {
  const ProfitLossScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Estado de Resultados'),
        elevation: 0,
      ),
      body: const ProfitLossView(),
    );
  }
}
