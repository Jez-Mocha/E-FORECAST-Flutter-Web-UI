import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart' show LandingCard, SampleDataChip;
import '../models/dashboard_message.dart';
import '../theme/landing_colors.dart';

/// Wide "Messages" panel for the dashboard.
///
/// It only displays the list it is given. By default that is
/// [sampleMessages], which are demo messages written by us. They are NOT
/// live notifications from a backend.
class MessagesPanel extends StatelessWidget {
  final List<DashboardMessage> messages;

  const MessagesPanel({super.key, this.messages = sampleMessages});

  @override
  Widget build(BuildContext context) {
    final unreadCount = messages.where((m) => m.isUnread).length;

    return LandingCard(
      // Zero padding here so the divider lines can reach the card edges.
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(unreadCount: unreadCount),
          Divider(height: 1, thickness: 1, color: LandingColors.border),
          if (messages.isEmpty)
            const _EmptyMessages()
          else
            for (var i = 0; i < messages.length; i++) ...[
              _MessageRow(message: messages[i]),
              if (i < messages.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                  color: LandingColors.border,
                ),
            ],
        ],
      ),
    );
  }
}

/// Top of the panel: heading, "Sample messages" chip and unread count.
class _PanelHeader extends StatelessWidget {
  final int unreadCount;

  const _PanelHeader({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(
            Icons.mail_outline_rounded,
            size: 20,
            color: LandingColors.primary,
          ),
          const SizedBox(width: 10),
          Text(
            'Messages',
            style: TextStyle(
              color: LandingColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          const SampleDataChip(label: 'Sample messages'),
          const Spacer(),
          if (unreadCount > 0)
            Text(
              '$unreadCount unread',
              style: TextStyle(
                color: LandingColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

/// One message: icon, title, category + time, body text, unread dot.
class _MessageRow extends StatelessWidget {
  final DashboardMessage message;

  const _MessageRow({required this.message});

  @override
  Widget build(BuildContext context) {
    final unread = message.isUnread;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category icon in a soft square.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: LandingColors.periwinkleTint,
              borderRadius: BorderRadius.circular(LandingRadius.control),
            ),
            child: Icon(
              message.category.icon,
              size: 18,
              color: LandingColors.primary,
            ),
          ),
          const SizedBox(width: 14),

          // Title, small info line, body.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: LandingColors.textPrimary,
                    fontSize: 14,
                    fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${message.category.label}  ·  ${message.timeLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: LandingColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unread
                        ? LandingColors.textPrimary
                        : LandingColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Unread dot. A fixed-size box keeps rows aligned when it is hidden.
          SizedBox(
            width: 10,
            height: 36,
            child: Align(
              alignment: Alignment.center,
              child: unread
                  ? Tooltip(
                      message: 'Unread',
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: LandingColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown only if the list is empty.
class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Center(
        child: Text(
          'No messages right now.',
          style: TextStyle(color: LandingColors.textSecondary, fontSize: 13),
        ),
      ),
    );
  }
}
