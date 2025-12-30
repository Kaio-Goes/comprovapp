import 'package:flutter/material.dart';
import '../../models/purchase_model.dart';
import '../../services/purchase_service.dart';
import '../../components/dashboard_header.dart';
import '../../components/stat_card.dart';
import '../../components/purchase_card.dart';
import '../../components/scan_button.dart';
import '../notas/buscar_notas_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final PurchaseService _purchaseService = PurchaseService();

  int _selectedIndex = 0;
  List<Purchase> _recentPurchases = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final purchases = await _purchaseService.getRecentPurchases();
      final stats = await _purchaseService.getMonthlyStats();

      setState(() {
        _recentPurchases = purchases;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Erro ao carregar dados');
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navega para a tela de buscar notas
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BuscarNotasPage()),
      );
    }
  }

  Future<void> _scanPurchase() async {
    try {
      await _purchaseService.scanPurchase();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Escanear Compra'),
          content:
              const Text('Funcionalidade de scanner será implementada em breve!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadData(); // Recarrega dados após escanear
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorDialog('Erro ao escanear compra');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onPurchaseTap(Purchase purchase) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Detalhes de ${purchase.store}')),
    );
  }

  void _onNotificationTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificações')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: DashboardHeader(
                onNotificationTap: _onNotificationTap,
              ),
            ),

            // Estatísticas
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo do Mês',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Total Gasto',
                            value:
                                'R\$ ${_stats['totalSpent']?.toStringAsFixed(2) ?? '0.00'}',
                            icon: Icons.shopping_cart,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Compras',
                            value: '${_stats['purchaseCount'] ?? 0}',
                            icon: Icons.receipt_long,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Itens',
                            value: '${_stats['totalItems'] ?? 0}',
                            icon: Icons.inventory_2,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Média',
                            value:
                                'R\$ ${_stats['average']?.toStringAsFixed(2) ?? '0.00'}',
                            icon: Icons.trending_up,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Botão de Escanear
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ScanButton(onPressed: _scanPurchase),
              ),
            ),

            // Compras Recentes
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Compras Recentes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Ver todas'),
                    ),
                  ],
                ),
              ),
            ),

            // Lista de Compras
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final purchase = _recentPurchases[index];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: PurchaseCard(
                      purchase: purchase,
                      onTap: () => _onPurchaseTap(purchase),
                    ),
                  );
                },
                childCount: _recentPurchases.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Compras',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estatísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanPurchase,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.qr_code_scanner),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
