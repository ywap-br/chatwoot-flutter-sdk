import 'dart:async';
import 'dart:convert';

import 'package:chatwoot_sdk/chatwoot_callbacks.dart';
import 'package:chatwoot_sdk/data/chatwoot_repository.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_contact.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_conversation.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_message.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_user.dart';
import 'package:chatwoot_sdk/data/local/local_storage.dart';
import 'package:chatwoot_sdk/data/remote/chatwoot_client_exception.dart';
import 'package:chatwoot_sdk/data/remote/requests/chatwoot_action_data.dart';
import 'package:chatwoot_sdk/data/remote/requests/chatwoot_new_message_request.dart';
import 'package:chatwoot_sdk/data/remote/service/chatwoot_client_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/test_resources_util.dart';
import 'chatwoot_repository_test.mocks.dart';
import 'local/local_storage_test.mocks.dart';

@GenerateMocks(
    [LocalStorage, ChatwootClientService, ChatwootCallbacks, WebSocketChannel])
void main() {
  group("Chatwoot Repository Tests", () {
    late final ChatwootContact testContact;

    late final ChatwootConversation testConversation;
    final testUser = ChatwootUser(
        identifier: "identifier",
        identifierHash: "identifierHash",
        name: "name",
        email: "email",
        avatarUrl: "avatarUrl",
        customAttributes: {});
    late final ChatwootMessage testMessage;

    final mockLocalStorage = MockLocalStorage();
    final mockChatwootClientService = MockChatwootClientService();
    final mockChatwootCallbacks = MockChatwootCallbacks();
    final mockMessagesDao = MockChatwootMessagesDao();
    final mockContactDao = MockChatwootContactDao();
    final mockConversationDao = MockChatwootConversationDao();
    final mockUserDao = MockChatwootUserDao();
    StreamController mockWebSocketStream = StreamController.broadcast();
    final mockWebSocketChannel = MockWebSocketChannel();

    late final ChatwootRepository repo;

    setUpAll(() async {
      testContact = ChatwootContact.fromJson(
          await TestResourceUtil.readJsonResource(fileName: "contact"));
      testConversation = ChatwootConversation.fromJson(
          await TestResourceUtil.readJsonResource(fileName: "conversation"));
      testMessage = ChatwootMessage.fromJson(
          await TestResourceUtil.readJsonResource(fileName: "message"));

      when(mockLocalStorage.messagesDao).thenReturn(mockMessagesDao);
      when(mockLocalStorage.contactDao).thenReturn(mockContactDao);
      when(mockLocalStorage.userDao).thenReturn(mockUserDao);
      when(mockLocalStorage.conversationDao).thenReturn(mockConversationDao);
      when(mockChatwootClientService.connection)
          .thenReturn(mockWebSocketChannel);
      when(mockWebSocketChannel.stream)
          .thenAnswer((_) => mockWebSocketStream.stream);
      when(mockChatwootClientService.startWebSocketConnection(any))
          .thenAnswer((_) => () {});

      repo = ChatwootRepositoryImpl(
          clientService: mockChatwootClientService,
          localStorage: mockLocalStorage,
          streamCallbacks: mockChatwootCallbacks);
    });

    setUp(() {
      reset(mockChatwootCallbacks);
      reset(mockContactDao);
      reset(mockConversationDao);
      reset(mockUserDao);
      reset(mockMessagesDao);
      when(mockContactDao.getContact()).thenReturn(testContact);
      when(mockChatwootCallbacks.onConversationsRetrieved).thenReturn(null);
      when(mockConversationDao.saveConversations(any))
          .thenAnswer((_) => Future.microtask(() {}));
      mockWebSocketStream = StreamController.broadcast();
      when(mockWebSocketChannel.stream)
          .thenAnswer((_) => mockWebSocketStream.stream);
    });

    test(
        'Given messages are successfully fetched when getMessages is called, then callback should be called with fetched messages',
        () async {
      //GIVEN
      final testMessages = [testMessage];
      when(mockChatwootClientService.getAllMessages())
          .thenAnswer((_) => Future.value(testMessages));
      when(mockChatwootCallbacks.onMessagesRetrieved).thenAnswer((_) => (_) {});
      when(mockMessagesDao.saveAllMessages(any))
          .thenAnswer((_) => Future.microtask(() {}));

      //WHEN
      await repo.getMessages();

      //THEN
      verify(mockChatwootClientService.getAllMessages());
      verify(mockChatwootCallbacks.onMessagesRetrieved?.call(testMessages));
      verify(mockMessagesDao.saveAllMessages(testMessages));
    });

    test(
        'Given messages are fails to fetch when getMessages is called, then callback should be called with an error',
        () async {
      //GIVEN
      final testError = ChatwootClientException(
          "error", ChatwootClientExceptionType.GET_MESSAGES_FAILED);
      when(mockChatwootClientService.getAllMessages()).thenThrow(testError);
      when(mockChatwootCallbacks.onError).thenAnswer((_) => (_) {});
      when(mockChatwootCallbacks.onMessagesRetrieved).thenAnswer((_) => (_) {});

      //WHEN
      await repo.getMessages();

      //THEN
      verify(mockChatwootClientService.getAllMessages());
      verifyNever(mockChatwootCallbacks.onMessagesRetrieved);
      verify(mockChatwootCallbacks.onError?.call(testError));
      verifyNever(mockMessagesDao.saveAllMessages(any));
    });

    test(
        'Given persisted messages are successfully fetched when getPersitedMessages is called, then callback should be called with fetched messages',
        () async {
      //GIVEN
      final testMessages = [testMessage];
      when(mockMessagesDao.getMessages()).thenReturn(testMessages);
      when(mockChatwootCallbacks.onPersistedMessagesRetrieved)
          .thenAnswer((_) => (_) {});

      //WHEN
      repo.getPersistedMessages();

      //THEN
      verifyNever(mockChatwootClientService.getAllMessages());
      verify(mockChatwootCallbacks.onPersistedMessagesRetrieved
          ?.call(testMessages));
    });

    test(
        'Given message is successfully sent when sendMessage is called, then callback should be called with sent message',
        () async {
      //GIVEN
      final messageRequest =
          ChatwootNewMessageRequest(content: "new message", echoId: "echoId");
      when(mockChatwootClientService.createMessage(any))
          .thenAnswer((_) => Future.value(testMessage));
      when(mockChatwootCallbacks.onMessageSent).thenAnswer((_) => (_, __) {});
      when(mockMessagesDao.saveMessage(any))
          .thenAnswer((_) => Future.microtask(() {}));

      //WHEN
      await repo.sendMessage(messageRequest);

      //THEN
      verify(mockChatwootClientService.createMessage(messageRequest));
      verify(mockChatwootCallbacks.onMessageSent
          ?.call(testMessage, messageRequest.echoId));
      verify(mockMessagesDao.saveMessage(testMessage));
    });

    test(
        'Given message fails to send when sendMessage is called, then callback should be called with an error',
        () async {
      //GIVEN
      final testError = ChatwootClientException(
          "error", ChatwootClientExceptionType.SEND_MESSAGE_FAILED);
      final messageRequest =
          ChatwootNewMessageRequest(content: "new message", echoId: "echoId");
      when(mockChatwootClientService.createMessage(any)).thenThrow(testError);
      when(mockChatwootCallbacks.onError).thenAnswer((_) => (_) {});

      //WHEN
      await repo.sendMessage(messageRequest);

      //THEN
      verify(mockChatwootClientService.createMessage(messageRequest));
      verify(mockChatwootCallbacks.onError?.call(testError));
      verifyNever(mockMessagesDao.saveMessage(any));
    });

    test(
        'Given repo is initialized with user successfully when initialize is called, then client should be properly initialized',
        () async {
      //GIVEN
      when(mockChatwootClientService.getContact())
          .thenAnswer((_) => Future.value(testContact));
      when(mockContactDao.getContact()).thenReturn(testContact);
      when(mockConversationDao.getConversation()).thenReturn(testConversation);
      when(mockChatwootClientService.getConversations())
          .thenAnswer((_) => Future.value([testConversation]));
      when(mockUserDao.saveUser(any))
          .thenAnswer((_) => Future.microtask(() {}));
      when(mockContactDao.saveContact(any))
          .thenAnswer((_) => Future.microtask(() {}));
      when(mockConversationDao.saveConversation(any))
          .thenAnswer((_) => Future.microtask(() {}));
      when(mockChatwootClientService.startWebSocketConnection(any))
          .thenAnswer((_) => () {});

      //WHEN
      await repo.initialize(testUser);

      //THEN
      verify(mockChatwootClientService.getContact());
      verify(mockUserDao.saveUser(testUser));
      verify(mockContactDao.saveContact(testContact));
      verify(mockConversationDao.saveConversation(testConversation));
    });

    test(
        'Given repo is initialized with null user successfully when initialize is called, then client should be properly initialized',
        () async {
      //GIVEN
      when(mockChatwootClientService.getContact())
          .thenAnswer((_) => Future.value(testContact));
      when(mockContactDao.getContact()).thenReturn(testContact);
      when(mockConversationDao.getConversation()).thenReturn(testConversation);
      when(mockChatwootClientService.getConversations())
          .thenAnswer((_) => Future.value([testConversation]));
      when(mockUserDao.saveUser(any))
          .thenAnswer((_) => Future.microtask(() {}));
      when(mockContactDao.saveContact(any))
          .thenAnswer((_) => Future.microtask(() {}));
      when(mockConversationDao.saveConversation(any))
          .thenAnswer((_) => Future.microtask(() {}));
      when(mockChatwootClientService.startWebSocketConnection(any))
          .thenAnswer((_) => () {});

      //WHEN
      await repo.initialize(null);

      //THEN
      verifyNever(mockUserDao.saveUser(testUser));
      verify(mockContactDao.saveContact(testContact));
      verify(mockConversationDao.saveConversation(testConversation));
    });

    test(
        'Given conversations are successfully loaded when loadConversations is called, then conversations should be saved and callback triggered',
        () async {
      //GIVEN
      final testConversations = [testConversation];
      when(mockChatwootClientService.getConversations())
          .thenAnswer((_) => Future.value(testConversations));
      when(mockConversationDao.saveConversations(any))
          .thenAnswer((_) => Future.microtask(() {}));
      when(mockChatwootCallbacks.onConversationsRetrieved).thenReturn((_) {});

      //WHEN
      final result = await repo.loadConversations();

      //THEN
      verify(mockChatwootClientService.getConversations());
      verify(mockConversationDao.saveConversations(testConversations));
      verify(mockChatwootCallbacks.onConversationsRetrieved
          ?.call(testConversations));
      expect(result, testConversations);
    });

    test(
        'Given new conversation is successfully created when createNewConversation is called, then conversation should be saved and returned',
        () async {
      //GIVEN
      when(mockChatwootClientService.createConversation())
          .thenAnswer((_) => Future.value(testConversation));
      when(mockConversationDao.saveConversation(any))
          .thenAnswer((_) => Future.microtask(() {}));
      when(mockConversationDao.getConversations()).thenReturn([]);
      when(mockConversationDao.saveConversations(any))
          .thenAnswer((_) => Future.microtask(() {}));
      when(mockChatwootCallbacks.onConversationCreated).thenReturn((_) {});

      //WHEN
      final result = await repo.createNewConversation();

      //THEN
      verify(mockChatwootClientService.createConversation());
      verify(mockConversationDao.saveConversation(testConversation));
      verify(
          mockChatwootCallbacks.onConversationCreated?.call(testConversation));
      expect(result, testConversation);
    });

    test(
        'Given active conversation is set when setActiveConversation is called, then dao should be updated and messages fetched',
        () async {
      //GIVEN
      when(mockConversationDao.setActiveConversation(any))
          .thenAnswer((_) => Future.microtask(() {}));
      when(mockChatwootClientService.getAllMessages())
          .thenAnswer((_) => Future.value([testMessage]));
      when(mockMessagesDao.saveAllMessages(any))
          .thenAnswer((_) => Future.microtask(() {}));
      when(mockChatwootCallbacks.onMessagesRetrieved).thenReturn((_) {});

      //WHEN
      await repo.setActiveConversation(testConversation);

      //THEN
      verify(mockConversationDao.setActiveConversation(testConversation));
      verify(mockChatwootClientService.getAllMessages());
    });

    test(
        'Given getPersistedConversations is called, then conversations from dao should be returned',
        () {
      //GIVEN
      final testConversations = [testConversation];
      when(mockConversationDao.getConversations())
          .thenReturn(testConversations);
      when(mockChatwootCallbacks.onPersistedConversationsRetrieved)
          .thenReturn((_) {});

      //WHEN
      final result = repo.getPersistedConversations();

      //THEN
      expect(result, testConversations);
      verify(mockChatwootCallbacks.onPersistedConversationsRetrieved
          ?.call(testConversations));
    });

    test(
        'Given welcome event is received when listening for events, then callback welcome event should be triggered',
        () async {
      //GIVEN
      when(mockLocalStorage.dispose()).thenAnswer((_) => (_) {});
      when(mockChatwootCallbacks.onWelcome).thenAnswer((_) => () {});
      final dynamic welcomeEvent = {"type": "welcome"};
      repo.listenForEvents();

      //WHEN
      mockWebSocketStream.add(jsonEncode(welcomeEvent));
      await Future.delayed(Duration(seconds: 1));

      //THEN
      verify(mockChatwootCallbacks.onWelcome?.call());
    });

    test(
        'Given ping event is received when listening for events, then callback onPing event should be triggered',
        () async {
      //GIVEN
      when(mockLocalStorage.dispose()).thenAnswer((_) => (_) {});
      when(mockChatwootCallbacks.onPing).thenAnswer((_) => () {});
      final dynamic pingEvent = {"type": "ping", "message": 12243849943};
      repo.listenForEvents();

      //WHEN
      mockWebSocketStream.add(jsonEncode(pingEvent));
      await Future.delayed(Duration(seconds: 1));

      //THEN
      verify(mockChatwootCallbacks.onPing?.call());
    });

    test(
        'Given confirm subscription event is received when listening for events, then callback onConfirmSubscription event should be triggered',
        () async {
      //GIVEN
      when(mockLocalStorage.dispose()).thenAnswer((_) => (_) {});
      when(mockChatwootClientService.sendAction(any, any))
          .thenAnswer((_) => (_) {});
      when(mockChatwootCallbacks.onConfirmedSubscription)
          .thenAnswer((_) => () {});
      final dynamic confirmSubscriptionEvent = {"type": "confirm_subscription"};
      repo.listenForEvents();

      //WHEN
      mockWebSocketStream.add(jsonEncode(confirmSubscriptionEvent));
      await Future.delayed(Duration(seconds: 1));

      //THEN
      verify(mockChatwootCallbacks.onConfirmedSubscription?.call());
      verify(mockChatwootClientService.sendAction(
          testContact.pubsubToken, ChatwootActionType.update_presence));
    });

    test(
        'Given typing on event is received when listening for events, then callback onConversationStartedTyping event should be triggered',
        () async {
      //GIVEN
      when(mockLocalStorage.dispose()).thenAnswer((_) => (_) {});
      when(mockChatwootCallbacks.onConversationStartedTyping)
          .thenAnswer((_) => () {});
      final dynamic typingOnEvent = await TestResourceUtil.readJsonResource(
          fileName: "websocket_conversation_typing_on");
      repo.listenForEvents();

      //WHEN
      mockWebSocketStream.add(jsonEncode(typingOnEvent));
      await Future.delayed(Duration(seconds: 1));

      //THEN
      verify(mockChatwootCallbacks.onConversationStartedTyping?.call());
    });

    test(
        'Given online presence update event is received when listening for events, then callback onConversationIsOnline event should be triggered',
        () async {
      //GIVEN
      when(mockLocalStorage.dispose()).thenAnswer((_) => (_) {});
      when(mockChatwootCallbacks.onConversationIsOnline)
          .thenAnswer((_) => () {});
      final dynamic presenceUpdateOnlineEvent =
          await TestResourceUtil.readJsonResource(
              fileName: "websocket_presence_update");
      repo.listenForEvents();

      //WHEN
      mockWebSocketStream.add(jsonEncode(presenceUpdateOnlineEvent));
      await Future.delayed(Duration(seconds: 1));

      //THEN
      verify(mockChatwootCallbacks.onConversationIsOnline?.call());
    });

    test(
        'Given conversation is offline when listening for events, then callback onConversationIsOffline event should be triggered',
        () async {
      //GIVEN
      when(mockLocalStorage.dispose()).thenAnswer((_) => (_) {});
      when(mockChatwootCallbacks.onConversationIsOffline)
          .thenAnswer((_) => () {});
      when(mockChatwootCallbacks.onConversationIsOnline)
          .thenAnswer((_) => () {});
      final dynamic presenceUpdateOnlineEvent =
          await TestResourceUtil.readJsonResource(
              fileName: "websocket_presence_update");
      repo.listenForEvents();

      //WHEN
      mockWebSocketStream.add(jsonEncode(presenceUpdateOnlineEvent));
      await Future.delayed(Duration(seconds: 41));

      //THEN
      verify(mockChatwootCallbacks.onConversationIsOnline?.call());
      verify(mockChatwootCallbacks.onConversationIsOffline?.call());
    }, timeout: Timeout(Duration(seconds: 45)));

    test(
        'Given typing off event is received when listening for events, then callback onConversationStoppedTyping event should be triggered',
        () async {
      //GIVEN
      when(mockLocalStorage.dispose()).thenAnswer((_) => (_) {});
      when(mockChatwootCallbacks.onConversationStoppedTyping)
          .thenAnswer((_) => () {});
      final dynamic typingOffEvent = await TestResourceUtil.readJsonResource(
          fileName: "websocket_conversation_typing_off");
      repo.listenForEvents();

      //WHEN
      mockWebSocketStream.add(jsonEncode(typingOffEvent));
      await Future.delayed(Duration(seconds: 1));

      //THEN
      verify(mockChatwootCallbacks.onConversationStoppedTyping?.call());
    });

    test(
        'Given conversation status changed event is received when listening for events, then callback onConversationResolved event should be triggered',
        () async {
      //GIVEN
      when(mockLocalStorage.conversationDao).thenReturn(mockConversationDao);
      when(mockConversationDao.getConversation()).thenReturn(testConversation);
      when(mockLocalStorage.dispose()).thenAnswer((_) => (_) {});
      when(mockChatwootCallbacks.onConversationResolved)
          .thenAnswer((_) => () {});
      when(mockChatwootCallbacks.onConversationStatusChanged)
          .thenAnswer((_) => (conversationId, status, snoozedUntil) {});
      final dynamic resolvedEvent = await TestResourceUtil.readJsonResource(
          fileName: "websocket_conversation_status_changed");
      repo.listenForEvents();

      //WHEN
      mockWebSocketStream.add(jsonEncode(resolvedEvent));
      await Future.delayed(Duration(seconds: 1));

      //THEN
      verify(mockChatwootCallbacks.onConversationResolved?.call());
      verify(mockChatwootCallbacks.onConversationStatusChanged?.call(
          testConversation.id, ChatwootConversationStatus.resolved, null));
    });

    test(
        'Given an updated message event is received when listening for events, then callback onMessageUpdated event should be triggered',
        () async {
      //GIVEN
      when(mockLocalStorage.dispose()).thenAnswer((_) => (_) {});
      when(mockMessagesDao.saveMessage(any))
          .thenAnswer((_) => Future.microtask(() {}));
      when(mockChatwootCallbacks.onMessageUpdated).thenAnswer((_) => (_) {});
      final dynamic messageUpdatedEvent =
          await TestResourceUtil.readJsonResource(
              fileName: "websocket_message_updated");

      repo.listenForEvents();

      //WHEN
      mockWebSocketStream.add(jsonEncode(messageUpdatedEvent));
      await Future.delayed(Duration(seconds: 1));

      //THEN
      final message =
          ChatwootMessage.fromJson(messageUpdatedEvent["message"]["data"]);
      verify(mockChatwootCallbacks.onMessageUpdated?.call(message));
    });

    test(
        'Given new message event is sent when listening for events, then callback onMessageSent event should be triggered',
        () async {
      //GIVEN
      when(mockLocalStorage.dispose()).thenAnswer((_) => (_) {});
      when(mockChatwootCallbacks.onMessageDelivered)
          .thenAnswer((_) => (_, __) {});
      when(mockMessagesDao.saveMessage(any))
          .thenAnswer((_) => Future.microtask(() {}));
      final dynamic messageSentEvent = {
        "type": "message",
        "message": {
          "event": "message.created",
          "data": {
            "id": 0,
            "content": "content",
            "echo_id": "echo_id",
            "message_type": 0,
            "content_type": "contentType",
            "content_attributes": "contentAttributes",
            "created_at": DateTime.now().toString(),
            "conversation_id": 0,
            "attachments": [],
          }
        }
      };

      repo.listenForEvents();

      //WHEN
      mockWebSocketStream.add(jsonEncode(messageSentEvent));
      await Future.delayed(Duration(seconds: 1));

      //THEN
      final message =
          ChatwootMessage.fromJson(messageSentEvent["message"]["data"]);
      verify(mockChatwootCallbacks.onMessageDelivered
          ?.call(message, messageSentEvent["message"]["echo_id"]));
    });

    test(
        'Given a bot/system message.created event (message_type 3, sender_type/sender_id null, no echo_id) is received, then onMessageReceived should be triggered instead of onMessageDelivered',
        () async {
      //GIVEN
      when(mockLocalStorage.dispose()).thenAnswer((_) => (_) {});
      when(mockChatwootCallbacks.onMessageReceived).thenAnswer((_) => (_) {});
      when(mockChatwootCallbacks.onMessageDelivered)
          .thenAnswer((_) => (_, __) {});
      when(mockMessagesDao.saveMessage(any))
          .thenAnswer((_) => Future.microtask(() {}));
      // Real-world shape reported for a bot/automation reply: no echo_id
      // (this client never sent it), sender_type/sender_id null. Before the
      // isMine fix this fell into the onMessageDelivered branch, forcing a
      // non-null read of a null echo_id and silently killing the listener.
      final dynamic botMessageEvent = {
        "type": "message",
        "message": {
          "event": "message.created",
          "data": {
            "id": 9001,
            "content": "Sua fatura foi enviada por e-mail.",
            "message_type": 3,
            "content_type": "text",
            "content_attributes": {},
            "created_at": DateTime.now().toString(),
            "conversation_id": 202,
            "sender_type": null,
            "sender_id": null,
            "attachments": [],
          }
        }
      };

      repo.listenForEvents();

      //WHEN
      mockWebSocketStream.add(jsonEncode(botMessageEvent));
      await Future.delayed(Duration(seconds: 1));

      //THEN
      final message =
          ChatwootMessage.fromJson(botMessageEvent["message"]["data"]);
      expect(message.isMine, isFalse);
      verify(mockChatwootCallbacks.onMessageReceived?.call(message));
      // The isMine branch (onMessageDelivered) is never even entered for
      // this message, so its getter is never accessed.
      verifyNever(mockChatwootCallbacks.onMessageDelivered);
    });

    test(
        'Given a message.created event for my own message arrives without echo_id, then onMessageDelivered falls back to the message id instead of throwing',
        () async {
      //GIVEN
      when(mockLocalStorage.dispose()).thenAnswer((_) => (_) {});
      when(mockChatwootCallbacks.onMessageDelivered)
          .thenAnswer((_) => (_, __) {});
      when(mockMessagesDao.saveMessage(any))
          .thenAnswer((_) => Future.microtask(() {}));
      final dynamic noEchoIdEvent = {
        "type": "message",
        "message": {
          "event": "message.created",
          "data": {
            "id": 9002,
            "content": "conteudo",
            "message_type": 0,
            "content_type": "text",
            "content_attributes": {},
            "created_at": DateTime.now().toString(),
            "conversation_id": 202,
            "attachments": [],
          }
        }
      };

      repo.listenForEvents();

      //WHEN
      mockWebSocketStream.add(jsonEncode(noEchoIdEvent));
      await Future.delayed(Duration(seconds: 1));

      //THEN
      final message =
          ChatwootMessage.fromJson(noEchoIdEvent["message"]["data"]);
      verify(mockChatwootCallbacks.onMessageDelivered
          ?.call(message, message.id.toString()));
    });

    test(
        'Given unknown event is received when listening for events, then no callback event should be triggered',
        () async {
      //GIVEN
      when(mockLocalStorage.dispose()).thenAnswer((_) => (_) {});
      final dynamic unknownEvent = {"type": "unknown"};
      repo.listenForEvents();

      //WHEN
      mockWebSocketStream.add(jsonEncode(unknownEvent));
      await Future.delayed(Duration(seconds: 1));

      //THEN
      verifyZeroInteractions(mockChatwootCallbacks);
      repo.dispose();
    });

    test(
        'Given listenForEvents is called twice in a row, then the previous physical websocket connection is closed before the new one is started',
        () async {
      //GIVEN
      when(mockLocalStorage.dispose()).thenAnswer((_) => (_) {});
      when(mockChatwootClientService.closeConnection())
          .thenAnswer((_) => (_) {});

      //WHEN
      repo.listenForEvents();
      repo.listenForEvents();

      //THEN
      // `closeConnection` is called once per `listenForEvents()` call that
      // finds an existing `clientService.connection` (the shared mock is
      // stubbed in setUpAll to always return a non-null connection), and
      // always before `startWebSocketConnection` opens the replacement --
      // otherwise the previous physical socket is left orphaned (leaked)
      // and can silently lose an event pushed between the old Dart
      // subscription being cancelled and the new one confirming.
      verifyInOrder([
        mockChatwootClientService.closeConnection(),
        mockChatwootClientService.startWebSocketConnection(any),
        mockChatwootClientService.closeConnection(),
        mockChatwootClientService.startWebSocketConnection(any),
      ]);
    });

    test(
        'Given action is successfully sent when sendAction is called, then client service sendAction should be triggered',
        () {
      //GIVEN
      when(mockContactDao.getContact()).thenReturn(testContact);
      when(mockChatwootClientService.sendAction(any, any))
          .thenAnswer((realInvocation) => Future.microtask(() {}));

      //WHEN
      repo.sendAction(ChatwootActionType.update_presence);

      //THEN
      verify(mockChatwootClientService.sendAction(
          testContact.pubsubToken, ChatwootActionType.update_presence));
    });

    test(
        'Given repository is successfully disposed when dispose is called, then localStorage should be disposed',
        () {
      //GIVEN
      when(mockLocalStorage.dispose()).thenAnswer((_) => (_) {});

      //WHEN
      repo.dispose();

      //THEN
      verify(mockLocalStorage.dispose());
    });

    test(
        'Given repository is successfully cleared when clear is called, then localStorage should be cleared',
        () {
      //GIVEN
      when(mockLocalStorage.dispose()).thenAnswer((_) => (_) {});

      //WHEN
      repo.clear();

      //THEN
      verify(mockLocalStorage.clear());
    });

    tearDown(() async {
      await mockWebSocketStream.close();
    });

    tearDownAll(() {
      repo.dispose();
    });
  });
}
