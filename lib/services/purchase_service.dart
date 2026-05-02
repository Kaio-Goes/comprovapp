import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/nota_fiscal_model.dart';
import '../models/purchase_model.dart';

class PurchaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cache das notas carregadas, indexadas pela chaveAcesso (= Purchase.id)
  final Map<String, NotaFiscal> _notasCache = {};

  String? get _uid => _auth.currentUser?.uid;

  /// Retorna as notas do usuário salvas no Firestore, em ordem decrescente.
  Future<List<NotaFiscal>> _buscarNotas({int limite = 50}) async {
    final uid = _uid;
    if (uid == null) return [];

    final snap = await _db
        .collection('notas_fiscais')
        .doc(uid)
        .collection('notas')
        .orderBy('dataEmissao', descending: true)
        .limit(limite)
        .get();

    return snap.docs.map((d) => NotaFiscal.fromJson(d.data())).toList();
  }

  /// Retorna as compras recentes mapeadas a partir das notas fiscais do Firestore.
  Future<List<Purchase>> getRecentPurchases() async {
    final notas = await _buscarNotas(limite: 20);

    _notasCache.clear();
    for (final nota in notas) {
      _notasCache[nota.chaveAcesso] = nota;
    }

    final fmt = DateFormat('dd/MM/yyyy', 'pt_BR');
    return notas
        .map((nota) => Purchase(
              id: nota.chaveAcesso,
              store: nota.nomeEmitente,
              date: fmt.format(nota.dataEmissao),
              total: nota.valorTotal,
              items: nota.itens.length,
            ))
        .toList();
  }

  /// Calcula estatísticas do mês atual com base nas notas do Firestore.
  Future<Map<String, dynamic>> getMonthlyStats() async {
    final notas = await _buscarNotas();
    final now = DateTime.now();

    final doMes = notas
        .where((n) =>
            n.dataEmissao.year == now.year &&
            n.dataEmissao.month == now.month)
        .toList();

    if (doMes.isEmpty) {
      return {
        'totalSpent': 0.0,
        'purchaseCount': 0,
        'totalItems': 0,
        'average': 0.0,
      };
    }

    final totalSpent = doMes.fold(0.0, (s, n) => s + n.valorTotal);
    final totalItems = doMes.fold(0, (s, n) => s + n.itens.length);

    return {
      'totalSpent': totalSpent,
      'purchaseCount': doMes.length,
      'totalItems': totalItems,
      'average': totalSpent / doMes.length,
    };
  }

  /// Retorna a nota fiscal correspondente a uma compra pelo id (chaveAcesso).
  NotaFiscal? notaParaCompra(String id) => _notasCache[id];

  Future<void> scanPurchase() async {
    // Integração com scanner/câmera a implementar
  }
}
