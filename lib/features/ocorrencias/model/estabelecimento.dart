class Estabelecimento {
  final String id;
  final String nome;

  const Estabelecimento({required this.id, required this.nome});

  factory Estabelecimento.fromJson(Map<String, dynamic> json) => Estabelecimento(
    id: json['id'] as String,
    nome: json['nome'] as String,
  );
}
