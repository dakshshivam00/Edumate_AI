import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ailearning/src/common/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherAIChatScreen extends StatefulWidget {
  final String? videoUrl;
  final String? courseTitle;
  final double courseProgress;
  final int? currentLessonIndex;
  final List<String> allowedLessonTitles;

  const TeacherAIChatScreen({
    super.key,
    this.videoUrl,
    this.courseTitle,
    this.courseProgress = 0,
    this.currentLessonIndex,
    this.allowedLessonTitles = const [],
  });

  @override
  State<TeacherAIChatScreen> createState() => _TeacherAIChatScreenState();
}

class _TeacherAIChatScreenState extends State<TeacherAIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  bool get _isCourseChat =>
      widget.courseTitle != null && widget.courseTitle!.trim().isNotEmpty;

  String get _historyKey => _isCourseChat
      ? 'zoomate_course_chat_${widget.courseTitle!.trim().toLowerCase()}'
      : 'zoomate_global_chat';

  @override
  void initState() {
    super.initState();
    _loadHistory();
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
          'Hello! I\'m your Zoomate AI assistant. Ask me anything, or use the course chat from a lesson when you want restricted help.',
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

    await Future.delayed(const Duration(milliseconds: 450));
    final response = _generateLocalResponse(text);

    if (!mounted) return;
    setState(() {
      _messages.add(
        ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
      );
      _isLoading = false;
    });
    await _saveHistory();
    _scrollToBottom();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(_messages.map((message) => message.toJson()).toList()),
    );
  }

  String _generateLocalResponse(String query) {
    return _isCourseChat
        ? _generateCourseResponse(query)
        : _generateGlobalResponse(query);
  }

  String _generateCourseResponse(String query) {
    final lower = query.toLowerCase();
    final unlockedCount = widget.allowedLessonTitles.length;
    final requestedLesson = _requestedLessonNumber(lower);

    if (requestedLesson != null && requestedLesson > unlockedCount) {
      return 'This course chat is progress-restricted. You have unlocked only the first $unlockedCount lesson${unlockedCount == 1 ? '' : 's'} of ${widget.courseTitle}, so I cannot answer from lesson $requestedLesson yet. Watch more lectures to unlock that topic.';
    }

    if (_asksForFutureContent(lower)) {
      return 'I will keep this answer inside your unlocked syllabus. For now, focus on: ${_allowedLessonSummary()}. I can explain, summarize, or quiz you on these lessons.';
    }

    if (_asksForQuiz(lower)) {
      return jsonEncode({
        'questions': [
          {
            'question':
                'Which part of ${widget.courseTitle} should you revise first based on your unlocked progress?',
            'options': [
              widget.allowedLessonTitles.isEmpty
                  ? 'The current lesson'
                  : widget.allowedLessonTitles.first,
              'A locked future lesson',
              'An unrelated topic',
              'Skip all practice',
            ],
            'answer': widget.allowedLessonTitles.isEmpty
                ? 'The current lesson'
                : widget.allowedLessonTitles.first,
          },
          {
            'question':
                'What is the best way to use course chat in Zoomate AI?',
            'options': [
              'Ask only from unlocked course content',
              'Ask for answers from future chapters',
              'Ignore the current lecture',
              'Use it only for account settings',
            ],
            'answer': 'Ask only from unlocked course content',
          },
        ],
      });
    }

    if (lower.contains('summar')) {
      return 'Summary for your unlocked ${widget.courseTitle} syllabus: ${_allowedLessonSummary()}. Revise the definitions, write a small example from each lesson, and then solve a quick practice question before moving ahead.';
    }

    if (lower.contains('explain') || lower.contains('doubt')) {
      return 'Here is a simple explanation inside your current course boundary: break the topic into what it means, why it is used, and one small example. For ${widget.courseTitle}, stay focused on ${_allowedLessonSummary()}.';
    }

    return 'I can help with this, but only from your unlocked ${widget.courseTitle} content. Based on your ${(widget.courseProgress * 100).round()}% progress, use these lessons as the source: ${_allowedLessonSummary()}.';
  }

  String _generateGlobalResponse(String query) {
    final lower = query.toLowerCase();

    if (_asksForQuiz(lower)) {
      return jsonEncode({
        'questions': [
          {
            'question': 'What is the main purpose of Zoomate AI?',
            'options': [
              'Structured learning with AI support',
              'Only social messaging',
              'Only video editing',
              'Only payment tracking',
            ],
            'answer': 'Structured learning with AI support',
          },
          {
            'question':
                'Which chat mode should students use for syllabus-limited help?',
            'options': [
              'Course chat',
              'Profile page',
              'Settings page',
              'Launcher screen',
            ],
            'answer': 'Course chat',
          },
        ],
      });
    }

    if (lower.contains('course chat') || lower.contains('global chat')) {
      return 'Global chat is open for general questions. Course chat is opened from a lecture and stays restricted to the lessons unlocked by the student progress.';
    }

    if (lower.contains('study plan') || lower.contains('plan')) {
      return 'A good study plan is: watch one lecture, write short notes, ask course chat for doubts, solve a small quiz, then move to the next lecture only after the idea feels clear.';
    }

    return 'I can help with general learning, programming doubts, explanations, quiz ideas, and planning. Since this is frontend-only right now, I answer with local guidance rather than calling an external AI backend.';
  }

  int? _requestedLessonNumber(String query) {
    final match = RegExp(
      r'(lesson|lecture|video)\s*(\d+)',
    ).firstMatch(query);
    if (match == null) return null;
    return int.tryParse(match.group(2) ?? '');
  }

  bool _asksForFutureContent(String query) {
    return query.contains('future') ||
        query.contains('next chapter') ||
        query.contains('next lesson') ||
        query.contains('advanced') ||
        query.contains('beyond syllabus') ||
        query.contains('upcoming');
  }

  bool _asksForQuiz(String query) {
    return query.contains('quiz') ||
        query.contains('test') ||
        query.contains('question') ||
        query.contains('mcq');
  }

  String _allowedLessonSummary() {
    if (widget.allowedLessonTitles.isEmpty) {
      return 'the current lesson';
    }
    return widget.allowedLessonTitles.join(', ');
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
