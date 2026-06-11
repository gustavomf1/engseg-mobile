import '../../ocorrencias/model/empresa.dart';
import '../../ocorrencias/model/estabelecimento.dart';

class WorkspaceState {
  final Empresa empresa;
  final Estabelecimento estabelecimento;
  final Empresa empresaFilha;

  const WorkspaceState({
    required this.empresa,
    required this.estabelecimento,
    required this.empresaFilha,
  });
}
