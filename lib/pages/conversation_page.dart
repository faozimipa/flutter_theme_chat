import 'dart:async';

import 'package:emoji_picker/emoji_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_theme_chat/models/chat_model.dart';
import 'package:flutter_theme_chat/models/chat_provider.dart';
import 'package:flutter_theme_chat/widgets/chat_message.dart';
import 'package:flutter_theme_chat/widgets/emoji_picker.dart';
import 'package:flutter_theme_chat/widgets/theme_model.dart';
import 'package:states_rebuilder/states_rebuilder.dart';

class ConversationPage extends StatefulWidget {
  final Chat chat;
  ConversationPage(this.chat);
  @override
  _ConversationPageState createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> with TickerProviderStateMixin {
  AnimationController animationController;
  TextEditingController textEditingController;
  ScrollController scrollController;
  ChatProvider chatProvider;
  ThemeModel themeModel;
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  //method
  void onSendMessage(String message) {
    if (textEditingController.text.isEmpty) return;
    var animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    var chatMessage = ChatMessage(
      text: message,
      animationController: animationController,
      isMe: true,
      user: "https://picsum.photos/300",
    );
    sendMessageToSocket();
    chatMessage.animationController.forward();
    textEditingController.clear();
    FocusScope.of(context).unfocus();
    //this._messages.add(chatMessage);
  }

  void sendMessageToSocket() {
    chatProvider.socket.emit("message", [
      {
        "message": textEditingController.text,
        "sender": themeModel.sender,
        "receiver": themeModel.receiver,
      },
    ]);
  }

  void initSocketConfiguration() {
    chatProvider.socket.on('message-${themeModel.sender}-${themeModel.receiver}', (data) async {
      print("Message receive: " + data.toString());
      var animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
      var chatMessage = ChatMessage(
        text: data['message'],
        animationController: animationController,
        isMe: data['sender'] == themeModel.sender,
        user: widget.chat.image,
      );
      chatMessage.animationController.forward();
      chatProvider.onAddNewMessage(chatMessage);
      await Future.delayed(Duration(milliseconds: 200));
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  @override
  void initState() {
    animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500))..forward();
    textEditingController = TextEditingController();
    scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((d) {
      chatProvider.initSocket();
      initSocketConfiguration();
    });
    super.initState();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    for (ChatMessage chatMessage in chatProvider.messages) {
      chatMessage.animationController.dispose();
    }
    chatProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    chatProvider = Injector.get(context: context);
    themeModel = Injector.get(context: context);
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            CircleAvatar(backgroundImage: NetworkImage(widget.chat.image)),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(widget.chat.name),
                Text("Active now", style: Theme.of(context).textTheme.caption),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(onPressed: () {}, icon: Icon(Icons.call)),
          IconButton(onPressed: () {}, icon: Icon(Icons.video_call)),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Container(
          child: Column(
            children: <Widget>[
              buildMessageList(),
              Divider(height: 0),
              buildMessageComposer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMessageList() {
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.only(left: 8, right: 8, bottom: 12, top: 12),
        itemCount: chatProvider.messages.length,
        controller: scrollController,
        itemBuilder: (context, index) {
          return chatProvider.messages[index];
        },
      ),
    );
  }

  Widget buildMessageComposer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Row(
        children: <Widget>[
          InkWell(
            child: Icon(Icons.photo, color: Theme.of(context).accentColor, size: 32),
            onTap: () {},
          ),
          SizedBox(width: 12),
          InkWell(
            child: Icon(Icons.tag_faces, color: Theme.of(context).accentColor, size: 32),
            onTap: () async {
              showDialog(
                context: context,
                builder: (dialogContext) => EmojiPickerDialog(
                  onEmojiSelected: (Emoji emoji) {
                    textEditingController.text = textEditingController.text + emoji.emoji;
                  },
                ),
              );
            },
          ),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: textEditingController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
                hintText: "Message",
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
          ),
          SizedBox(width: 12),
          InkWell(
            child: Icon(Icons.send, color: Theme.of(context).accentColor, size: 32),
            onTap: () => onSendMessage(textEditingController.text),
          ),
        ],
      ),
    );
  }
}