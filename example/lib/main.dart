import 'dart:io';

import 'package:chatwoot_sdk/chatwoot_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  final testUser = ChatwootUser(
    identifier: "test@test.com",
    name: "Tester test",
    email: "test@test.com",
  );

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Chatwoot SDK Example"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.chat_bubble_outline), text: "Native (History)"),
              Tab(icon: Icon(Icons.web), text: "WebView"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Native Flutter widget with Recent Conversations history
            ChatwootChat(
              baseUrl: "https://app.chatwoot.com",
              inboxIdentifier: "your_api_inbox_identifier",
              user: testUser,
              showConversationHistory: true,
              l10n: const ChatwootL10n(
                recentConversationsTitle: "Conversas recentes",
                startNewConversationText: "Iniciar nova conversa",
                noConversationsText: "Nenhuma conversa encontrada",
              ),
            ),
            // Official webview widget
            ChatwootWidget(
              websiteToken: "websiteToken",
              baseUrl: "https://app.chatwoot.com",
              user: testUser,
              locale: "pt",
              closeWidget: () {
                if (Platform.isAndroid) {
                  SystemNavigator.pop();
                } else if (Platform.isIOS) {
                  exit(0);
                }
              },
              onAttachFile: _androidFilePicker,
              onLoadStarted: () {
                print("loading widget");
              },
              onLoadProgress: (int progress) {
                print("loading... $progress");
              },
              onLoadCompleted: () {
                print("widget loaded");
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: "Open Dialog",
          child: const Icon(Icons.forum),
          onPressed: () {
            ChatwootChatDialog.show(
              context,
              baseUrl: "https://app.chatwoot.com",
              inboxIdentifier: "your_api_inbox_identifier",
              title: "Atendimento",
              user: testUser,
              showConversationHistory: true,
            );
          },
        ),
      ),
    );
  }

  Future<List<String>> _androidFilePicker() async {
    final picker = image_picker.ImagePicker();
    final photo =
        await picker.pickImage(source: image_picker.ImageSource.gallery);

    if (photo == null) {
      return [];
    }

    final imageData = await photo.readAsBytes();
    final decodedImage = image.decodeImage(imageData);
    final scaledImage = image.copyResize(decodedImage!, width: 500);
    final jpg = image.encodeJpg(scaledImage, quality: 90);

    final filePath = (await getTemporaryDirectory()).uri.resolve(
          './image_${DateTime.now().microsecondsSinceEpoch}.jpg',
        );
    final file = await File.fromUri(filePath).create(recursive: true);
    await file.writeAsBytes(jpg, flush: true);

    return [file.uri.toString()];
  }
}
