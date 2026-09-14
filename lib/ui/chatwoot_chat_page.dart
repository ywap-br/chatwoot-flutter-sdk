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

  /// Show user names for received messages.
  final bool showUserNames;

  final ChatwootChatTheme? theme;

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
      this.showUserNames = true,
      this.theme,
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
  ChatwootConversation? _activeConversation;
  late bool _showingChat;
  bool _isLoadingConversations = true;

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
        widget.onConversationStoppedTyping?.call();
      },
      onConversationStoppedTyping: () {
        widget.onConversationStartedTyping?.call();
      },
      onPersistedMessagesRetrieved: (persistedMessages) {
        if (widget.enablePersistence) {
          setState(() {
            _messages = persistedMessages
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
        setState(() {
          final chatMessages = messages
              .map((message) => _chatwootMessageToTextMessage(message))
              .toList();
          final mergedMessages =
              <types.Message>[..._messages, ...chatMessages].toSet().toList();
          final now = DateTime.now().millisecondsSinceEpoch;
          mergedMessages.sort((a, b) {
            return (b.createdAt ?? now).compareTo(a.createdAt ?? now);
          });
          _messages = mergedMessages;
        });
        widget.onMessagesRetrieved?.call(messages);
      },
      onMessageReceived: (chatwootMessage) {
        _addMessage(_chatwootMessageToTextMessage(chatwootMessage));
        widget.onMessageReceived?.call(chatwootMessage);
      },
      onMessageDelivered: (chatwootMessage, echoId) {
        _handleMessageSent(
            _chatwootMessageToTextMessage(chatwootMessage, echoId: echoId));
        widget.onMessageDelivered?.call(chatwootMessage);
      },
      onMessageUpdated: (chatwootMessage) {
        _handleMessageUpdated(_chatwootMessageToTextMessage(chatwootMessage,
            echoId: chatwootMessage.id.toString()));
        widget.onMessageUpdated?.call(chatwootMessage);
      },
      onMessageSent: (chatwootMessage, echoId) {
        final textMessage = types.TextMessage(
            id: echoId,
            author: _user,
            text: chatwootMessage.content ?? "",
            status: types.Status.delivered);
        _handleMessageSent(textMessage);
        widget.onMessageSent?.call(chatwootMessage);
      },
      onConversationsRetrieved: (conversations) {
        if (mounted) {
          setState(() {
            _conversations = conversations;
            _isLoadingConversations = false;
          });
        }
        widget.onConversationsRetrieved?.call(conversations);
      },
      onPersistedConversationsRetrieved: (conversations) {
        if (mounted) {
          setState(() {
            _conversations = conversations;
            _isLoadingConversations = false;
          });
        }
      },
      onConversationCreated: (conversation) {
        if (mounted) {
          setState(() {
            _activeConversation = conversation;
            _messages = [];
            _showingChat = true;
            _isLoadingConversations = false;
          });
        }
        widget.onConversationCreated?.call(conversation);
      },
      onConversationResolved: () {
        final resolvedMessage = types.TextMessage(
            id: idGen.v4(),
            text: widget.l10n.conversationResolvedMessage,
            author: types.User(
                id: idGen.v4(),
                firstName: "Bot",
                imageUrl:
                    "https://d2cbg94ubxgsnp.cloudfront.net/Pictures/480x270//9/9/3/512993_shutterstock_715962319converted_920340.png"),
            status: types.Status.delivered);
        _addMessage(resolvedMessage);
      },
      onError: (error) {
        if (error.type == ChatwootClientExceptionType.SEND_MESSAGE_FAILED) {
          _handleSendMessageFailed(error.data);
        }
        print("Ooops! Something went wrong. [${error.type}] Error Cause: ${error.cause}");
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
          _activeConversation = client.getActiveConversation();
          _conversations = client.getPersistedConversations();
          if (_conversations.isNotEmpty) {
            _isLoadingConversations = false;
          }
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
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleSendMessageFailed(String echoId) async {
    final index = _messages.indexWhere((element) => element.id == echoId);
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
      _activeConversation = conversation;
      _showingChat = true;
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
      final conversation = await chatwootClient?.createConversation();
      if (conversation != null && mounted) {
        setState(() {
          _activeConversation = conversation;
          _messages = [];
          _showingChat = true;
          _isLoadingConversations = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = widget.isPresentedInDialog ? 8.0 : 16.0;

    if (!_showingChat && widget.showConversationHistory) {
      return Scaffold(
        appBar: widget.appBar ??
            AppBar(
              title: Text(widget.l10n.recentConversationsTitle),
              backgroundColor:
                  widget.theme?.primaryColor ?? CHATWOOT_COLOR_PRIMARY,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
        backgroundColor: widget.theme?.backgroundColor,
        body: ChatwootRecentConversations(
          conversations: _conversations,
          onConversationSelected: _handleSelectConversation,
          onNewConversation: _handleNewConversation,
          onRefresh: () async {
            await chatwootClient?.loadConversations();
          },
          theme: widget.theme ?? const ChatwootChatTheme(),
          l10n: widget.l10n,
          dateFormat: widget.dateFormat,
          timeFormat: widget.timeFormat,
          isLoading: _isLoadingConversations && _conversations.isEmpty,
        ),
      );
    }

    PreferredSizeWidget? chatAppBar = widget.appBar;
    if (chatAppBar == null && widget.showConversationHistory) {
      chatAppBar = AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: widget.l10n.backButtonTooltip,
          onPressed: _handleBackToConversations,
        ),
        title: Text(_activeConversation != null
            ? "Conversa #${_activeConversation!.id}"
            : widget.l10n.recentConversationsTitle),
        backgroundColor: widget.theme?.primaryColor ?? CHATWOOT_COLOR_PRIMARY,
        foregroundColor: Colors.white,
        elevation: 0,
      );
    }

    return Scaffold(
      appBar: chatAppBar,
      backgroundColor: widget.theme?.backgroundColor,
      body: Column(
        children: [
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
                showUserNames: widget.showUserNames,
                timeFormat: widget.timeFormat ?? DateFormat.Hm(),
                dateFormat: widget.dateFormat ?? DateFormat("EEEE MMMM d"),
                theme: widget.theme ?? ChatwootChatTheme(),
                l10n: widget.l10n,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    chatwootClient?.dispose();
  }
}
