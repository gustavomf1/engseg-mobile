class Estabelecimento {
  final String id;
  final String nome;
  final String? empresaId;

  const Estabelecimento({required this.id, required this.nome, this.empresaId});

  factory Estabelecimento.fromJson(Map<String, dynamic> json) => Estabelecimento(
        id: json['id'] as String,
        nome: json['nome'] as String,
        empresaId: json['empresaId'] as String?,
      );
}
