import 'package:chatwoot_sdk/chatwoot_callbacks.dart';
import 'package:chatwoot_sdk/chatwoot_client.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_conversation.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_message.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_user.dart';
import 'package:chatwoot_sdk/data/remote/chatwoot_client_exception.dart';
import 'package:chatwoot_sdk/ui/chatwoot_chat_theme.dart';
import 'package:chatwoot_sdk/ui/chatwoot_l10n.dart';
import 'package:chatwoot_sdk/ui/chatwoot_recent_conversations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Presence status shown in the chat header subtitle.
///
/// [ChatwootChat] derives [online]/[offline] on its own from the real-time
/// presence events the SDK already receives. [busy] has no equivalent
/// signal in the SDK today, so it is only ever shown when the host app
/// supplies it explicitly via [ChatwootChat.presenceStatus].
enum ChatwootPresenceStatus { online, busy, offline }

/// Metadata key marking a locally-synthesized message (e.g. the "resolved"
/// notice) so it never gets mistaken for a real agent identity.
const _kIsSystemMessageKey = 'chatwootIsSystemMessage';

///Chatwoot chat widget
/// {@category FlutterClientSdk}
class ChatwootChat extends StatefulWidget {
  /// Specifies a custom app bar for chatwoot page widget
  final PreferredSizeWidget? appBar;

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

  /// See [ChatList.onEndReached]
  final Future<void> Function()? onEndReached;

  /// See [ChatList.onEndReachedThreshold]
  final double? onEndReachedThreshold;

  /// See [Message.onMessageLongPress]
  final void Function(BuildContext context, types.Message)? onMessageLongPress;

  /// See [Message.onMessageTap]
  final void Function(types.Message)? onMessageTap;

  /// See [Input.onSendPressed]
  final void Function(types.PartialText)? onSendPressed;

  /// Show avatars for received messages.
  final bool showUserAvatars;

  /// Show user names for received messages. Defaults to false: like a
  /// WhatsApp 1:1 conversation, the agent's identity is already shown once
  /// in the page header, so repeating it on every message is redundant.
  final bool showUserNames;

  /// Whether received messages show each agent's own real name/avatar.
  ///
  /// Defaults to `true`, which leaves [showUserNames] and the per-message
  /// avatar exactly as configured elsewhere (no visible change from before
  /// this field existed) -- [ChatwootChatTheme.avatarImageSource] only
  /// drives the header avatar in that case.
  ///
  /// Set to `false` to hide the agent's name on every received message
  /// (regardless of [showUserNames]) and force every received message's
  /// avatar to [ChatwootChatTheme.avatarImageSource] -- the same fixed
  /// picture already shown in the header -- instead of each agent's own
  /// photo/initials.
  final bool showAgentIdentity;

  final ChatwootChatTheme? theme;

  /// Overrides the online/busy/offline status shown under the header title.
  ///
  /// When null (the default), [ChatwootChat] shows the real online/offline
  /// state it receives from the Chatwoot websocket presence events. Set
  /// this when your app has its own richer agent-availability signal (for
  /// example a "busy" status the SDK cannot derive on its own).
  final ChatwootPresenceStatus? presenceStatus;

  /// See [ChatwootL10n]
  final ChatwootL10n l10n;

  /// See [Chat.timeFormat]
  final DateFormat? timeFormat;

  /// See [Chat.dateFormat]
  final DateFormat? dateFormat;

  ///See [ChatwootCallbacks.onWelcome]
  final void Function()? onWelcome;

  ///See [ChatwootCallbacks.onPing]
  final void Function()? onPing;

  ///See [ChatwootCallbacks.onConfirmedSubscription]
  final void Function()? onConfirmedSubscription;

  ///See [ChatwootCallbacks.onConversationStartedTyping]
  final void Function()? onConversationStartedTyping;

  ///See [ChatwootCallbacks.onConversationIsOnline]
  final void Function()? onConversationIsOnline;

  ///See [ChatwootCallbacks.onConversationIsOffline]
  final void Function()? onConversationIsOffline;

  ///See [ChatwootCallbacks.onConversationStoppedTyping]
  final void Function()? onConversationStoppedTyping;

  ///See [ChatwootCallbacks.onMessageReceived]
  final void Function(ChatwootMessage)? onMessageReceived;

  ///See [ChatwootCallbacks.onMessageSent]
  final void Function(ChatwootMessage)? onMessageSent;

  ///See [ChatwootCallbacks.onMessageDelivered]
  final void Function(ChatwootMessage)? onMessageDelivered;

  ///See [ChatwootCallbacks.onMessageUpdated]
  final void Function(ChatwootMessage)? onMessageUpdated;

  ///See [ChatwootCallbacks.onPersistedMessagesRetrieved]
  final void Function(List<ChatwootMessage>)? onPersistedMessagesRetrieved;

  ///See [ChatwootCallbacks.onMessagesRetrieved]
  final void Function(List<ChatwootMessage>)? onMessagesRetrieved;

  ///See [ChatwootCallbacks.onError]
  final void Function(ChatwootClientException)? onError;

  ///Horizontal padding is reduced if set to true
  final bool isPresentedInDialog;

  /// Whether to show the recent conversations history list before opening chat
  final bool showConversationHistory;

  /// Triggered when conversations are retrieved
  final void Function(List<ChatwootConversation>)? onConversationsRetrieved;

  /// Triggered when a new conversation is created
  final void Function(ChatwootConversation)? onConversationCreated;

  const ChatwootChat(
      {Key? key,
      required this.baseUrl,
      required this.inboxIdentifier,
      this.enablePersistence = true,
      this.user,
      this.appBar,
      this.onEndReached,
      this.onEndReachedThreshold,
      this.onMessageLongPress,
      this.onMessageTap,
      this.onSendPressed,
      this.showUserAvatars = true,
      this.showUserNames = false,
      this.showAgentIdentity = true,
      this.theme,
      this.presenceStatus,
      this.l10n = const ChatwootL10n(),
      this.timeFormat,
      this.dateFormat,
      this.onWelcome,
      this.onPing,
      this.onConfirmedSubscription,
      this.onMessageReceived,
      this.onMessageSent,
      this.onMessageDelivered,
      this.onMessageUpdated,
      this.onPersistedMessagesRetrieved,
      this.onMessagesRetrieved,
      this.onConversationsRetrieved,
      this.onConversationCreated,
      this.onConversationStartedTyping,
      this.onConversationStoppedTyping,
      this.onConversationIsOnline,
      this.onConversationIsOffline,
      this.onError,
      this.isPresentedInDialog = false,
      this.showConversationHistory = true})
      : super(key: key);

  @override
  _ChatwootChatState createState() => _ChatwootChatState();
}

class _ChatwootChatState extends State<ChatwootChat> {
  ///
  List<types.Message> _messages = [];
  List<ChatwootConversation> _conversations = [];
  late bool _showingChat;
  bool _isLoadingConversations = true;

  /// The conversation currently shown in the chat screen (as opposed to
  /// the recent-conversations list). Drives the header's ticket badge and
  /// the resolved banner -- both need the live status/id of whatever the
  /// user is actually looking at, not just the raw message list.
  ChatwootConversation? _activeConversation;

  /// Whether the active conversation is currently online, offline, or
  /// unknown (null) because no status update has been received yet.
  bool? _isOnline;

  /// Whether the agent is currently typing a reply.
  bool _isTyping = false;

  late String status;

  final idGen = Uuid();
  late final _user;
  ChatwootClient? chatwootClient;

  late final chatwootCallbacks;

  @override
  void initState() {
    super.initState();
    _showingChat = !widget.showConversationHistory;

    if (widget.user == null) {
      _user = types.User(id: idGen.v4());
    } else {
      _user = types.User(
        id: widget.user?.identifier ?? idGen.v4(),
        firstName: widget.user?.name,
        imageUrl: widget.user?.avatarUrl,
      );
    }

    chatwootCallbacks = ChatwootCallbacks(
      onWelcome: () {
        widget.onWelcome?.call();
      },
      onPing: () {
        widget.onPing?.call();
      },
      onConfirmedSubscription: () {
        widget.onConfirmedSubscription?.call();
      },
      onConversationStartedTyping: () {
        if (mounted) {
          setState(() {
            _isTyping = true;
          });
        }
        widget.onConversationStartedTyping?.call();
      },
      onConversationStoppedTyping: () {
        if (mounted) {
          setState(() {
            _isTyping = false;
          });
        }
        widget.onConversationStoppedTyping?.call();
      },
      onConversationIsOnline: () {
        if (mounted) {
          setState(() {
            _isOnline = true;
          });
        }
        widget.onConversationIsOnline?.call();
      },
      onConversationIsOffline: () {
        if (mounted) {
          setState(() {
            _isOnline = false;
          });
        }
        widget.onConversationIsOffline?.call();
      },
      onPersistedMessagesRetrieved: (persistedMessages) {
        if (widget.enablePersistence) {
          // `localStorage.messagesDao.getMessages()` (behind
          // `getPersistedMessages()`) returns every locally-persisted
          // message for the *contact*, across every conversation it ever
          // had -- not just the one on screen. Wholesale-assigning that
          // unfiltered list to `_messages` used to leak another
          // conversation's messages into whichever conversation happened to
          // be active (most easily triggered with
          // `showConversationHistory: false`, which jumps straight into a
          // single conversation without the recent-conversations list as an
          // intermediary), corrupting `_messages` with mixed
          // `conversationId`s. `SliverAnimatedList` (inside `Chat`) assumes
          // controlled, incremental mutation of its list and asserts/crashes
          // when it isn't. Scope to the active conversation here; with none
          // selected yet, start empty rather than show messages that may not
          // belong to whatever becomes active.
          final activeConversationId = _activeConversation?.id;
          final scopedMessages = activeConversationId == null
              ? const <ChatwootMessage>[]
              : persistedMessages
                  .where((message) =>
                      message.conversationId == activeConversationId)
                  .toList();
          setState(() {
            _messages = scopedMessages
                .map((message) => _chatwootMessageToTextMessage(message))
                .toList();
          });
        }
        widget.onPersistedMessagesRetrieved?.call(persistedMessages);
      },
      onMessagesRetrieved: (messages) {
        if (messages.isEmpty) {
          return;
        }
        // Same cross-conversation leak as `onPersistedMessagesRetrieved`
        // above, from the remote-fetch side: `getAllMessages()` (behind
        // `ChatwootRepository.getMessages()`) fetches every message for the
        // contact, not just the active conversation. Scope the merge to the
        // active conversation; the raw, unfiltered list still reaches
        // `widget.onMessagesRetrieved` unchanged for host apps that rely on
        // it for other purposes (e.g. their own cross-conversation state).
        final activeConversationId = _activeConversation?.id;
        if (activeConversationId != null) {
          final scopedMessages = messages
              .where(
                  (message) => message.conversationId == activeConversationId)
              .toList();
          if (scopedMessages.isNotEmpty) {
            setState(() {
              final chatMessages = scopedMessages
                  .map((message) => _chatwootMessageToTextMessage(message))
                  .toList();
              final mergedMessages = <types.Message>[
                ..._messages,
                ...chatMessages
              ].toSet().toList();
              final now = DateTime.now().millisecondsSinceEpoch;
              mergedMessages.sort((a, b) {
                return (b.createdAt ?? now).compareTo(a.createdAt ?? now);
              });
              _messages = mergedMessages;
            });
          }
        }
        widget.onMessagesRetrieved?.call(messages);
      },
      onMessageReceived: (chatwootMessage) {
        // Realtime events are pushed to this client for every conversation
        // of the contact, not just the one on screen (see
        // `ChatwootRepository.listenForEvents`) -- guard the same way
        // `onConversationStatusChanged` below already does, so a message
        // for a background conversation never mutates the visible
        // `_messages`. It was already persisted locally by
        // `ChatwootRepository.listenForEvents` regardless, so nothing is
        // lost -- it just won't render in the wrong conversation's list.
        if (_activeConversation != null &&
            chatwootMessage.conversationId == _activeConversation!.id) {
          _addMessage(_chatwootMessageToTextMessage(chatwootMessage));
        }
        widget.onMessageReceived?.call(chatwootMessage);
      },
      onMessageDelivered: (chatwootMessage, echoId) {
        if (_activeConversation != null &&
            chatwootMessage.conversationId == _activeConversation!.id) {
          _handleMessageSent(
              _chatwootMessageToTextMessage(chatwootMessage, echoId: echoId));
        }
        widget.onMessageDelivered?.call(chatwootMessage);
      },
      onMessageUpdated: (chatwootMessage) {
        if (_activeConversation != null &&
            chatwootMessage.conversationId == _activeConversation!.id) {
          _handleMessageUpdated(_chatwootMessageToTextMessage(chatwootMessage,
              echoId: chatwootMessage.id.toString()));
        }
        widget.onMessageUpdated?.call(chatwootMessage);
      },
      onMessageSent: (chatwootMessage, echoId) {
        if (_activeConversation != null &&
            chatwootMessage.conversationId == _activeConversation!.id) {
          final textMessage = types.TextMessage(
              id: echoId,
              author: _user,
              text: chatwootMessage.content ?? "",
              status: types.Status.delivered);
          _handleMessageSent(textMessage);
        }
        widget.onMessageSent?.call(chatwootMessage);
      },
      onConversationsRetrieved: (conversations) {
        if (mounted) {
          setState(() {
            _conversations = conversations;
            _isLoadingConversations = false;
            _refreshActiveConversationFrom(conversations);
          });
        }
        widget.onConversationsRetrieved?.call(conversations);
      },
      onPersistedConversationsRetrieved: (conversations) {
        if (mounted) {
          setState(() {
            _conversations = conversations;
            _isLoadingConversations = false;
            _refreshActiveConversationFrom(conversations);
          });
        }
      },
      onConversationCreated: (conversation) {
        if (mounted) {
          setState(() {
            _activeConversation = conversation;
            // No more synthetic "Ticket #{id} aberto" notice here -- a new
            // conversation now starts genuinely empty, showing only real
            // messages as they arrive. See [ChatwootL10n.ticketOpenedMessage]
            // for why that field still exists unused.
            _messages = [];
            _showingChat = true;
            _isLoadingConversations = false;
          });
        }
        widget.onConversationCreated?.call(conversation);
      },
      onConversationStatusChanged: (conversationId, status, snoozedUntil) {
        if (mounted && _activeConversation?.id == conversationId) {
          setState(() {
            _activeConversation = _activeConversation!.withStatus(
              status.name,
              snoozedUntil: snoozedUntil,
            );
          });
        }
      },
      onError: (error) {
        if (error.type == ChatwootClientExceptionType.SEND_MESSAGE_FAILED) {
          _handleSendMessageFailed(error.data);
        }
        print(
            "Ooops! Something went wrong. [${error.type}] Error Cause: ${error.cause}");
        widget.onError?.call(error);
      },
    );

    ChatwootClient.create(
            baseUrl: widget.baseUrl,
            inboxIdentifier: widget.inboxIdentifier,
            user: widget.user,
            enablePersistence: widget.enablePersistence,
            callbacks: chatwootCallbacks)
        .then((client) {
      if (mounted) {
        setState(() {
          chatwootClient = client;
          _conversations = client.getPersistedConversations();
          if (_conversations.isNotEmpty) {
            _isLoadingConversations = false;
          }
          // Restores the ticket badge/resolved banner for a returning
          // session (persistence on, `showConversationHistory: false`)
          // where the chat opens straight into an existing conversation
          // without going through [_handleSelectConversation].
          _activeConversation = client.getActiveConversation();
          client.loadMessages();
          client.loadConversations();
        });
      }
    }).onError((error, stackTrace) {
      widget.onError?.call(ChatwootClientException(
          error.toString(), ChatwootClientExceptionType.CREATE_CLIENT_FAILED));
      print("chatwoot client failed with error $error: $stackTrace");
    });
  }

  types.TextMessage _chatwootMessageToTextMessage(ChatwootMessage message,
      {String? echoId}) {
    String? avatarUrl = message.sender?.avatarUrl ?? message.sender?.thumbnail;

    //Sets avatar url to null if its a gravatar not found url
    //This enables placeholder for avatar to show
    if (avatarUrl?.contains("?d=404") ?? false) {
      avatarUrl = null;
    }
    return types.TextMessage(
        id: echoId ?? message.id.toString(),
        author: message.isMine
            ? _user
            : types.User(
                id: message.sender?.id.toString() ?? idGen.v4(),
                firstName: message.sender?.name,
                imageUrl: avatarUrl,
              ),
        text: message.content ?? "",
        status: types.Status.seen,
        createdAt: DateTime.parse(message.createdAt).millisecondsSinceEpoch);
  }

  void _addMessage(types.Message message) {
    // Defensive: skip if a message with this id is already present. Cheap,
    // safe, and prevents duplicate bubbles even if `onMessageReceived`
    // genuinely fires more than once for the same real event (reconnection,
    // server retry, etc.) -- see `listenForEvents()` in
    // chatwoot_repository.dart for the actual duplicate-subscription root
    // cause this also guards against.
    if (_messages.any((element) => element.id == message.id)) {
      return;
    }
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleSendMessageFailed(String echoId) async {
    final index = _messages.indexWhere((element) => element.id == echoId);
    // Defensive: this fires from the async SEND_MESSAGE_FAILED error
    // callback (see repository's `sendMessage`), which can land after the
    // echoed message it refers to is gone from `_messages` -- e.g. the user
    // switched conversations (`_handleSelectConversation` replaces
    // `_messages` wholesale) before the network error came back. Same
    // RangeError-on-`_messages[-1]` shape as `_handleMessageSent`/
    // `_handleMessageUpdated`; skip instead of crashing.
    if (index == -1) {
      return;
    }
    setState(() {
      _messages[index] = _messages[index].copyWith(status: types.Status.error);
    });
  }

  void _handleResendMessage(types.TextMessage message) async {
    chatwootClient!.sendMessage(content: message.text, echoId: message.id);
    final index = _messages.indexWhere((element) => element.id == message.id);
    setState(() {
      _messages[index] = message.copyWith(status: types.Status.sending);
    });
  }

  void _handleMessageTap(BuildContext context, types.Message message) async {
    if (message.status == types.Status.error && message is types.TextMessage) {
      _handleResendMessage(message);
    }
    widget.onMessageTap?.call(message);
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMetaData = _messages[index].metadata ?? Map();
    updatedMetaData["previewData"] = previewData;
    final updatedMessage = _messages[index].copyWith(metadata: updatedMetaData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages[index] = updatedMessage;
      });
    });
  }

  void _handleMessageSent(
    types.Message message,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    // Defensive: this is called from the async `onMessageDelivered`/
    // `onMessageSent` callbacks, which can arrive after the echoed message
    // they refer to is gone from `_messages` -- e.g. the user sent a
    // message (local echo via `_addMessage`), then switched conversations
    // (`_handleSelectConversation` replaces `_messages` wholesale) before
    // the delivery/sent confirmation came back. `_messages[-1]` throws a
    // RangeError in Dart, crashing the widget; skip instead, same as
    // `_handleMessageUpdated` below.
    if (index == -1) {
      return;
    }

    if (_messages[index].status == types.Status.seen) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages[index] = message;
      });
    });
  }

  void _handleMessageUpdated(
    types.Message message,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    // Defensive: an update event can arrive for a message this client
    // hasn't inserted into `_messages` yet (e.g. ordering races between
    // `message.created`/`message.updated`, or a duplicate-subscription
    // replay -- see `listenForEvents()` in chatwoot_repository.dart).
    // `_messages[-1]` throws in Dart (unlike Python), so skip the update
    // instead of crashing; the message's own insertion (via
    // `onMessageReceived`/`_addMessage`) is what will show it.
    if (index == -1) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages[index] = message;
      });
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: message.text,
        status: types.Status.sending);

    _addMessage(textMessage);

    chatwootClient!
        .sendMessage(content: textMessage.text, echoId: textMessage.id);
    widget.onSendPressed?.call(message);
  }

  void _handleSelectConversation(ChatwootConversation conversation) {
    setState(() {
      _showingChat = true;
      _activeConversation = conversation;
      _messages = conversation.messages
          .map((message) => _chatwootMessageToTextMessage(message))
          .toList();
      final now = DateTime.now().millisecondsSinceEpoch;
      _messages.sort((a, b) {
        return (b.createdAt ?? now).compareTo(a.createdAt ?? now);
      });
    });
    chatwootClient?.setActiveConversation(conversation);
  }

  Future<void> _handleNewConversation() async {
    try {
      setState(() {
        _isLoadingConversations = true;
      });
      // `onConversationCreated` (wired in initState) is what actually sets
      // _messages/_activeConversation/_showingChat once the conversation
      // comes back -- including the "Ticket #{id} aberto" notice. Setting
      // them again here would race it and wipe that notice back out.
      await chatwootClient?.createConversation();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingConversations = false;
        });
      }
    }
  }

  void _handleBackToConversations() {
    setState(() {
      _showingChat = false;
    });
    chatwootClient?.loadConversations();
  }

  /// The agent shown in the header avatar: whoever sent the most recent
  /// message that isn't from [_user]. The header *title* is always the
  /// fixed [ChatwootChat.l10n].defaultChatTitle, never the agent's name.
  types.User? get _agent {
    for (final message in _messages) {
      if (message.metadata?[_kIsSystemMessageKey] == true) {
        continue;
      }
      if (message.author.id != _user.id) {
        return message.author;
      }
    }
    return null;
  }

  /// Keeps [_activeConversation] in sync whenever a fresh conversations
  /// list comes in from the server or from disk -- catches status changes
  /// (resolved/pending/snoozed) that arrived via a REST refresh instead of
  /// the websocket's `conversation_status_changed` event, so the ticket
  /// badge and resolved banner never show stale data.
  void _refreshActiveConversationFrom(
      List<ChatwootConversation> conversations) {
    final active = _activeConversation;
    if (active == null) {
      return;
    }
    for (final conversation in conversations) {
      if (conversation.id == active.id) {
        _activeConversation = conversation;
        return;
      }
    }
  }

  /// Formats [_activeConversation]'s `snoozed_until` as `dd/MM/yyyy HH:mm`,
  /// or null if [snoozedUntil] is missing or fails to parse. Callers embed
  /// the result into their own `{date}` template -- [_snoozedStatusText]
  /// for the header subtitle's [ChatwootL10n.snoozedUntilLabel],
  /// [_buildSnoozedBanner] for [ChatwootL10n.conversationSnoozedMessage] --
  /// falling back to the plain [ChatwootL10n.conversationStatusSnoozed]
  /// label when this returns null, same tolerant-of-bad-data spirit as
  /// [chatwootImageProvider].
  String? _formatSnoozedUntil(String? snoozedUntil) {
    if (snoozedUntil == null) {
      return null;
    }
    final date = DateTime.tryParse(snoozedUntil);
    if (date == null) {
      return null;
    }
    // TODO: `snoozed_until` is a UTC ISO 8601 timestamp (DateTime.tryParse
    // keeps it in UTC as long as `.toLocal()` isn't called here). Fixed to
    // UTC for now because the host app has no configurable timezone yet --
    // the correct conversion (either done by the host app before it reaches
    // the SDK, or driven by a new variable passed into
    // `ChatwootChatDialog.show()`) is left for later.
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Header-subtitle text for a snoozed conversation:
  /// [ChatwootL10n.snoozedUntilLabel] with `{date}` filled in from
  /// [_formatSnoozedUntil], or the plain [ChatwootL10n.conversationStatusSnoozed]
  /// label when that date is missing/unparsable.
  String _snoozedStatusText() {
    final formattedDate =
        _formatSnoozedUntil(_activeConversation?.snoozedUntil);
    return formattedDate == null
        ? widget.l10n.conversationStatusSnoozed
        : widget.l10n.snoozedUntilLabel.replaceAll('{date}', formattedDate);
  }

  /// Ticket number label for the top-right of the chat header. Color is
  /// derived from [ChatwootChatTheme.headerForegroundColor] -- the same
  /// color the host app already picked to read well on
  /// [ChatwootChatTheme.headerColor] -- rather than a fixed color, so it
  /// always has adequate contrast no matter which theme/tenant brand is
  /// active. Plain text, no background/border -- not a visual badge.
  Widget _buildTicketBadge(ChatwootChatTheme theme) {
    final conversation = _activeConversation!;
    final label =
        widget.l10n.ticketBadgeLabel.replaceAll('{id}', '${conversation.id}');
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: theme.headerForegroundColor,
        ),
      ),
    );
  }

  /// Sticky banner shown right above the message list, common shape shared
  /// by [_buildResolvedBanner] and [_buildSnoozedBanner]. Colors are
  /// derived from [ChatwootChatTheme.headerColor] for the same
  /// theme-safe-contrast reason as [_buildTicketBadge].
  Widget _buildStatusBanner({
    required ChatwootChatTheme theme,
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      color: theme.headerColor.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.headerColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: theme.headerColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sticky banner shown right above the message list whenever
  /// [_activeConversation] is resolved. Returns null (renders nothing) for
  /// every other status, including when there's no active conversation
  /// yet -- callers gate on that null instead of checking status again.
  Widget? _buildResolvedBanner(ChatwootChatTheme theme) {
    if (_activeConversation?.statusEnum !=
        ChatwootConversationStatus.resolved) {
      return null;
    }
    return _buildStatusBanner(
      theme: theme,
      icon: Icons.check_circle_outline,
      text: widget.l10n.conversationResolvedMessage,
    );
  }

  /// Sticky banner shown right above the message list whenever
  /// [_activeConversation] is snoozed, with [ChatwootL10n.conversationSnoozedMessage]'s
  /// `{date}` filled in from [_formatSnoozedUntil] (falling back to the
  /// plain [ChatwootL10n.conversationStatusSnoozed] label when that date is
  /// missing/unparsable, same tolerance as the header subtitle). Returns
  /// null for every other status. Resolved and snoozed are mutually
  /// exclusive conversation statuses, so this and [_buildResolvedBanner]
  /// never both render at once.
  Widget? _buildSnoozedBanner(ChatwootChatTheme theme) {
    if (_activeConversation?.statusEnum != ChatwootConversationStatus.snoozed) {
      return null;
    }
    final formattedDate =
        _formatSnoozedUntil(_activeConversation?.snoozedUntil);
    final text = formattedDate == null
        ? widget.l10n.conversationStatusSnoozed
        : widget.l10n.conversationSnoozedMessage
            .replaceAll('{date}', formattedDate);
    return _buildStatusBanner(
      theme: theme,
      icon: Icons.schedule,
      text: text,
    );
  }

  /// Replaces `flutter_chat_ui`'s default [UserAvatar] -- which only ever
  /// shows the message's own author (i.e. each individual agent's photo)
  /// and only supports network images -- with one fixed picture for every
  /// received message, resolved from [ChatwootChatTheme.avatarImageSource]
  /// (URL, absolute path or bundled asset). Only used when
  /// [ChatwootChat.showAgentIdentity] is `false` -- see that field. Sizing/
  /// margin mirrors `UserAvatar` so swapping it in doesn't shift the
  /// message layout.
  Widget _buildFixedAvatar(ChatwootChatTheme theme, ImageProvider avatar) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: theme.userAvatarImageBackgroundColor,
        backgroundImage: avatar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? const ChatwootChatTheme();
    // Full-bleed by default so the chat wallpaper reaches the screen edges,
    // like a native WhatsApp conversation. A small inset is kept only when
    // the widget is hosted inside a floating dialog.
    final horizontalPadding = widget.isPresentedInDialog ? 8.0 : 0.0;

    if (!_showingChat && widget.showConversationHistory) {
      return Scaffold(
        appBar: widget.appBar ??
            AppBar(
              title: Text(widget.l10n.recentConversationsTitle),
              backgroundColor: theme.headerColor,
              foregroundColor: theme.headerForegroundColor,
              elevation: 0,
            ),
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: ChatwootRecentConversations(
            conversations: _conversations,
            onConversationSelected: _handleSelectConversation,
            onNewConversation: _handleNewConversation,
            onRefresh: () async {
              await chatwootClient?.loadConversations();
            },
            theme: theme,
            l10n: widget.l10n,
            dateFormat: widget.dateFormat,
            timeFormat: widget.timeFormat,
            isLoading: _isLoadingConversations && _conversations.isEmpty,
          ),
        ),
      );
    }

    PreferredSizeWidget? chatAppBar = widget.appBar;
    if (chatAppBar == null) {
      final agent = _agent;
      final fixedAvatar = chatwootImageProvider(theme.avatarImageSource);
      final conversationStatus = _activeConversation?.statusEnum;
      final effectivePresence = widget.presenceStatus ??
          (_isOnline == null
              ? null
              : (_isOnline!
                  ? ChatwootPresenceStatus.online
                  : ChatwootPresenceStatus.offline));
      // Resolved already gets its own banner below the header, so it's
      // left out here to avoid saying the same thing twice; pending and
      // snoozed have no banner of their own, so they take over the
      // presence subtitle instead.
      final statusText = _isTyping
          ? widget.l10n.isTyping
          : conversationStatus == ChatwootConversationStatus.pending
              ? widget.l10n.conversationStatusPending
              : conversationStatus == ChatwootConversationStatus.snoozed
                  ? _snoozedStatusText()
                  : switch (effectivePresence) {
                      ChatwootPresenceStatus.online => widget.l10n.onlineText,
                      ChatwootPresenceStatus.busy => widget.l10n.busyText,
                      ChatwootPresenceStatus.offline => widget.l10n.offlineText,
                      null => null,
                    };
      chatAppBar = AppBar(
        leading: widget.showConversationHistory
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: widget.l10n.backButtonTooltip,
                onPressed: _handleBackToConversations,
              )
            : null,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  theme.headerForegroundColor.withValues(alpha: 0.16),
              backgroundImage: fixedAvatar ??
                  (agent?.imageUrl != null
                      ? NetworkImage(agent!.imageUrl!)
                      : null),
              child: fixedAvatar == null && agent?.imageUrl == null
                  ? Icon(
                      Icons.chat_bubble_outline,
                      color: theme.headerForegroundColor,
                      size: 18,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.l10n.defaultChatTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (statusText != null)
                    Text(
                      statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.headerSubtitleTextStyle,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_activeConversation != null) _buildTicketBadge(theme),
        ],
        backgroundColor: theme.headerColor,
        foregroundColor: theme.headerForegroundColor,
        elevation: 0,
      );
    }

    final wallpaper = chatwootImageProvider(theme.backgroundImageSource);
    // The inner Chat widget always paints an opaque theme.backgroundColor
    // fill of its own, so the wallpaper is drawn one level up here and the
    // Chat's own fill is made transparent to let it show through.
    final chatTheme = wallpaper == null
        ? theme
        : theme.copyWith(backgroundColor: Colors.transparent);
    final resolvedBanner = _buildResolvedBanner(theme);
    final snoozedBanner = _buildSnoozedBanner(theme);
    final fixedAvatarProvider = chatwootImageProvider(theme.avatarImageSource);
    // Per-message identity is only ever forced to the fixed avatar when the
    // host explicitly turns showAgentIdentity off -- merely configuring
    // avatarImageSource (for the header, which always uses it regardless of
    // this flag) must not by itself change per-message avatars.
    final forceFixedAvatarPerMessage =
        !widget.showAgentIdentity && fixedAvatarProvider != null;

    return Scaffold(
      appBar: chatAppBar,
      backgroundColor: theme.backgroundColor,
      body: Container(
        decoration: wallpaper == null
            ? null
            : BoxDecoration(
                image: DecorationImage(
                  image: wallpaper,
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    debugPrint(
                        "Chatwoot: failed to load chat background image: $exception");
                  },
                ),
              ),
        child: SafeArea(
          child: Column(
            children: [
              if (resolvedBanner != null)
                resolvedBanner
              else if (snoozedBanner != null)
                snoozedBanner,
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(
                      left: horizontalPadding, right: horizontalPadding),
                  child: Chat(
                    messages: _messages,
                    onMessageTap: _handleMessageTap,
                    onPreviewDataFetched: _handlePreviewDataFetched,
                    onSendPressed: _handleSendPressed,
                    user: _user,
                    onEndReached: widget.onEndReached,
                    onEndReachedThreshold: widget.onEndReachedThreshold,
                    onMessageLongPress: widget.onMessageLongPress,
                    showUserAvatars: widget.showUserAvatars,
                    showUserNames:
                        widget.showAgentIdentity && widget.showUserNames,
                    avatarBuilder: forceFixedAvatarPerMessage
                        ? (author) =>
                            _buildFixedAvatar(theme, fixedAvatarProvider)
                        : null,
                    timeFormat: widget.timeFormat ?? DateFormat.Hm(),
                    dateFormat: widget.dateFormat ?? DateFormat("EEEE MMMM d"),
                    theme: chatTheme,
                    l10n: widget.l10n,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    chatwootClient?.dispose();
  }
}
