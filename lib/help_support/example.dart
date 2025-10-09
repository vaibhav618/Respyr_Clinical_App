import 'package:chatview/chatview.dart';
import 'package:flutter/material.dart';

import 'data.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool isDarkTheme = false;
  late final ChatController _chatController;

  @override
  void initState() {
    super.initState();
    _chatController = ChatController(
      initialMessageList: Data.messageList,
      scrollController: ScrollController(),
      currentUser: const ChatUser(
        id: '1',
        name: 'Flutter',
        profilePhoto: Data.profileImage,
      ),
      otherUsers: const [
        ChatUser(id: '2', name: 'Simform', profilePhoto: Data.profileImage),
        ChatUser(id: '3', name: 'Jhon', profilePhoto: Data.profileImage),
        ChatUser(id: '4', name: 'Mike', profilePhoto: Data.profileImage),
        ChatUser(id: '5', name: 'Rich', profilePhoto: Data.profileImage),
      ],
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _showHideTypingIndicator() {
    _chatController.setTypingIndicator = !_chatController.showTypingIndicator;
  }

  void receiveMessage() async {
    _chatController.addMessage(
      Message(
        id: DateTime.now().toString(),
        message: 'I will schedule the meeting.',
        createdAt: DateTime.now(),
        sentBy: '2',
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    _chatController.addReplySuggestions([
      const SuggestionItemData(text: 'Thanks.'),
      const SuggestionItemData(text: 'Thank you very much.'),
      const SuggestionItemData(text: 'Great.')
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChatView(
        chatController: _chatController,
        onSendTap: _onSendTap,
        featureActiveConfig: const FeatureActiveConfig(
          lastSeenAgoBuilderVisibility: true,
          receiptsBuilderVisibility: true,
          enableScrollToBottomButton: true,
        ),
        scrollToBottomButtonConfig: ScrollToBottomButtonConfig(
          backgroundColor: const Color(0xFFF0F0F0),
          border: Border.all(color: Colors.grey),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF333333),
            weight: 10,
            size: 30,
          ),
        ),
        chatViewState: ChatViewState.hasMessages,
        chatViewStateConfig: const ChatViewStateConfiguration(),
        typeIndicatorConfig: const TypeIndicatorConfiguration(
          flashingCircleBrightColor: Color(0xFF00FF00),
          flashingCircleDarkColor: Color(0xFF008800),
        ),
        appBar: ChatViewAppBar(
          elevation: 2.0,
          backGroundColor: const Color(0xFFFFFFFF),
          profilePicture: Data.profileImage,
          backArrowColor: Colors.black,
          chatTitle: "Chat view",
          chatTitleTextStyle: const TextStyle(
            color: Color(0xFF111111),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.25,
          ),
          userStatus: "online",
          userStatusTextStyle: const TextStyle(color: Colors.grey),
          actions: [
            IconButton(
              onPressed: _onThemeIconTap,
              icon: Icon(
                isDarkTheme ? Icons.brightness_4_outlined : Icons.dark_mode_outlined,
                color: const Color(0xFF333333),
              ),
            ),
            IconButton(
              tooltip: 'Toggle TypingIndicator',
              onPressed: _showHideTypingIndicator,
              icon: const Icon(Icons.keyboard, color: Color(0xFF333333)),
            ),
            IconButton(
              tooltip: 'Simulate Message receive',
              onPressed: receiveMessage,
              icon: const Icon(Icons.supervised_user_circle, color: Color(0xFF333333)),
            ),
          ],
        ),
        chatBackgroundConfig: ChatBackgroundConfiguration(
          messageTimeIconColor: const Color(0xFFAAAAAA),
          messageTimeTextStyle: const TextStyle(color: Color(0xFF888888)),
          defaultGroupSeparatorConfig: const DefaultGroupSeparatorConfiguration(
            textStyle: TextStyle(color: Color(0xFF444444), fontSize: 17),
          ),
          backgroundColor: const Color(0xFFFFFFFF),
        ),
        sendMessageConfig: SendMessageConfiguration(
          imagePickerIconsConfig: const ImagePickerIconsConfiguration(
            cameraIconColor: Color(0xFF5555FF),
            galleryIconColor: Color(0xFF55FF55),
          ),
          replyMessageColor: Color(0xFFEFEFEF),
          defaultSendButtonColor: Color(0xFF0099FF),
          replyDialogColor: Color(0xFFFFFFFF),
          replyTitleColor: Color(0xFF444444),
          textFieldBackgroundColor: Color(0xFFF5F5F5),
          closeIconColor: Color(0xFF333333),
          textFieldConfig: TextFieldConfiguration(
            onMessageTyping: (status) => debugPrint(status.toString()),
            compositionThresholdTime: const Duration(seconds: 1),
            textStyle: const TextStyle(color: Colors.black),
          ),
          micIconColor: Color(0xFF444444),
          voiceRecordingConfiguration: const VoiceRecordingConfiguration(
            backgroundColor: Color(0xFFE0E0E0),
            recorderIconColor: Color(0xFF3333FF),
            waveStyle: WaveStyle(
              showMiddleLine: false,
              waveColor: Color(0xFF8888FF),
              extendWaveform: true,
            ),
          ),
        ),
        chatBubbleConfig: ChatBubbleConfiguration(
          outgoingChatBubbleConfig: const ChatBubble(
            color: Color(0xFFDCF8C6),
            linkPreviewConfig: LinkPreviewConfiguration(
              backgroundColor: Color(0xFFBBF1C8),
              bodyStyle: TextStyle(color: Colors.black),
              titleStyle: TextStyle(color: Colors.black),
            ),
            receiptsWidgetConfig: ReceiptsWidgetConfig(showReceiptsIn: ShowReceiptsIn.all),
          ),
          inComingChatBubbleConfig: ChatBubble(
            color: const Color(0xFFFFFFFF),
            textStyle: const TextStyle(color: Color(0xFF000000)),
            linkPreviewConfig: const LinkPreviewConfiguration(
              linkStyle: TextStyle(color: Color(0xFF0000EE), decoration: TextDecoration.underline),
              backgroundColor: Color(0xFFF0F0F0),
              bodyStyle: TextStyle(color: Color(0xFF000000)),
              titleStyle: TextStyle(color: Color(0xFF000000)),
            ),
            onMessageRead: (message) => debugPrint('Message Read'),
            senderNameTextStyle: const TextStyle(color: Color(0xFF000000)),
          ),
        ),
        replyPopupConfig: const ReplyPopupConfiguration(
          backgroundColor: Color(0xFFFFFFFF),
          buttonTextStyle: TextStyle(color: Color(0xFF0000FF)),
          topBorderColor: Color(0xFFCCCCCC),
        ),
        reactionPopupConfig: ReactionPopupConfiguration(
          shadow: BoxShadow(
            color: isDarkTheme ? Colors.black54 : Colors.grey.shade400,
            blurRadius: 20,
          ),
          backgroundColor: const Color(0xFFFFFFFF),
        ),
        messageConfig: MessageConfiguration(
          messageReactionConfig: const MessageReactionConfiguration(
            backgroundColor: Color(0xFFE0E0E0),
            borderColor: Color(0xFFE0E0E0),
            reactedUserCountTextStyle: TextStyle(color: Color(0xFF000000)),
            reactionCountTextStyle: TextStyle(color: Color(0xFF000000)),
            reactionsBottomSheetConfig: ReactionsBottomSheetConfiguration(
              backgroundColor: Color(0xFFFFFFFF),
              reactedUserTextStyle: TextStyle(color: Color(0xFF000000)),
              reactionWidgetDecoration: BoxDecoration(
                color: Color(0xFFFFFFFF),
                boxShadow: [
                  BoxShadow(color: Color(0xFFE0E0E0), offset: Offset(0, 20), blurRadius: 40),
                ],
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
          imageMessageConfig: ImageMessageConfiguration(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            shareIconConfig: ShareIconConfiguration(
              defaultIconBackgroundColor: Color(0xFFEFEFEF),
              defaultIconColor: Color(0xFF444444),
            ),
          ),
        ),
        profileCircleConfig: const ProfileCircleConfiguration(profileImageUrl: Data.profileImage),
        repliedMessageConfig: RepliedMessageConfiguration(
          backgroundColor: const Color(0xFF444444),
          verticalBarColor: const Color(0xFF00BCD4),
          repliedMsgAutoScrollConfig: RepliedMsgAutoScrollConfig(
            enableHighlightRepliedMsg: true,
            highlightColor: Colors.pinkAccent,
            highlightScale: 1.1,
          ),
          textStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.25,
          ),
          replyTitleTextStyle: const TextStyle(color: Color(0xFFAAAAAA)),
        ),
        swipeToReplyConfig: const SwipeToReplyConfiguration(
          replyIconColor: Color(0xFF00BCD4),
        ),
        replySuggestionsConfig: ReplySuggestionsConfig(
          itemConfig: SuggestionItemConfig(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFDCF8C6)),
            ),
            textStyle: const TextStyle(color: Colors.black),
          ),
          onTap: (item) => _onSendTap(item.text, const ReplyMessage(), MessageType.text),
        ),
      ),
    );
  }

  void _onSendTap(String message, ReplyMessage replyMessage, MessageType messageType) {
    final messageObj = Message(
      id: DateTime.now().toString(),
      createdAt: DateTime.now(),
      message: message,
      sentBy: _chatController.currentUser.id,
      replyMessage: replyMessage,
      messageType: messageType,
    );
    _chatController.addMessage(messageObj);

    Future.delayed(const Duration(milliseconds: 300), () {
      final index = _chatController.initialMessageList.indexOf(messageObj);
      _chatController.initialMessageList[index].setStatus = MessageStatus.undelivered;
    });
    Future.delayed(const Duration(seconds: 1), () {
      final index = _chatController.initialMessageList.indexOf(messageObj);
      _chatController.initialMessageList[index].setStatus = MessageStatus.read;
    });
  }

  void _onThemeIconTap() {
    setState(() {
      isDarkTheme = !isDarkTheme;
    });
  }
}
