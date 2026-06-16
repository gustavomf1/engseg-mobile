import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'eng_auth_image.dart';
import 'motion_helpers.dart';

class EngCoverCard extends StatelessWidget {
  final String id;
  final String titulo;
  final String? coverUrl;
  final bool hasImageCover;
  final bool hasAnyCover;
  final List<Widget> pills;
  final String? meta;
  final VoidCallback onTap;

  const EngCoverCard({
    super.key,
    required this.id,
    required this.titulo,
    required this.coverUrl,
    required this.hasImageCover,
    required this.hasAnyCover,
    required this.pills,
    this.meta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Hero(
          tag: 'cover-$id',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(EngSegRadius.md),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCover(),
                  // scrim gradiente
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.35, 1.0],
                        colors: [Colors.transparent, Color(0xCC000000)],
                      ),
                    ),
                  ),
                  // pills (canto superior esquerdo)
                  if (pills.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Wrap(spacing: 6, runSpacing: 4, children: pills),
                    ),
                  // título + meta (rodapé)
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: EngSegColors.dark.fg0,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        if (meta != null && meta!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            meta!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: EngSegColors.dark.fg2,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    // Caminho 1: imagem
    if (hasImageCover && coverUrl != null) {
      return EngAuthImage(url: coverUrl!, fit: BoxFit.cover);
    }
    // Caminho 2: evidência não-imagem (pdf, video, etc.)
    if (hasAnyCover) {
      return Container(
        color: EngSegColors.dark.bgElevated,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file_outlined,
                color: EngSegColors.dark.fg2, size: 36),
            const SizedBox(height: 6),
            Text(
              'Documento anexado',
              style: TextStyle(color: EngSegColors.dark.fg2, fontSize: 12),
            ),
          ],
        ),
      );
    }
    // Caminho 3: sem evidência
    return Container(
      color: EngSegColors.dark.bgElevated,
      child: Center(
        child: Icon(Icons.shield_outlined,
            color: EngSegColors.dark.fg3, size: 40),
      ),
    );
  }
}
