import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/nota_fiscal_model.dart';
import '../../models/preco_produto_model.dart';
import '../../services/nota_fiscal_service.dart';
import '../../services/produto_image_service.dart';
import '../../config/sefaz_config.dart';
import '../../config/app_colors.dart';

class DetalheNotaPage extends StatefulWidget {
  final NotaFiscal nota;

  const DetalheNotaPage({super.key, required this.nota});

  @override
  State<DetalheNotaPage> createState() => _DetalheNotaPageState();
}

class _DetalheNotaPageState extends State<DetalheNotaPage> {
  Map<String, PrecoProduto> _precos = {};
  // produto codigo → lista ordenada por preço em outras lojas
  final Map<String, List<PrecoProduto>> _crossStore = {};
  bool _isLoading = true;
  NotaFiscalService? _service;

  final _currFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFmt = DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR');

  NotaFiscal get nota => widget.nota;

  @override
  void initState() {
    super.initState();
    _carregarPrecos();
  }

  Future<void> _carregarPrecos() async {
    try {
      final config = await SefazConfig.fromSecureStorage(
        tipoAmbiente: 1,
        codigoUF: 53,
        modoSimulacao: false,
      );
      _service = NotaFiscalService(config: config);
      final precos = await _service!.buscarVariacoesParaNota(nota);
      if (mounted) {
        setState(() {
          _precos = precos;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Carrega preços de outros mercados para um produto (lazy).
  Future<void> _carregarCrossStore(String codigo) async {
    if (_crossStore.containsKey(codigo) || _service == null) return;
    final lista = await _service!.buscarPrecosPorCodigo(codigo);
    if (mounted) {
      setState(() => _crossStore[codigo] = lista);
    }
  }

  // ── Computed ─────────────────────────────────────────────────────────────

  int get _qtdMaisCaro =>
      _precos.values.where((p) => p.ficouMaisCaro).length;
  int get _qtdMaisBarato =>
      _precos.values.where((p) => p.ficouMaisBarato).length;
  int get _qtdIgual =>
      _precos.values.where((p) => p.mesmoPreco).length;
  int get _qtdNovos => nota.itens
      .where((i) => !_precos.containsKey(i.codigo) || _precos[i.codigo]!.semHistorico)
      .length;

  double get _variacaoTotal => nota.itens.fold(0.0, (soma, item) {
        final p = _precos[item.codigo];
        if (p?.variacao == null) return soma;
        return soma + p!.variacao! * item.quantidade;
      });

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SliverToBoxAdapter(child: _buildStoreHeader()),
            if (_precos.isNotEmpty)
              SliverToBoxAdapter(child: _buildVariacaoSummary()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_basket_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Produtos (${nota.itens.length})',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildProductCard(nota.itens[i]),
                childCount: nota.itens.length,
              ),
            ),
            SliverToBoxAdapter(child: _buildTotalFooter()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    final cor = ProdutoImageService.corEmpresa(nota.nomeEmitente);
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      snap: true,
      backgroundColor: cor,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        nota.nomeEmitente,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ── Store header ──────────────────────────────────────────────────────────

  Widget _buildStoreHeader() {
    final cor = ProdutoImageService.corEmpresa(nota.nomeEmitente);
    final iniciais = ProdutoImageService.iniciaisEmpresa(nota.nomeEmitente);
    final cnpjFmt = _formatarCnpj(nota.cnpjEmitente);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cor, cor.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar da loja
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5), width: 2),
                ),
                child: Center(
                  child: Text(
                    iniciais,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nota.nomeEmitente,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'CNPJ: $cnpjFmt',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chips de info
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _infoBadge(Icons.calendar_today_outlined,
                  _dateFmt.format(nota.dataEmissao)),
              _infoBadge(Icons.receipt_outlined,
                  'NF ${nota.numero} / Série ${nota.serie}'),
              _infoBadge(
                  Icons.check_circle_outline, nota.situacao),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Variação summary ──────────────────────────────────────────────────────

  Widget _buildVariacaoSummary() {
    if (_qtdMaisCaro == 0 && _qtdMaisBarato == 0 && _qtdIgual == 0) {
      return const SizedBox.shrink();
    }

    final variacaoTotal = _variacaoTotal;
    final ficouMaisCaro = variacaoTotal > 0.01;
    final ficouMaisBarato = variacaoTotal < -0.01;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ficouMaisCaro
                  ? Colors.red.shade50
                  : ficouMaisBarato
                      ? Colors.green.shade50
                      : Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  ficouMaisCaro
                      ? Icons.trending_up_rounded
                      : ficouMaisBarato
                          ? Icons.trending_down_rounded
                          : Icons.trending_flat_rounded,
                  color: ficouMaisCaro
                      ? Colors.red.shade700
                      : ficouMaisBarato
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comparativo com compra anterior',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        ficouMaisCaro
                            ? 'Você pagou ${_currFmt.format(variacaoTotal.abs())} a mais nessa compra'
                            : ficouMaisBarato
                                ? 'Você economizou ${_currFmt.format(variacaoTotal.abs())} nessa compra'
                                : 'Preços estáveis em relação à compra anterior',
                        style: TextStyle(
                          fontSize: 12,
                          color: ficouMaisCaro
                              ? Colors.red.shade700
                              : ficouMaisBarato
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Contadores
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (_qtdMaisCaro > 0)
                  _contadorVariacao(
                    icon: Icons.arrow_upward_rounded,
                    cor: Colors.red.shade600,
                    bgCor: Colors.red.shade50,
                    quantidade: _qtdMaisCaro,
                    label: 'Mais caro',
                  ),
                if (_qtdMaisBarato > 0)
                  _contadorVariacao(
                    icon: Icons.arrow_downward_rounded,
                    cor: Colors.green.shade700,
                    bgCor: Colors.green.shade50,
                    quantidade: _qtdMaisBarato,
                    label: 'Mais barato',
                  ),
                if (_qtdIgual > 0)
                  _contadorVariacao(
                    icon: Icons.remove_rounded,
                    cor: Colors.grey.shade600,
                    bgCor: Colors.grey.shade100,
                    quantidade: _qtdIgual,
                    label: 'Mesmo preço',
                  ),
                if (_qtdNovos > 0)
                  _contadorVariacao(
                    icon: Icons.fiber_new_rounded,
                    cor: Colors.blue.shade600,
                    bgCor: Colors.blue.shade50,
                    quantidade: _qtdNovos,
                    label: 'Novo item',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contadorVariacao({
    required IconData icon,
    required Color cor,
    required Color bgCor,
    required int quantidade,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: bgCor, shape: BoxShape.circle),
          child: Center(
            child: Icon(icon, color: cor, size: 22),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$quantidade',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: cor),
        ),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  // ── Product card ──────────────────────────────────────────────────────────

  Widget _buildProductCard(ItemNotaFiscal item) {
    final preco = _precos[item.codigo];
    final emoji = ProdutoImageService.emojiProduto(item.descricao);
    final bgCor = ProdutoImageService.corFundoProduto(item.descricao);
    final cross = _crossStore[item.codigo];
    // Melhor preço em outra loja (diferente da atual)
    final cnpjAtual =
        nota.cnpjEmitente.replaceAll(RegExp(r'[^\d]'), '');
    final melhorCross = cross
        ?.where((p) => p.cnpj != cnpjAtual)
        .firstOrNull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _abrirDetalhesProduto(item, preco, cross),
        onLongPress: () {
          // Carrega comparativo de outras lojas ao pressionar longo
          _carregarCrossStore(item.codigo);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji / imagem do produto
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: bgCor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _buildProductImage(item.codigo, emoji),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info do produto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleCase(item.descricao),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cód: ${item.codigo}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.quantidade} ${item.unidade ?? "UN"}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '× ${_currFmt.format(item.valorUnitario)}',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Valor total + badge de variação
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        _currFmt.format(item.valorTotal),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildVariacaoBadge(preco),
                    ],
                  ),
                ],
              ),
              // Dica de melhor preço em outra loja
              if (melhorCross != null &&
                  melhorCross.valorAtual < item.valorUnitario)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 5),
                        Text(
                          'Mais barato em ${_primeiraPalavra(melhorCross.nomeEmpresa)}: '
                          '${_currFmt.format(melhorCross.valorAtual)}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.green.shade800),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String codigo, String emoji) {
    // Tenta carregar imagem da internet, fallback para emoji
    final url = ProdutoImageService.urlEmCache(codigo);
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Text(emoji, style: const TextStyle(fontSize: 28)),
        ),
      );
    }
    // Dispara busca assíncrona sem await para não bloquear build
    _prefetchImagem(codigo);
    return Text(emoji, style: const TextStyle(fontSize: 28));
  }

  Future<void> _prefetchImagem(String codigo) async {
    final url =
        await ProdutoImageService.buscarImagemProduto(codigo);
    if (url != null && mounted) setState(() {});
  }

  Widget _buildVariacaoBadge(PrecoProduto? preco) {
    if (preco == null || preco.semHistorico) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Text(
          'Novo',
          style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 10,
              fontWeight: FontWeight.bold),
        ),
      );
    }

    if (preco.mesmoPreco) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          '= Igual',
          style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 10,
              fontWeight: FontWeight.bold),
        ),
      );
    }

    final variacao = preco.variacao!;
    final pct = preco.variacaoPercent!;
    final maisC = preco.ficouMaisCaro;
    final cor = maisC ? Colors.red.shade700 : Colors.green.shade700;
    final bgCor = maisC ? Colors.red.shade50 : Colors.green.shade50;
    final border = maisC ? Colors.red.shade200 : Colors.green.shade200;
    final sinal = maisC ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: bgCor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(
            '${maisC ? "▲" : "▼"} ${_currFmt.format(variacao.abs())}',
            style: TextStyle(
                color: cor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            '$sinal${pct.toStringAsFixed(1)}%',
            style: TextStyle(color: cor.withValues(alpha: 0.85), fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ── Total footer ──────────────────────────────────────────────────────────

  Widget _buildTotalFooter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          if (nota.protocolo != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.verified_outlined,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    'Protocolo: ${nota.protocolo}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${nota.itens.length} itens',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('TOTAL',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    Text(
                      _currFmt.format(nota.valorTotal),
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Chave de acesso
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chave de Acesso',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                SelectableText(
                  nota.chaveAcesso,
                  style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: Colors.grey.shade700,
                      letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom sheet detalhe produto ─────────────────────────────────────────

  void _abrirDetalhesProduto(
    ItemNotaFiscal item,
    PrecoProduto? preco,
    List<PrecoProduto>? cross,
  ) {
    // Carrega cross-store se ainda não tiver
    if (cross == null) _carregarCrossStore(item.codigo);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProdutoDetalheSheet(
        item: item,
        preco: preco,
        crossStore: _crossStore[item.codigo] ?? [],
        currFmt: _currFmt,
        dateFmt: DateFormat('dd/MM/yyyy'),
        cnpjAtual: nota.cnpjEmitente.replaceAll(RegExp(r'[^\d]'), ''),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatarCnpj(String cnpj) {
    final c = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    if (c.length != 14) return cnpj;
    return '${c.substring(0, 2)}.${c.substring(2, 5)}.${c.substring(5, 8)}/'
        '${c.substring(8, 12)}-${c.substring(12, 14)}';
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    const preposicoes = {'de', 'da', 'do', 'das', 'dos', 'e', 'a', 'o'};
    return s
        .toLowerCase()
        .split(' ')
        .asMap()
        .entries
        .map((e) => (e.key == 0 || !preposicoes.contains(e.value))
            ? e.value.isEmpty
                ? ''
                : '${e.value[0].toUpperCase()}${e.value.substring(1)}'
            : e.value)
        .join(' ');
  }

  String _primeiraPalavra(String nome) {
    final palavras = nome.split(' ');
    return palavras.isNotEmpty ? palavras[0] : nome;
  }
}

// ── Sheet de detalhe do produto ───────────────────────────────────────────

class _ProdutoDetalheSheet extends StatelessWidget {
  final ItemNotaFiscal item;
  final PrecoProduto? preco;
  final List<PrecoProduto> crossStore;
  final NumberFormat currFmt;
  final DateFormat dateFmt;
  final String cnpjAtual;

  const _ProdutoDetalheSheet({
    required this.item,
    required this.preco,
    required this.crossStore,
    required this.currFmt,
    required this.dateFmt,
    required this.cnpjAtual,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = ProdutoImageService.emojiProduto(item.descricao);
    final bgCor = ProdutoImageService.corFundoProduto(item.descricao);
    final temHistorico = preco != null && !preco!.semHistorico;
    final outraLojas = crossStore.where((p) => p.cnpj != cnpjAtual).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Produto header
            Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: bgCor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:
                      Center(child: Text(emoji, style: const TextStyle(fontSize: 36))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.descricao,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text('Código: ${item.codigo}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 6),
                      Text(
                        '${item.quantidade} ${item.unidade ?? "UN"} × ${currFmt.format(item.valorUnitario)} = ${currFmt.format(item.valorTotal)}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Histórico de preços na mesma loja
            if (temHistorico) ...[
              const Text('Histórico neste mercado',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: preco!.historico.reversed.take(6).toList().asMap().entries.map((e) {
                    final h = e.value;
                    final isLast = e.key == 0;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        isLast ? Icons.radio_button_checked : Icons.circle,
                        size: 12,
                        color: isLast
                            ? AppColors.primary
                            : Colors.grey.shade400,
                      ),
                      title: Text(
                        currFmt.format(h.valor),
                        style: TextStyle(
                          fontWeight: isLast
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isLast
                              ? AppColors.primary
                              : Colors.black87,
                        ),
                      ),
                      trailing: Text(
                        dateFmt.format(h.data),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Preços em outras lojas
            if (outraLojas.isNotEmpty) ...[
              const Text('Preços em outros mercados',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...outraLojas.map((p) {
                final diff = p.valorAtual - item.valorUnitario;
                final isCheaper = diff < -0.005;
                final isExpensive = diff > 0.005;
                final cor = isCheaper
                    ? Colors.green.shade700
                    : isExpensive
                        ? Colors.red.shade700
                        : Colors.grey.shade600;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCheaper
                        ? Colors.green.shade50
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isCheaper
                            ? Colors.green.shade200
                            : Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: ProdutoImageService.corEmpresa(
                            p.nomeEmpresa),
                        child: Text(
                          ProdutoImageService.iniciaisEmpresa(
                              p.nomeEmpresa),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(p.nomeEmpresa,
                            style: const TextStyle(fontSize: 13)),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currFmt.format(p.valorAtual),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: cor),
                          ),
                          if (diff.abs() > 0.005)
                            Text(
                              isCheaper
                                  ? '${currFmt.format(diff.abs())} mais barato'
                                  : '${currFmt.format(diff.abs())} mais caro',
                              style: TextStyle(fontSize: 10, color: cor),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],

            if (!temHistorico && outraLojas.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Primeira vez comprando este produto.\nCompre mais vezes para ver o comparativo!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
