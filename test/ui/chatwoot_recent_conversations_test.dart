import 'package:chatwoot_sdk/data/local/entity/chatwoot_contact.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_conversation.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_message.dart';
import 'package:chatwoot_sdk/ui/chatwoot_l10n.dart';
import 'package:chatwoot_sdk/ui/chatwoot_recent_conversations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ChatwootRecentConversations Tests", () {
    // ChatwootRecentConversations defaults to `const ChatwootL10n()`, whose
    // strings are the SDK's own PT-BR defaults (see chatwoot_l10n.dart) and
    // change independently of this widget. Pinning an explicit l10n here
    // keeps these assertions stable across default-copy changes -- these
    // are the same strings the test originally asserted against.
    const testL10n = ChatwootL10n(
      noConversationsText: "No conversations found",
      startNewConversationText: "Start new conversation",
      ticketBadgeLabel: "Conversa #{id}",
      conversationStatusOpen: "Open",
      conversationStatusResolved: "Resolved",
    );

    final testContact = ChatwootContact(
      id: 1,
      contactIdentifier: "contact_1",
      name: "Test User",
      email: "test@user.com",
      pubsubToken: "token",
    );

    final testMessage = ChatwootMessage(
      id: 1,
      content: "Hello from Chatwoot",
      messageType: 1,
      contentType: "text",
      contentAttributes: {},
      createdAt: "1626155918",
      conversationId: 101,
      attachments: [],
      sender: null,
    );

    final testConversation1 = ChatwootConversation(
      id: 101,
      inboxId: 1,
      contact: testContact,
      status: "open",
      messages: [testMessage],
    );

    final testConversation2 = ChatwootConversation(
      id: 102,
      inboxId: 1,
      contact: testContact,
      status: "resolved",
      messages: [],
    );

    testWidgets(
        'Given conversations list is empty, then empty state and new conversation button should be displayed',
        (WidgetTester tester) async {
      bool newConversationCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatwootRecentConversations(
              conversations: const [],
              onConversationSelected: (_) {},
              onNewConversation: () {
                newConversationCalled = true;
              },
              l10n: testL10n,
            ),
          ),
        ),
      );

      expect(find.text("No conversations found"), findsOneWidget);
      expect(find.text("Start new conversation"), findsOneWidget);

      await tester.tap(find.text("Start new conversation"));
      await tester.pump();

      expect(newConversationCalled, isTrue);
    });

    testWidgets(
        'Given conversations exist, then conversation tiles with status and last message should be displayed',
        (WidgetTester tester) async {
      ChatwootConversation? selectedConversation;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatwootRecentConversations(
              conversations: [testConversation1, testConversation2],
              onConversationSelected: (conv) {
                selectedConversation = conv;
              },
              onNewConversation: () {},
              l10n: testL10n,
            ),
          ),
        ),
      );

      expect(find.text("Conversa #101"), findsOneWidget);
      expect(find.text("Conversa #102"), findsOneWidget);
      expect(find.text("Hello from Chatwoot"), findsOneWidget);
      expect(find.text("Open"), findsOneWidget);
      expect(find.text("Resolved"), findsOneWidget);

      await tester.tap(find.text("Conversa #101"));
      await tester.pump();

      expect(selectedConversation, isNotNull);
      expect(selectedConversation!.id, 101);
    });

    testWidgets(
        'Given new conversation button in header is tapped, then onNewConversation callback should be called',
        (WidgetTester tester) async {
      bool newConversationTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatwootRecentConversations(
              conversations: [testConversation1],
              onConversationSelected: (_) {},
              onNewConversation: () {
                newConversationTapped = true;
              },
              l10n: testL10n,
            ),
          ),
        ),
      );

      await tester.tap(find.text("Start new conversation"));
      await tester.pump();

      expect(newConversationTapped, isTrue);
    });
  });
}
