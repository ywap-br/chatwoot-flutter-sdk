import 'package:flutter_chat_ui/flutter_chat_ui.dart';

/// Base chat l10n containing all required variables to provide localized chatwoot chat
class ChatwootL10n extends ChatL10n {
  /// Accessibility label (hint) for the attachment button
  final String attachmentButtonAccessibilityLabel;

  /// Placeholder when there are no messages
  final String emptyChatPlaceholder;

  /// Accessibility label (hint) for the tap action on file message
  final String fileButtonAccessibilityLabel;

  /// Placeholder for the text field
  final String inputPlaceholder;

  /// Placeholder for the text field
  final String onlineText;

  /// Placeholder for the text field
  final String offlineText;

  /// Placeholder for the text field
  final String typingText;

  /// Status text shown when the host app reports the agent as busy via
  /// [ChatwootChat.presenceStatus]. The SDK itself has no "busy" signal.
  final String busyText;

  /// Header title shown before any agent has sent a message yet.
  final String defaultChatTitle;

  /// Accessibility label (hint) for the send button
  final String sendButtonAccessibilityLabel;

  /// Sticky banner shown over the message list whenever the active
  /// conversation's status is resolved. It disappears on its own the
  /// moment the status changes away from resolved (e.g. a new message
  /// reopens the ticket), since it always reflects the conversation's
  /// current status rather than being a one-off inserted chat message.
  final String conversationResolvedMessage;

  /// Sticky banner shown over the message list whenever the active
  /// conversation's status is snoozed and its `snoozed_until` timestamp
  /// parses, with `{date}` replaced by that timestamp formatted as
  /// `dd/MM/yyyy HH:mm`. Falls back to [conversationStatusSnoozed] when
  /// `snoozed_until` is missing or fails to parse, same tolerant-of-bad-data
  /// spirit as [conversationResolvedMessage]'s banner.
  final String conversationSnoozedMessage;

  /// Message when agent resolves conversation
  final String and;

  /// Message when agent resolves conversation
  final String isTyping;

  /// Message when agent resolves conversation
  final String others;

  /// Message when agent resolves conversation
  final String unreadMessagesLabel;

  /// Title for recent conversations list
  final String recentConversationsTitle;

  /// Label for start new conversation button
  final String startNewConversationText;

  /// Placeholder when there are no conversations
  final String noConversationsText;

  /// Label for open conversation status
  final String conversationStatusOpen;

  /// Label for resolved conversation status
  final String conversationStatusResolved;

  /// Label for pending conversation status
  final String conversationStatusPending;

  /// Label for snoozed conversation status
  final String conversationStatusSnoozed;

  /// Secondary caption shown for a snoozed conversation, with `{date}`
  /// replaced by its formatted `snoozed_until`. Only rendered when that
  /// timestamp is present and parses.
  final String snoozedUntilLabel;

  /// Tooltip for back button
  final String backButtonTooltip;

  /// Ticket number badge shown at the top-right of the chat header and on
  /// each row of the recent-conversations list, with `{id}` replaced by
  /// the conversation's numeric id.
  final String ticketBadgeLabel;

  /// Unused. Used to be inserted as a synthetic system message right after
  /// "Iniciar nova conversa" succeeded, with `{id}` replaced by the newly
  /// created conversation's numeric id. [ChatwootChat.onConversationCreated]
  /// (see `_ChatwootChatState` in chatwoot_chat_page.dart) no longer shows
  /// that notice -- a new conversation now starts genuinely empty. Kept for
  /// backwards compatibility with host apps that already set it.
  final String ticketOpenedMessage;

  /// Creates a new chatwoot l10n
  const ChatwootL10n(
      {this.attachmentButtonAccessibilityLabel = "",
      this.emptyChatPlaceholder = "",
      this.fileButtonAccessibilityLabel = "",
      this.onlineText = "Disponível",
      this.offlineText = "Estamos ausentes no momento",
      this.typingText = "digitando...",
      this.busyText = "Ocupado",
      this.defaultChatTitle = "Chat",
      this.inputPlaceholder = "Digite sua mensagem",
      this.sendButtonAccessibilityLabel = "Enviar mensagem",
      this.conversationResolvedMessage = "Essa conversa foi marcada como "
          "resolvida, mandar uma nova mensagem irá reabrir esse atendimento",
      this.conversationSnoozedMessage = "O ticket foi marcado como em "
          "espera, com prazo para retorno em: {date}",
      this.and = "e",
      this.isTyping = "está digitando...",
      this.others = "outros",
      this.unreadMessagesLabel = "Seu ticket foi marcado como resolvido",
      this.recentConversationsTitle = "Conversas recentes",
      this.startNewConversationText = "Iniciar nova conversa",
      this.noConversationsText = "Nenhuma conversa encontrada",
      this.conversationStatusOpen = "Aberto",
      this.conversationStatusResolved = "Resolvido",
      this.conversationStatusPending = "Pendente",
      this.conversationStatusSnoozed = "Em espera",
      this.snoozedUntilLabel = "Em espera até {date}",
      this.backButtonTooltip = "Voltar",
      this.ticketBadgeLabel = "Ticket #{id}",
      this.ticketOpenedMessage = "Ticket #{id} aberto"})
      : super(
            attachmentButtonAccessibilityLabel:
                attachmentButtonAccessibilityLabel,
            emptyChatPlaceholder: emptyChatPlaceholder,
            fileButtonAccessibilityLabel: fileButtonAccessibilityLabel,
            inputPlaceholder: inputPlaceholder,
            sendButtonAccessibilityLabel: sendButtonAccessibilityLabel,
            and: and,
            isTyping: isTyping,
            others: others,
            unreadMessagesLabel: unreadMessagesLabel);

  /// Returns a copy of this l10n with the given fields replaced.
  ChatwootL10n copyWith({
    String? attachmentButtonAccessibilityLabel,
    String? emptyChatPlaceholder,
    String? fileButtonAccessibilityLabel,
    String? inputPlaceholder,
    String? onlineText,
    String? offlineText,
    String? typingText,
    String? busyText,
    String? defaultChatTitle,
    String? sendButtonAccessibilityLabel,
    String? conversationResolvedMessage,
    String? conversationSnoozedMessage,
    String? and,
    String? isTyping,
    String? others,
    String? unreadMessagesLabel,
    String? recentConversationsTitle,
    String? startNewConversationText,
    String? noConversationsText,
    String? conversationStatusOpen,
    String? conversationStatusResolved,
    String? conversationStatusPending,
    String? conversationStatusSnoozed,
    String? snoozedUntilLabel,
    String? backButtonTooltip,
    String? ticketBadgeLabel,
    String? ticketOpenedMessage,
  }) {
    return ChatwootL10n(
      attachmentButtonAccessibilityLabel: attachmentButtonAccessibilityLabel ??
          this.attachmentButtonAccessibilityLabel,
      emptyChatPlaceholder: emptyChatPlaceholder ?? this.emptyChatPlaceholder,
      fileButtonAccessibilityLabel:
          fileButtonAccessibilityLabel ?? this.fileButtonAccessibilityLabel,
      inputPlaceholder: inputPlaceholder ?? this.inputPlaceholder,
      onlineText: onlineText ?? this.onlineText,
      offlineText: offlineText ?? this.offlineText,
      typingText: typingText ?? this.typingText,
      busyText: busyText ?? this.busyText,
      defaultChatTitle: defaultChatTitle ?? this.defaultChatTitle,
      sendButtonAccessibilityLabel:
          sendButtonAccessibilityLabel ?? this.sendButtonAccessibilityLabel,
      conversationResolvedMessage:
          conversationResolvedMessage ?? this.conversationResolvedMessage,
      conversationSnoozedMessage:
          conversationSnoozedMessage ?? this.conversationSnoozedMessage,
      and: and ?? this.and,
      isTyping: isTyping ?? this.isTyping,
      others: others ?? this.others,
      unreadMessagesLabel: unreadMessagesLabel ?? this.unreadMessagesLabel,
      recentConversationsTitle:
          recentConversationsTitle ?? this.recentConversationsTitle,
      startNewConversationText:
          startNewConversationText ?? this.startNewConversationText,
      noConversationsText: noConversationsText ?? this.noConversationsText,
      conversationStatusOpen:
          conversationStatusOpen ?? this.conversationStatusOpen,
      conversationStatusResolved:
          conversationStatusResolved ?? this.conversationStatusResolved,
      conversationStatusPending:
          conversationStatusPending ?? this.conversationStatusPending,
      conversationStatusSnoozed:
          conversationStatusSnoozed ?? this.conversationStatusSnoozed,
      snoozedUntilLabel: snoozedUntilLabel ?? this.snoozedUntilLabel,
      backButtonTooltip: backButtonTooltip ?? this.backButtonTooltip,
      ticketBadgeLabel: ticketBadgeLabel ?? this.ticketBadgeLabel,
      ticketOpenedMessage: ticketOpenedMessage ?? this.ticketOpenedMessage,
    );
  }
}
