class Norma {
  final String id;
  final String codigo; // e.g. "NR-35"
  final String nome;

  const Norma({required this.id, required this.codigo, required this.nome});

  factory Norma.fromJson(Map<String, dynamic> json) => Norma(
    id: json['id'] as String,
    codigo: json['codigo'] as String? ?? '',
    nome: json['nome'] as String? ?? '',
  );
}
