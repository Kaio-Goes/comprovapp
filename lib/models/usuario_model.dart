class Usuario {
  final String uid;
  final String cpf;
  final String nomeCompleto;
  final String email;
  final DateTime dataNascimento;
  /// 0 = admin, 1 = cliente normal
  final int role;

  Usuario({
    required this.uid,
    required this.cpf,
    required this.nomeCompleto,
    required this.email,
    required this.dataNascimento,
    this.role = 1,
  });

  factory Usuario.fromFirestore(Map<String, dynamic> data, String uid) {
    return Usuario(
      uid: uid,
      cpf: data['cpf'] ?? '',
      nomeCompleto: data['nomeCompleto'] ?? '',
      email: data['email'] ?? '',
      dataNascimento: data['dataNascimento'] != null
          ? DateTime.parse(data['dataNascimento'])
          : DateTime(2000),
      role: data['role'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cpf': cpf,
      'nomeCompleto': nomeCompleto,
      'email': email,
      'dataNascimento': dataNascimento.toIso8601String(),
      'role': role,
    };
  }

  bool get isAdmin => role == 0;

  String get cpfFormatado {
    final c = cpf.replaceAll(RegExp(r'[^\d]'), '');
    if (c.length != 11) return cpf;
    return '${c.substring(0, 3)}.${c.substring(3, 6)}.${c.substring(6, 9)}-${c.substring(9, 11)}';
  }

  String get primeiroNome => nomeCompleto.split(' ').first;
}
