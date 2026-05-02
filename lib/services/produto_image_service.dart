import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Fornece imagens de produtos (via Open Food Facts) e
/// utilitários visuais para emojis e cores de empresas.
class ProdutoImageService {
  // Cache em memória: código → URL (null = não encontrado)
  static final Map<String, String?> _cacheImagens = {};

  /// Retorna a URL em cache para um código (sem fazer requisição).
  static String? urlEmCache(String codigo) => _cacheImagens[codigo];

  /// Tenta buscar a imagem do produto no Open Food Facts.
  ///
  /// Funciona para códigos EAN-8 e EAN-13. Outros códigos retornam null.
  static Future<String?> buscarImagemProduto(String codigo) async {
    final key = codigo.trim();
    if (_cacheImagens.containsKey(key)) return _cacheImagens[key];

    final isEan = RegExp(r'^\d{8}$|^\d{13}$').hasMatch(key);
    if (!isEan) {
      _cacheImagens[key] = null;
      return null;
    }

    try {
      final resp = await http
          .get(Uri.parse(
            'https://world.openfoodfacts.org/api/v2/product/$key?fields=image_front_url',
          ))
          .timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final url = body['product']?['image_front_url'] as String?;
        _cacheImagens[key] = url;
        return url;
      }
    } catch (_) {}

    _cacheImagens[key] = null;
    return null;
  }

  /// Emoji representando a categoria do produto por palavras-chave.
  static String emojiProduto(String descricao) {
    final d = descricao.toLowerCase();

    if (_any(d, ['leite', 'iogurte', 'queijo', 'manteiga', 'requeijão', 'nata', 'creme de leite'])) return '🥛';
    if (_any(d, ['frango', 'galeto', 'filé', 'peixe', 'atum', 'sardinha', 'camarão', 'bacalhau'])) return '🍗';
    if (_any(d, ['carne', 'bife', 'picanha', 'costela', 'linguiça', 'salsicha', 'presunto', 'mortadela', 'bacon'])) return '🥩';
    if (_any(d, ['pão', 'torrada', 'brioche', 'baguete', 'croissant', 'bisnaguinha'])) return '🍞';
    if (_any(d, ['biscoito', 'bolacha', 'cookie', 'wafer', 'cream cracker'])) return '🍪';
    if (_any(d, ['bolo', 'sonho', 'rosca', 'panetone', 'cupcake'])) return '🎂';
    if (_any(d, ['arroz', 'feijão', 'lentilha', 'grão de bico', 'soja'])) return '🌾';
    if (_any(d, ['macarrão', 'macarrao', 'espaguete', 'lasanha', 'nhoque', 'farinha', 'aveia', 'cereal', 'granola'])) return '🍝';
    if (_any(d, ['maçã', 'maca', 'banana', 'uva', 'laranja', 'limão', 'limao', 'mamão', 'mamao', 'manga', 'abacaxi', 'morango', 'pêra', 'pera', 'melão', 'melao', 'fruta'])) return '🍎';
    if (_any(d, ['tomate', 'cebola', 'alho', 'batata', 'cenoura', 'alface', 'brócoli', 'brocoli', 'couve', 'pepino', 'abobrinha', 'berinjela', 'pimentão', 'legume', 'verdura'])) return '🥦';
    if (_any(d, ['ovo', 'ovos'])) return '🥚';
    if (_any(d, ['refrigerante', 'suco', 'néctar', 'nectar', 'água', 'agua', 'energético', 'energetico', 'isotônico'])) return '🥤';
    if (_any(d, ['cerveja', 'chope', 'vinho', 'espumante', 'whisky', 'vodka', 'cachaça', 'rum'])) return '🍺';
    if (_any(d, ['café', 'cafe', 'achocolatado', 'cacau', 'chocolate em pó', 'nescau', 'ovomaltine'])) return '☕';
    if (_any(d, ['chá', 'cha', 'erva mate', 'chimarrão'])) return '🍵';
    if (_any(d, ['azeite', 'óleo', 'oleo', 'vinagre', 'molho', 'ketchup', 'mostarda', 'maionese', 'shoyu', 'catchup'])) return '🫙';
    if (_any(d, ['açúcar', 'acucar', 'sal', 'tempero', 'alecrim', 'orégano', 'oregano', 'pimenta', 'canela', 'cúrcuma'])) return '🧂';
    if (_any(d, ['chocolate', 'bombom', 'trufa', 'ao leite', 'amargo'])) return '🍫';
    if (_any(d, ['doce', 'bala', 'pirulito', 'goma', 'chiclete', 'sorvete', 'picolé', 'picole', 'gelado'])) return '🍬';
    if (_any(d, ['detergente', 'amaciante', 'sabão', 'sabao', 'desinfetante', 'limpador', 'multiuso', 'cloro', 'água sanitária'])) return '🧴';
    if (_any(d, ['papel higiênico', 'papel toalha', 'guardanapo', 'fralda', 'lenço', 'lenco'])) return '🧻';
    if (_any(d, ['sabonete', 'shampoo', 'condicionador', 'desodorante', 'creme', 'loção', 'hidratante', 'escova', 'dental', 'enxaguante'])) return '🧼';
    if (_any(d, ['ração', 'racao', 'pet', 'animal'])) return '🐾';

    return '🛒';
  }

  /// Cor de fundo para o emoji baseada em categoria.
  static Color corFundoProduto(String descricao) {
    final d = descricao.toLowerCase();
    if (_any(d, ['leite', 'iogurte', 'queijo', 'manteiga', 'creme'])) return const Color(0xFFE3F2FD);
    if (_any(d, ['carne', 'frango', 'peixe', 'atum', 'filé', 'linguiça'])) return const Color(0xFFFFEBEE);
    if (_any(d, ['pão', 'biscoito', 'bolacha', 'bolo', 'torrada'])) return const Color(0xFFFFF3E0);
    if (_any(d, ['arroz', 'feijão', 'macarrão', 'farinha', 'aveia'])) return const Color(0xFFF3E5F5);
    if (_any(d, ['fruta', 'maçã', 'banana', 'uva', 'laranja', 'morango'])) return const Color(0xFFE8F5E9);
    if (_any(d, ['legume', 'verdura', 'alface', 'tomate', 'cebola'])) return const Color(0xFFE8F5E9);
    if (_any(d, ['refrigerante', 'suco', 'água', 'bebida', 'cerveja'])) return const Color(0xFFE0F7FA);
    if (_any(d, ['café', 'chocolate', 'achocolatado'])) return const Color(0xFFEFEBE9);
    if (_any(d, ['detergente', 'sabão', 'limpador', 'desinfetante'])) return const Color(0xFFE1F5FE);
    return const Color(0xFFF5F5F5);
  }

  /// Cor da empresa para avatar (derivada do nome).
  static Color corEmpresa(String nome) {
    const paleta = [
      Color(0xFF1565C0),
      Color(0xFF2E7D32),
      Color(0xFF6A1B9A),
      Color(0xFFE65100),
      Color(0xFF00838F),
      Color(0xFFC62828),
      Color(0xFF4527A0),
      Color(0xFF00695C),
      Color(0xFF558B2F),
      Color(0xFF283593),
    ];
    return paleta[nome.hashCode.abs() % paleta.length];
  }

  /// Iniciais da empresa (máx. 2 letras).
  static String iniciaisEmpresa(String nome) {
    final palavras = nome.trim().split(RegExp(r'\s+')).where((p) => p.length > 2).toList();
    if (palavras.isEmpty) return nome.substring(0, nome.length.clamp(0, 2)).toUpperCase();
    if (palavras.length == 1) return palavras[0].substring(0, 2).toUpperCase();
    return '${palavras[0][0]}${palavras[1][0]}'.toUpperCase();
  }

  static bool _any(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));
}
