class Usuario {
  final String cpf;
  final String nome;
  final String? email;
  final String? telefone;
  final DateTime? dataNascimento;
  final String? foto;
  final String accessToken;
  final String? refreshToken;
  final DateTime tokenExpiry;

  Usuario({
    required this.cpf,
    required this.nome,
    this.email,
    this.telefone,
    this.dataNascimento,
    this.foto,
    required this.accessToken,
    this.refreshToken,
    required this.tokenExpiry,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      cpf: json['cpf'] ?? '',
      nome: json['nome'] ?? json['name'] ?? '',
      email: json['email'],
      telefone: json['telefone'] ?? json['phone_number'],
      dataNascimento: json['dataNascimento'] != null
          ? DateTime.parse(json['dataNascimento'])
          : null,
      foto: json['foto'] ?? json['picture'],
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'],
      tokenExpiry: json['tokenExpiry'] != null
          ? DateTime.parse(json['tokenExpiry'])
          : DateTime.now().add(const Duration(hours: 1)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cpf': cpf,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'dataNascimento': dataNascimento?.toIso8601String(),
      'foto': foto,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenExpiry': tokenExpiry.toIso8601String(),
    };
  }

  String get cpfFormatado {
    if (cpf.length != 11) return cpf;
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9, 11)}';
  }

  String get primeiroNome {
    return nome.split(' ').first;
  }

  bool get tokenValido {
    return DateTime.now().isBefore(tokenExpiry);
  }
}
