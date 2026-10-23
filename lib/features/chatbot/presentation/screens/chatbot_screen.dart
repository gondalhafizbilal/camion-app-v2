import 'package:camion/core/api/api_consumer.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/features/chatbot/data/data_source/chatbot_remote_data_source.dart';
import 'package:camion/features/chatbot/data/models/chatbot_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  static const String _sessionCacheKey = 'chatbot_session_id';

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  late final ChatbotRemoteDataSource _chatbotDataSource;

  bool _isInitializing = true;
  bool _isSending = false;

  String? _sessionId;
  String? _token;
  String? _activeCategory;

  List<ChatMessage> _messages = const [];

  final List<String> _categories = const [
    'support',
    'technical',
    'general',
    'faq',
  ];

  final Map<String, List<String>> _starterQuestions = const {
    'support': [
      'How can I contact support for my order?',
      'What should I do if my order has not arrived?',
    ],
    'technical': [
      'The app is crashing, how can I fix it?',
      'Why am I unable to complete checkout?',
    ],
    'general': [
      'What services does Camion provide?',
      'How do I start using the app?',
    ],
    'faq': [
      'What is your return policy?',
      'How long does shipping usually take?',
    ],
  };

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  String _t(String en, String ar) => _isArabic ? ar : en;

  String _categoryLabel(String category) {
    switch (category) {
      case 'support':
        return _t('Support', 'الدعم');
      case 'technical':
        return _t('Technical', 'تقني');
      case 'general':
        return _t('General', 'عام');
      case 'faq':
        return _t('FAQ', 'الأسئلة الشائعة');
      default:
        return category;
    }
  }

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final localTime = dateTime.toLocal();
    final timeOfDay = TimeOfDay.fromDateTime(localTime);
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  List<String> _starterQuestionsFor(String category) {
    if (_isArabic) {
      switch (category) {
        case 'support':
          return const [
            'كيف يمكنني التواصل مع الدعم بخصوص طلبي؟',
            'ماذا أفعل إذا لم يصل طلبي؟',
          ];
        case 'technical':
          return const [
            'التطبيق يتعطل، كيف يمكنني إصلاح المشكلة؟',
            'لماذا لا أستطيع إكمال عملية الدفع؟',
          ];
        case 'faq':
          return const ['ما هي سياسة الإرجاع لديكم؟', 'كم يستغرق الشحن عادة؟'];
        case 'general':
        default:
          return const [
            'ما الخدمات التي يقدمها تطبيق كاميون؟',
            'كيف أبدأ باستخدام التطبيق؟',
          ];
      }
    }
    return _starterQuestions[category] ?? const [];
  }

  @override
  void initState() {
    super.initState();
    _chatbotDataSource = ChatbotRemoteDataSource(
      apiConsumer: sl<ApiConsumer>(),
    );
    _initializeSessionAndHistory();
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeSessionAndHistory() async {
    setState(() => _isInitializing = true);

    final secureCache = sl<SecureCacheHelper>();
    _token = await secureCache.getData(key: 'token');

    String? sessionId = await secureCache.getData(key: _sessionCacheKey);

    if (sessionId != null && sessionId.isNotEmpty) {
      final loaded = await _loadHistory(sessionId);
      if (loaded) {
        if (!mounted) return;
        setState(() {
          _isInitializing = false;
        });
        _scrollToBottom();
        return;
      }
    }

    sessionId = await _createAndPersistSession();
    if (!mounted) return;

    setState(() {
      _sessionId = sessionId;
      _messages = const [];
      _isInitializing = false;
    });
  }

  Future<bool> _loadHistory(String sessionId) async {
    try {
      final history = await _chatbotDataSource.getSessionHistory(sessionId);
      if (!mounted) return false;

      setState(() {
        _sessionId = history.sessionUUID.isNotEmpty
            ? history.sessionUUID
            : sessionId;
        _messages = history.messages;
      });
      return true;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String> _createAndPersistSession() async {
    final secureCache = sl<SecureCacheHelper>();
    final token = (_token ?? '').trim();
    if (token.isEmpty) {
      return '';
    }
    final sessionId = await _chatbotDataSource.createSession(token: token);

    if (sessionId.isNotEmpty) {
      await secureCache.saveData(key: _sessionCacheKey, value: sessionId);
    }
    return sessionId;
  }

  Future<void> _sendQuestion(String question, {String? forcedCategory}) async {
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty || _isSending) return;

    final sessionId = _sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      AppToast.show(
        msg: _t(
          'Unable to start chat. Please reopen chatbot.',
          'تعذر بدء المحادثة. يرجى إعادة فتح دعم المحادثة.',
        ),
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
      );
      return;
    }

    final category = (forcedCategory ?? _activeCategory ?? 'general')
        .toLowerCase();

    setState(() {
      _activeCategory = category;
      _isSending = true;
      _messages = [
        ..._messages,
        ChatMessage(
          role: 'user',
          content: trimmedQuestion,
          timestamp: DateTime.now(),
        ),
      ];
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await _chatbotDataSource.askInSession(
        sessionId: sessionId,
        token: (_token ?? '').trim(),
        question: trimmedQuestion,
      );

      if (!mounted) return;

      setState(() {
        _messages = [
          ..._messages,
          ChatMessage(
            role: 'assistant',
            content: response.answer,
            timestamp: DateTime.now(),
            sources: response.sources,
          ),
        ];
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        msg: _t(
          'Failed to get response. Please try again.',
          'تعذر الحصول على رد. يرجى المحاولة مرة أخرى.',
        ),
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _onEmojiTap() {
    _inputFocusNode.requestFocus();
    const emoji = '😊';
    final oldValue = _controller.value;
    final baseText = oldValue.text;
    final selection = oldValue.selection;
    final hasValidSelection =
        selection.start >= 0 &&
        selection.end >= 0 &&
        selection.start <= baseText.length &&
        selection.end <= baseText.length;

    String updatedText;
    int caretOffset;
    if (hasValidSelection) {
      final prefix = baseText.substring(0, selection.start);
      final suffix = baseText.substring(selection.end);
      updatedText = '$prefix$emoji$suffix';
      caretOffset = (prefix + emoji).length;
    } else {
      updatedText = '$baseText$emoji';
      caretOffset = updatedText.length;
    }

    _controller.value = TextEditingValue(
      text: updatedText,
      selection: TextSelection.collapsed(offset: caretOffset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10.h),
            _buildTopBar(context),
            SizedBox(height: 12.h),
            _buildCategoryBar(),
            SizedBox(height: 8.h),
            Expanded(child: _buildBody()),
            _buildQuickReplies(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SizedBox(
      height: 56.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            InkWell(
              onTap: () => AppNavigator.safePop(context),
              borderRadius: BorderRadius.circular(14.r),
              child: Ink(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: const Color(0xFF0F172A),
                  size: 18.r,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                _t('Camion Chatbot', 'كاميون شات بوت'),
                style: TextStyle(
                  fontFamily: 'Montes',
                  fontWeight: FontWeight.w600,
                  fontSize: 24.sp,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return _buildStarters();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 20.h),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isSending && index == _messages.length) {
          return const _TypingIndicatorBubble();
        }

        final message = _messages[index];
        final isUser = message.role.toLowerCase() == 'user';
        final bubbleMaxWidth = MediaQuery.of(context).size.width * 0.75;
        final timeLabel = _formatMessageTime(message.timestamp);

        return Padding(
          padding: EdgeInsets.only(bottom: 18.h),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  right: isUser ? 2.w : 0,
                  left: isUser ? 0 : 2.w,
                  bottom: 6.h,
                ),
                child: isUser
                    ? Text(
                        timeLabel.isEmpty
                            ? _t('Visitor', 'الزائر')
                            : '${_t('Visitor', 'الزائر')} $timeLabel',
                        style: TextStyle(
                          fontFamily: 'Montes',
                          fontWeight: FontWeight.w500,
                          fontSize: 11.sp,
                          color: const Color(0xFF64748B),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ChatAvatar(size: 30.r),
                          SizedBox(width: 8.w),
                          Text(
                            timeLabel.isEmpty
                                ? _t('Chatbot', 'شات بوت')
                                : '${_t('Chatbot', 'شات بوت')} $timeLabel',
                            style: TextStyle(
                              fontFamily: 'Montes',
                              fontWeight: FontWeight.w500,
                              fontSize: 11.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
              ),
              Align(
                alignment: isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 13.h,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                      bottomLeft: Radius.circular(isUser ? 16.r : 4.r),
                      bottomRight: Radius.circular(isUser ? 4.r : 16.r),
                    ),
                    border: Border.all(
                      color: isUser
                          ? AppColors.primaryColor.withAlpha(90)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(12),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          fontFamily: 'Montes',
                          fontWeight: FontWeight.w400,
                          fontSize: 14.sp,
                          height: 1.5,
                          color: isUser
                              ? Colors.white
                              : const Color(0xFF334155),
                        ),
                      ),
                      if (!isUser && message.sources.isNotEmpty) ...[
                        SizedBox(height: 9.h),
                        Text(
                          '${_t('Sources', 'المصادر')}: ${message.sources.map((s) => s.title).take(2).join(', ')}',
                          style: TextStyle(
                            fontFamily: 'Montes',
                            fontWeight: FontWeight.w400,
                            fontSize: 11.sp,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isUser)
                Padding(
                  padding: EdgeInsets.only(top: 6.h, right: 2.w),
                  child: Text(
                    _t('Read', 'تمت القراءة'),
                    style: TextStyle(
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w500,
                      fontSize: 11.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryBar() {
    return SizedBox(
      height: 46.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isActive = _activeCategory == category;
          return InkWell(
            borderRadius: BorderRadius.circular(13.r),
            onTap: () {
              setState(() => _activeCategory = category);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFFFF1F2) : Colors.white,
                borderRadius: BorderRadius.circular(13.r),
                border: Border.all(
                  color: isActive
                      ? AppColors.primaryColor
                      : const Color(0xFFD5DBE5),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primaryColor.withAlpha(24),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : const [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _categoryLabel(category),
                    style: TextStyle(
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w500,
                      fontSize: 13.sp,
                      color: isActive
                          ? AppColors.primaryColor
                          : const Color(0xFF475569),
                    ),
                  ),
                  if (isActive) ...[
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18.r,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemCount: _categories.length,
      ),
    );
  }

  Widget _buildStarters() {
    final category = _activeCategory ?? 'general';
    final questions = _starterQuestionsFor(category);

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      children: [
        Text(
          _t(
            'Choose a topic so I can help you faster.',
            'اختر موضوعًا حتى أتمكن من مساعدتك بشكل أسرع.',
          ),
          style: TextStyle(
            fontFamily: 'Montes',
            fontWeight: FontWeight.w500,
            fontSize: 15.sp,
            height: 1.45,
            color: const Color(0xFF475569),
          ),
        ),
        SizedBox(height: 12.h),
        ...questions.map(
          (question) => Container(
            margin: EdgeInsets.only(bottom: 10.h),
            child: InkWell(
              onTap: () => _sendQuestion(question, forcedCategory: category),
              borderRadius: BorderRadius.circular(14.r),
              child: Ink(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xFFD5DBE5)),
                  color: Colors.white,
                ),
                child: Text(
                  question,
                  style: TextStyle(
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w400,
                    fontSize: 14.sp,
                    height: 1.5,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickReplies() {
    if (_isInitializing || _isSending) return const SizedBox.shrink();

    final category = _activeCategory ?? 'general';
    final quickReplies = _starterQuestionsFor(category);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: quickReplies
            .map(
              (reply) => InkWell(
                onTap: () => _sendQuestion(reply, forcedCategory: category),
                borderRadius: BorderRadius.circular(22.r),
                child: Ink(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22.r),
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFD5DBE5)),
                  ),
                  child: Text(
                    reply,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Montes',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Color(0xFFDDE3EC))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _inputFocusNode,
                        enabled: !_isInitializing,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendQuestion(_controller.text),
                        minLines: 1,
                        maxLines: 4,
                        style: TextStyle(
                          fontFamily: 'Montes',
                          fontWeight: FontWeight.w400,
                          fontSize: 15.sp,
                          height: 1.45,
                          color: const Color(0xFF334155),
                        ),
                        decoration: InputDecoration(
                          hintText: _t('Write a message', 'اكتب رسالة'),
                          hintStyle: TextStyle(
                            fontFamily: 'Montes',
                            fontWeight: FontWeight.w400,
                            fontSize: 15.sp,
                            color: const Color(0xFF64748B),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(16.r),
                      onTap: _isInitializing ? null : _onEmojiTap,
                      child: Padding(
                        padding: EdgeInsets.all(2.r),
                        child: Icon(
                          Icons.sentiment_satisfied_alt_rounded,
                          color: const Color(0xFF64748B),
                          size: 24.r,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            InkWell(
              borderRadius: BorderRadius.circular(18.r),
              onTap: (_isInitializing || _isSending)
                  ? null
                  : () => _sendQuestion(_controller.text),
              child: Ink(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: _isSending
                    ? Center(
                        child: SizedBox(
                          width: 16.w,
                          height: 16.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: const Color(0xFF9CA3AF),
                        size: 18.r,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicatorBubble extends StatelessWidget {
  const _TypingIndicatorBubble();

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: EdgeInsets.only(bottom: 18.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 2.w, bottom: 6.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ChatAvatar(size: 30.r),
                SizedBox(width: 8.w),
                Text(
                  isArabic ? 'شات بوت' : 'Chatbot',
                  style: TextStyle(
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w500,
                    fontSize: 11.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              isArabic ? 'جاري الكتابة...' : 'Typing...',
              style: TextStyle(
                fontFamily: 'Montes',
                fontWeight: FontWeight.w400,
                fontSize: 14.sp,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Container(
          width: size * 0.46,
          height: size * 0.46,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(size * 0.16),
          ),
          child: Icon(
            Icons.chat_bubble_rounded,
            color: Colors.white,
            size: size * 0.24,
          ),
        ),
      ),
    );
  }
}
