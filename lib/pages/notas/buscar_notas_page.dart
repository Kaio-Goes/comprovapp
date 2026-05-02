import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/nota_fiscal_service.dart';
import '../../services/auth_service.dart';
import '../../models/nota_fiscal_model.dart';
import '../../models/usuario_model.dart';
import '../../models/empresa_model.dart';
import '../../config/sefaz_config.dart';
import '../../config/app_colors.dart';
import 'detalhe_nota_page.dart';
import '../configurar_certificado_page.dart';

class MinhasNotasPage extends StatefulWidget {
  const MinhasNotasPage({super.key});

  @override
  State<MinhasNotasPage> createState() => _MinhasNotasPageState();
}

class _MinhasNotasPageState extends State<MinhasNotasPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isSyncLoading = false;
  List<NotaFiscal> _notas = [];
  List<Empresa> _empresas = [];
  String? _errorMessage;
  Usuario? _usuario;
  NotaFiscalService? _sefazService;

  final _currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _inicializar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    setState(() => _isLoading = true);
    try {
      final usuario = await _authService.perfilAtual();
      if (usuario == null) {
        setState(() {
          _errorMessage = 'Usuário não autenticado.';
          _isLoading = false;
        });
        return;
      }
      _usuario = usuario;

      // Carrega config com senha do secure storage (modo produção, cUF=53 DF)
      final config = await SefazConfig.fromSecureStorage(
        tipoAmbiente: 1, // 1 = produção
        codigoUF: 53,    // DF
        modoSimulacao: false,
      );
      _sefazService = NotaFiscalService(config: config);

      await _carregarSalvos();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao inicializar: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _carregarSalvos() async {
    if (_usuario == null || _sefazService == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final notas = await _sefazService!.buscarNotasSalvas(_usuario!.uid);
      final empresas =
          await _sefazService!.listarEmpresasPorUsuario(_usuario!.uid);
      setState(() {
        _notas = notas;
        _empresas = empresas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar dados: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sincronizarSefaz() async {
    if (_usuario == null || _sefazService == null) return;
    setState(() {
      _isSyncLoading = true;
      _errorMessage = null;
    });
    try {
      final notas = await _sefazService!.buscarNotasDoUsuario(_usuario!);
      await _carregarSalvos();
      setState(() => _isSyncLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              notas.isEmpty
                  ? 'Nenhuma nota nova encontrada na SEFAZ.'
                  : '${notas.length} nota(s) sincronizada(s) com sucesso!',
            ),
            backgroundColor:
                notas.isEmpty ? Colors.orange : Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSyncLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Notas Fiscais',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isSyncLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync, color: Colors.white),
              tooltip: 'Sincronizar com SEFAZ',
              onPressed: _sincronizarSefaz,
            ),
          IconButton(
            icon: const Icon(Icons.security_rounded, color: Colors.white),
            tooltip: 'Configurar certificado',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ConfigurarCertificadoPage()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Notas'),
            Tab(icon: Icon(Icons.store), text: 'Mercados'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                                color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNotasTab(),
                      _buildMercadosTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNotasTab() {
    if (_notas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Nenhuma nota encontrada.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
            const SizedBox(height: 8),
            Text('Toque em 🔄 para sincronizar com a SEFAZ.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _carregarSalvos,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _notas.length,
        itemBuilder: (_, i) => _buildNotaCard(_notas[i]),
      ),
    );
  }

  Widget _buildNotaCard(NotaFiscal nota) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalheNotaPage(nota: nota),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nota.nomeEmitente,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  _situacaoBadge(nota.situacao),
                ],
              ),
              const SizedBox(height: 6),
              Text('CNPJ: ${nota.cnpjEmitente}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(
                  'NF: ${nota.numero}  Série: ${nota.serie}  •  ${nota.itens.length} itens',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_dateFmt.format(nota.dataEmissao),
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700)),
                  Text(
                    _currencyFmt.format(nota.valorTotal),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _situacaoBadge(String situacao) {
    final ok = situacao == 'Autorizada';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ok ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        situacao,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: ok ? Colors.green.shade800 : Colors.orange.shade800,
        ),
      ),
    );
  }

  Widget _buildMercadosTab() {
    if (_empresas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Nenhum mercado registrado.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
            const SizedBox(height: 8),
            Text('Sincronize suas notas para ver o comparativo.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      );
    }

    final totalGeral = _empresas.fold(0.0, (s, e) => s + e.totalGasto);

    return RefreshIndicator(
      onRefresh: _carregarSalvos,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: AppColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet,
                      color: Colors.white, size: 32),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Geral',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(
                        _currencyFmt.format(totalGeral),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${_empresas.length} mercado${_empresas.length != 1 ? "s" : ""}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Comparativo por Mercado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._empresas
              .map((e) => _buildEmpresaCard(e, totalGeral)),
        ],
      ),
    );
  }

  Widget _buildEmpresaCard(Empresa empresa, double totalGeral) {
    final pct = totalGeral > 0 ? (empresa.totalGasto / totalGeral) : 0.0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarNotasDaEmpresa(empresa),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      empresa.nome.isNotEmpty
                          ? empresa.nome[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(empresa.nome,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(empresa.cnpjFormatado,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFmt.format(empresa.totalGasto),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.primary),
                      ),
                      Text(
                        '${empresa.quantidadeNotas} nota${empresa.quantidadeNotas != 1 ? "s" : ""}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${(pct * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              if (empresa.ultimaCompra != null) ...[
                const SizedBox(height: 4),
                Text(
                    'Última compra: ${_dateFmt.format(empresa.ultimaCompra!)}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarNotasDaEmpresa(Empresa empresa) {
    final notasDaEmpresa = _notas
        .where((n) =>
            n.cnpjEmitente.replaceAll(RegExp(r'[^\d]'), '') == empresa.cnpj)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 16),
              Text(empresa.nome,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(empresa.cnpjFormatado,
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 6),
              Text(
                'Total: ${_currencyFmt.format(empresa.totalGasto)}  •  ${empresa.quantidadeNotas} nota(s)',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
              const Divider(height: 24),
              ...notasDaEmpresa.map((n) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                        'NF ${n.numero} — ${_dateFmt.format(n.dataEmissao)}',
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text('${n.itens.length} itens',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    trailing: Text(
                      _currencyFmt.format(n.valorTotal),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalheNotaPage(nota: n),
                        ),
                      );
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

}
