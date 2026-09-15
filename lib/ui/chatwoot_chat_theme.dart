import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:path/path.dart' as p;

/// Sent message bubble / accent color, tuned to read as a WhatsApp-style
/// light green bubble instead of the previous flat brand blue.
const CHATWOOT_COLOR_PRIMARY = Color(0xffD9FDD3);
const CHATWOOT_BG_COLOR = Color(0xffECE5DD);
const CHATWOOT_AVATAR_COLORS = [CHATWOOT_COLOR_PRIMARY];
const NEUTRAL_2 = Colors.grey;
const NEUTRAL_0 = Colors.black26;
const NEUTRAL_7 = Colors.black;
const NEUTRAL_7_WITH_OPACITY = Colors.black54;
const PRIMARY = CHATWOOT_COLOR_PRIMARY;

/// Chat page header (app bar) background, matching WhatsApp's header teal.
const CHATWOOT_HEADER_COLOR = Color(0xff008069);

/// Foreground (title/icon) color used on top of [CHATWOOT_HEADER_COLOR].
const CHATWOOT_HEADER_FOREGROUND_COLOR = Colors.white;

/// Sent message body text color, tuned for contrast on the light green
/// [CHATWOOT_COLOR_PRIMARY] bubble.
const CHATWOOT_SENT_MESSAGE_TEXT_COLOR = Color(0xff111B21);

/// Received message body text color -- matches [ChatTheme]'s own historical
/// default so introducing [ChatwootChatTheme.receivedMessageBodyTextStyle]
/// as a named constant here doesn't change anything by default.
const CHATWOOT_RECEIVED_MESSAGE_TEXT_COLOR = Colors.black87;

const CHATWOOT_SENT_MESSAGE_BODY_TEXT_STYLE = TextStyle(
  color: CHATWOOT_SENT_MESSAGE_TEXT_COLOR,
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.5,
);

const CHATWOOT_RECEIVED_MESSAGE_BODY_TEXT_STYLE = TextStyle(
  color: CHATWOOT_RECEIVED_MESSAGE_TEXT_COLOR,
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.5,
);

/// Recent-conversations list colors -- title, subtitle (last message
/// preview), timestamp/chevron/snoozed-caption, row divider, and the empty
/// state's icon/text. Each matches the literal [Colors.*] value
/// [ChatwootRecentConversations] used before these existed, so introducing
/// them doesn't change anything by default.
const CHATWOOT_LIST_TITLE_COLOR = Colors.black87;
const CHATWOOT_LIST_SUBTITLE_COLOR = Color(0xFF616161); // Colors.grey.shade700
const CHATWOOT_LIST_TIMESTAMP_COLOR = Color(0xFF757575); // Colors.grey.shade600
const CHATWOOT_LIST_DIVIDER_COLOR =
    Color(0x269E9E9E); // Colors.grey @ 15% alpha
const CHATWOOT_LIST_EMPTY_ICON_COLOR =
    Color(0xFFE0E0E0); // Colors.grey.shade300
const CHATWOOT_LIST_EMPTY_TEXT_COLOR =
    Color(0xFF757575); // Colors.grey.shade600

/// Default chatwoot chat theme which extends [ChatTheme]
@immutable
class ChatwootChatTheme extends ChatTheme {
  /// Background color of the chat page header (app bar).
  final Color headerColor;

  /// Color of the title/icons shown on top of [headerColor].
  final Color headerForegroundColor;

  /// Text style for the small status line shown under the header title
  /// (e.g. online/offline state).
  final TextStyle headerSubtitleTextStyle;

  /// Chat wallpaper image, drawn full-bleed behind the message list.
  /// Resolved by [chatwootImageProvider] into one of three
  /// [ImageProvider]s, based on the shape of the string:
  ///
  /// - `http://` or `https://` maps to [NetworkImage].
  /// - An absolute filesystem path (e.g. `/data/.../file.png` or
  ///   `C:\Users\...\file.png`) maps to [FileImage], read straight off disk.
  ///   Missing/unreadable file falls back to null (flat [backgroundColor]
  ///   fill) instead of crashing the chat page.
  /// - Anything else (e.g. `assets/images/chat_wallpaper.png`) is treated
  ///   as a **relative path**, resolved as a Flutter asset via
  ///   [AssetImage] -- the common case for a path coming from inside the
  ///   host app itself, which must also declare it under `assets:` in its
  ///   own `pubspec.yaml`. This never touches the filesystem directly, so
  ///   there is nothing to check for existence up front; an unregistered
  ///   asset fails when the image is actually painted, same as any other
  ///   broken [ImageProvider].
  ///
  /// Null or empty keeps a flat [backgroundColor] fill, as before.
  ///
  /// This is host-app configuration, not end-user input: set it to a value
  /// your app controls (a bundled asset path, an absolute path, or a URL
  /// you trust). Never bind it to untrusted or remote data -- a URL is
  /// fetched with no allowlist, and a filesystem path is read with no
  /// sandboxing beyond the OS's own app-storage restrictions.
  final String? backgroundImageSource;

  /// Fixed avatar image used everywhere a person's picture would otherwise
  /// show: the header (replacing the real agent's photo/initial-bubble
  /// icon) and every received message bubble (replacing each agent's own
  /// photo/initials). Resolved by [chatwootImageProvider] with the same
  /// URL / absolute-path / asset-relative-path rules as
  /// [backgroundImageSource] -- see that field's doc for the exact rules.
  ///
  /// Null (the default) keeps the real per-agent avatar wherever the SDK
  /// has one, falling back to initials/an icon when it doesn't -- the
  /// behavior before this field existed. Set this when the host app wants
  /// one consistent picture (e.g. a support/brand icon) instead of
  /// individual agent photos.
  final String? avatarImageSource;

  /// Title color for each row of [ChatwootRecentConversations] (the
  /// ticket/conversation label).
  final Color listTitleColor;

  /// Subtitle color for each row of [ChatwootRecentConversations] (the
  /// last-message preview).
  final Color listSubtitleColor;

  /// Muted secondary text color used for [ChatwootRecentConversations]:
  /// the per-row timestamp, its chevron affordance, and the snoozed-until
  /// caption.
  final Color listTimestampColor;

  /// Divider color between rows of [ChatwootRecentConversations].
  final Color listDividerColor;

  /// Icon color for [ChatwootRecentConversations]'s empty state.
  final Color listEmptyIconColor;

  /// Text color for [ChatwootRecentConversations]'s empty state.
  final Color listEmptyTextColor;

  /// Creates a chatwoot chat theme. Use this constructor if you want to
  /// override only a couple of variables.
  const ChatwootChatTheme({
    this.headerColor = CHATWOOT_HEADER_COLOR,
    this.headerForegroundColor = CHATWOOT_HEADER_FOREGROUND_COLOR,
    this.headerSubtitleTextStyle = const TextStyle(
      color: Colors.white70,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
    this.backgroundImageSource,
    this.avatarImageSource,
    this.listTitleColor = CHATWOOT_LIST_TITLE_COLOR,
    this.listSubtitleColor = CHATWOOT_LIST_SUBTITLE_COLOR,
    this.listTimestampColor = CHATWOOT_LIST_TIMESTAMP_COLOR,
    this.listDividerColor = CHATWOOT_LIST_DIVIDER_COLOR,
    this.listEmptyIconColor = CHATWOOT_LIST_EMPTY_ICON_COLOR,
    this.listEmptyTextColor = CHATWOOT_LIST_EMPTY_TEXT_COLOR,
    Widget? attachmentButtonIcon,
    Color backgroundColor = CHATWOOT_BG_COLOR,
    TextStyle dateDividerTextStyle = const TextStyle(
      color: Colors.black26,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.333,
    ),
    Widget? deliveredIcon,
    Widget? documentIcon,
    TextStyle emptyChatPlaceholderTextStyle = const TextStyle(
      color: NEUTRAL_2,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    Color errorColor = Colors.red,
    Widget? errorIcon,
    Color inputBackgroundColor = Colors.white,
    BorderRadius inputBorderRadius = const BorderRadius.all(
      Radius.circular(24),
    ),
    Color inputTextColor = Colors.black87,
    TextStyle inputTextStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    double messageBorderRadius = 12.0,
    Color primaryColor = CHATWOOT_COLOR_PRIMARY,
    TextStyle receivedMessageBodyTextStyle =
        CHATWOOT_RECEIVED_MESSAGE_BODY_TEXT_STYLE,
    TextStyle receivedMessageCaptionTextStyle = const TextStyle(
      color: NEUTRAL_2,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.333,
    ),
    Color receivedMessageDocumentIconColor = CHATWOOT_HEADER_COLOR,
    TextStyle receivedMessageLinkDescriptionTextStyle = const TextStyle(
      color: NEUTRAL_0,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.428,
    ),
    TextStyle receivedMessageLinkTitleTextStyle = const TextStyle(
      color: NEUTRAL_0,
      fontSize: 16,
      fontWeight: FontWeight.w800,
      height: 1.375,
    ),
    Color secondaryColor = Colors.white,
    Widget? seenIcon,
    Widget? sendButtonIcon,
    Widget? sendingIcon,
    TextStyle sentMessageBodyTextStyle = CHATWOOT_SENT_MESSAGE_BODY_TEXT_STYLE,
    TextStyle sentMessageCaptionTextStyle = const TextStyle(
      color: NEUTRAL_7_WITH_OPACITY,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.333,
    ),
    Color sentMessageDocumentIconColor = NEUTRAL_7,
    TextStyle sentMessageLinkDescriptionTextStyle = const TextStyle(
      color: NEUTRAL_7,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.428,
    ),
    TextStyle sentMessageLinkTitleTextStyle = const TextStyle(
      color: NEUTRAL_7,
      fontSize: 16,
      fontWeight: FontWeight.w800,
      height: 1.375,
    ),
    List<Color> userAvatarNameColors = CHATWOOT_AVATAR_COLORS,
    TextStyle userAvatarTextStyle = const TextStyle(
      color: NEUTRAL_7,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.333,
    ),
    TextStyle userNameTextStyle = const TextStyle(
      color: Colors.black87,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.333,
    ),
    EdgeInsets? attachmentButtonMargin,
    EdgeInsets dateDividerMargin = const EdgeInsets.all(8),
    Color inputSurfaceTintColor = Colors.blueAccent,
    double inputElevation = 0,
    EdgeInsets inputMargin = const EdgeInsets.all(8),
    EdgeInsets inputPadding = const EdgeInsets.all(8),
    InputDecoration inputTextDecoration = const InputDecoration(),
    double messageInsetsHorizontal = 8,
    double messageInsetsVertical = 8,
    double messageMaxWidth = 500,
    TextStyle receivedEmojiMessageTextStyle = const TextStyle(),
    EdgeInsets sendButtonMargin = const EdgeInsets.all(8),
    TextStyle sentEmojiMessageTextStyle = const TextStyle(),
    EdgeInsets statusIconPadding = const EdgeInsets.all(8),
    SystemMessageTheme systemMessageTheme = const SystemMessageTheme(
        margin: const EdgeInsets.all(8), textStyle: const TextStyle()),
    TypingIndicatorTheme typingIndicatorTheme = const TypingIndicatorTheme(
        animatedCirclesColor: CHATWOOT_COLOR_PRIMARY,
        animatedCircleSize: 8,
        bubbleBorder: const BorderRadius.all(const Radius.circular(8)),
        bubbleColor: CHATWOOT_COLOR_PRIMARY,
        countAvatarColor: CHATWOOT_COLOR_PRIMARY,
        countTextColor: NEUTRAL_7,
        multipleUserTextStyle: const TextStyle()),
    UnreadHeaderTheme unreadHeaderTheme = const UnreadHeaderTheme(
        color: CHATWOOT_COLOR_PRIMARY, textStyle: const TextStyle()),
    Color userAvatarImageBackgroundColor = Colors.grey,
  }) : super(
          attachmentButtonIcon: attachmentButtonIcon,
          backgroundColor: backgroundColor,
          dateDividerTextStyle: dateDividerTextStyle,
          deliveredIcon: deliveredIcon,
          documentIcon: documentIcon,
          emptyChatPlaceholderTextStyle: emptyChatPlaceholderTextStyle,
          errorColor: errorColor,
          errorIcon: errorIcon,
          inputBackgroundColor: inputBackgroundColor,
          inputBorderRadius: inputBorderRadius,
          inputTextColor: inputTextColor,
          inputTextStyle: inputTextStyle,
          messageBorderRadius: messageBorderRadius,
          primaryColor: primaryColor,
          receivedMessageBodyTextStyle: receivedMessageBodyTextStyle,
          receivedMessageCaptionTextStyle: receivedMessageCaptionTextStyle,
          receivedMessageDocumentIconColor: receivedMessageDocumentIconColor,
          receivedMessageLinkDescriptionTextStyle:
              receivedMessageLinkDescriptionTextStyle,
          receivedMessageLinkTitleTextStyle: receivedMessageLinkTitleTextStyle,
          secondaryColor: secondaryColor,
          seenIcon: seenIcon,
          sendButtonIcon: sendButtonIcon,
          sendingIcon: sendingIcon,
          sentMessageBodyTextStyle: sentMessageBodyTextStyle,
          sentMessageCaptionTextStyle: sentMessageCaptionTextStyle,
          sentMessageDocumentIconColor: sentMessageDocumentIconColor,
          sentMessageLinkDescriptionTextStyle:
              sentMessageLinkDescriptionTextStyle,
          sentMessageLinkTitleTextStyle: sentMessageLinkTitleTextStyle,
          userAvatarNameColors: userAvatarNameColors,
          userAvatarTextStyle: userAvatarTextStyle,
          userNameTextStyle: userNameTextStyle,
          attachmentButtonMargin: attachmentButtonMargin,
          dateDividerMargin: dateDividerMargin,
          inputSurfaceTintColor: inputSurfaceTintColor,
          inputElevation: inputElevation,
          inputMargin: inputMargin,
          inputPadding: inputPadding,
          inputTextDecoration: inputTextDecoration,
          messageInsetsHorizontal: messageInsetsHorizontal,
          messageInsetsVertical: messageInsetsVertical,
          messageMaxWidth: messageMaxWidth,
          receivedEmojiMessageTextStyle: receivedEmojiMessageTextStyle,
          sendButtonMargin: sendButtonMargin,
          sentEmojiMessageTextStyle: sentEmojiMessageTextStyle,
          statusIconPadding: statusIconPadding,
          systemMessageTheme: systemMessageTheme,
          typingIndicatorTheme: typingIndicatorTheme,
          unreadHeaderTheme: unreadHeaderTheme,
          userAvatarImageBackgroundColor: userAvatarImageBackgroundColor,
        );

  /// Returns a copy of this theme with the given fields replaced.
  ChatwootChatTheme copyWith({
    Color? headerColor,
    Color? headerForegroundColor,
    TextStyle? headerSubtitleTextStyle,
    String? backgroundImageSource,
    String? avatarImageSource,
    Color? listTitleColor,
    Color? listSubtitleColor,
    Color? listTimestampColor,
    Color? listDividerColor,
    Color? listEmptyIconColor,
    Color? listEmptyTextColor,
    Widget? attachmentButtonIcon,
    Color? backgroundColor,
    TextStyle? dateDividerTextStyle,
    Widget? deliveredIcon,
    Widget? documentIcon,
    TextStyle? emptyChatPlaceholderTextStyle,
    Color? errorColor,
    Widget? errorIcon,
    Color? inputBackgroundColor,
    BorderRadius? inputBorderRadius,
    Color? inputTextColor,
    TextStyle? inputTextStyle,
    double? messageBorderRadius,
    Color? primaryColor,
    TextStyle? receivedMessageBodyTextStyle,
    TextStyle? receivedMessageCaptionTextStyle,
    Color? receivedMessageDocumentIconColor,
    TextStyle? receivedMessageLinkDescriptionTextStyle,
    TextStyle? receivedMessageLinkTitleTextStyle,
    Color? secondaryColor,
    Widget? seenIcon,
    Widget? sendButtonIcon,
    Widget? sendingIcon,
    TextStyle? sentMessageBodyTextStyle,
    TextStyle? sentMessageCaptionTextStyle,
    Color? sentMessageDocumentIconColor,
    TextStyle? sentMessageLinkDescriptionTextStyle,
    TextStyle? sentMessageLinkTitleTextStyle,
    List<Color>? userAvatarNameColors,
    TextStyle? userAvatarTextStyle,
    TextStyle? userNameTextStyle,
    EdgeInsets? attachmentButtonMargin,
    EdgeInsets? dateDividerMargin,
    Color? inputSurfaceTintColor,
    double? inputElevation,
    EdgeInsets? inputMargin,
    EdgeInsets? inputPadding,
    InputDecoration? inputTextDecoration,
    double? messageInsetsHorizontal,
    double? messageInsetsVertical,
    double? messageMaxWidth,
    TextStyle? receivedEmojiMessageTextStyle,
    EdgeInsets? sendButtonMargin,
    TextStyle? sentEmojiMessageTextStyle,
    EdgeInsets? statusIconPadding,
    SystemMessageTheme? systemMessageTheme,
    TypingIndicatorTheme? typingIndicatorTheme,
    UnreadHeaderTheme? unreadHeaderTheme,
    Color? userAvatarImageBackgroundColor,
  }) {
    return ChatwootChatTheme(
      headerColor: headerColor ?? this.headerColor,
      headerForegroundColor:
          headerForegroundColor ?? this.headerForegroundColor,
      headerSubtitleTextStyle:
          headerSubtitleTextStyle ?? this.headerSubtitleTextStyle,
      backgroundImageSource:
          backgroundImageSource ?? this.backgroundImageSource,
      avatarImageSource: avatarImageSource ?? this.avatarImageSource,
      listTitleColor: listTitleColor ?? this.listTitleColor,
      listSubtitleColor: listSubtitleColor ?? this.listSubtitleColor,
      listTimestampColor: listTimestampColor ?? this.listTimestampColor,
      listDividerColor: listDividerColor ?? this.listDividerColor,
      listEmptyIconColor: listEmptyIconColor ?? this.listEmptyIconColor,
      listEmptyTextColor: listEmptyTextColor ?? this.listEmptyTextColor,
      attachmentButtonIcon: attachmentButtonIcon ?? this.attachmentButtonIcon,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      dateDividerTextStyle: dateDividerTextStyle ?? this.dateDividerTextStyle,
      deliveredIcon: deliveredIcon ?? this.deliveredIcon,
      documentIcon: documentIcon ?? this.documentIcon,
      emptyChatPlaceholderTextStyle:
          emptyChatPlaceholderTextStyle ?? this.emptyChatPlaceholderTextStyle,
      errorColor: errorColor ?? this.errorColor,
      errorIcon: errorIcon ?? this.errorIcon,
      inputBackgroundColor: inputBackgroundColor ?? this.inputBackgroundColor,
      inputBorderRadius: inputBorderRadius ?? this.inputBorderRadius,
      inputTextColor: inputTextColor ?? this.inputTextColor,
      inputTextStyle: inputTextStyle ?? this.inputTextStyle,
      messageBorderRadius: messageBorderRadius ?? this.messageBorderRadius,
      primaryColor: primaryColor ?? this.primaryColor,
      receivedMessageBodyTextStyle:
          receivedMessageBodyTextStyle ?? this.receivedMessageBodyTextStyle,
      receivedMessageCaptionTextStyle: receivedMessageCaptionTextStyle ??
          this.receivedMessageCaptionTextStyle,
      receivedMessageDocumentIconColor: receivedMessageDocumentIconColor ??
          this.receivedMessageDocumentIconColor,
      receivedMessageLinkDescriptionTextStyle:
          receivedMessageLinkDescriptionTextStyle ??
              this.receivedMessageLinkDescriptionTextStyle,
      receivedMessageLinkTitleTextStyle: receivedMessageLinkTitleTextStyle ??
          this.receivedMessageLinkTitleTextStyle,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      seenIcon: seenIcon ?? this.seenIcon,
      sendButtonIcon: sendButtonIcon ?? this.sendButtonIcon,
      sendingIcon: sendingIcon ?? this.sendingIcon,
      sentMessageBodyTextStyle:
          sentMessageBodyTextStyle ?? this.sentMessageBodyTextStyle,
      sentMessageCaptionTextStyle:
          sentMessageCaptionTextStyle ?? this.sentMessageCaptionTextStyle,
      sentMessageDocumentIconColor:
          sentMessageDocumentIconColor ?? this.sentMessageDocumentIconColor,
      sentMessageLinkDescriptionTextStyle:
          sentMessageLinkDescriptionTextStyle ??
              this.sentMessageLinkDescriptionTextStyle,
      sentMessageLinkTitleTextStyle:
          sentMessageLinkTitleTextStyle ?? this.sentMessageLinkTitleTextStyle,
      userAvatarNameColors: userAvatarNameColors ?? this.userAvatarNameColors,
      userAvatarTextStyle: userAvatarTextStyle ?? this.userAvatarTextStyle,
      userNameTextStyle: userNameTextStyle ?? this.userNameTextStyle,
      attachmentButtonMargin:
          attachmentButtonMargin ?? this.attachmentButtonMargin,
      dateDividerMargin: dateDividerMargin ?? this.dateDividerMargin,
      inputSurfaceTintColor:
          inputSurfaceTintColor ?? this.inputSurfaceTintColor,
      inputElevation: inputElevation ?? this.inputElevation,
      inputMargin: inputMargin ?? this.inputMargin,
      inputPadding: inputPadding ?? this.inputPadding,
      inputTextDecoration: inputTextDecoration ?? this.inputTextDecoration,
      messageInsetsHorizontal:
          messageInsetsHorizontal ?? this.messageInsetsHorizontal,
      messageInsetsVertical:
          messageInsetsVertical ?? this.messageInsetsVertical,
      messageMaxWidth: messageMaxWidth ?? this.messageMaxWidth,
      receivedEmojiMessageTextStyle:
          receivedEmojiMessageTextStyle ?? this.receivedEmojiMessageTextStyle,
      sendButtonMargin:
          sendButtonMargin ?? this.sendButtonMargin ?? const EdgeInsets.all(8),
      sentEmojiMessageTextStyle:
          sentEmojiMessageTextStyle ?? this.sentEmojiMessageTextStyle,
      statusIconPadding: statusIconPadding ?? this.statusIconPadding,
      systemMessageTheme: systemMessageTheme ?? this.systemMessageTheme,
      typingIndicatorTheme: typingIndicatorTheme ?? this.typingIndicatorTheme,
      unreadHeaderTheme: unreadHeaderTheme ?? this.unreadHeaderTheme,
      userAvatarImageBackgroundColor:
          userAvatarImageBackgroundColor ?? this.userAvatarImageBackgroundColor,
    );
  }
}

/// Resolves a [ChatwootChatTheme.backgroundImageSource] or
/// [ChatwootChatTheme.avatarImageSource] into an [ImageProvider]. See
/// either field's doc for the exact rules; in short: an `http(s)://` value
/// loads as a [NetworkImage], an absolute filesystem path loads as a
/// [FileImage] (or null if missing), and anything else -- a relative path
/// -- loads as a Flutter [AssetImage] bundled by the host app. Returns
/// null for a null/empty source.
ImageProvider? chatwootImageProvider(String? source) {
  if (source == null || source.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(source);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return NetworkImage(source);
  }
  if (!p.isAbsolute(source)) {
    // Not a URL and not an absolute filesystem path: assume it's a
    // relative path to an asset the host app declared under `assets:` in
    // its own pubspec.yaml (e.g. `assets/images/chat_wallpaper.png`) --
    // the common case for a path "coming from inside the project", as
    // opposed to one pointing at the device's filesystem.
    return AssetImage(source);
  }
  final file = File(source);
  // A typo'd or not-yet-downloaded local path is common enough that it
  // shouldn't crash the chat page: fall back to the flat backgroundColor.
  if (!file.existsSync()) {
    return null;
  }
  return FileImage(file);
}
