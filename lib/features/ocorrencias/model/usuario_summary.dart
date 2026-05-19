class UsuarioSummary {
  final String id;
  final String nome;
  final String email;
  final String perfil;

  const UsuarioSummary({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
  });

  factory UsuarioSummary.fromJson(Map<String, dynamic> json) => UsuarioSummary(
    id: json['id'] as String,
    nome: json['nome'] as String,
    email: json['email'] as String,
    perfil: json['perfil'] as String,
  );
}
