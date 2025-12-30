import '../models/purchase_model.dart';

class PurchaseService {
  // Aqui você integrará com o backend

  // Dados simulados - substituir pela chamada API
  Future<List<Purchase>> getRecentPurchases() async {
    // TODO: Implementar chamada ao backend
    // final response = await http.get(Uri.parse('$baseUrl/purchases'));

    await Future.delayed(const Duration(milliseconds: 500)); // Simula delay de rede

    return [
      Purchase(
        id: '1',
        store: 'Supermercado Extra',
        date: '28/12/2024',
        total: 245.80,
        items: 15,
      ),
      Purchase(
        id: '2',
        store: 'Walmart',
        date: '25/12/2024',
        total: 189.50,
        items: 12,
      ),
      Purchase(
        id: '3',
        store: 'Carrefour',
        date: '22/12/2024',
        total: 312.40,
        items: 20,
      ),
    ];
  }

  Future<Map<String, dynamic>> getMonthlyStats() async {
    // TODO: Implementar chamada ao backend para estatísticas
    await Future.delayed(const Duration(milliseconds: 300));

    return {
      'totalSpent': 747.70,
      'purchaseCount': 3,
      'totalItems': 47,
      'average': 249.23,
    };
  }

  Future<void> scanPurchase() async {
    // TODO: Implementar lógica de scanner
    // Aqui você integrará com o scanner de código de barras/QR code
    // e enviará os dados para o backend
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<Purchase?> getPurchaseById(String id) async {
    // TODO: Implementar busca por ID no backend
    await Future.delayed(const Duration(milliseconds: 300));
    return null;
  }
}
