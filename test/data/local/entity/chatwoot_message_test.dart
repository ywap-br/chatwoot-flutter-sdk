import 'package:chatwoot_sdk/data/local/entity/chatwoot_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatwootMessage.isMine', () {
    // Real bot/system payloads: message_type 3 (template), sender_type and
    // sender_id both null. Before this fix, `messageType != 1` treated
    // anything that wasn't an outgoing agent message as "mine", so these
    // rendered as sent-by-the-user bubbles instead of received ones.
    test(
        'message_type 3 with sender_type/sender_id null is never mine (bot payload 1)',
        () {
      final json = {
        'id': 5001,
        'content': 'Seu boleto foi gerado com sucesso.',
        'message_type': 3,
        'content_type': 'text',
        'content_attributes': {},
        'created_at': '1626155918',
        'conversation_id': 202,
        'sender_type': null,
        'sender_id': null,
        'attachments': [],
        'sender': null,
      };

      final message = ChatwootMessage.fromJson(json);

      expect(message.messageType, 3);
      expect(message.isMine, isFalse);
    });

    test(
        'message_type 3 with sender_type/sender_id null is never mine (bot payload 2)',
        () {
      final json = {
        'id': 5002,
        'content': 'Encerramos este atendimento automaticamente.',
        'message_type': 3,
        'content_type': 'text',
        'content_attributes': {'automation_rule_id': 12},
        'created_at': '1626155999',
        'conversation_id': 202,
        'sender_type': null,
        'sender_id': null,
        'attachments': [],
        'sender': null,
      };

      final message = ChatwootMessage.fromJson(json);

      expect(message.messageType, 3);
      expect(message.isMine, isFalse);
    });

    test('message_type 0 (incoming from contact) is mine', () {
      final json = {
        'id': 5003,
        'content': 'Oi, preciso de ajuda',
        'message_type': 0,
        'content_type': 'text',
        'content_attributes': {},
        'created_at': '1626155918',
        'conversation_id': 202,
        'attachments': [],
        'sender': null,
      };

      final message = ChatwootMessage.fromJson(json);

      expect(message.isMine, isTrue);
    });

    test('message_type 1 (outgoing from agent) is never mine', () {
      final json = {
        'id': 5004,
        'content': 'Olá! Como posso ajudar?',
        'message_type': 1,
        'content_type': 'text',
        'content_attributes': {},
        'created_at': '1626155918',
        'conversation_id': 202,
        'attachments': [],
        'sender': {'id': 9, 'name': 'Agente'},
      };

      final message = ChatwootMessage.fromJson(json);

      expect(message.isMine, isFalse);
    });

    test('message_type 2 (activity/private note) is never mine', () {
      final json = {
        'id': 5005,
        'content': 'Conversa marcada como resolvida',
        'message_type': 2,
        'content_type': 'text',
        'content_attributes': {},
        'created_at': '1626155918',
        'conversation_id': 202,
        'attachments': [],
        'sender': null,
      };

      final message = ChatwootMessage.fromJson(json);

      expect(message.isMine, isFalse);
    });
  });
}
