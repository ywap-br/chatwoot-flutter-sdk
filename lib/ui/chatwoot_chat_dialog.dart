import 'package:chatwoot_sdk/data/local/entity/chatwoot_user.dart';
import 'package:chatwoot_sdk/ui/chatwoot_chat_theme.dart';
import 'package:chatwoot_sdk/ui/chatwoot_l10n.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'chatwoot_chat_page.dart';

///Chatwoot chat modal widget
/// {@category FlutterClientSdk}
class ChatwootChatDialog extends StatefulWidget {
  static show(
    BuildContext context, {
    required String baseUrl,
    required String inboxIdentifier,
    bool enablePersistence = true,
    required String title,
    ChatwootUser? user,
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? headerColor,
    Color? headerForegroundColor,
    String? backgroundImageSource,
    String? avatarImageSource,
    ChatwootL10n? l10n,
    DateFormat? timeFormat,
    DateFormat? dateFormat,
    bool showConversationHistory = true,
  }) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ChatwootChatDialog(
          baseUrl: baseUrl,
          inboxIdentifier: inboxIdentifier,
          title: title,
          user: user,
          enablePersistence: enablePersistence,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          backgroundColor: backgroundColor,
          headerColor: headerColor,
          headerForegroundColor: headerForegroundColor,
          backgroundImageSource: backgroundImageSource,
          avatarImageSource: avatarImageSource,
          l10n: l10n,
          timeFormat: timeFormat,
          dateFormat: dateFormat,
          showConversationHistory: showConversationHistory,
        ),
      ),
    );
  }

  ///Installation url for chatwoot
  final String baseUrl;

  ///Identifier for target chatwoot inbox.
  ///
  /// For more details see https://www.chatwoot.com/docs/product/channels/api/client-apis
  final String inboxIdentifier;

  /// Enables persistence of chatwoot client instance's contact, conversation and messages to disk
  /// for convenience.
  ///
  /// Setting [enablePersistence] to false holds chatwoot client instance's data in memory and is cleared as
  /// soon as chatwoot client instance is disposed
  final bool enablePersistence;

  /// Custom user details to be attached to chatwoot contact
  final ChatwootUser? user;

  /// Primary color for [ChatwootChatTheme]
  final Color? primaryColor;

  /// Secondary color for [ChatwootChatTheme]
  final Color? secondaryColor;

  /// Secondary color for [ChatwootChatTheme]
  final Color? backgroundColor;

  /// Header (app bar) background for [ChatwootChatTheme]. Defaults to
  /// [primaryColor] when unset, matching the color the header used before
  /// [ChatwootChatTheme.headerColor] existed.
  final Color? headerColor;

  /// Header (app bar) title/icon color for [ChatwootChatTheme].
  final Color? headerForegroundColor;

  /// Chat wallpaper for [ChatwootChatTheme.backgroundImageSource]. See that
  /// field for how a URL vs. an absolute vs. a relative (asset) path is
  /// resolved, and for the trust assumptions on this value.
  final String? backgroundImageSource;

  /// Fixed avatar for [ChatwootChatTheme.avatarImageSource], shown in the
  /// header and on every received message instead of each agent's own
  /// photo/initials. See that field for how a URL vs. an absolute vs. a
  /// relative (asset) path is resolved.
  final String? avatarImageSource;

  /// Fixed title shown in the chat header instead of the agent's real
  /// name, and as the recent-conversations screen title.
  final String title;

  /// See [ChatwootL10n]
  final ChatwootL10n? l10n;

  /// See [Chat.timeFormat]
  final DateFormat? timeFormat;

  /// See [Chat.dateFormat]
  final DateFormat? dateFormat;

  /// Whether to show recent conversations history list before opening chat
  final bool showConversationHistory;

  const ChatwootChatDialog({
    Key? key,
    required this.baseUrl,
    required this.inboxIdentifier,
    this.enablePersistence = true,
    required this.title,
    this.user,
    this.primaryColor,
    this.secondaryColor,
    this.backgroundColor,
    this.headerColor,
    this.headerForegroundColor,
    this.backgroundImageSource,
    this.avatarImageSource,
    this.l10n,
    this.timeFormat,
    this.dateFormat,
    this.showConversationHistory = true,
  }) : super(key: key);

  @override
  _ChatwootChatDialogState createState() => _ChatwootChatDialogState();
}

class _ChatwootChatDialogState extends State<ChatwootChatDialog> {
  @override
  Widget build(BuildContext context) {
    // ChatwootChat already renders a full page (header, wallpaper, input)
    // on its own, so this wrapper just needs to hand it the dialog's
    // color/l10n overrides and make sure `widget.title` always drives the
    // chat header title: it is the fixed name shown there (never the real
    // agent's name), and it also names the recent-conversations screen
    // when the host does not supply its own l10n.
    final baseL10n =
        widget.l10n ?? ChatwootL10n(recentConversationsTitle: widget.title);
    final l10n = baseL10n.copyWith(defaultChatTitle: widget.title);
    return ChatwootChat(
      baseUrl: widget.baseUrl,
      inboxIdentifier: widget.inboxIdentifier,
      user: widget.user,
      enablePersistence: widget.enablePersistence,
      timeFormat: widget.timeFormat,
      dateFormat: widget.dateFormat,
      showConversationHistory: widget.showConversationHistory,
      l10n: l10n,
      theme: ChatwootChatTheme(
          primaryColor: widget.primaryColor ?? CHATWOOT_COLOR_PRIMARY,
          secondaryColor: widget.secondaryColor ?? Colors.white,
          backgroundColor: widget.backgroundColor ?? CHATWOOT_BG_COLOR,
          headerColor: widget.headerColor ??
              widget.primaryColor ??
              CHATWOOT_HEADER_COLOR,
          headerForegroundColor:
              widget.headerForegroundColor ?? CHATWOOT_HEADER_FOREGROUND_COLOR,
          backgroundImageSource: widget.backgroundImageSource,
          avatarImageSource: widget.avatarImageSource,
          userAvatarNameColors: [
            widget.primaryColor ?? CHATWOOT_COLOR_PRIMARY
          ]),
    );
  }
}
