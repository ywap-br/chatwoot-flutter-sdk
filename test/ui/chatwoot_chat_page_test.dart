import 'dart:convert';
import 'dart:io';

import 'package:chatwoot_sdk/data/local/entity/chatwoot_contact.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_conversation.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_message.dart';
import 'package:chatwoot_sdk/ui/chatwoot_chat_page.dart';
import 'package:chatwoot_sdk/ui/chatwoot_chat_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// Minimal valid 1x1 transparent PNG, used as a real, quickly-decodable file
// for [ChatwootChatTheme.avatarImageSource] -- avoids the network/asset
// image-loading errors flutter_test surfaces as test failures when a
// NetworkImage/AssetImage can't actually resolve in the test environment.
const _kMinimalPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY'
    '42YAAAAASUVORK5CYII=';

void main() {
  late File avatarFile;

  setUpAll(() async {
    avatarFile = File('${Directory.systemTemp.path}/chatwoot_test_avatar.png');
    await avatarFile.writeAsBytes(base64Decode(_kMinimalPngBase64));
  });

  tearDownAll(() async {
    if (await avatarFile.exists()) {
      await avatarFile.delete();
    }
  });

  final testContact = ChatwootContact(
    id: 1,
    contactIdentifier: "identifier",
    pubsubToken: "token",
  );

  ChatwootConversation buildConversation(int id) {
    return ChatwootConversation(
      id: id,
      inboxId: 1,
      contact: testContact,
      status: "open",
      messages: const [],
    );
  }

  ChatwootMessage buildMessage({
    required int id,
    required int conversationId,
    String content = 'msg',
    int messageType = 0,
  }) {
    return ChatwootMessage(
      id: id,
      content: content,
      messageType: messageType,
      contentType: 'text',
      contentAttributes: null,
      createdAt: DateTime.now().toIso8601String(),
      conversationId: conversationId,
      attachments: const [],
      sender: null,
    );
  }

  group('ChatwootChat onConversationCreated', () {
    testWidgets(
        'no longer inserts a synthetic "Ticket #xx aberto" message -- a new conversation starts empty',
        (WidgetTester tester) async {
      ChatwootConversation? notifiedConversation;

      await tester.pumpWidget(
        MaterialApp(
          home: ChatwootChat(
            baseUrl: 'https://example.invalid',
            inboxIdentifier: 'inbox',
            showConversationHistory: true,
            onConversationCreated: (conversation) {
              notifiedConversation = conversation;
            },
          ),
        ),
      );
      // Let the (network-backed, failing-fast against an invalid host)
      // ChatwootClient.create() future settle without ever awaiting it, so
      // it doesn't interfere with the callback we're driving by hand below.
      await tester.pump();

      final dynamic chatState = tester.state(find.byType(ChatwootChat));
      final conversation = buildConversation(42);

      chatState.chatwootCallbacks.onConversationCreated(conversation);
      await tester.pump();

      expect(notifiedConversation, conversation);

      final chatWidget = tester.widget<Chat>(find.byType(Chat));
      expect(chatWidget.messages, isEmpty);
      // The header's ticket badge ("Ticket #42") is a separate, intentional
      // feature (see _buildTicketBadge) and legitimately still shows here;
      // only the synthetic *message* bubble ("...aberto") must be gone.
      expect(find.textContaining('aberto'), findsNothing);
    });
  });

  group('ChatwootChat showAgentIdentity', () {
    Widget buildChat({required bool showAgentIdentity}) {
      return MaterialApp(
        home: ChatwootChat(
          baseUrl: 'https://example.invalid',
          inboxIdentifier: 'inbox',
          showConversationHistory: false,
          showUserNames: true,
          showAgentIdentity: showAgentIdentity,
          theme: ChatwootChatTheme(
            avatarImageSource: avatarFile.path,
          ),
        ),
      );
    }

    testWidgets(
        'true (default) leaves per-message avatar/name as real agent identity',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildChat(showAgentIdentity: true));
      await tester.pump();

      final chatWidget = tester.widget<Chat>(find.byType(Chat));
      // avatarBuilder null => flutter_chat_ui falls back to each message's
      // own author avatar instead of the fixed one.
      expect(chatWidget.avatarBuilder, isNull);
      expect(chatWidget.showUserNames, isTrue);
    });

    testWidgets(
        'false hides the per-message name and forces the fixed avatar on every received message',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildChat(showAgentIdentity: false));
      await tester.pump();

      final chatWidget = tester.widget<Chat>(find.byType(Chat));
      expect(chatWidget.avatarBuilder, isNotNull);
      // Forced false even though showUserNames: true was passed in.
      expect(chatWidget.showUserNames, isFalse);
    });
  });

  group('ChatwootChat snoozed banner', () {
    ChatwootConversation buildSnoozedConversation({String? snoozedUntil}) {
      return ChatwootConversation(
        id: 7,
        inboxId: 1,
        contact: testContact,
        status: 'snoozed',
        snoozedUntil: snoozedUntil,
        messages: const [],
      );
    }

    testWidgets(
        'valid snoozedUntil shows the banner with the formatted dd/MM/yyyy HH:mm date',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatwootChat(
            baseUrl: 'https://example.invalid',
            inboxIdentifier: 'inbox',
            showConversationHistory: true,
          ),
        ),
      );
      await tester.pump();

      final dynamic chatState = tester.state(find.byType(ChatwootChat));
      chatState.chatwootCallbacks.onConversationCreated(
          buildSnoozedConversation(snoozedUntil: '2026-09-14T22:52:37.000Z'));
      await tester.pump();

      expect(
        find.textContaining('O ticket foi marcado como em espera, com '
            'prazo para retorno em: 14/09/2026 22:52'),
        findsOneWidget,
      );
    });

    testWidgets('null snoozedUntil falls back to the plain status text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatwootChat(
            baseUrl: 'https://example.invalid',
            inboxIdentifier: 'inbox',
            showConversationHistory: true,
          ),
        ),
      );
      await tester.pump();

      final dynamic chatState = tester.state(find.byType(ChatwootChat));
      chatState.chatwootCallbacks
          .onConversationCreated(buildSnoozedConversation(snoozedUntil: null));
      await tester.pump();

      expect(find.text('Em espera'), findsWidgets);
      expect(find.textContaining('prazo para retorno'), findsNothing);
    });

    testWidgets(
        'invalid (unparsable) snoozedUntil falls back to the plain status text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatwootChat(
            baseUrl: 'https://example.invalid',
            inboxIdentifier: 'inbox',
            showConversationHistory: true,
          ),
        ),
      );
      await tester.pump();

      final dynamic chatState = tester.state(find.byType(ChatwootChat));
      chatState.chatwootCallbacks.onConversationCreated(
          buildSnoozedConversation(snoozedUntil: 'not-a-date'));
      await tester.pump();

      expect(find.text('Em espera'), findsWidgets);
      expect(find.textContaining('prazo para retorno'), findsNothing);
    });
  });

  group('ChatwootChat onMessageReceived deduplication', () {
    testWidgets(
        'the same message_created event (same id) received twice results in a single message in _messages',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatwootChat(
            baseUrl: 'https://example.invalid',
            inboxIdentifier: 'inbox',
            showConversationHistory: false,
          ),
        ),
      );
      // Let the (network-backed, failing-fast against an invalid host)
      // ChatwootClient.create() future settle without ever awaiting it.
      await tester.pump();

      final dynamic chatState = tester.state(find.byType(ChatwootChat));
      // `onMessageReceived` is now scoped to the active conversation (see
      // the cross-conversation message isolation group below), so give it
      // one matching the bot message's conversationId before dispatching --
      // otherwise the event would be correctly ignored as belonging to no
      // conversation currently on screen, which isn't what this test is
      // about (it's testing de-duplication, not the scoping itself).
      chatState.chatwootCallbacks.onConversationCreated(buildConversation(202));
      await tester.pump();

      // Sender-less bot/system message (message_type 3), the shape that
      // was observed rendering duplicated in the app.
      final botMessage = ChatwootMessage(
        id: 9001,
        content: 'Sua fatura foi enviada por e-mail.',
        messageType: 3,
        contentType: 'text',
        contentAttributes: {},
        createdAt: DateTime.now().toIso8601String(),
        conversationId: 202,
        attachments: const [],
        sender: null,
      );

      chatState.chatwootCallbacks.onMessageReceived(botMessage);
      await tester.pump();
      chatState.chatwootCallbacks.onMessageReceived(botMessage);
      await tester.pump();

      final chatWidget = tester.widget<Chat>(find.byType(Chat));
      expect(chatWidget.messages.length, 1);
      expect(chatWidget.messages.single.id, botMessage.id.toString());
    });
  });

  group('ChatwootChat _handleMessageSent guard', () {
    // Regression for the RangeError this used to throw: the user sends a
    // message (local echo added via `_addMessage`), then switches to a
    // different conversation before the delivery/sent confirmation comes
    // back -- `_handleSelectConversation` replaces `_messages` wholesale, so
    // the confirmation's `indexWhere` lookup no longer finds the echoed
    // message and returns -1. `_messages[-1]` throws in Dart (unlike
    // Python's negative indexing), which used to crash the widget. Starting
    // `_messages` empty (no conversation ever selected) reproduces the same
    // "id not found" precondition without needing the full switch dance.
    ChatwootMessage buildStaleMessage(int id) {
      return ChatwootMessage(
        id: id,
        content: 'stale echo, conversation switched before confirmation',
        messageType: 0,
        contentType: 'text',
        contentAttributes: null,
        createdAt: DateTime.now().toIso8601String(),
        conversationId: 1,
        attachments: const [],
        sender: null,
      );
    }

    testWidgets(
        'onMessageDelivered for an echoId no longer present in _messages does not throw',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatwootChat(
            baseUrl: 'https://example.invalid',
            inboxIdentifier: 'inbox',
            showConversationHistory: false,
          ),
        ),
      );
      await tester.pump();

      final dynamic chatState = tester.state(find.byType(ChatwootChat));

      expect(
        () => chatState.chatwootCallbacks
            .onMessageDelivered(buildStaleMessage(1001), 'gone-echo-id-1'),
        returnsNormally,
      );
      await tester.pump();

      final chatWidget = tester.widget<Chat>(find.byType(Chat));
      expect(chatWidget.messages, isEmpty);
    });

    testWidgets(
        'onMessageSent for an echoId no longer present in _messages does not throw',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatwootChat(
            baseUrl: 'https://example.invalid',
            inboxIdentifier: 'inbox',
            showConversationHistory: false,
          ),
        ),
      );
      await tester.pump();

      final dynamic chatState = tester.state(find.byType(ChatwootChat));

      expect(
        () => chatState.chatwootCallbacks
            .onMessageSent(buildStaleMessage(1002), 'gone-echo-id-2'),
        returnsNormally,
      );
      await tester.pump();

      final chatWidget = tester.widget<Chat>(find.byType(Chat));
      expect(chatWidget.messages, isEmpty);
    });
  });

  // Regression for the reported crash: with `showConversationHistory:
  // false` (or even with it enabled but a contact with more than one
  // conversation), `conversation.updated`/`message.created` websocket
  // events for a DIFFERENT conversation of the same contact -- and
  // `getAllMessages()`'s cross-conversation response -- used to be merged
  // straight into `_messages` with no filter by `conversationId`. That
  // corrupted the single active conversation's message list with another
  // conversation's messages, which `flutter_chat_ui`'s
  // `SliverAnimatedList` isn't built to tolerate (it expects controlled,
  // incremental mutation), crashing with "child == null || indexOf(child)
  // > index" followed by duplicate-GlobalKey/deactivated-widget errors.
  group('ChatwootChat cross-conversation message isolation', () {
    testWidgets(
        'onMessagesRetrieved with messages from two conversations of the same contact only merges the active conversation\'s messages',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatwootChat(
            baseUrl: 'https://example.invalid',
            inboxIdentifier: 'inbox',
            showConversationHistory: false,
          ),
        ),
      );
      await tester.pump();

      final dynamic chatState = tester.state(find.byType(ChatwootChat));
      chatState.chatwootCallbacks.onConversationCreated(buildConversation(43));
      await tester.pump();

      // Mirrors the real log: `getAllMessages()` returning messages for
      // conversation_id 48 and 43 (same contact) interleaved.
      chatState.chatwootCallbacks.onMessagesRetrieved([
        buildMessage(id: 1, conversationId: 48, content: 'conv48-a'),
        buildMessage(id: 2, conversationId: 43, content: 'conv43-a'),
        buildMessage(id: 3, conversationId: 48, content: 'conv48-b'),
        buildMessage(id: 4, conversationId: 43, content: 'conv43-b'),
      ]);
      await tester.pump();

      final chatWidget = tester.widget<Chat>(find.byType(Chat));
      expect(chatWidget.messages.map((m) => m.id).toSet(), {'2', '4'});
      expect(find.textContaining('conv48'), findsNothing);
    });

    testWidgets(
        'onPersistedMessagesRetrieved only shows the active conversation\'s persisted messages',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatwootChat(
            baseUrl: 'https://example.invalid',
            inboxIdentifier: 'inbox',
            showConversationHistory: false,
          ),
        ),
      );
      await tester.pump();

      final dynamic chatState = tester.state(find.byType(ChatwootChat));
      chatState.chatwootCallbacks.onConversationCreated(buildConversation(43));
      await tester.pump();

      chatState.chatwootCallbacks.onPersistedMessagesRetrieved([
        buildMessage(id: 1, conversationId: 48, content: 'conv48-persisted'),
        buildMessage(id: 2, conversationId: 43, content: 'conv43-persisted'),
      ]);
      await tester.pump();

      final chatWidget = tester.widget<Chat>(find.byType(Chat));
      expect(chatWidget.messages.length, 1);
      expect(chatWidget.messages.single.id, '2');
    });

    testWidgets(
        'onMessagesRetrieved before any active conversation is selected merges nothing (empty is safer than showing the wrong conversation\'s messages)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatwootChat(
            baseUrl: 'https://example.invalid',
            inboxIdentifier: 'inbox',
            showConversationHistory: false,
          ),
        ),
      );
      await tester.pump();

      final dynamic chatState = tester.state(find.byType(ChatwootChat));
      // No conversation has been selected/created yet -- _activeConversation
      // is still null.
      chatState.chatwootCallbacks.onMessagesRetrieved([
        buildMessage(id: 1, conversationId: 43),
        buildMessage(id: 2, conversationId: 48),
      ]);
      await tester.pump();

      final chatWidget = tester.widget<Chat>(find.byType(Chat));
      expect(chatWidget.messages, isEmpty);
    });

    testWidgets(
        'realtime onMessageReceived/onMessageUpdated for a background conversation do not leak into the active conversation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatwootChat(
            baseUrl: 'https://example.invalid',
            inboxIdentifier: 'inbox',
            showConversationHistory: false,
          ),
        ),
      );
      await tester.pump();

      final dynamic chatState = tester.state(find.byType(ChatwootChat));
      chatState.chatwootCallbacks.onConversationCreated(buildConversation(43));
      await tester.pump();

      chatState.chatwootCallbacks
          .onMessageReceived(buildMessage(id: 10, conversationId: 48));
      await tester.pump();
      chatState.chatwootCallbacks
          .onMessageReceived(buildMessage(id: 11, conversationId: 43));
      await tester.pump();
      chatState.chatwootCallbacks.onMessageUpdated(
          buildMessage(id: 10, conversationId: 48, content: 'edited-48'));
      await tester.pump();

      final chatWidget = tester.widget<Chat>(find.byType(Chat));
      expect(chatWidget.messages.length, 1);
      expect(chatWidget.messages.single.id, '11');
    });

    testWidgets(
        'switching the active conversation (real _handleSelectConversation flow) never leaks the previous conversation\'s messages, including against a stray realtime event',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatwootChat(
            baseUrl: 'https://example.invalid',
            inboxIdentifier: 'inbox',
            showConversationHistory: true,
          ),
        ),
      );
      await tester.pump();

      final dynamic chatState = tester.state(find.byType(ChatwootChat));
      final conv43 = ChatwootConversation(
        id: 43,
        inboxId: 1,
        contact: testContact,
        status: 'open',
        messages: [
          buildMessage(id: 21, conversationId: 43, content: 'hello-43')
        ],
      );
      final conv48 = ChatwootConversation(
        id: 48,
        inboxId: 1,
        contact: testContact,
        status: 'open',
        messages: [
          buildMessage(id: 22, conversationId: 48, content: 'hello-48')
        ],
      );
      chatState.chatwootCallbacks.onConversationsRetrieved([conv43, conv48]);
      await tester.pump();

      // Select conversation 43 through the real recent-conversations list
      // tap -- drives the actual `_handleSelectConversation` code path, not
      // a stand-in.
      await tester.tap(find.text('Ticket #43'));
      await tester.pump();

      var chatWidget = tester.widget<Chat>(find.byType(Chat));
      expect(chatWidget.messages.single.id, '21');

      // A stray realtime event for the OTHER conversation must not leak in
      // while 43 is the one on screen.
      chatState.chatwootCallbacks
          .onMessageReceived(buildMessage(id: 23, conversationId: 48));
      await tester.pump();
      chatWidget = tester.widget<Chat>(find.byType(Chat));
      expect(chatWidget.messages.length, 1);
      expect(chatWidget.messages.single.id, '21');

      // Go back and select conversation 48 -- only its own message shows;
      // nothing from 43 carries over.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.tap(find.text('Ticket #48'));
      await tester.pump();

      chatWidget = tester.widget<Chat>(find.byType(Chat));
      expect(chatWidget.messages.single.id, '22');
    });

    testWidgets(
        'interleaved conversation.updated/message.created-style events for two conversations of the same contact do not crash the widget while one is on screen',
        (WidgetTester tester) async {
      // Reproduces the reported production scenario end-to-end through the
      // real ChatwootChat/Chat (flutter_chat_ui) widget tree:
      // `showConversationHistory: false` jumps straight into a single
      // conversation, then realtime events for a second conversation of
      // the same contact (conversation_id 48) arrive intermixed with
      // events for the active one (43), the exact shape from the crash
      // log. The widget-test environment doesn't reproduce
      // `SliverAnimatedList`'s own internal diffing/scroll-physics
      // machinery (no real viewport), so a clean `tester.takeException()`
      // here isn't a full substitute for manual/E2E verification of the
      // original crash -- but it does prove `_messages` (what actually
      // feeds that list) never mixes conversations, which was the root
      // cause of the corrupt mutations `SliverAnimatedList` asserted on.
      await tester.pumpWidget(
        MaterialApp(
          home: ChatwootChat(
            baseUrl: 'https://example.invalid',
            inboxIdentifier: 'inbox',
            showConversationHistory: false,
          ),
        ),
      );
      await tester.pump();

      final dynamic chatState = tester.state(find.byType(ChatwootChat));
      chatState.chatwootCallbacks.onConversationCreated(buildConversation(43));
      await tester.pump();

      chatState.chatwootCallbacks
          .onMessageReceived(buildMessage(id: 101, conversationId: 48));
      await tester.pump();
      chatState.chatwootCallbacks
          .onMessageReceived(buildMessage(id: 102, conversationId: 43));
      await tester.pump();
      chatState.chatwootCallbacks.onMessageUpdated(
          buildMessage(id: 101, conversationId: 48, content: 'edited-48'));
      await tester.pump();
      chatState.chatwootCallbacks
          .onMessageReceived(buildMessage(id: 103, conversationId: 48));
      await tester.pump();
      chatState.chatwootCallbacks.onMessagesRetrieved([
        buildMessage(id: 104, conversationId: 48, content: 'conv48-c'),
        buildMessage(id: 105, conversationId: 43, content: 'conv43-c'),
      ]);
      await tester.pump();
      // Every `buildMessage` above defaults to `messageType: 0` (isMine),
      // so flutter_chat_ui's `ChatList` schedules a 100ms
      // `Future.delayed(...).animateTo(...)` "scroll to bottom" timer on
      // each insertion (see `_scrollToBottomIfNeeded` in
      // flutter_chat_ui's chat_list.dart). Settle past that delay so no
      // Timer is left pending when the widget tree is torn down at the
      // end of this test -- unrelated to the fix under test, just cleanup.
      await tester.pump(const Duration(milliseconds: 150));

      expect(tester.takeException(), isNull);

      final chatWidget = tester.widget<Chat>(find.byType(Chat));
      // Only conversation 43's messages (102 and 105) ever entered
      // `_messages` -- 101/103/104 (conversation 48) never leaked in.
      expect(chatWidget.messages.map((m) => m.id).toSet(), {'102', '105'});
    });
  });

  group('ChatwootChat rapid message sending race condition', () {
    testWidgets(
        'delivery confirmation arriving while another message is being sent does not overwrite or duplicate messages',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatwootChat(
            baseUrl: 'https://example.invalid',
            inboxIdentifier: 'inbox',
            showConversationHistory: false,
          ),
        ),
      );
      await tester.pump();

      final dynamic chatState = tester.state(find.byType(ChatwootChat));
      chatState.chatwootCallbacks.onConversationCreated(buildConversation(43));
      await tester.pump();

      final user = types.User(id: 'test-user');
      final msg1 = types.TextMessage(
        id: 'echo-1',
        author: user,
        text: 'msg 1',
        status: types.Status.sending,
      );
      chatState.addMessageForTesting(msg1);

      // Delivery arrives for msg 1 (echoId 'echo-1'), queuing addPostFrameCallback with index 0
      final delivered1 = buildMessage(id: 101, conversationId: 43, content: 'msg 1');
      chatState.chatwootCallbacks.onMessageDelivered(delivered1, 'echo-1');

      // User rapidly sends msg 2 BEFORE the next pump/frame
      final msg2 = types.TextMessage(
        id: 'echo-2',
        author: user,
        text: 'msg 2',
        status: types.Status.sending,
      );
      chatState.addMessageForTesting(msg2);

      await tester.pump();

      final chatWidget = tester.widget<Chat>(find.byType(Chat));
      final messageIds = chatWidget.messages.map((m) => m.id).toList();

      expect(messageIds, contains('echo-1'));
      expect(messageIds, contains('echo-2'));
      expect(messageIds.length, 2);
      expect(messageIds.toSet().length, 2,
          reason: 'Must not contain duplicate message IDs');
    });

    testWidgets(
        'onMessagesRetrieved does not duplicate a message that is already in _messages with a different status',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatwootChat(
            baseUrl: 'https://example.invalid',
            inboxIdentifier: 'inbox',
            showConversationHistory: false,
          ),
        ),
      );
      await tester.pump();

      final dynamic chatState = tester.state(find.byType(ChatwootChat));
      chatState.chatwootCallbacks.onConversationCreated(buildConversation(43));
      await tester.pump();

      final user = types.User(id: 'test-user');
      final msgSending = types.TextMessage(
        id: '101',
        author: user,
        text: 'msg 101',
        status: types.Status.sending,
      );
      chatState.addMessageForTesting(msgSending);
      await tester.pump();

      final serverMsg =
          buildMessage(id: 101, conversationId: 43, content: 'msg 101');
      chatState.chatwootCallbacks.onMessagesRetrieved([serverMsg]);
      await tester.pump();

      final chatWidget = tester.widget<Chat>(find.byType(Chat));
      final messageIds = chatWidget.messages.map((m) => m.id).toList();

      expect(messageIds.length, 1);
      expect(messageIds.single, '101');
    });
  });
}
