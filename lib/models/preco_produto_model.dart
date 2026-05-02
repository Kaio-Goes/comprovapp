import 'package:cloud_firestore/cloud_firestore.dart';

class HistoricoPreco {
  final double valor;
  final DateTime data;
  final String chaveNota;

  HistoricoPreco({
    required this.valor,
    required this.data,
    required this.chaveNota,
  });

  factory HistoricoPreco.fromMap(Map<String, dynamic> m) => HistoricoPreco(
        valor: (m['valor'] ?? 0).toDouble(),
        data: m['data'] is Timestamp
            ? (m['data'] as Timestamp).toDate()
            : DateTime.now(),
        chaveNota: m['chaveNota'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'valor': valor,
        'data': Timestamp.fromDate(data),
        'chaveNota': chaveNota,
      };
}

/// Rastreia o preço de um produto em uma loja específica (CNPJ + código).
///
/// ID do documento: "{cnpj}_{codigoProduto}"
class PrecoProduto {
  /// Identificador único: "{cnpj}_{codigo}"
  final String id;
  final String codigo;
  final String descricao;
  final String unidade;
  final String cnpj;
  final String nomeEmpresa;
  final double valorAtual;
  final double? valorAnterior;
  final DateTime dataAtualizado;
  final DateTime? dataAnterior;
  final List<HistoricoPreco> historico;

  PrecoProduto({
    required this.id,
    required this.codigo,
    required this.descricao,
    required this.unidade,
    required this.cnpj,
    required this.nomeEmpresa,
    required this.valorAtual,
    this.valorAnterior,
    required this.dataAtualizado,
    this.dataAnterior,
    this.historico = const [],
  });

  /// Diferença em reais: positivo = ficou mais caro, negativo = mais barato.
  double? get variacao =>
      valorAnterior != null ? valorAtual - valorAnterior! : null;

  /// Variação percentual.
  double? get variacaoPercent =>
      valorAnterior != null && valorAnterior! > 0
          ? ((valorAtual - valorAnterior!) / valorAnterior!) * 100
          : null;

  bool get ficouMaisCaro => (variacao ?? 0) > 0.005;
  bool get ficouMaisBarato => (variacao ?? 0) < -0.005;
  bool get mesmoPreco => variacao != null && variacao!.abs() <= 0.005;
  bool get semHistorico => valorAnterior == null;

  factory PrecoProduto.fromFirestore(Map<String, dynamic> data, String id) {
    return PrecoProduto(
      id: id,
      codigo: data['codigo'] ?? '',
      descricao: data['descricao'] ?? '',
      unidade: data['unidade'] ?? 'UN',
      cnpj: data['cnpj'] ?? '',
      nomeEmpresa: data['nomeEmpresa'] ?? '',
      valorAtual: (data['valorAtual'] ?? 0).toDouble(),
      valorAnterior: data['valorAnterior'] != null
          ? (data['valorAnterior'] as num).toDouble()
          : null,
      dataAtualizado: data['dataAtualizado'] is Timestamp
          ? (data['dataAtualizado'] as Timestamp).toDate()
          : DateTime.now(),
      dataAnterior: data['dataAnterior'] is Timestamp
          ? (data['dataAnterior'] as Timestamp).toDate()
          : null,
      historico: (data['historico'] as List?)
              ?.map((h) => HistoricoPreco.fromMap(h as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'codigo': codigo,
        'descricao': descricao,
        'unidade': unidade,
        'cnpj': cnpj,
        'nomeEmpresa': nomeEmpresa,
        'valorAtual': valorAtual,
        'valorAnterior': valorAnterior,
        'dataAtualizado': Timestamp.fromDate(dataAtualizado),
        'dataAnterior':
            dataAnterior != null ? Timestamp.fromDate(dataAnterior!) : null,
        'historico': historico.map((h) => h.toMap()).toList(),
      };
}
