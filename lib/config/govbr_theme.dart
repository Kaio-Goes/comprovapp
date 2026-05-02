import 'package:flutter/material.dart';

/// Tema e constantes do Padrão Digital de Governo (GOVBR-DS)
/// 
/// Este arquivo centraliza todas as definições de cores, tipografia,
/// espaçamentos e outros tokens de design do Design System oficial
/// do Governo Federal.
/// 
/// Referência: https://www.gov.br/ds/
class GovBrTheme {
  // ==================== CORES ====================
  
  /// Cores primárias do GOVBR-DS
  static const Color azulGovBr = Color(0xFF1351B4);
  static const Color azulGovBrVivido = Color(0xFF155BCB);
  static const Color azulGovBrEscuro = Color(0xFF071D41);
  static const Color azulGovBrClaro = Color(0xFF4799EB);
  
  /// Cores secundárias
  static const Color cinzaEscuro = Color(0xFF333333);
  static const Color cinza = Color(0xFF888888);
  static const Color cinzaClaro = Color(0xFFCCCCCC);
  static const Color cinzaMuitoClaro = Color(0xFFF8F8F8);
  
  /// Cores de estado
  static const Color sucesso = Color(0xFF168821);
  static const Color aviso = Color(0xFFFFCD07);
  static const Color erro = Color(0xFFE52207);
  static const Color informacao = Color(0xFF155BCB);
  
  /// Cores de fundo
  static const Color fundoPrincipal = Colors.white;
  static const Color fundoSecundario = Color(0xFFF8F8F8);
  static const Color fundoTerciario = Color(0xFFEDEFF2);
  
  // ==================== TIPOGRAFIA ====================
  
  /// Estilos de texto seguindo GOVBR-DS
  static const TextStyle displayLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w600,
    color: azulGovBrEscuro,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    color: azulGovBrEscuro,
    height: 1.3,
    letterSpacing: -0.25,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: azulGovBrEscuro,
    height: 1.4,
  );
  
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: cinzaEscuro,
    height: 1.5,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: cinzaEscuro,
    height: 1.5,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: cinzaEscuro,
    height: 1.6,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: cinzaEscuro,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: cinza,
    height: 1.5,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: cinzaEscuro,
    letterSpacing: 0.5,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: cinzaEscuro,
    letterSpacing: 0.25,
  );
  
  // ==================== ESPAÇAMENTOS ====================
  
  /// Espaçamentos padrão do GOVBR-DS (múltiplos de 8)
  static const double space1 = 8.0;   // 0.5rem
  static const double space2 = 16.0;  // 1rem
  static const double space3 = 24.0;  // 1.5rem
  static const double space4 = 32.0;  // 2rem
  static const double space5 = 40.0;  // 2.5rem
  static const double space6 = 48.0;  // 3rem
  static const double space7 = 56.0;  // 3.5rem
  static const double space8 = 64.0;  // 4rem
  
  // ==================== BORDAS ====================
  
  /// Border radius padrão
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 16.0;
  static const double radiusCircular = 100.0; // Para botões pill
  
  /// Largura de bordas
  static const double borderWidth = 1.0;
  static const double borderWidthThick = 2.0;
  
  // ==================== SOMBRAS ====================
  
  /// Elevações (box-shadow)
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  // ==================== TEMA MATERIAL ====================
  
  /// Retorna um ThemeData configurado com GOVBR-DS
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: azulGovBr,
        secondary: azulGovBrVivido,
        error: erro,
        surface: fundoPrincipal,
        surfaceContainerHighest: fundoSecundario,
      ),
      
      // Tipografia
      textTheme: const TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
      ),
      
      // Botões
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: azulGovBr,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCircular),
          ),
          textStyle: labelLarge,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: azulGovBr,
          side: const BorderSide(color: azulGovBr, width: borderWidth),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCircular),
          ),
          textStyle: labelLarge,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: azulGovBr,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: labelMedium,
        ),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: fundoPrincipal,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: BorderSide(color: cinzaClaro, width: borderWidth),
        ),
      ),
      
      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fundoPrincipal,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: cinzaClaro),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: cinzaClaro),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: azulGovBr, width: borderWidthThick),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: erro),
        ),
        contentPadding: const EdgeInsets.all(space2),
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: azulGovBr,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cinzaEscuro,
        contentTextStyle: bodyMedium.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: cinzaClaro,
        thickness: borderWidth,
        space: space3,
      ),
    );
  }
  
  // ==================== COMPONENTES CUSTOMIZADOS ====================
  
  /// Decoração para containers seguindo GOVBR-DS
  static BoxDecoration containerDecoration({
    Color? color,
    bool withBorder = true,
    bool withShadow = false,
  }) {
    return BoxDecoration(
      color: color ?? fundoPrincipal,
      borderRadius: BorderRadius.circular(radiusMedium),
      border: withBorder
          ? Border.all(color: cinzaClaro, width: borderWidth)
          : null,
      boxShadow: withShadow ? shadowMedium : null,
    );
  }
  
  /// Botão Gov.br padrão
  static Widget govBrButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: azulGovBr,
          disabledBackgroundColor: cinzaClaro,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: space1),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }
  
  /// Badge de informação
  static Widget infoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: space2,
        vertical: space1,
      ),
      decoration: BoxDecoration(
        color: fundoSecundario,
        borderRadius: BorderRadius.circular(radiusSmall),
        border: Border.all(color: cinzaClaro),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 16, color: informacao),
          const SizedBox(width: space1),
          Text(text, style: bodySmall),
        ],
      ),
    );
  }
}
