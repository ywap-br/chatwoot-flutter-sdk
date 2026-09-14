import 'package:chatwoot_sdk/data/local/entity/chatwoot_contact.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_conversation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testContact = ChatwootContact(
    id: 1,
    contactIdentifier: "identifier",
    pubsubToken: "token",
  );

  ChatwootConversation buildConversation({
    String? status,
    String? snoozedUntil,
  }) {
    return ChatwootConversation(
      id: 7,
      inboxId: 1,
      contact: testContact,
      status: status,
      snoozedUntil: snoozedUntil,
    );
  }

  group('chatwootConversationStatusFromString', () {
    test('maps every known raw status to its enum value', () {
      expect(chatwootConversationStatusFromString('open'),
          ChatwootConversationStatus.open);
      expect(chatwootConversationStatusFromString('pending'),
          ChatwootConversationStatus.pending);
      expect(chatwootConversationStatusFromString('resolved'),
          ChatwootConversationStatus.resolved);
      expect(chatwootConversationStatusFromString('snoozed'),
          ChatwootConversationStatus.snoozed);
    });

    test('is case-insensitive', () {
      expect(chatwootConversationStatusFromString('Resolved'),
          ChatwootConversationStatus.resolved);
      expect(chatwootConversationStatusFromString('SNOOZED'),
          ChatwootConversationStatus.snoozed);
    });

    test('defaults null/unknown status to open', () {
      expect(chatwootConversationStatusFromString(null),
          ChatwootConversationStatus.open);
      expect(chatwootConversationStatusFromString('something-new'),
          ChatwootConversationStatus.open);
    });
  });

  group('ChatwootConversation.statusEnum', () {
    test('reflects the raw status field', () {
      expect(buildConversation(status: 'pending').statusEnum,
          ChatwootConversationStatus.pending);
      expect(buildConversation(status: null).statusEnum,
          ChatwootConversationStatus.open);
    });
  });

  group('ChatwootConversation.withStatus', () {
    test('replaces status and snoozedUntil together', () {
      final snoozed = buildConversation(status: 'open').withStatus(
        'snoozed',
        snoozedUntil: '2026-09-14T22:52:37.000Z',
      );

      expect(snoozed.status, 'snoozed');
      expect(snoozed.statusEnum, ChatwootConversationStatus.snoozed);
      expect(snoozed.snoozedUntil, '2026-09-14T22:52:37.000Z');
    });

    test('clears snoozedUntil when moving away from snoozed', () {
      // Regression guard: copyWith's "replace if non-null" semantics can't
      // express clearing a field back to null, which is exactly what a
      // snoozed -> open/resolved/pending transition needs. withStatus must
      // always overwrite snoozedUntil, never fall back to the old value.
      final wasSnoozed = buildConversation(
        status: 'snoozed',
        snoozedUntil: '2026-09-14T22:52:37.000Z',
      );

      final reopened = wasSnoozed.withStatus('open', snoozedUntil: null);

      expect(reopened.status, 'open');
      expect(reopened.snoozedUntil, isNull);
    });

    test('preserves every other field', () {
      final original = buildConversation(status: 'open');
      final updated = original.withStatus('resolved');

      expect(updated.id, original.id);
      expect(updated.inboxId, original.inboxId);
      expect(updated.contact, original.contact);
    });
  });

  group('ChatwootConversation JSON round-trip', () {
    test('reads and writes snoozed_until', () {
      final json = {
        'id': 7,
        'inbox_id': 1,
        'status': 'snoozed',
        'snoozed_until': '2026-09-14T22:52:37.000Z',
        'messages': [],
        'contact': testContact.toJson(),
      };

      final conversation = ChatwootConversation.fromJson(json);

      expect(conversation.snoozedUntil, '2026-09-14T22:52:37.000Z');
      expect(
          conversation.toJson()['snoozed_until'], '2026-09-14T22:52:37.000Z');
    });

    test('snoozed_until is absent/null for a plain open conversation', () {
      final json = {
        'id': 7,
        'inbox_id': 1,
        'status': 'open',
        'messages': [],
        'contact': testContact.toJson(),
      };

      final conversation = ChatwootConversation.fromJson(json);

      expect(conversation.snoozedUntil, isNull);
    });
  });
}
