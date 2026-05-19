import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../ocorrencias/repository/support_repository_impl.dart';
import 'provider/auth_provider.dart';

class WorkspaceSelectPage extends ConsumerWidget {
  const WorkspaceSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estabelecimentosAsync = ref.watch(estabelecimentosProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1118),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecionar Workspace',
                style: TextStyle(
                  color: Color(0xFFF8FBFF),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escolha o estabelecimento para esta sessão',
                style: TextStyle(color: Color(0xFF566170), fontSize: 14),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: estabelecimentosAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Erro ao carregar: $e',
                      style: const TextStyle(color: Color(0xFFFF4D4D)),
                    ),
                  ),
                  data: (list) => ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final est = list[i];
                      return ListTile(
                        tileColor: const Color(0xFF151A21),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        title: Text(
                          est.nome,
                          style: const TextStyle(color: Color(0xFFF8FBFF)),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF566170),
                          size: 16,
                        ),
                        onTap: () {
                          ref.read(workspaceProvider.notifier).state = est.id;
                          context.go('/feed');
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
