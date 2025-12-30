class NotaFiscal {
  final String chaveAcesso;
  final String numero;
  final String serie;
  final DateTime dataEmissao;
  final String cnpjEmitente;
  final String nomeEmitente;
  final String cpfDestinatario;
  final String nomeDestinatario;
  final double valorTotal;
  final List<ItemNotaFiscal> itens;
  final String? protocolo;
  final String situacao;

  NotaFiscal({
    required this.chaveAcesso,
    required this.numero,
    required this.serie,
    required this.dataEmissao,
    required this.cnpjEmitente,
    required this.nomeEmitente,
    required this.cpfDestinatario,
    required this.nomeDestinatario,
    required this.valorTotal,
    required this.itens,
    this.protocolo,
    required this.situacao,
  });

  factory NotaFiscal.fromJson(Map<String, dynamic> json) {
    return NotaFiscal(
      chaveAcesso: json['chaveAcesso'] ?? '',
      numero: json['numero'] ?? '',
      serie: json['serie'] ?? '',
      dataEmissao: json['dataEmissao'] != null
          ? DateTime.parse(json['dataEmissao'])
          : DateTime.now(),
      cnpjEmitente: json['cnpjEmitente'] ?? '',
      nomeEmitente: json['nomeEmitente'] ?? '',
      cpfDestinatario: json['cpfDestinatario'] ?? '',
      nomeDestinatario: json['nomeDestinatario'] ?? '',
      valorTotal: (json['valorTotal'] ?? 0).toDouble(),
      itens: (json['itens'] as List?)
              ?.map((item) => ItemNotaFiscal.fromJson(item))
              .toList() ??
          [],
      protocolo: json['protocolo'],
      situacao: json['situacao'] ?? 'Autorizada',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chaveAcesso': chaveAcesso,
      'numero': numero,
      'serie': serie,
      'dataEmissao': dataEmissao.toIso8601String(),
      'cnpjEmitente': cnpjEmitente,
      'nomeEmitente': nomeEmitente,
      'cpfDestinatario': cpfDestinatario,
      'nomeDestinatario': nomeDestinatario,
      'valorTotal': valorTotal,
      'itens': itens.map((item) => item.toJson()).toList(),
      'protocolo': protocolo,
      'situacao': situacao,
    };
  }
}

class ItemNotaFiscal {
  final String codigo;
  final String descricao;
  final int quantidade;
  final double valorUnitario;
  final double valorTotal;
  final String? unidade;

  ItemNotaFiscal({
    required this.codigo,
    required this.descricao,
    required this.quantidade,
    required this.valorUnitario,
    required this.valorTotal,
    this.unidade,
  });

  factory ItemNotaFiscal.fromJson(Map<String, dynamic> json) {
    return ItemNotaFiscal(
      codigo: json['codigo'] ?? '',
      descricao: json['descricao'] ?? '',
      quantidade: json['quantidade'] ?? 0,
      valorUnitario: (json['valorUnitario'] ?? 0).toDouble(),
      valorTotal: (json['valorTotal'] ?? 0).toDouble(),
      unidade: json['unidade'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'descricao': descricao,
      'quantidade': quantidade,
      'valorUnitario': valorUnitario,
      'valorTotal': valorTotal,
      'unidade': unidade,
    };
  }
}
