import 'package:chatwoot_sdk/data/local/entity/chatwoot_conversation.dart';
import 'package:chatwoot_sdk/ui/chatwoot_chat_theme.dart';
import 'package:chatwoot_sdk/ui/chatwoot_l10n.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A widget that displays the list of recent conversations for a Chatwoot contact.
///
/// Can be used standalone or embedded within [ChatwootChat].
class ChatwootRecentConversations extends StatelessWidget {
  /// The list of conversations to display
  final List<ChatwootConversation> conversations;

  /// Callback when a conversation is tapped
  final void Function(ChatwootConversation conversation) onConversationSelected;

  /// Callback when the "New Conversation" button is pressed
  final void Function() onNewConversation;

  /// Optional pull-to-refresh callback
  final Future<void> Function()? onRefresh;

  /// Theme configuration for styling
  final ChatwootChatTheme theme;

  /// Localization configuration
  final ChatwootL10n l10n;

  /// Time format for conversation timestamps
  final DateFormat? timeFormat;

  /// Date format for conversation timestamps
  final DateFormat? dateFormat;

  /// Optional custom builder for list items
  final Widget Function(
      BuildContext context, ChatwootConversation conversation)? itemBuilder;

  /// Optional custom header
  final Widget? header;

  /// Indicates if conversations are currently loading
  final bool isLoading;

  const ChatwootRecentConversations({
    Key? key,
    required this.conversations,
    required this.onConversationSelected,
    required this.onNewConversation,
    this.onRefresh,
    this.theme = const ChatwootChatTheme(),
    this.l10n = const ChatwootL10n(),
    this.timeFormat,
    this.dateFormat,
    this.itemBuilder,
    this.header,
    this.isLoading = false,
  }) : super(key: key);

  String _formatTimestamp(ChatwootConversation conversation) {
    DateTime? date;
    if (conversation.messages.isNotEmpty) {
      final lastMsg = conversation.messages.last;
      date = DateTime.tryParse(lastMsg.createdAt);
      if (date == null) {
        final intTimestamp = int.tryParse(lastMsg.createdAt);
        if (intTimestamp != null) {
          date = DateTime.fromMillisecondsSinceEpoch(intTimestamp * 1000);
        }
      }
    }
    if (date == null && conversation.createdAt != null) {
      if (conversation.createdAt is int) {
        date = DateTime.fromMillisecondsSinceEpoch(
            (conversation.createdAt as int) * 1000);
      } else if (conversation.createdAt is String) {
        date = DateTime.tryParse(conversation.createdAt as String);
      }
    }

    if (date == null) return "";

    final now = DateTime.now();
    final isToday =
        now.year == date.year && now.month == date.month && now.day == date.day;

    if (isToday) {
      return (timeFormat ?? DateFormat.jm()).format(date);
    } else {
      return (dateFormat ?? DateFormat.MMMd()).format(date);
    }
  }

  String _getLastMessagePreview(ChatwootConversation conversation) {
    if (conversation.messages.isEmpty) {
      return l10n.emptyChatPlaceholder.isNotEmpty
          ? l10n.emptyChatPlaceholder
          : "...";
    }
    final lastMsg = conversation.messages.last;
    if (lastMsg.content != null && lastMsg.content!.isNotEmpty) {
      return lastMsg.content!;
    }
    if (lastMsg.attachments != null && lastMsg.attachments!.isNotEmpty) {
      return "[Attachment]";
    }
    return "...";
  }

  /// Semantic (not thematic) label + color for a conversation's status --
  /// this is meaning, not brand identity, so unlike the header's ticket
  /// badge these four colors are fixed rather than derived from [theme].
  (String, Color) _statusLabelAndColor(ChatwootConversationStatus status) {
    switch (status) {
      case ChatwootConversationStatus.resolved:
        return (l10n.conversationStatusResolved, Colors.grey);
      case ChatwootConversationStatus.pending:
        return (l10n.conversationStatusPending, Colors.orange);
      case ChatwootConversationStatus.snoozed:
        return (l10n.conversationStatusSnoozed, Colors.blueGrey);
      case ChatwootConversationStatus.open:
        return (l10n.conversationStatusOpen, Colors.green);
    }
  }

  Widget _buildStatusChip(ChatwootConversationStatus status) {
    final (label, color) = _statusLabelAndColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  /// Formats [ChatwootConversation.snoozedUntil] into
  /// [ChatwootL10n.snoozedUntilLabel], or null if it's missing or fails to
  /// parse -- same tolerant-of-bad-data fallback as everywhere else this
  /// timestamp is used.
  String? _formatSnoozedUntil(String? snoozedUntil) {
    if (snoozedUntil == null) {
      return null;
    }
    final date = DateTime.tryParse(snoozedUntil);
    if (date == null) {
      return null;
    }
    final formatted =
        (timeFormat ?? DateFormat('dd/MM HH:mm')).format(date.toLocal());
    return l10n.snoozedUntilLabel.replaceAll('{date}', formatted);
  }

  Widget _buildConversationTile(
      BuildContext context, ChatwootConversation conversation) {
    if (itemBuilder != null) {
      return itemBuilder!(context, conversation);
    }

    final status = conversation.statusEnum;
    final (_, statusColor) = _statusLabelAndColor(status);
    final lastMessage = _getLastMessagePreview(conversation);
    final timeString = _formatTimestamp(conversation);
    final snoozedCaption = status == ChatwootConversationStatus.snoozed
        ? _formatSnoozedUntil(conversation.snoozedUntil)
        : null;

    return InkWell(
      onTap: () => onConversationSelected(conversation),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.secondaryColor,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.headerColor.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: theme.headerColor,
                    size: 22,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.ticketBadgeLabel
                            .replaceAll('{id}', '${conversation.id}'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (timeString.isNotEmpty)
                        Text(
                          timeString,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(status),
                    ],
                  ),
                  if (snoozedCaption != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      snoozedCaption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noConversationsText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onNewConversation,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.startNewConversationText),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.headerColor,
                foregroundColor: theme.headerForegroundColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewConversationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.backgroundColor,
      child: ElevatedButton.icon(
        onPressed: onNewConversation,
        icon: const Icon(Icons.add_comment_outlined, size: 18),
        label: Text(l10n.startNewConversationText),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.headerColor,
          foregroundColor: theme.headerForegroundColor,
          minimumSize: const Size(double.infinity, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        color: theme.backgroundColor,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.headerColor),
          ),
        ),
      );
    }

    Widget content;
    if (conversations.isEmpty) {
      content = _buildEmptyState(context);
    } else {
      content = ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          // Show newest conversations first
          final conversation = conversations[conversations.length - 1 - index];
          return _buildConversationTile(context, conversation);
        },
      );
    }

    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        color: theme.headerColor,
        child: content,
      );
    }

    return Container(
      color: theme.backgroundColor,
      child: Column(
        children: [
          if (header != null) header!,
          if (conversations.isNotEmpty) _buildNewConversationBar(context),
          Expanded(child: content),
        ],
      ),
    );
  }
}
