import 'dart:async';

import 'package:chatwoot_sdk/data/local/entity/chatwoot_contact.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_conversation.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_user.dart';
import 'package:chatwoot_sdk/data/remote/chatwoot_client_exception.dart';
import 'package:chatwoot_sdk/data/remote/service/chatwoot_client_api_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Service for handling chatwoot user authentication api calls
/// See [ChatwootClientAuthServiceImpl]
abstract class ChatwootClientAuthService {
  WebSocketChannel? connection;
  final Dio dio;

  ChatwootClientAuthService(this.dio);

  Future<ChatwootContact> createNewContact(
      String inboxIdentifier, ChatwootUser? user);

  Future<ChatwootConversation> createNewConversation(
      String inboxIdentifier, String contactIdentifier);
}

/// Default Implementation for [ChatwootClientAuthService]
class ChatwootClientAuthServiceImpl extends ChatwootClientAuthService {
  ChatwootClientAuthServiceImpl({required Dio dio}) : super(dio);

  ///Creates new contact for inbox with [inboxIdentifier] and passes [user] body to be linked to created contact
  ///
  /// When the deterministic [user.identifier] this SDK's consumers commonly
  /// send (e.g. built from a customer id/document) has already been used to
  /// create a contact on a previous attempt -- one that was accepted
  /// server-side but never persisted locally (app killed mid-flow, a
  /// network drop after the response, etc) -- re-posting it can make
  /// Chatwoot's public contacts endpoint return a bare `500` instead of a
  /// clean `409`/`422` for the identifier collision. On that specific
  /// status only, and only when we have an [user.identifier] to look up,
  /// try once to fetch the already-existing contact via the same
  /// `GET /public/api/v1/inboxes/:inbox_identifier/contacts/:contact_identifier`
  /// route this SDK already uses elsewhere (see
  /// [ChatwootClientServiceImpl.getContact]) before giving up. This is
  /// best-effort: any failure of that lookup falls back to the original
  /// [ChatwootClientExceptionType.CREATE_CONTACT_FAILED] behavior.
  ///
  /// The 500 can surface two ways here: [dio] on this service has no
  /// [ChatwootClientApiInterceptor] attached, so against a real server
  /// Dio's default `validateStatus` rejects any non-2xx and throws a
  /// [DioException] with the response attached (handled in the `catch`
  /// below) rather than returning it from `await dio.post(...)` -- the
  /// direct `createResponse.statusCode == 500` check only fires for a
  /// caller (e.g. a test) that stubs [dio] to return the error response
  /// without going through real status validation.
  @override
  Future<ChatwootContact> createNewContact(
      String inboxIdentifier, ChatwootUser? user) async {
    try {
      final createResponse = await dio.post(
          "/public/api/v1/inboxes/$inboxIdentifier/contacts",
          data: user?.toJson());
      if ((createResponse.statusCode ?? 0).isBetween(199, 300)) {
        //creating contact successful continue with request
        final contact = ChatwootContact.fromJson(createResponse.data);
        return contact;
      } else if (createResponse.statusCode == 500) {
        final recoveredContact =
            await _recoverContactAfter500(inboxIdentifier, user);
        if (recoveredContact != null) {
          return recoveredContact;
        }
        throw ChatwootClientException(
            createResponse.statusMessage ?? "unknown error",
            ChatwootClientExceptionType.CREATE_CONTACT_FAILED);
      } else {
        throw ChatwootClientException(
            createResponse.statusMessage ?? "unknown error",
            ChatwootClientExceptionType.CREATE_CONTACT_FAILED);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        final recoveredContact =
            await _recoverContactAfter500(inboxIdentifier, user);
        if (recoveredContact != null) {
          return recoveredContact;
        }
      }
      throw ChatwootClientException(ChatwootClientException.extractError(e),
          ChatwootClientExceptionType.CREATE_CONTACT_FAILED);
    } catch (e) {
      throw ChatwootClientException(
          e.toString(), ChatwootClientExceptionType.CREATE_CONTACT_FAILED);
    }
  }

  /// Shared 500-recovery step for [createNewContact]: when we have a
  /// non-empty [user.identifier] to look up, try once to fetch a contact
  /// that may already exist server-side under it. Returns `null` (never
  /// throws) when there is no identifier to try, or the lookup itself
  /// fails, so the caller always has a clean fallback to the original
  /// failure.
  Future<ChatwootContact?> _recoverContactAfter500(
      String inboxIdentifier, ChatwootUser? user) async {
    final identifier = user?.identifier;
    if (identifier == null || identifier.isEmpty) {
      return null;
    }
    return _tryRecoverExistingContact(inboxIdentifier, identifier);
  }

  /// Best-effort fetch of a contact that may already exist server-side for
  /// [contactIdentifier] under [inboxIdentifier]. Returns `null` on any
  /// non-2xx response or error so the caller can fall back to its original
  /// failure instead of masking a genuine outage as a successful recovery.
  Future<ChatwootContact?> _tryRecoverExistingContact(
      String inboxIdentifier, String contactIdentifier) async {
    try {
      final getResponse = await dio.get(
          "/public/api/v1/inboxes/$inboxIdentifier/contacts/$contactIdentifier");
      if ((getResponse.statusCode ?? 0).isBetween(199, 300)) {
        return ChatwootContact.fromJson(getResponse.data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  ///Creates a new conversation for inbox with [inboxIdentifier] and contact with source id [contactIdentifier]
  @override
  Future<ChatwootConversation> createNewConversation(
      String inboxIdentifier, String contactIdentifier) async {
    try {
      final createResponse = await dio.post(
          "/public/api/v1/inboxes/$inboxIdentifier/contacts/$contactIdentifier/conversations");
      if ((createResponse.statusCode ?? 0).isBetween(199, 300)) {
        //creating contact successful continue with request
        final newConversation =
            ChatwootConversation.fromJson(createResponse.data);
        return newConversation;
      } else {
        throw ChatwootClientException(
            createResponse.statusMessage ?? "unknown error",
            ChatwootClientExceptionType.CREATE_CONVERSATION_FAILED);
      }
    } on DioException catch (e) {
      throw ChatwootClientException(ChatwootClientException.extractError(e),
          ChatwootClientExceptionType.CREATE_CONVERSATION_FAILED);
    } catch (e) {
      throw ChatwootClientException(
          e.toString(), ChatwootClientExceptionType.CREATE_CONVERSATION_FAILED);
    }
  }
}
