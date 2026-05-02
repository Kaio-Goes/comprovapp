import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xml/xml.dart';
import '../models/empresa_model.dart';
import '../models/nota_fiscal_model.dart';
import '../models/preco_produto_model.dart';
import '../models/usuario_model.dart';
import '../config/sefaz_config.dart';

/// Serviço de consulta de Notas Fiscais na SEFAZ usando certificado A1.
///
/// O certificado A1 (.pfx / .p12) é carregado via [SefazConfig] e
/// utilizado para autenticação mTLS nas chamadas ao webservice da SEFAZ.
///
/// Endpoints por ambiente:
///   - Homologação NF-e:  https://hom.nfe.fazenda.gov.br/nfeservicos/services/...
///   - Produção NF-e:     https://www.nfe.fazenda.gov.br/nfeservicos/services/...
///   - NFC-e varia por estado (SVRS, SVAN, etc.)
class NotaFiscalService {
  final SefazConfig config;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  NotaFiscalService({required this.config});

  /// Busca todas as notas fiscais do destinatário identificado pelo CPF.
  ///
  /// Em produção, usa a API DistDFeInt (Distribuição de DF-e) da SEFAZ.
  Future<List<NotaFiscal>> buscarNotasDoUsuario(
    Usuario usuario, {
    DateTime? dataInicio,
    DateTime? dataFim,
    int ultNSU = 0,
  }) async {
    try {
      final cpf = usuario.cpf.replaceAll(RegExp(r'[^\d]'), '');
      if (cpf.length != 11) throw Exception('CPF inválido');

      if (config.modoSimulacao) {
        await Future.delayed(const Duration(seconds: 2));
        return _gerarNotasSimuladas(cpf);
      }

      final xmlBody = _montarXmlDistDFe(cpf: cpf, ultNSU: ultNSU);
      final response = await _chamarWebservice(
        endpoint: config.endpointDistDFe,
        xmlBody: xmlBody,
      );

      final notas = _parsearRespostaDistDFe(response, cpf);
      await salvarNotasFirestore(uid: usuario.uid, notas: notas);
      return notas;
    } catch (e) {
      throw Exception('Erro ao buscar notas fiscais: $e');
    }
  }

  /// Salva as notas no Firestore e consolida dados por empresa (CNPJ).
  ///
  /// Estrutura:
  ///   `notas_fiscais/{uid}/{chaveAcesso}` — nota completa
  ///   `empresas/{cnpj}` — consolidado da empresa
  Future<void> salvarNotasFirestore({
    required String uid,
    required List<NotaFiscal> notas,
  }) async {
    final batch = _firestore.batch();

    for (final nota in notas) {
      // Salva a nota vinculada ao usuário
      final notaRef = _firestore
          .collection('notas_fiscais')
          .doc(uid)
          .collection('notas')
          .doc(nota.chaveAcesso);
      batch.set(notaRef, nota.toJson(), SetOptions(merge: true));

      // Atualiza consolidado da empresa
      final cnpjKey = nota.cnpjEmitente.replaceAll(RegExp(r'[^\d]'), '');
      final empresaRef = _firestore.collection('empresas').doc(cnpjKey);
      batch.set(
        empresaRef,
        {
          'cnpj': cnpjKey,
          'nome': nota.nomeEmitente,
          'ultimaCompra': Timestamp.fromDate(nota.dataEmissao),
          'totalGasto': FieldValue.increment(nota.valorTotal),
          'quantidadeNotas': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();

    // Rastreia histórico de preços por produto × loja
    for (final nota in notas) {
      await salvarPrecosProdutos(nota);
    }
  }

  /// Salva / atualiza o histórico de preço de cada item da nota.
  ///
  /// Chave do documento: "{cnpj}_{codigoProduto}".
  /// Idempotente: se a nota já foi processada (chaveAcesso no histórico), ignora.
  Future<void> salvarPrecosProdutos(NotaFiscal nota) async {
    if (nota.itens.isEmpty) return;
    final cnpjLimpo = nota.cnpjEmitente.replaceAll(RegExp(r'[^\d]'), '');
    final now = DateTime.now();

    // Lê os documentos existentes em paralelo
    final ids = nota.itens
        .map((i) => '${cnpjLimpo}_${i.codigo}')
        .toList();
    final snaps = await Future.wait(
      ids.map((id) => _firestore.collection('precos_produtos').doc(id).get()),
    );

    final batch = _firestore.batch();
    bool temAlteracao = false;

    for (int i = 0; i < nota.itens.length; i++) {
      final item = nota.itens[i];
      if (item.codigo.isEmpty || item.valorUnitario <= 0) continue;

      final id = ids[i];
      final ref = _firestore.collection('precos_produtos').doc(id);
      final snap = snaps[i];

      double? valorAnterior;
      DateTime? dataAnterior;
      List<Map<String, dynamic>> historico = [];

      if (snap.exists) {
        final data = snap.data()!;
        final hist = (data['historico'] as List?) ?? [];
        // Idempotência: pula se a nota já foi processada
        final jaProcessado = hist.any(
          (h) => (h as Map)['chaveNota'] == nota.chaveAcesso,
        );
        if (jaProcessado) continue;

        historico = hist.cast<Map<String, dynamic>>().toList();

        // Guarda o preço anterior
        final prev = (data['valorAtual'] as num?)?.toDouble();
        if (prev != null) {
          valorAnterior = prev;
          final prevData = data['dataAtualizado'];
          dataAnterior =
              prevData is Timestamp ? prevData.toDate() : null;
        }
      }

      historico.add({
        'valor': item.valorUnitario,
        'data': Timestamp.fromDate(now),
        'chaveNota': nota.chaveAcesso,
      });
      // Mantém no máximo 24 entradas
      if (historico.length > 24) {
        historico = historico.sublist(historico.length - 24);
      }

      batch.set(ref, {
        'codigo': item.codigo,
        'descricao': item.descricao,
        'unidade': item.unidade ?? 'UN',
        'cnpj': cnpjLimpo,
        'nomeEmpresa': nota.nomeEmitente,
        'valorAtual': item.valorUnitario,
        'valorAnterior': valorAnterior,
        'dataAtualizado': Timestamp.fromDate(now),
        'dataAnterior':
            dataAnterior != null ? Timestamp.fromDate(dataAnterior) : null,
        'historico': historico,
      });
      temAlteracao = true;
    }

    if (temAlteracao) await batch.commit();
  }

  /// Retorna variações de preço para cada item de uma nota.
  ///
  /// Útil para exibir "ficou mais caro / mais barato" na tela de detalhes.
  Future<Map<String, PrecoProduto>> buscarVariacoesParaNota(
      NotaFiscal nota) async {
    final cnpjLimpo = nota.cnpjEmitente.replaceAll(RegExp(r'[^\d]'), '');
    final futures = nota.itens
        .map((i) => _firestore
            .collection('precos_produtos')
            .doc('${cnpjLimpo}_${i.codigo}')
            .get())
        .toList();

    final snaps = await Future.wait(futures);
    final result = <String, PrecoProduto>{};
    for (int i = 0; i < nota.itens.length; i++) {
      final snap = snaps[i];
      if (snap.exists) {
        result[nota.itens[i].codigo] =
            PrecoProduto.fromFirestore(snap.data()!, snap.id);
      }
    }
    return result;
  }

  /// Busca preços do mesmo produto em diferentes lojas (base compartilhada).
  Future<List<PrecoProduto>> buscarPrecosPorCodigo(String codigo) async {
    if (codigo.isEmpty) return [];
    try {
      final snap = await _firestore
          .collection('precos_produtos')
          .where('codigo', isEqualTo: codigo)
          .get();
      final lista = snap.docs
          .map((d) => PrecoProduto.fromFirestore(d.data(), d.id))
          .toList()
        ..sort((a, b) => a.valorAtual.compareTo(b.valorAtual));
      return lista;
    } catch (_) {
      return [];
    }
  }

  /// Busca notas já salvas no Firestore para um usuário.
  Future<List<NotaFiscal>> buscarNotasSalvas(String uid) async {
    final snap = await _firestore
        .collection('notas_fiscais')
        .doc(uid)
        .collection('notas')
        .orderBy('dataEmissao', descending: true)
        .get();
    return snap.docs
        .map((d) => NotaFiscal.fromJson(d.data()))
        .toList();
  }

  /// Lista todas as empresas com compras do usuário (via notas salvas).
  Future<List<Empresa>> listarEmpresasPorUsuario(String uid) async {
    final notas = await buscarNotasSalvas(uid);
    final Map<String, Empresa> mapa = {};
    for (final nota in notas) {
      final cnpj = nota.cnpjEmitente.replaceAll(RegExp(r'[^\d]'), '');
      if (mapa.containsKey(cnpj)) {
        final e = mapa[cnpj]!;
        mapa[cnpj] = e.copyWith(
          totalGasto: e.totalGasto + nota.valorTotal,
          quantidadeNotas: e.quantidadeNotas + 1,
          ultimaCompra: nota.dataEmissao.isAfter(e.ultimaCompra ?? DateTime(0))
              ? nota.dataEmissao
              : e.ultimaCompra,
        );
      } else {
        mapa[cnpj] = Empresa(
          cnpj: cnpj,
          nome: nota.nomeEmitente,
          totalGasto: nota.valorTotal,
          quantidadeNotas: 1,
          ultimaCompra: nota.dataEmissao,
        );
      }
    }
    return mapa.values.toList()
      ..sort((a, b) => (b.ultimaCompra ?? DateTime(0))
          .compareTo(a.ultimaCompra ?? DateTime(0)));
  }

  /// Consulta uma NF-e específica pela chave de acesso (44 dígitos).
  Future<NotaFiscal?> consultarNotaPorChave(
    String chaveAcesso,
    Usuario usuario,
  ) async {
    try {
      final chave = chaveAcesso.replaceAll(RegExp(r'\s'), '');
      if (chave.length != 44) throw Exception('Chave de acesso inválida');

      if (config.modoSimulacao) {
        await Future.delayed(const Duration(seconds: 1));
        final notas = _gerarNotasSimuladas(usuario.cpf);
        return notas.isNotEmpty ? notas.first : null;
      }

      final xmlBody = _montarXmlConsultaChave(chave);
      final response = await _chamarWebservice(
        endpoint: config.endpointConsultaProtocolo,
        xmlBody: xmlBody,
      );

      return _parsearNota(response, usuario.cpf);
    } catch (e) {
      throw Exception('Erro ao consultar nota fiscal: $e');
    }
  }

  // ── XML ──────────────────────────────────────────────────────────────────

  String _montarXmlDistDFe({required String cpf, required int ultNSU}) {
    final cUF = config.codigoUF;
    return '''<?xml version="1.0" encoding="UTF-8"?>
<soap12:Envelope
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
  xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <nfeDistDFeInteresse xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NFeDistribuicaoDFe">
      <nfeDadosMsg>
        <distDFeInt versao="1.01" xmlns="http://www.portalfiscal.inf.br/nfe">
          <tpAmb>${config.tipoAmbiente}</tpAmb>
          <cUFAutor>$cUF</cUFAutor>
          <CNPJ></CNPJ>
          <CPF>$cpf</CPF>
          <distNSU>
            <ultNSU>${ultNSU.toString().padLeft(15, '0')}</ultNSU>
          </distNSU>
        </distDFeInt>
      </nfeDadosMsg>
    </nfeDistDFeInteresse>
  </soap12:Body>
</soap12:Envelope>''';
  }

  String _montarXmlConsultaChave(String chave) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<soap12:Envelope
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
  xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <nfeConsultaNF xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsulta4">
      <nfeDadosMsg>
        <consSitNFe versao="4.01" xmlns="http://www.portalfiscal.inf.br/nfe">
          <tpAmb>${config.tipoAmbiente}</tpAmb>
          <xServ>CONSULTAR</xServ>
          <chNFe>$chave</chNFe>
        </consSitNFe>
      </nfeDadosMsg>
    </nfeConsultaNF>
  </soap12:Body>
</soap12:Envelope>''';
  }

  // ── HTTP com mTLS (certificado A1) ───────────────────────────────────────

  Future<String> _chamarWebservice({
    required String endpoint,
    required String xmlBody,
  }) async {
    final certBytes = await config.carregarCertificado();
    final certSenha = config.senhaCertificado;

    final context = SecurityContext(withTrustedRoots: true);
    context.useCertificateChainBytes(certBytes, password: certSenha);
    context.usePrivateKeyBytes(certBytes, password: certSenha);

    final client = HttpClient(context: context)
      ..badCertificateCallback = (cert, host, port) => false;

    try {
      final uri = Uri.parse(endpoint);
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/soap+xml; charset=utf-8');
      request.headers.set('Content-Length', utf8.encode(xmlBody).length.toString());
      request.write(xmlBody);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception('SEFAZ retornou HTTP ${response.statusCode}: $body');
      }

      return body;
    } finally {
      client.close();
    }
  }

  // ── Parse XML ────────────────────────────────────────────────────────────

  List<NotaFiscal> _parsearRespostaDistDFe(String xml, String cpf) {
    final notas = <NotaFiscal>[];
    try {
      final document = XmlDocument.parse(xml);
      final docZips = document.findAllElements('docZip');
      for (final docZip in docZips) {
        final schema = docZip.getAttribute('schema') ?? '';
        if (!schema.startsWith('procNFe') && !schema.startsWith('nfeProc')) {
          continue;
        }
        // O conteúdo é base64 + gzip; parse básico do XML interno
        final innerXml = utf8.decode(base64.decode(docZip.innerText.trim()));
        final nota = _parsearNota(innerXml, cpf);
        if (nota != null) notas.add(nota);
      }
    } catch (_) {
      // retorna lista parcial em caso de erro de parse
    }
    return notas;
  }

  NotaFiscal? _parsearNota(String xml, String cpf) {
    try {
      final doc = XmlDocument.parse(xml);
      final infNFe = doc.findAllElements('infNFe').firstOrNull;
      if (infNFe == null) return null;

      String texto(String tag) =>
          infNFe.findElements(tag).firstOrNull?.innerText ?? '';

      final chave = infNFe.getAttribute('Id')?.replaceFirst('NFe', '') ?? '';
      final numero = texto('nNF');
      final serie = texto('serie');
      final dataEmissao = DateTime.tryParse(texto('dhEmi')) ?? DateTime.now();
      final cnpjEmit = texto('CNPJ');
      final nomeEmit = texto('xNome');
      final valorTotal = double.tryParse(texto('vNF')) ?? 0.0;
      final situacao = 'Autorizada';

      final itens = infNFe.findAllElements('det').map((det) {
        final prod = det.findElements('prod').firstOrNull;
        String campo(String t) =>
            prod?.findElements(t).firstOrNull?.innerText ?? '';
        return ItemNotaFiscal(
          codigo: campo('cProd'),
          descricao: campo('xProd'),
          quantidade: int.tryParse(campo('qCom').split('.').first) ?? 1,
          valorUnitario: double.tryParse(campo('vUnCom')) ?? 0.0,
          valorTotal: double.tryParse(campo('vProd')) ?? 0.0,
          unidade: campo('uCom'),
        );
      }).toList();

      return NotaFiscal(
        chaveAcesso: chave,
        numero: numero,
        serie: serie,
        dataEmissao: dataEmissao,
        cnpjEmitente: cnpjEmit,
        nomeEmitente: nomeEmit,
        cpfDestinatario: cpf,
        nomeDestinatario: 'Consumidor',
        valorTotal: valorTotal,
        itens: itens,
        situacao: situacao,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Simulação ────────────────────────────────────────────────────────────

  List<NotaFiscal> _gerarNotasSimuladas(String cpf) {
    return [
      NotaFiscal(
        chaveAcesso: '35231012345678000190650010000123451234567890',
        numero: '12345',
        serie: '001',
        dataEmissao: DateTime.now().subtract(const Duration(days: 2)),
        cnpjEmitente: '12.345.678/0001-90',
        nomeEmitente: 'Supermercado Exemplo LTDA',
        cpfDestinatario: cpf,
        nomeDestinatario: 'Consumidor',
        valorTotal: 245.80,
        protocolo: '135230012345678',
        situacao: 'Autorizada',
        itens: [
          ItemNotaFiscal(
            codigo: '7891234567890',
            descricao: 'Arroz Tipo 1 5kg',
            quantidade: 2,
            valorUnitario: 25.90,
            valorTotal: 51.80,
            unidade: 'UN',
          ),
          ItemNotaFiscal(
            codigo: '7891234567891',
            descricao: 'Feijão Preto 1kg',
            quantidade: 3,
            valorUnitario: 8.50,
            valorTotal: 25.50,
            unidade: 'UN',
          ),
          ItemNotaFiscal(
            codigo: '7891234567892',
            descricao: 'Óleo de Soja 900ml',
            quantidade: 4,
            valorUnitario: 7.90,
            valorTotal: 31.60,
            unidade: 'UN',
          ),
        ],
      ),
      NotaFiscal(
        chaveAcesso: '35231012345678000190650010000123461234567891',
        numero: '12346',
        serie: '001',
        dataEmissao: DateTime.now().subtract(const Duration(days: 5)),
        cnpjEmitente: '98.765.432/0001-10',
        nomeEmitente: 'Farmácia Saúde e Vida',
        cpfDestinatario: cpf,
        nomeDestinatario: 'Consumidor',
        valorTotal: 89.90,
        protocolo: '135230012345679',
        situacao: 'Autorizada',
        itens: [
          ItemNotaFiscal(
            codigo: '7891234567893',
            descricao: 'Dipirona 500mg 20cp',
            quantidade: 1,
            valorUnitario: 12.90,
            valorTotal: 12.90,
            unidade: 'CX',
          ),
          ItemNotaFiscal(
            codigo: '7891234567894',
            descricao: 'Vitamina C 1g 10cp',
            quantidade: 2,
            valorUnitario: 38.50,
            valorTotal: 77.00,
            unidade: 'CX',
          ),
        ],
      ),
      NotaFiscal(
        chaveAcesso: '35231012345678000190650010000123471234567892',
        numero: '12347',
        serie: '001',
        dataEmissao: DateTime.now().subtract(const Duration(days: 10)),
        cnpjEmitente: '11.222.333/0001-44',
        nomeEmitente: 'Posto de Combustível Estrela',
        cpfDestinatario: cpf,
        nomeDestinatario: 'Consumidor',
        valorTotal: 150.00,
        protocolo: '135230012345680',
        situacao: 'Autorizada',
        itens: [
          ItemNotaFiscal(
            codigo: '0001',
            descricao: 'Gasolina Comum',
            quantidade: 30,
            valorUnitario: 5.00,
            valorTotal: 150.00,
            unidade: 'LT',
          ),
        ],
      ),
    ];
  }

  // ── Utilitários ──────────────────────────────────────────────────────────

  bool validarCPF(String cpf) {
    final c = cpf.replaceAll(RegExp(r'[^\d]'), '');
    if (c.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(c)) return false;

    final d = c.split('').map(int.parse).toList();
    int sum = 0;
    for (int i = 0; i < 9; i++) { sum += d[i] * (10 - i); }
    int f1 = 11 - (sum % 11);
    if (f1 >= 10) f1 = 0;
    if (d[9] != f1) return false;

    sum = 0;
    for (int i = 0; i < 10; i++) { sum += d[i] * (11 - i); }
    int f2 = 11 - (sum % 11);
    if (f2 >= 10) f2 = 0;
    return d[10] == f2;
  }
}
