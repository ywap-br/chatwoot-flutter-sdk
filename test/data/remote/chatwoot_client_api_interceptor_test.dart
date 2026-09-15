import 'package:chatwoot_sdk/data/local/entity/chatwoot_contact.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_conversation.dart';
import 'package:chatwoot_sdk/data/local/entity/chatwoot_user.dart';
import 'package:chatwoot_sdk/data/remote/service/chatwoot_client_api_interceptor.dart';
import 'package:chatwoot_sdk/data/remote/service/chatwoot_client_auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../utils/test_resources_util.dart';
import '../chatwoot_repository_test.mocks.dart';
import '../local/local_storage_test.mocks.dart';
import 'chatwoot_client_api_interceptor_test.mocks.dart';
import 'chatwoot_client_service_test.mocks.dart';

class _HasPath extends Matcher {
  final String _pathValue;
  const _HasPath(this._pathValue);

  @override
  bool matches(item, Map matchState) =>
      (item as RequestOptions).path == _pathValue;

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_pathValue);
}

@GenerateMocks([
  ResponseInterceptorHandler,
  RequestInterceptorHandler,
  ChatwootClientAuthService
])
void main() {
  group("Client Api Interceptor Test", () {
    late final ChatwootClientApiInterceptor interceptor;
    final testInboxIdentifier = "testIdentifier";
    final mockAuthService = MockChatwootClientAuthService();
    final mockLocalStorage = MockLocalStorage();
    final mockContactDao = MockChatwootContactDao();
    final mockUserDao = MockChatwootUserDao();
    final mockDio = MockDio();
    final mockConversationDao = MockChatwootConversationDao();
    final mockResponseHandler = MockResponseInterceptorHandler();
    final mockRequestHandler = MockRequestInterceptorHandler();

    late final testContact;

    late final testConversation;

    // Represents the contact/conversation recreated by onResponse's
    // 401/403/404 recovery path -- deliberately different identifiers from
    // [testContact]/[testConversation] so tests can prove the retried
    // request is rebuilt against the NEW identifiers rather than the
    // stale ones already baked into the failed request's path.
    final recreatedContact = ChatwootContact(
        id: 2,
        contactIdentifier: "recreatedContactIdentifier",
        pubsubToken: "recreatedPubsubToken",
        name: "test",
        email: "test@test.com");

    final recreatedConversation =
        ChatwootConversation(id: 42, inboxId: 1, contact: recreatedContact);

    final testUser = ChatwootUser(
        identifier: "identifier",
        identifierHash: "identifierHash",
        name: "name",
        email: "email",
        avatarUrl: "avatarUrl",
        customAttributes: {});

    setUpAll(() async {
      when(mockLocalStorage.contactDao).thenReturn(mockContactDao);
      when(mockLocalStorage.userDao).thenReturn(mockUserDao);
      when(mockAuthService.dio).thenReturn(mockDio);
      when(mockLocalStorage.conversationDao).thenReturn(mockConversationDao);
      testContact = ChatwootContact.fromJson(
          await TestResourceUtil.readJsonResource(fileName: "contact"));
      testConversation = ChatwootConversation.fromJson(
          await TestResourceUtil.readJsonResource(fileName: "conversation"));
      interceptor = ChatwootClientApiInterceptor(
          testInboxIdentifier, mockLocalStorage, mockAuthService);
    });

    tearDown(() {
      reset(mockAuthService);
      reset(mockContactDao);
      reset(mockConversationDao);
      reset(mockUserDao);
      reset(mockDio);
      when(mockAuthService.dio).thenReturn(mockDio);
    });

    _createSuccessResponse(body) {
      return Response(
          data: body,
          statusCode: 200,
          requestOptions: RequestOptions(path: "", headers: new Map()));
    }

    _createErrorResponse({required int statusCode, body}) {
      return Response(
          data: body,
          statusCode: statusCode,
          requestOptions: RequestOptions(path: "", headers: new Map()));
    }

    test(
        'Given persisted contact is null when a request is made, then recreate contact and submit request',
        () async {
      //GIVEN
      final testRequest = RequestOptions(path: "/");

      when(mockContactDao.getContact()).thenReturn(null);
      when(mockConversationDao.getConversation()).thenReturn(null);
      when(mockUserDao.getUser()).thenReturn(testUser);
      when(mockAuthService.createNewContact(any, any))
          .thenAnswer((_) => Future.value(testContact));
      when(mockAuthService.createNewConversation(any, any))
          .thenAnswer((_) => Future.value(testConversation));

      //WHEN
      await interceptor.onRequest(testRequest, mockRequestHandler);

      //THEN
      verify(mockAuthService.createNewContact(testInboxIdentifier, testUser));
      verify(mockAuthService.createNewConversation(
          testInboxIdentifier, testContact.contactIdentifier));
      verify(mockContactDao.saveContact(testContact));
      verify(mockConversationDao.saveConversation(testConversation));
      verify(mockRequestHandler.next(any));
    });

    test(
        'Given persisted conversation is null when a request is made, then create a conversation and submit request',
        () async {
      //GIVEN
      final testRequest = RequestOptions(path: "/");

      when(mockContactDao.getContact()).thenReturn(testContact);
      when(mockConversationDao.getConversation()).thenReturn(null);
      when(mockAuthService.createNewConversation(any, any))
          .thenAnswer((_) => Future.value(testConversation));

      //WHEN
      await interceptor.onRequest(testRequest, mockRequestHandler);

      //THEN
      verify(mockAuthService.createNewConversation(
          testInboxIdentifier, testContact.contactIdentifier));
      verify(mockConversationDao.saveConversation(testConversation));
      verify(mockRequestHandler.next(any));
    });

    test(
        'Given contact identifier is needed when a request is made, then attach contact identifier and submit request',
        () async {
      //GIVEN
      final testRequest = RequestOptions(
          path:
              "/${ChatwootClientApiInterceptor.INTERCEPTOR_CONTACT_IDENTIFIER_PLACEHOLDER}");

      when(mockContactDao.getContact()).thenReturn(testContact);
      when(mockConversationDao.getConversation()).thenReturn(testConversation);

      //WHEN
      await interceptor.onRequest(testRequest, mockRequestHandler);

      //THEN
      verify(mockRequestHandler
          .next(argThat(_HasPath("/${testContact.contactIdentifier}"))));
    });

    test(
        'Given inbox identifier is needed when a request is made, then attach inbox identifier and submit request',
        () async {
      //GIVEN
      final testRequest = RequestOptions(
          path:
              "/${ChatwootClientApiInterceptor.INTERCEPTOR_INBOX_IDENTIFIER_PLACEHOLDER}");

      when(mockContactDao.getContact()).thenReturn(testContact);
      when(mockConversationDao.getConversation()).thenReturn(testConversation);

      //WHEN
      await interceptor.onRequest(testRequest, mockRequestHandler);

      //THEN
      verify(
          mockRequestHandler.next(argThat(_HasPath("/$testInboxIdentifier"))));
    });

    test(
        'Given conversation identifier is needed when a request is made, then attach conversation identifier and submit request',
        () async {
      //GIVEN
      final testRequest = RequestOptions(
          path:
              "/${ChatwootClientApiInterceptor.INTERCEPTOR_CONVERSATION_IDENTIFIER_PLACEHOLDER}");

      when(mockContactDao.getContact()).thenReturn(testContact);
      when(mockConversationDao.getConversation()).thenReturn(testConversation);

      //WHEN
      await interceptor.onRequest(testRequest, mockRequestHandler);

      //THEN
      verify(mockRequestHandler
          .next(argThat(_HasPath("/${testConversation.id}"))));
    });

    test(
        'Given api response is 401 unauthorized when a response is returned, then recreate contact AND conversation and resubmit request',
        () async {
      //GIVEN
      final testRequestOptions = RequestOptions(
          path:
              "/public/api/v1/inboxes/$testInboxIdentifier/contacts/${testContact.contactIdentifier}",
          headers: new Map());
      final testResponse = Response(
          data: {}, statusCode: 401, requestOptions: testRequestOptions);

      when(mockLocalStorage.contactDao).thenReturn(mockContactDao);
      when(mockContactDao.getContact()).thenReturn(testContact);
      when(mockConversationDao.getConversation()).thenReturn(testConversation);
      when(mockDio.fetch(any))
          .thenAnswer((_) => Future.value(_createSuccessResponse({})));
      when(mockUserDao.getUser()).thenReturn(testUser);
      when(mockAuthService.createNewContact(testInboxIdentifier, testUser))
          .thenAnswer((_) => Future.value(recreatedContact));
      when(mockAuthService.createNewConversation(
              testInboxIdentifier, recreatedContact.contactIdentifier))
          .thenAnswer((_) => Future.value(recreatedConversation));

      //WHEN
      await interceptor.onResponse(testResponse, mockResponseHandler);

      //THEN
      // a brand new contact must be created -- reusing the persisted
      // (possibly dead) contact identifier is exactly the bug this fix
      // closes.
      verify(mockAuthService.createNewContact(testInboxIdentifier, testUser));
      verify(mockAuthService.createNewConversation(
          testInboxIdentifier, recreatedContact.contactIdentifier));
      verify(mockContactDao.deleteContact());
      verify(mockContactDao.saveContact(recreatedContact));
      verify(mockConversationDao.saveConversation(recreatedConversation));
      // the retried request must target the NEW contact, not the stale one
      // baked into the original failed request's path.
      verify(mockDio.fetch(argThat(_HasPath(
          "/public/api/v1/inboxes/$testInboxIdentifier/contacts/${recreatedContact.contactIdentifier}"))));
      verify(mockResponseHandler.next(any));
    });

    test(
        'Given api response is 404 not found (contact deleted server-side) when a response is returned, then recreate contact AND conversation, save both and resubmit the original request successfully',
        () async {
      //GIVEN
      // path as it would look after onRequest already resolved the
      // placeholders with the (now invalid) persisted contact/conversation
      // identifiers -- the exact shape a real GET_CONTACT_FAILED/
      // GET_CONVERSATION_FAILED/GET_MESSAGES_FAILED 404 would carry.
      final staleRequestPath =
          "/public/api/v1/inboxes/$testInboxIdentifier/contacts/${testContact.contactIdentifier}/conversations/${testConversation.id}/messages";
      final testRequestOptions =
          RequestOptions(path: staleRequestPath, headers: new Map());
      final testResponse = Response(
          data: {"error": "Contact not found"},
          statusCode: 404,
          requestOptions: testRequestOptions);

      when(mockLocalStorage.contactDao).thenReturn(mockContactDao);
      when(mockContactDao.getContact()).thenReturn(testContact);
      when(mockConversationDao.getConversation()).thenReturn(testConversation);
      when(mockUserDao.getUser()).thenReturn(testUser);
      when(mockAuthService.createNewContact(testInboxIdentifier, testUser))
          .thenAnswer((_) => Future.value(recreatedContact));
      when(mockAuthService.createNewConversation(
              testInboxIdentifier, recreatedContact.contactIdentifier))
          .thenAnswer((_) => Future.value(recreatedConversation));
      when(mockDio.fetch(any))
          .thenAnswer((_) => Future.value(_createSuccessResponse({})));

      //WHEN
      await interceptor.onResponse(testResponse, mockResponseHandler);

      //THEN
      // both contact AND conversation are recreated -- not just the
      // conversation reusing the deleted contact's identifier.
      verify(mockAuthService.createNewContact(testInboxIdentifier, testUser));
      verify(mockAuthService.createNewConversation(
          testInboxIdentifier, recreatedContact.contactIdentifier));
      verify(mockContactDao.deleteContact());
      verify(mockContactDao.saveContact(recreatedContact));
      verify(mockConversationDao.saveConversation(recreatedConversation));

      // the original request is resubmitted with the NEW identifiers, not
      // the stale ones that produced the 404 (this is what actually stops
      // the reported infinite 404 loop -- the retried request must not
      // hit the same dead resource again).
      final expectedNewPath =
          "/public/api/v1/inboxes/$testInboxIdentifier/contacts/${recreatedContact.contactIdentifier}/conversations/${recreatedConversation.id}/messages";
      verify(mockDio.fetch(argThat(_HasPath(expectedNewPath))));

      // and it is resubmitted successfully.
      verify(mockResponseHandler.next(any));
    });

    test(
        'Given api response is not 401 unauthorized when a response is returned, then forward response through handler',
        () async {
      //GIVEN
      final testResponse = _createErrorResponse(statusCode: 400);

      //WHEN
      await interceptor.onResponse(testResponse, mockResponseHandler);

      //THEN
      verify(mockResponseHandler.next(any));
      verifyNever(mockAuthService.createNewConversation(any, any));
      verifyNever(mockContactDao.saveContact(any));
      verifyNever(mockConversationDao.saveConversation(any));
    });

    test(
        'Given api response is successful when a response is returned, then forward response through handler',
        () async {
      //GIVEN
      final testResponse = _createSuccessResponse({});

      //WHEN
      await interceptor.onResponse(testResponse, mockResponseHandler);

      //THEN
      verify(mockResponseHandler.next(any));
      verifyNever(mockAuthService.createNewContact(any, any));
      verifyNever(mockAuthService.createNewConversation(any, any));
      verifyNever(mockContactDao.saveContact(any));
      verifyNever(mockConversationDao.saveConversation(any));
    });
  });
}
