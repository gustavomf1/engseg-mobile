import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool online;
  final bool hasNotif;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.online = true,
    this.hasNotif = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(color: context.c.fg3, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          if (!online) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: context.c.statusOrangeBg, borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 12, color: context.c.statusOrangeFg),
                  const SizedBox(width: 6),
                  Text('Offline', style: TextStyle(color: context.c.statusOrangeFg, fontSize: 11, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: context.c.bgSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: context.c.borderSoft),
                ),
              ),
              onPressed: () => context.go('/notif'),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_rounded, size: 18, color: context.c.fg1),
                  if (hasNotif)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: context.c.statusRedFg, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
