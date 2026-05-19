class DashboardStats {
  final int totalNcs;
  final int ncsAbertas;
  final int ncsVencidas;
  final int totalDesvios;
  final int desviosAbertos;

  const DashboardStats({
    required this.totalNcs,
    required this.ncsAbertas,
    required this.ncsVencidas,
    required this.totalDesvios,
    required this.desviosAbertos,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalNcs: (json['totalNcs'] as num?)?.toInt() ?? 0,
        ncsAbertas: (json['ncsAbertas'] as num?)?.toInt() ?? 0,
        ncsVencidas: (json['ncsVencidas'] as num?)?.toInt() ?? 0,
        totalDesvios: (json['totalDesvios'] as num?)?.toInt() ?? 0,
        desviosAbertos: (json['desviosAbertos'] as num?)?.toInt() ?? 0,
      );
}
