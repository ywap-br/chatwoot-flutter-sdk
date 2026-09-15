import 'package:chatwoot_sdk/data/local/entity/chatwoot_contact.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_conversation.dart';
import 'package:chatwoot_sdk/data/local/local_storage.dart';
import 'package:chatwoot_sdk/data/remote/service/chatwoot_client_auth_service.dart';
import 'package:dio/dio.dart';
import 'package:synchronized/synchronized.dart' as synchronized;

///Intercepts network requests and attaches inbox identifier, contact identifiers, conversation identifiers
class ChatwootClientApiInterceptor extends Interceptor {
  static const INTERCEPTOR_INBOX_IDENTIFIER_PLACEHOLDER = "{INBOX_IDENTIFIER}";
  static const INTERCEPTOR_CONTACT_IDENTIFIER_PLACEHOLDER =
      "{CONTACT_IDENTIFIER}";
  static const INTERCEPTOR_CONVERSATION_IDENTIFIER_PLACEHOLDER =
      "{CONVERSATION_IDENTIFIER}";

  final String _inboxIdentifier;
  final LocalStorage _localStorage;
  final ChatwootClientAuthService _authService;
  final requestLock = synchronized.Lock();
  final responseLock = synchronized.Lock();

  ChatwootClientApiInterceptor(
      this._inboxIdentifier, this._localStorage, this._authService);

  /// Creates a new contact and conversation when no persisted contact is found when an api call is made
  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    await requestLock.synchronized(() async {
      RequestOptions newOptions = options;
      ChatwootContact? contact = _localStorage.contactDao.getContact();
      ChatwootConversation? conversation =
          _localStorage.conversationDao.getConversation();

      if (contact == null) {
        // create new contact from user if no token found
        contact = await _authService.createNewContact(
            _inboxIdentifier, _localStorage.userDao.getUser());
        conversation = await _authService.createNewConversation(
            _inboxIdentifier, contact.contactIdentifier!);
        await _localStorage.conversationDao.saveConversation(conversation);
        await _localStorage.contactDao.saveContact(contact);
      }

      if (conversation == null) {
        conversation = await _authService.createNewConversation(
            _inboxIdentifier, contact.contactIdentifier!);
        await _localStorage.conversationDao.saveConversation(conversation);
      }

      newOptions.path = newOptions.path.replaceAll(
          INTERCEPTOR_INBOX_IDENTIFIER_PLACEHOLDER, _inboxIdentifier);
      newOptions.path = newOptions.path.replaceAll(
          INTERCEPTOR_CONTACT_IDENTIFIER_PLACEHOLDER,
          contact.contactIdentifier!);
      newOptions.path = newOptions.path.replaceAll(
          INTERCEPTOR_CONVERSATION_IDENTIFIER_PLACEHOLDER,
          "${conversation.id}");

      handler.next(newOptions);
    });
  }

  /// Clears and recreates the contact AND conversation when a 401
  /// (Unauthorized), 403 (Forbidden) or 404 (Not found) response is
  /// returned from chatwoot public client api.
  ///
  /// A 401/403/404 here can mean the *contact* itself is gone server-side
  /// (e.g. deleted from the Chatwoot dashboard) -- the public api returns
  /// the same status codes for `GET_CONTACT_FAILED`, `GET_CONVERSATION_FAILED`
  /// and `GET_MESSAGES_FAILED` alike, and nothing here can tell those apart
  /// from the status code alone. Previously this method assumed only the
  /// *conversation* could ever be invalid and kept reusing the persisted
  /// (possibly dead) contact, which just reproduces the same error against
  /// the server and traps callers in a request/fail loop. Mirroring
  /// [onRequest]'s `contact == null` branch, always recreate both.
  @override
  Future<void> onResponse(
      Response response, ResponseInterceptorHandler handler) async {
    await responseLock.synchronized(() async {
      if (response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 404) {
        // Capture the identifiers that were actually resolved into the
        // failed request's path *before* wiping local storage. By the time
        // a response reaches this interceptor, [onRequest] has already
        // substituted {CONTACT_IDENTIFIER}/{CONVERSATION_IDENTIFIER} with
        // real values on `response.requestOptions.path` -- those
        // placeholder constants no longer appear in it. Replacing them
        // again below is therefore a no-op for the path, and without also
        // swapping the stale identifiers for the freshly created ones the
        // retried request would hit the exact same (now invalid)
        // contact/conversation and 404 again, reproducing the loop this
        // fix is meant to close.
        final staleContact = _localStorage.contactDao.getContact();
        final staleConversation =
            _localStorage.conversationDao.getConversation();

        // Clear conversation + messages first (existing behavior; messages
        // must never linger on screen for a contact/conversation we are
        // about to discard). We deliberately do NOT call
        // clear(clearChatwootUserStorage: true): that also deletes the
        // persisted ChatwootUser, which is still needed immediately below
        // to rebuild a fresh contact (name/email/custom attributes). So the
        // now-suspect contact is dropped explicitly instead, right after.
        await _localStorage.clear(clearChatwootUserStorage: false);
        await _localStorage.contactDao.deleteContact();

        // Recreate both contact and conversation from scratch -- same
        // pattern as onRequest's `contact == null` branch -- since a
        // 401/403/404 means the previously persisted contact can no longer
        // be assumed valid.
        final contact = await _authService.createNewContact(
            _inboxIdentifier, _localStorage.userDao.getUser());
        final conversation = await _authService.createNewConversation(
            _inboxIdentifier, contact.contactIdentifier!);
        await _localStorage.contactDao.saveContact(contact);
        await _localStorage.conversationDao.saveConversation(conversation);

        RequestOptions newOptions = response.requestOptions;

        // Defensive: resolve any placeholders that are still unresolved
        // (keeps prior behavior intact for any caller/path that reaches
        // here without having gone through onRequest first).
        newOptions.path = newOptions.path.replaceAll(
            INTERCEPTOR_INBOX_IDENTIFIER_PLACEHOLDER, _inboxIdentifier);
        newOptions.path = newOptions.path.replaceAll(
            INTERCEPTOR_CONTACT_IDENTIFIER_PLACEHOLDER,
            contact.contactIdentifier!);
        newOptions.path = newOptions.path.replaceAll(
            INTERCEPTOR_CONVERSATION_IDENTIFIER_PLACEHOLDER,
            "${conversation.id}");

        // Swap the stale identifiers already baked into the path (captured
        // above, before storage was cleared) for the freshly created ones,
        // scoped to their known path segments so a small numeric
        // conversation id can't accidentally match an unrelated substring
        // elsewhere in the url (e.g. the "1" in "/api/v1/").
        final staleContactIdentifier = staleContact?.contactIdentifier;
        if (staleContactIdentifier != null &&
            staleContactIdentifier.isNotEmpty) {
          newOptions.path = newOptions.path.replaceAll(
              RegExp(
                  '/contacts/${RegExp.escape(staleContactIdentifier)}(?=/|\$)'),
              '/contacts/${contact.contactIdentifier}');
        }
        if (staleConversation != null) {
          newOptions.path = newOptions.path.replaceAll(
              RegExp('/conversations/${staleConversation.id}(?=/|\$)'),
              '/conversations/${conversation.id}');
        }

        //use authservice's dio without the interceptor for subsequent call
        handler.next(await _authService.dio.fetch(newOptions));
      } else {
        // if response is not unauthorized, forbidden or not found forward response
        handler.next(response);
      }
    });
  }
}

extension Range on num {
  bool isBetween(num from, num to) {
    return from < this && this < to;
  }
}
