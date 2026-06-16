import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/tokens.dart';

class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;

  const TapScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
    reverseDuration: const Duration(milliseconds: 160),
  );
  late final _anim = Tween<double>(begin: 1.0, end: widget.scale).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, child) =>
            Transform.scale(scale: _anim.value, child: child),
        child: widget.child,
      ),
    );
  }
}

extension StaggeredEntrance on Widget {
  Widget staggered(int index,
      {Duration itemDelay = const Duration(milliseconds: 55)}) {
    return animate(delay: itemDelay * index)
        .fadeIn(duration: EngSegMotion.base, curve: EngSegMotion.curve)
        .slideY(
          begin: 0.04,
          end: 0,
          duration: EngSegMotion.base,
          curve: EngSegMotion.curve,
        );
  }
}
