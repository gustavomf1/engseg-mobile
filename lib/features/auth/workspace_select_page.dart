import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ocorrencias/model/empresa.dart';
import '../ocorrencias/model/estabelecimento.dart';
import '../ocorrencias/repository/support_repository_impl.dart';
import '../auth/model/workspace_state.dart';
import 'provider/auth_provider.dart';
import '../../shared/widgets/prototype_ui.dart';

enum _Step { empresa, estabelecimento, empresaFilha }

class WorkspaceSelectPage extends ConsumerStatefulWidget {
  const WorkspaceSelectPage({super.key});

  @override
  ConsumerState<WorkspaceSelectPage> createState() => _WorkspaceSelectPageState();
}

class _WorkspaceSelectPageState extends ConsumerState<WorkspaceSelectPage> {
  _Step step = _Step.empresa;
  Empresa? empresaSelecionada;
  Estabelecimento? estabelecimentoSelecionado;

  void _selecionarEmpresa(Empresa emp) {
    setState(() {
      empresaSelecionada = emp;
      step = _Step.estabelecimento;
    });
  }

  void _selecionarEstabelecimento(Estabelecimento est) {
    setState(() {
      estabelecimentoSelecionado = est;
      step = _Step.empresaFilha;
    });
  }

  void _selecionarEmpresaFilha(Empresa filha) {
    ref.read(workspaceProvider.notifier).state = WorkspaceState(
      empresa: empresaSelecionada!,
      estabelecimento: estabelecimentoSelecionado!,
      empresaFilha: filha,
    );
    context.go('/feed');
  }

  void _voltar() {
    setState(() {
      if (step == _Step.empresaFilha) {
        step = _Step.estabelecimento;
      } else if (step == _Step.estabelecimento) {
        step = _Step.empresa;
        empresaSelecionada = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProtoColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  if (step != _Step.empresa)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: ProtoColors.text),
                      onPressed: _voltar,
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step == _Step.empresa
                              ? 'Selecionar empresa'
                              : step == _Step.estabelecimento
                                  ? 'Selecionar estabelecimento'
                                  : 'Empresa contratada',
                          style: const TextStyle(
                            color: ProtoColors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step == _Step.empresa
                              ? 'Escolha a empresa para esta sessão'
                              : step == _Step.estabelecimento
                                  ? empresaSelecionada?.nome ?? ''
                                  : estabelecimentoSelecionado?.nome ?? '',
                          style: const TextStyle(color: ProtoColors.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _StepIndicator(step: step),
            const SizedBox(height: 8),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (step) {
      case _Step.empresa:
        return _ListaEmpresas(onSelect: _selecionarEmpresa);
      case _Step.estabelecimento:
        return _ListaEstabelecimentos(
          empresaId: empresaSelecionada!.id,
          onSelect: _selecionarEstabelecimento,
        );
      case _Step.empresaFilha:
        return _ListaEmpresasFilhas(
          estabelecimentoId: estabelecimentoSelecionado!.id,
          onSelect: _selecionarEmpresaFilha,
        );
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final _Step step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _Dot(active: true, label: '1'),
          _Line(active: step != _Step.empresa),
          _Dot(active: step != _Step.empresa, label: '2'),
          _Line(active: step == _Step.empresaFilha),
          _Dot(active: step == _Step.empresaFilha, label: '3'),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  final String label;
  const _Dot({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? ProtoColors.blue : ProtoColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: active ? ProtoColors.blue : ProtoColors.border),
      ),
      child: Text(label,
          style: TextStyle(
              color: active ? Colors.white : ProtoColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900)),
    );
  }
}

class _Line extends StatelessWidget {
  final bool active;
  const _Line({required this.active});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? ProtoColors.blue : ProtoColors.border,
      ),
    );
  }
}

class _ListaEmpresas extends ConsumerWidget {
  final void Function(Empresa) onSelect;
  const _ListaEmpresas({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(empresasMaeProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e', style: const TextStyle(color: ProtoColors.red))),
      data: (list) => _Lista(
        items: list.map((e) => _Item(id: e.id, nome: e.nome, onTap: () => onSelect(e))).toList(),
      ),
    );
  }
}

class _ListaEstabelecimentos extends ConsumerWidget {
  final String empresaId;
  final void Function(Estabelecimento) onSelect;
  const _ListaEstabelecimentos({required this.empresaId, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(estabelecimentosProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e', style: const TextStyle(color: ProtoColors.red))),
      data: (list) {
        final filtrados = list.where((e) => e.empresaId == empresaId).toList();
        if (filtrados.isEmpty) {
          return const Center(child: Text('Nenhum estabelecimento encontrado.', style: TextStyle(color: ProtoColors.muted)));
        }
        return _Lista(
          items: filtrados.map((e) => _Item(id: e.id, nome: e.nome, onTap: () => onSelect(e))).toList(),
        );
      },
    );
  }
}

class _ListaEmpresasFilhas extends ConsumerWidget {
  final String estabelecimentoId;
  final void Function(Empresa) onSelect;
  const _ListaEmpresasFilhas({required this.estabelecimentoId, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(empresasDoEstabelecimentoProvider(estabelecimentoId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e', style: const TextStyle(color: ProtoColors.red))),
      data: (list) {
        if (list.isEmpty) {
          return const Center(child: Text('Nenhuma empresa contratada encontrada.', style: TextStyle(color: ProtoColors.muted)));
        }
        return _Lista(
          items: list.map((e) => _Item(id: e.id, nome: e.nome, onTap: () => onSelect(e))).toList(),
        );
      },
    );
  }
}

class _Lista extends StatelessWidget {
  final List<_Item> items;
  const _Lista({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => items[i],
    );
  }
}

class _Item extends StatelessWidget {
  final String id;
  final String nome;
  final VoidCallback onTap;
  const _Item({required this.id, required this.nome, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: ProtoColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ProtoColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(nome,
                  style: const TextStyle(
                      color: ProtoColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: ProtoColors.muted, size: 14),
          ],
        ),
      ),
    );
  }
}
