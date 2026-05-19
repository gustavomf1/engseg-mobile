class Localizacao {
  final String id;
  final String nome;

  const Localizacao({required this.id, required this.nome});

  factory Localizacao.fromJson(Map<String, dynamic> json) => Localizacao(
    id: json['id'] as String,
    nome: json['nome'] as String,
  );
}
