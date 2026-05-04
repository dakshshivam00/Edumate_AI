import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ailearning/src/common/app_theme.dart';
import 'package:ailearning/src/common/user_role_service.dart';
import 'package:ailearning/src/services/chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherAIChatScreen extends StatefulWidget {
  final String? videoUrl;
  final String? courseTitle;
  final double courseProgress;
  final int? currentLessonIndex;
  final List<String> allowedLessonTitles;
  final String? userRole;

  const TeacherAIChatScreen({
    super.key,
    this.videoUrl,
    this.courseTitle,
    this.courseProgress = 0,
    this.currentLessonIndex,
    this.allowedLessonTitles = const [],
    this.userRole,
  });

  @override
  State<TeacherAIChatScreen> createState() => _TeacherAIChatScreenState();
}

class _TeacherAIChatScreenState extends State<TeacherAIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final UserRoleService _userRoleService = UserRoleService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _resolvedUserRole = 'student';

  bool get _isCourseChat =>
      widget.courseTitle != null && widget.courseTitle!.trim().isNotEmpty;

  String get _historyKey {
    final roleSegment = _resolvedUserRole.trim().toLowerCase();
    return _isCourseChat
        ? 'edumate_ai_${roleSegment}_course_chat_${widget.courseTitle!.trim().toLowerCase()}'
        : 'edumate_ai_${roleSegment}_global_chat';
  }

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    if (widget.userRole != null && widget.userRole!.trim().isNotEmpty) {
      _resolvedUserRole = widget.userRole!.trim().toLowerCase();
    } else {
      _resolvedUserRole = await _userRoleService.isTeacher()
          ? 'teacher'
          : 'student';
    }
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHistory = prefs.getString(_historyKey);

    if (savedHistory != null) {
      try {
        final decoded = jsonDecode(savedHistory) as List<dynamic>;
        final messages = decoded
            .whereType<Map>()
            .map((message) => ChatMessage.fromJson(message))
            .toList();
        if (mounted && messages.isNotEmpty) {
          setState(() => _messages.addAll(messages));
          _scrollToBottom();
          return;
        }
      } catch (_) {
        // Fall through to fresh welcome message.
      }
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_welcomeMessage());
    });
  }

  ChatMessage _welcomeMessage() {
    if (_isCourseChat) {
      final unlocked = widget.allowedLessonTitles.length;
      final progress = (widget.courseProgress * 100).round();
      return ChatMessage(
        text:
            'Course chat is active for ${widget.courseTitle}. I will stay inside your unlocked syllabus: $unlocked lesson${unlocked == 1 ? '' : 's'} and $progress% progress.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    return ChatMessage(
      text:
          'Hello! I\'m your Edumate AI assistant. Ask me anything, or use the course chat from a lesson when you want restricted help.',
      isUser: false,
      timestamp: DateTime.now(),
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

  Future<void> _sendMessage([String? overrideText]) async {
    final text = (overrideText ?? _messageController.text).trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    final prompt = _isCourseChat
        ? _buildCourseScopedPrompt(text)
        : _buildGlobalPrompt(text);

    String responseText = '';
    final stream = (widget.videoUrl != null && widget.videoUrl!.trim().isNotEmpty)
        ? _chatService.sendChatMessageWithVideoStream(
            query: prompt,
            videoUrl: widget.videoUrl!,
          )
        : _chatService.sendChatMessageStream(query: prompt);

    await for (final chunk in stream) {
      if (chunk.startsWith('error:')) {
        responseText = 'Server error. Please try again.';
        break;
      }
      responseText += chunk;
    }

    if (!mounted) return;
    setState(() {
      _messages.add(
        ChatMessage(
          text: responseText.trim().isEmpty
              ? 'No response received. Please try again.'
              : responseText.trim(),
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = false;
    });
    await _saveHistory();
    _scrollToBottom();
  }

  String _buildGlobalPrompt(String query) {
    return 'You are an AI tutor inside the Edumate AI learning app. '
        'Provide concise, practical, student-friendly answers.\n\n'
        'User question: $query';
  }

  String _buildCourseScopedPrompt(String query) {
    final unlockedCount = widget.allowedLessonTitles.length;
    final progress = (widget.courseProgress * 100).round();
    final lessons = widget.allowedLessonTitles.isEmpty
        ? 'current lesson'
        : widget.allowedLessonTitles.join(', ');

    return 'You are an AI tutor in course-restricted mode.\n'
        'Course: ${widget.courseTitle}\n'
        'Progress: $progress%\n'
        'Unlocked lessons: $unlockedCount\n'
        'Allowed syllabus scope: $lessons\n'
        'If user asks outside this scope, politely refuse and guide to unlocked topics.\n\n'
        'User question: $query';
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(_messages.map((message) => message.toJson()).toList()),
    );
  }

  Widget _buildPromptChips() {
    final prompts = _isCourseChat
        ? const ['Summarize', 'Make quiz', 'Explain simply']
        : const ['Study plan', 'Generate quiz', 'Global vs course chat'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: prompts
            .map(
              (prompt) => Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: ActionChip(
                  label: Text(prompt),
                  onPressed: _isLoading ? null : () => _sendMessage(prompt),
                  backgroundColor: AppTheme.textPrimary.withOpacity(
                    AppTheme.containerOpacity,
                  ),
                  labelStyle: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12.sp,
                  ),
                  side: BorderSide(
                    color: AppTheme.textPrimary.withOpacity(
                      AppTheme.borderOpacity,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
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
                  _isCourseChat
                      ? '${widget.allowedLessonTitles.length} lessons unlocked'
                      : 'Global chat',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: 'Clear chat',
            onPressed: () async {
              setState(() {
                _messages
                  ..clear()
                  ..add(_welcomeMessage());
              });
              await _saveHistory();
            },
          ),
        ],
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPromptChips(),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 240.h),
                          child: TextFormField(
                            controller: _messageController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: _isCourseChat
                                  ? 'Ask from unlocked course content...'
                                  : 'Ask anything...',
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
                          onPressed: _isLoading ? null : () => _sendMessage(),
                          tooltip: 'Send message',
                        ),
                      ),
                    ],
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

  factory ChatMessage.fromJson(Map<dynamic, dynamic> json) {
    return ChatMessage(
      text: (json['text'] ?? '').toString(),
      isUser: json['isUser'] == true,
      timestamp:
          DateTime.tryParse((json['timestamp'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }
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
      content = _buildQuizWidget(jsonData);
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
