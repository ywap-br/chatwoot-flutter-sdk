import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:chatwoot_sdk/chatwoot_callbacks.dart';
import 'package:chatwoot_sdk/chatwoot_client.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_conversation.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_user.dart';
import 'package:chatwoot_sdk/data/local/local_storage.dart';
import 'package:chatwoot_sdk/data/remote/chatwoot_client_exception.dart';
import 'package:chatwoot_sdk/data/remote/requests/chatwoot_action_data.dart';
import 'package:chatwoot_sdk/data/remote/requests/chatwoot_new_message_request.dart';
import 'package:chatwoot_sdk/data/remote/responses/chatwoot_event.dart';
import 'package:chatwoot_sdk/data/remote/service/chatwoot_client_service.dart';
import 'package:flutter/material.dart';

/// Handles interactions between chatwoot client api service[clientService] and
/// [localStorage] if persistence is enabled.
///
/// Results from repository operations are passed through [callbacks] to be handled
/// appropriately
abstract class ChatwootRepository {
  @protected
  final ChatwootClientService clientService;
  @protected
  final LocalStorage localStorage;
  @protected
  ChatwootCallbacks callbacks;
  List<StreamSubscription> _subscriptions = [];

  ChatwootRepository(this.clientService, this.localStorage, this.callbacks);

  Future<void> initialize(ChatwootUser? user);

  void getPersistedMessages();

  Future<void> getMessages();

  Future<List<ChatwootConversation>> loadConversations();

  List<ChatwootConversation> getPersistedConversations();

  Future<ChatwootConversation> createNewConversation();

  Future<void> setActiveConversation(ChatwootConversation conversation);

  ChatwootConversation? getActiveConversation();

  void listenForEvents();

  Future<void> sendMessage(ChatwootNewMessageRequest request);

  void sendAction(ChatwootActionType action);

  Future<void> clear();

  void dispose();
}

class ChatwootRepositoryImpl extends ChatwootRepository {
  bool _isListeningForEvents = false;
  Timer? _publishPresenceTimer;
  Timer? _presenceResetTimer;

  ChatwootRepositoryImpl(
      {required ChatwootClientService clientService,
      required LocalStorage localStorage,
      required ChatwootCallbacks streamCallbacks})
      : super(clientService, localStorage, streamCallbacks);

  /// Fetches persisted messages.
  ///
  /// Calls [ChatwootCallbacks.onMessagesRetrieved] when [ChatwootClientService.getAllMessages] is successful
  /// Calls [ChatwootCallbacks.onError] when [ChatwootClientService.getAllMessages] fails
  @override
  Future<void> getMessages() async {
    try {
      final messages = await clientService.getAllMessages();
      await localStorage.messagesDao.saveAllMessages(messages);
      callbacks.onMessagesRetrieved?.call(messages);
    } on ChatwootClientException catch (e) {
      callbacks.onError?.call(e);
    }
  }

  /// Fetches persisted messages.
  ///
  /// Calls [ChatwootCallbacks.onPersistedMessagesRetrieved] if persisted messages are found
  @override
  void getPersistedMessages() {
    final persistedMessages = localStorage.messagesDao.getMessages();
    if (persistedMessages.isNotEmpty) {
      callbacks.onPersistedMessagesRetrieved?.call(persistedMessages);
    }
  }

  /// Initializes chatwoot client repository
  Future<void> initialize(ChatwootUser? user) async {
    try {
      if (user != null) {
        await localStorage.userDao.saveUser(user);
      }

      //refresh contact
      final contact = await clientService.getContact();
      localStorage.contactDao.saveContact(contact);

      //refresh conversations
      final conversations = await clientService.getConversations();
      await localStorage.conversationDao.saveConversations(conversations);
      callbacks.onConversationsRetrieved?.call(conversations);

      final persistedConversation =
          localStorage.conversationDao.getConversation();
      if (persistedConversation != null) {
        final refreshedConversation = conversations.firstWhere(
            (element) => element.id == persistedConversation.id,
            orElse: () => persistedConversation);
        await localStorage.conversationDao
            .saveConversation(refreshedConversation);
      } else if (conversations.isNotEmpty) {
        await localStorage.conversationDao.saveConversation(conversations.last);
      }
    } on ChatwootClientException catch (e) {
      callbacks.onError?.call(e);
    }

    listenForEvents();
  }

  /// Loads conversations for the contact from remote server
  @override
  Future<List<ChatwootConversation>> loadConversations() async {
    try {
      final conversations = await clientService.getConversations();
      await localStorage.conversationDao.saveConversations(conversations);
      callbacks.onConversationsRetrieved?.call(conversations);
      return conversations;
    } on ChatwootClientException catch (e) {
      callbacks.onError?.call(e);
      return localStorage.conversationDao.getConversations();
    }
  }

  /// Retrieves persisted conversations from local storage
  @override
  List<ChatwootConversation> getPersistedConversations() {
    final conversations = localStorage.conversationDao.getConversations();
    if (conversations.isNotEmpty) {
      callbacks.onPersistedConversationsRetrieved?.call(conversations);
    }
    return conversations;
  }

  /// Creates a new conversation on remote server and saves it locally
  @override
  Future<ChatwootConversation> createNewConversation() async {
    try {
      final conversation = await clientService.createConversation();
      await localStorage.conversationDao.saveConversation(conversation);
      final current = localStorage.conversationDao.getConversations();
      await localStorage.conversationDao
          .saveConversations([...current, conversation]);
      callbacks.onConversationCreated?.call(conversation);
      return conversation;
    } on ChatwootClientException catch (e) {
      callbacks.onError?.call(e);
      rethrow;
    }
  }

  /// Sets the active conversation and fetches its messages
  @override
  Future<void> setActiveConversation(ChatwootConversation conversation) async {
    await localStorage.conversationDao.setActiveConversation(conversation);
    await getMessages();
  }

  /// Gets the currently active conversation
  @override
  ChatwootConversation? getActiveConversation() {
    return localStorage.conversationDao.getConversation();
  }

  ///Sends message to chatwoot inbox
  Future<void> sendMessage(ChatwootNewMessageRequest request) async {
    try {
      final createdMessage = await clientService.createMessage(request);
      await localStorage.messagesDao.saveMessage(createdMessage);
      callbacks.onMessageSent?.call(createdMessage, request.echoId);
      if (clientService.connection != null && !_isListeningForEvents) {
        listenForEvents();
      }
    } on ChatwootClientException catch (e) {
      callbacks.onError?.call(
          ChatwootClientException(e.cause, e.type, data: request.echoId));
    }
  }

  /// Connects to chatwoot websocket and starts listening for updates
  ///
  /// Received events/messages are pushed through [ChatwootClient.callbacks]
  @override
  void listenForEvents() {
    final token = localStorage.contactDao.getContact()?.pubsubToken;
    if (token == null) {
      return;
    }

    // Guard: `listenForEvents()` can be called more than once before
    // `confirm_subscription` arrives -- e.g. `initialize()` calls it
    // unconditionally on startup, and `sendMessage()` calls it again
    // whenever `_isListeningForEvents` is still false, which race easily
    // when a message is sent right after opening the chat. Without this,
    // each call stacked another live subscription onto the same/next
    // websocket stream, so a single realtime event (like `message_created`
    // for a sender-less bot/system message) dispatched its callback once
    // per stacked subscription, rendering the same message more than once.
    // Cancelling any previous subscription(s) first keeps at most one live
    // listener at a time, covering both "called from more than one place"
    // and "reconnection without cancelling the previous subscription".
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _isListeningForEvents = false;

    // Close any previous physical websocket connection before opening a
    // new one. `startWebSocketConnection` below always calls
    // `WebSocketChannel.connect()` and overwrites `clientService.connection`
    // -- without this, the old socket was left orphaned, physically open
    // forever (a real client/server connection leak), every time
    // `listenForEvents()` ran more than once (e.g. `initialize()` calling
    // it unconditionally, plus `sendMessage()` calling it again whenever
    // `_isListeningForEvents` is still false, which races easily right
    // after opening the chat). Worse, any event the server pushed to that
    // orphaned socket between cancelling the Dart subscription above and
    // the new one confirming was silently lost. Closing the previous
    // connection first keeps at most one live physical socket, so there is
    // never a window where the server can push to a socket nobody is
    // listening to anymore.
    if (clientService.connection != null) {
      clientService.closeConnection();
    }

    clientService.startWebSocketConnection(
        localStorage.contactDao.getContact()!.pubsubToken ?? "");

    final newSubscription = clientService.connection!.stream.listen((event) {
      ChatwootEvent chatwootEvent = ChatwootEvent.fromJson(jsonDecode(event));
      if (chatwootEvent.type == ChatwootEventType.welcome) {
        callbacks.onWelcome?.call();
      } else if (chatwootEvent.type == ChatwootEventType.ping) {
        callbacks.onPing?.call();
      } else if (chatwootEvent.type == ChatwootEventType.confirm_subscription) {
        if (!_isListeningForEvents) {
          _isListeningForEvents = true;
        }
        _publishPresenceUpdates();
        callbacks.onConfirmedSubscription?.call();
      } else if (chatwootEvent.message?.event ==
          ChatwootEventMessageType.message_created) {
        print("here comes message: $event");
        final message = chatwootEvent.message!.data!.getMessage();
        localStorage.messagesDao.saveMessage(message);
        if (message.isMine) {
          // Defensive: `echo_id` is only guaranteed for a message this
          // client itself just sent (see ChatwootRepository.sendMessage).
          // A null echo_id here would previously crash this listener via
          // `!`, silently killing the realtime stream for every message
          // after it. Falling back to the message's own id keeps
          // onMessageDelivered's contract (a non-null id) without ever
          // throwing on an unexpected shape.
          callbacks.onMessageDelivered?.call(message,
              chatwootEvent.message!.data!.echoId ?? message.id.toString());
        } else {
          // With the isMine fix above, bot/system messages (message_type 3,
          // sender_type/sender_id null) land here -- inserted straight into
          // the UI via onMessageReceived, same as any other agent message,
          // instead of depending on an echo_id these payloads never carry.
          callbacks.onMessageReceived?.call(message);
        }
      } else if (chatwootEvent.message?.event ==
          ChatwootEventMessageType.message_updated) {
        print("here comes the updated message: $event");

        final message = chatwootEvent.message!.data!.getMessage();
        localStorage.messagesDao.saveMessage(message);

        callbacks.onMessageUpdated?.call(message);
      } else if (chatwootEvent.message?.event ==
          ChatwootEventMessageType.conversation_typing_off) {
        callbacks.onConversationStoppedTyping?.call();
      } else if (chatwootEvent.message?.event ==
          ChatwootEventMessageType.conversation_typing_on) {
        callbacks.onConversationStartedTyping?.call();
      } else if (chatwootEvent.message?.event ==
          ChatwootEventMessageType.conversation_status_changed) {
        // Update the persisted active conversation's status in place (no
        // more wiping its messages, which used to make the "resolved"
        // notice pointless -- the conversation and its history need to
        // stay readable so the UI can show a status banner over them).
        // See [ChatwootCallbacks.onConversationStatusChanged].
        final data = chatwootEvent.message?.data;
        final activeConversation =
            localStorage.conversationDao.getConversation();
        final newStatus = data?.status;
        if (activeConversation != null &&
            data?.id == activeConversation.id &&
            newStatus != null) {
          final updatedConversation = activeConversation.withStatus(
            newStatus,
            snoozedUntil: data?.snoozedUntil,
          );
          localStorage.conversationDao.saveConversation(updatedConversation);
          callbacks.onConversationStatusChanged?.call(
            updatedConversation.id,
            updatedConversation.statusEnum,
            updatedConversation.snoozedUntil,
          );
          if (updatedConversation.statusEnum ==
              ChatwootConversationStatus.resolved) {
            callbacks.onConversationResolved?.call();
          }
        }
      } else if (chatwootEvent.message?.event ==
          ChatwootEventMessageType.presence_update) {
        final presenceStatuses =
            (chatwootEvent.message!.data!.users as Map<dynamic, dynamic>)
                .values;
        final isOnline = presenceStatuses.contains("online");
        if (isOnline) {
          callbacks.onConversationIsOnline?.call();
          _presenceResetTimer?.cancel();
          _startPresenceResetTimer();
        } else {
          callbacks.onConversationIsOffline?.call();
        }
      } else {
        print("chatwoot unknown event: $event");
      }
    });
    _subscriptions.add(newSubscription);
  }

  /// Clears all data related to current chatwoot client instance
  @override
  Future<void> clear() async {
    await localStorage.clear();
  }

  /// Cancels websocket stream subscriptions and disposes [localStorage]
  @override
  void dispose() {
    localStorage.dispose();
    callbacks = ChatwootCallbacks();
    _presenceResetTimer?.cancel();
    _publishPresenceTimer?.cancel();
    _subscriptions.forEach((subs) {
      subs.cancel();
    });
  }

  ///Send actions like user started typing
  @override
  void sendAction(ChatwootActionType action) {
    clientService.sendAction(
        localStorage.contactDao.getContact()!.pubsubToken ?? "", action);
  }

  ///Publishes presence update to websocket channel at a 30 second interval
  void _publishPresenceUpdates() {
    sendAction(ChatwootActionType.update_presence);
    _publishPresenceTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      sendAction(ChatwootActionType.update_presence);
    });
  }

  ///Triggers an offline presence event after 40 seconds without receiving a presence update event
  void _startPresenceResetTimer() {
    _presenceResetTimer = Timer.periodic(Duration(seconds: 40), (timer) {
      callbacks.onConversationIsOffline?.call();
      _presenceResetTimer?.cancel();
    });
  }
}
