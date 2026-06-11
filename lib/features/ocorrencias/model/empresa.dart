class Empresa {
  final String id;
  final String nome;
  final bool exibirNoSeletor;

  const Empresa({required this.id, required this.nome, this.exibirNoSeletor = true});

  factory Empresa.fromJson(Map<String, dynamic> json) => Empresa(
        id: json['id'] as String,
        nome: (json['nomeFantasia'] ?? json['razaoSocial'] ?? json['nome'] ?? '') as String,
        exibirNoSeletor: json['exibirNoSeletor'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome};
}
