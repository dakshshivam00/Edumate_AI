import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ailearning/src/common/app_theme.dart';
import 'package:ailearning/src/services/chat_service.dart';
import 'package:ailearning/src/common/global_snackbar.dart';

class TeacherAIChatScreen extends StatefulWidget {
  final String? videoUrl;

  const TeacherAIChatScreen({super.key, this.videoUrl});

  @override
  State<TeacherAIChatScreen> createState() => _TeacherAIChatScreenState();
}

class _TeacherAIChatScreenState extends State<TeacherAIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ChatService _chatService = ChatService();
  bool _isLoading = false;
  int? _streamingMessageIndex;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      ChatMessage(
        text:
            'Hello! I\'m your AI teaching assistant. How can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    // Prevent sending if message is empty or if we're currently streaming
    if (text.isEmpty || _streamingMessageIndex != null) return;

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
    });

    _messageController.clear();
    _scrollToBottom();

    // Create a placeholder message for streaming response
    setState(() {
      _messages.add(
        ChatMessage(text: '', isUser: false, timestamp: DateTime.now()),
      );
      _streamingMessageIndex = _messages.length - 1;
      _isLoading =
          false; // Don't show loading indicator, we're showing streaming text
    });

    // Send message to chat API with streaming
    // Use video streaming if videoUrl is present, otherwise use regular streaming
    try {
      final stream = widget.videoUrl != null && widget.videoUrl!.isNotEmpty
          ? _chatService.sendChatMessageWithVideoStream(
              query: text,
              videoUrl: widget.videoUrl!,
            )
          : _chatService.sendChatMessageStream(query: text);

      await for (final chunk in stream) {
        if (!mounted) return;

        // Handle errors
        if (chunk.startsWith('error:')) {
          final errorParts = chunk.substring(6).split(':');
          final errorMessage = errorParts.length > 1
              ? errorParts.sublist(1).join(':')
              : errorParts[0];

          setState(() {
            if (_streamingMessageIndex != null &&
                _streamingMessageIndex! < _messages.length) {
              _messages[_streamingMessageIndex!] = ChatMessage(
                text: 'Sorry, I encountered an error: $errorMessage',
                isUser: false,
                timestamp: _messages[_streamingMessageIndex!].timestamp,
              );
            }
            _isLoading = false;
            _streamingMessageIndex = null;
          });

          GlobalScaffoldManager().showSnackbar(
            'Error: $errorMessage',
            type: SnackbarType.error,
          );
          break;
        } else if (chunk.isNotEmpty) {
          // Update streaming message with new chunk
          setState(() {
            if (_streamingMessageIndex != null &&
                _streamingMessageIndex! < _messages.length) {
              final currentMessage = _messages[_streamingMessageIndex!];
              _messages[_streamingMessageIndex!] = ChatMessage(
                text: currentMessage.text + chunk,
                isUser: false,
                timestamp: currentMessage.timestamp,
              );
            }
          });
          _scrollToBottom();
        }
      }

      // Streaming complete
      if (mounted) {
        setState(() {
          _isLoading = false;
          _streamingMessageIndex = null;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        if (_streamingMessageIndex != null &&
            _streamingMessageIndex! < _messages.length) {
          _messages[_streamingMessageIndex!] = ChatMessage(
            text: 'An error occurred: ${e.toString()}',
            isUser: false,
            timestamp: _messages[_streamingMessageIndex!].timestamp,
          );
        }
        _isLoading = false;
        _streamingMessageIndex = null;
      });

      GlobalScaffoldManager().showSnackbar(
        'Error: ${e.toString()}',
        type: SnackbarType.error,
      );
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                size: 20.sp,
                color: AppTheme.secondaryColor,
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('AI Assistant'),
                Text(
                  'Always here to help',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textPrimary.withOpacity(
                      AppTheme.textSecondaryOpacity,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.more_vert),
        //     onPressed: () {
        //       // Show options menu
        //       showModalBottomSheet(
        //         context: context,
        //         backgroundColor: AppTheme.primaryColor,
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.vertical(
        //             top: Radius.circular(20.r),
        //           ),
        //         ),
        //         builder: (context) => Container(
        //           padding: EdgeInsets.all(20.w),
        //           child: Column(
        //             mainAxisSize: MainAxisSize.min,
        //             children: [
        //               ListTile(
        //                 leading: const Icon(Icons.cleaning_services),
        //                 title: const Text('Clear Chat'),
        //                 onTap: () {
        //                   Navigator.pop(context);
        //                   setState(() {
        //                     _messages.clear();
        //                     _messages.add(
        //                       ChatMessage(
        //                         text: 'Chat cleared. How can I help you today?',
        //                         isUser: false,
        //                         timestamp: DateTime.now(),
        //                       ),
        //                     );
        //                   });
        //                 },
        //               ),
        //             ],
        //           ),
        //         ),
        //       );
        //     },
        //   ),
        // ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64.sp,
                          color: AppTheme.textPrimary.withOpacity(
                            AppTheme.textTertiaryOpacity,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Start a conversation',
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: AppTheme.textPrimary.withOpacity(
                              AppTheme.textSecondaryOpacity,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        // Loading indicator for AI response
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32.w,
                                height: 32.h,
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryColor.withOpacity(
                                    0.2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.smart_toy,
                                  size: 20.sp,
                                  color: AppTheme.secondaryColor,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: AppTheme.textPrimary.withOpacity(
                                      AppTheme.containerOpacity,
                                    ),
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 20.w,
                                        height: 20.h,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppTheme.secondaryColor,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        'Thinking...',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: AppTheme.textPrimary
                                              .withOpacity(
                                                AppTheme.textSecondaryOpacity,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final message = _messages[index];
                      return ChatBubble(message: message);
                    },
                  ),
          ),

          // Input Area
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(color: AppTheme.primaryColor),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 240.h, // Maximum height for input field
                      ),
                      child: TextFormField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(
                            color: AppTheme.textPrimary.withOpacity(
                              AppTheme.textTertiaryOpacity,
                            ),
                            fontSize: 16.sp,
                          ),
                          filled: true,
                          fillColor: AppTheme.textPrimary.withOpacity(
                            AppTheme.containerOpacity,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.r),
                            borderSide: BorderSide(
                              color: AppTheme.textPrimary.withOpacity(
                                AppTheme.borderOpacity,
                              ),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.r),
                            borderSide: BorderSide(
                              color: AppTheme.textPrimary.withOpacity(
                                AppTheme.borderOpacity,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.r),
                            borderSide: BorderSide(
                              color: AppTheme.secondaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 12.h,
                          ),
                        ),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16.sp,
                        ),
                        maxLines: null,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        // Allows Enter key (newline). To send, user taps send button.
                        // When text exceeds maxHeight, it will scroll up automatically
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        color: AppTheme.buttonForeground,
                        size: 24.sp,
                      ),
                      onPressed: _sendMessage,
                      tooltip: 'Send message',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  /// Try to parse text as JSON and return parsed data, or null if not valid JSON
  Map<String, dynamic>? _tryParseJson(String text) {
    try {
      // Try to extract JSON from text if it's wrapped in markdown code blocks
      String jsonText = text.trim();
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      }
      if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      jsonText = jsonText.trim();

      return jsonDecode(jsonText) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Check if JSON contains quiz questions
  bool _isQuizJson(Map<String, dynamic> json) {
    return json.containsKey('questions') &&
        json['questions'] is List &&
        (json['questions'] as List).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final jsonData = _tryParseJson(message.text);
    final isQuiz = jsonData != null && _isQuizJson(jsonData);

    Widget content;
    if (isQuiz) {
      content = _buildQuizWidget(jsonData!);
    } else if (jsonData != null) {
      content = _buildJsonWidget(jsonData);
    } else {
      content = Text(
        message.text,
        style: TextStyle(
          fontSize: 15.sp,
          color: message.isUser
              ? AppTheme.buttonForeground
              : AppTheme.textPrimary,
          height: 1.4,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                size: 20.sp,
                color: AppTheme.secondaryColor,
              ),
            ),
            SizedBox(width: 12.w),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.secondaryColor
                    : AppTheme.textPrimary.withOpacity(
                        AppTheme.containerOpacity,
                      ),
                borderRadius: BorderRadius.circular(16.r).copyWith(
                  bottomLeft: message.isUser
                      ? Radius.circular(16.r)
                      : Radius.circular(4.r),
                  bottomRight: message.isUser
                      ? Radius.circular(4.r)
                      : Radius.circular(16.r),
                ),
              ),
              child: content,
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 12.w),
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: AppTheme.textPrimary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: 20.sp,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizWidget(Map<String, dynamic> json) {
    final questions = json['questions'] as List<dynamic>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < questions.length; i++)
          Container(
            margin: EdgeInsets.only(
              bottom: i < questions.length - 1 ? 24.h : 0,
            ),
            child: _buildQuestionWidget(
              questions[i] as Map<String, dynamic>,
              i + 1,
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionWidget(
    Map<String, dynamic> question,
    int questionNumber,
  ) {
    final questionText = question['question'] as String? ?? '';
    final options = question['options'] as List<dynamic>? ?? [];
    final answer = question['answer'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question $questionNumber:',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          questionText,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            height: 1.4,
          ),
        ),
        SizedBox(height: 12.h),
        ...options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value.toString();
          final isCorrect = answer != null && option == answer;
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isCorrect
                  ? AppTheme.secondaryColor.withOpacity(0.15)
                  : AppTheme.textPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isCorrect
                    ? AppTheme.secondaryColor
                    : AppTheme.textPrimary.withOpacity(0.1),
                width: isCorrect ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? AppTheme.secondaryColor
                        : AppTheme.textPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: isCorrect
                            ? AppTheme.buttonForeground
                            : AppTheme.textPrimary.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textPrimary,
                      fontWeight: isCorrect
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (isCorrect)
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.secondaryColor,
                    size: 20.sp,
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildJsonWidget(Map<String, dynamic> json) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        const JsonEncoder.withIndent('  ').convert(json),
        style: TextStyle(
          fontSize: 13.sp,
          color: AppTheme.textPrimary.withOpacity(0.8),
          fontFamily: 'monospace',
          height: 1.4,
        ),
      ),
    );
  }
}
