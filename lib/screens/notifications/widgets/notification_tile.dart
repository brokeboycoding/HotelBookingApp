import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const NotificationTile({
    super.key,
    required this.n,
    required this.onTap,
    this.onDelete,
  });

  IconData _iconByType(String type) {
    switch (type) {
      case 'booking':
        return Icons.event_available_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'approval':
        return Icons.fact_check_rounded;
      case 'message':
        return Icons.forum_rounded;
      case 'promo':
        return Icons.local_offer_rounded;
      case 'system':
      default:
        return Icons.info_rounded;
    }
  }

  String _timeText(DateTime dt) {
    return DateFormat('dd/MM/yyyy • HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = n.isRead
        ? cs.surface
        : cs.primary.withValues(alpha: isDark ? 0.14 : 0.10);

    final border = cs.outlineVariant.withValues(alpha: isDark ? 0.30 : 0.55);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + dot
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.secondary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _iconByType(n.type),
                      color: cs.secondary,
                      size: 26,
                    ),
                  ),
                  if (!n.isRead)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: n.isRead ? FontWeight.w700 : FontWeight.w900,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.72),
                        height: 1.25,
                        fontSize: 12.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _timeText(n.createdAt),
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.55),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // delete (optional)
              if (onDelete != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Xoá',
                  icon: Icon(Icons.delete_outline_rounded,
                      color: cs.onSurface.withValues(alpha: 0.65)),
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
