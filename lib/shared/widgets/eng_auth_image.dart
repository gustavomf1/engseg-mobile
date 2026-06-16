import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../theme/tokens.dart';

class EngAuthImage extends ConsumerWidget {
  final String url;
  final BoxFit fit;
  final Widget? errorWidget;

  const EngAuthImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(authProvider).valueOrNull?.token;

    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders:
          token != null ? {'Authorization': 'Bearer $token'} : const {},
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => Container(
        color: EngSegColors.dark.bgElevated,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: EngSegColors.dark.accent,
            ),
          ),
        ),
      ),
      errorWidget: (_, __, ___) =>
          errorWidget ??
          Container(
            color: EngSegColors.dark.bgElevated,
            child: Icon(
              Icons.broken_image_outlined,
              color: EngSegColors.dark.fg2,
              size: 32,
            ),
          ),
    );
  }
}
