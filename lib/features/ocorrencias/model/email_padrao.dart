class EmailPadrao {
  final String id;
  final String email;
  final String? descricao;
  const EmailPadrao({required this.id, required this.email, this.descricao});

  factory EmailPadrao.fromJson(Map<String, dynamic> j) => EmailPadrao(
        id: j['id'] as String,
        email: j['email'] as String,
        descricao: j['descricao'] as String?,
      );
}
