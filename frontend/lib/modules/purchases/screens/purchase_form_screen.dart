import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/purchase_provider.dart';
import '../widgets/purchase_header.dart';
import '../widgets/purchase_items_table.dart';
import '../widgets/purchase_details_card.dart';
import '../widgets/purchase_bottom_bar.dart';

class PurchaseFormScreen extends StatelessWidget {
  const PurchaseFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PurchaseProvider(),
      child: const _PurchaseFormScreenContent(),
    );
  }
}

class _PurchaseFormScreenContent extends StatefulWidget {
  const _PurchaseFormScreenContent();

  @override
  State<_PurchaseFormScreenContent> createState() => _PurchaseFormScreenContentState();
}

class _PurchaseFormScreenContentState extends State<_PurchaseFormScreenContent> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PurchaseProvider>(context);

    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(provider.error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: provider.loadData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 950;

          return Stack(
            children: [
              Column(
                children: [
                  const PurchaseHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: isLargeScreen
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const PurchaseItemsTable(),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 32),
                                // Right Column
                                const SizedBox(
                                  width: 400,
                                  child: PurchaseDetailsCard(),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const PurchaseDetailsCard(),
                                const SizedBox(height: 24),
                                const PurchaseItemsTable(),
                                const SizedBox(height: 24),
                              ],
                            ),
                    ),
                  ),
                  const PurchaseBottomBar(),
                ],
              ),
              if (provider.isSubmitting)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Registrando Compra...',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
