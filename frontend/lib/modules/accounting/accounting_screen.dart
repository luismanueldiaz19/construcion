import 'package:flutter/material.dart';
import 'catalog_view.dart';
import 'journal_view.dart';
import 'profit_loss_view.dart';

class AccountingScreen extends StatelessWidget {
  const AccountingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contabilidad Integrada'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Catálogo de Cuentas'),
              Tab(text: 'Libro Diario (Asientos)'),
              Tab(text: 'Estado de Resultados'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CatalogView(),
            JournalView(),
            ProfitLossView(),
          ],
        ),
      ),
    );
  }
}
