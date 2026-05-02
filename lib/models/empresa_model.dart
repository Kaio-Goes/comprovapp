import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa uma empresa emitente identificada pelo CNPJ,
/// consolidando todas as compras feitas pelo usuário naquele estabelecimento.
class Empresa {
  final String cnpj;
  final String nome;
  final double totalGasto;
  final int quantidadeNotas;
  final DateTime? ultimaCompra;

  Empresa({
    required this.cnpj,
    required this.nome,
    this.totalGasto = 0.0,
    this.quantidadeNotas = 0,
    this.ultimaCompra,
  });

  String get cnpjFormatado {
    final c = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    if (c.length != 14) return cnpj;
    return '${c.substring(0, 2)}.${c.substring(2, 5)}.${c.substring(5, 8)}/'
        '${c.substring(8, 12)}-${c.substring(12, 14)}';
  }

  factory Empresa.fromFirestore(Map<String, dynamic> data, String cnpj) {
    return Empresa(
      cnpj: cnpj,
      nome: data['nome'] ?? '',
      totalGasto: (data['totalGasto'] ?? 0).toDouble(),
      quantidadeNotas: data['quantidadeNotas'] ?? 0,
      ultimaCompra: data['ultimaCompra'] != null
          ? (data['ultimaCompra'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cnpj': cnpj,
      'nome': nome,
      'totalGasto': totalGasto,
      'quantidadeNotas': quantidadeNotas,
      'ultimaCompra':
          ultimaCompra != null ? Timestamp.fromDate(ultimaCompra!) : null,
    };
  }

  Empresa copyWith({
    String? nome,
    double? totalGasto,
    int? quantidadeNotas,
    DateTime? ultimaCompra,
  }) {
    return Empresa(
      cnpj: cnpj,
      nome: nome ?? this.nome,
      totalGasto: totalGasto ?? this.totalGasto,
      quantidadeNotas: quantidadeNotas ?? this.quantidadeNotas,
      ultimaCompra: ultimaCompra ?? this.ultimaCompra,
    );
  }
}
