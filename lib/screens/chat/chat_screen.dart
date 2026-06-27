// lib/screens/chat/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/screens/chat/message_bubble.dart';
import 'package:GeniusHouse/screens/chat/system_builder_sheet.dart'; 
import 'package:GeniusHouse/screens/offers/offer_details_screen.dart';
import 'package:GeniusHouse/screens/products/product_details_screen.dart';

class ChatScreen extends StatefulWidget {
  final AuthService authService;
  final ApiService apiService;

  const ChatScreen({
    super.key,
    required this.authService,
    required this.apiService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _messages = [];
  List<String> _suggestedQuestions = [];

  bool _isLoading = true;
  bool _isSending = false;
  bool _isAiTyping = false;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  int _currentOffset = 0;
  final int _limit = 1;
  final int _loadMoreLimit = 3;
  String? _errorMessage;

  String? _processingCalculationId;

  double _fontScale = 1.0;
  static const double _minFontScale = 0.7;
  static const double _maxFontScale = 2.0;

  
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  late AnimationController _typingAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _typingAnimation1;
  late Animation<double> _typingAnimation2;
  late Animation<double> _typingAnimation3;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchChatHistory();
    });
  }

  void _initAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _typingAnimation1 = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _typingAnimationController,
        curve: const Interval(0.0, 0.33, curve: Curves.easeInOut),
      ),
    );

    _typingAnimation2 = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _typingAnimationController,
        curve: const Interval(0.33, 0.66, curve: Curves.easeInOut),
      ),
    );

    _typingAnimation3 = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _typingAnimationController,
        curve: const Interval(0.66, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _resetFontScale() {
    HapticFeedback.lightImpact();
    setState(() => _fontScale = 1.0);
    _showFontScaleSnackBar();
  }

  void _showFontScaleSnackBar() {
    final percentage = (_fontScale * 100).round();
    String sizeLabel;
    if (_fontScale <= 0.8) {
      sizeLabel = 'صغير';
    } else if (_fontScale <= 1.1) {
      sizeLabel = 'عادي';
    } else if (_fontScale <= 1.5) {
      sizeLabel = 'كبير';
    } else {
      sizeLabel = 'كبير جداً';
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.text_fields_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('حجم الخط: $sizeLabel ($percentage%)', style: GoogleFonts.cairo(fontSize: 13)),
          ],
        ),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 1),
      ));
  }

  Future<void> _fetchChatHistory({bool loadMore = false}) async {
    if (loadMore) {
      if (!_hasMore || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final int currentLimit = loadMore ? _loadMoreLimit : _limit;

      final response = await widget.apiService.get(
        '/v1/user/chat/history?limit=$currentLimit&offset=${loadMore ? _currentOffset : 0}',
        requiresAuth: true,
      );

      if (response['status'] == 'success' && mounted) {
        final data = response['data'];
        final List<dynamic> messages = data['messages'] ?? [];
        final pagination = data['pagination'];

        final processedMessages = messages.reversed
            .map<Map<String, dynamic>>((msg) => Map<String, dynamic>.from(msg))
            .toList();

        setState(() {
          if (loadMore) {
            _messages.insertAll(0, processedMessages);
            _isLoadingMore = false;
          } else {
            _messages = processedMessages;
            _isLoading = false;
          }

          _hasMore = pagination?['has_more'] ?? false;
          _currentOffset = pagination?['next_offset'] ?? _currentOffset + currentLimit;

          if (_messages.isNotEmpty && !loadMore) {
            final lastMessage = _messages.last;
            if (!(lastMessage['me'] ?? false) && lastMessage.containsKey('data')) {
              _suggestedQuestions = List<String>.from(
                lastMessage['data']?['suggested_questions'] ?? [],
              );
            }
          }
        });

        if (!loadMore && _messages.isNotEmpty) {
          _scrollToBottom();
        }
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = response['message'] ?? 'حدث خطأ في تحميل المحادثة';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = 'حدث خطأ في الاتصال';
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _messages.isNotEmpty) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? customMessage}) async {
    final message = customMessage ?? _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    HapticFeedback.mediumImpact();

    final userMessage = {
      'me': true,
      'role': 'user',
      'content': message,
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'text',
    };

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isSending = true;
      _isAiTyping = true;
      _suggestedQuestions = [];
    });

    _scrollToBottom();
    _focusNode.unfocus();

    try {
      final response = await widget.apiService.post(
        '/v1/user/chat/send',
        requiresAuth: true,
        data: {'message': message},
      );

      setState(() => _isAiTyping = false);

      if (response['status'] == 'success' && mounted) {
        final assistantMessage = {
          'me': false,
          'role': 'assistant',
          'content': response['data']['message'],
          'timestamp': DateTime.now().toIso8601String(),
          'data': response['data']['data'],
          'type': response['data']['type'] ?? 'text',
        };

        setState(() {
          _messages.add(assistantMessage);
          _isSending = false;
          _suggestedQuestions = List<String>.from(
            response['data']['suggested_questions'] ?? [],
          );
        });

        _scrollToBottom();
      } else if (response['status'] == 'processing' && mounted) {
        _processingCalculationId = response['calculation_id'];
        _showProcessingSnackBar();
        _pollCalculationResult();
      } else {
        setState(() => _isSending = false);
        _showErrorSnackBar(response['message'] ?? 'حدث خطأ في إرسال الرسالة');
      }
    } catch (e) {
      setState(() {
        _isSending = false;
        _isAiTyping = false;
      });
      _showErrorSnackBar('حدث خطأ في الاتصال');
    }
  }

  Future<void> _pollCalculationResult() async {
    int attempts = 0;
    const maxAttempts = 30;

    while (attempts < maxAttempts && _processingCalculationId != null) {
      await Future.delayed(const Duration(seconds: 2));

      try {
        final response = await widget.apiService.get(
          '/v1/user/chat/calculation-result?calculation_id=$_processingCalculationId',
          requiresAuth: true,
        );

        if (response['status'] == 'success' && mounted) {
          final assistantMessage = {
            'me': false,
            'role': 'assistant',
            'content': response['data']['message'],
            'timestamp': DateTime.now().toIso8601String(),
            'data': response['data']['data'],
            'type': response['data']['type'] ?? 'offers',
          };

          setState(() {
            _messages.add(assistantMessage);
            _isSending = false;
            _isAiTyping = false;
            _processingCalculationId = null;
            _suggestedQuestions = List<String>.from(
              response['data']['suggested_questions'] ?? [],
            );
          });

          _scrollToBottom();
          return;
        } else if (response['status'] == 'error' && mounted) {
          setState(() {
            _isSending = false;
            _isAiTyping = false;
            _processingCalculationId = null;
          });
          _showErrorSnackBar(response['message'] ?? 'حدث خطأ في الحساب');
          return;
        }
        attempts++;
      } catch (e) {
        attempts++;
      }
    }

    if (mounted && _processingCalculationId != null) {
      setState(() {
        _isSending = false;
        _isAiTyping = false;
        _processingCalculationId = null;
      });
      _showErrorSnackBar('انتهت مهلة الانتظار، يرجى المحاولة مرة أخرى');
    }
  }

  void _openSystemBuilder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SystemBuilderSheet(
        onSend: (message) {
          Navigator.pop(context);
          _sendMessage(customMessage: message);
        },
      ),
    );
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.delete_rounded, color: Colors.red.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            Text('مسح المحادثة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: darkColor)),
          ],
        ),
        content: Text('هل أنت متأكد من مسح جميع رسائل المحادثة؟', style: GoogleFonts.cairo(fontSize: 15, color: mediumGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: mediumGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('مسح', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final response = await widget.apiService.delete('/v1/user/chat/clear', requiresAuth: true);
        if (response['status'] == 'success' && mounted) {
          setState(() {
            _messages = [];
            _suggestedQuestions = [];
            _currentOffset = 0;
            _hasMore = false;
            _isLoading = false;
            _isAiTyping = false;
          });
          _showSuccessSnackBar('تم مسح المحادثة بنجاح');
        } else {
          setState(() => _isLoading = false);
          _showErrorSnackBar(response['message'] ?? 'حدث خطأ في مسح المحادثة');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('حدث خطأ في الاتصال');
      }
    }
  }

  void _sendSuggestedQuestion(String question) {
    _messageController.text = question;
    _sendMessage();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: GoogleFonts.cairo())),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: GoogleFonts.cairo())),
          ],
        ),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));
  }

  void _showProcessingSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            const SizedBox(width: 10),
            Text('جاري حساب احتياجاتك...', style: GoogleFonts.cairo()),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green.shade400, size: 20),
            const SizedBox(width: 8),
            Text('تم نسخ النص', style: GoogleFonts.cairo()),
          ],
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      if (difference.inDays > 0) {
        return DateFormat('MMM dd, hh:mm a').format(dateTime);
      } else if (difference.inHours > 0) {
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inMinutes > 0) {
        return 'منذ ${difference.inMinutes} دقيقة';
      }
      return 'الآن';
    } catch (e) {
      return '';
    }
  }

  void _navigateToProduct(String slug) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          productSlug: slug,
          apiService: widget.apiService,
          authService: widget.authService,
        ),
      ),
    );
  }

  void _navigateToOffer(String slug) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfferDetailsScreen(
          offerSlug: slug,
          apiService: widget.apiService,
          authService: widget.authService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseAnimationController.value * 0.1),
                  child: child,
                );
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المساعد الذكي', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('نظام الطاقة الشمسية', style: GoogleFonts.cairo(fontSize: 11, color: Colors.white.withOpacity(0.85))),
              ],
            ),
          ],
        ),
        elevation: 0,
        actions: [
          if (_fontScale != 1.0)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.text_fields_rounded, color: Colors.white, size: 20),
                onPressed: _resetFontScale,
                tooltip: 'إعادة تعيين حجم الخط',
              ),
            ),
          if (_messages.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                onPressed: _clearChat,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? _buildEmptyState() : _buildMessagesList(),
          ),
          if (_suggestedQuestions.isNotEmpty && !_isSending)
            _buildSuggestedQuestions(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return GestureDetector(
      onScaleUpdate: (details) {
        setState(() {
          _fontScale = (_fontScale * details.scale).clamp(_minFontScale, _maxFontScale);
        });
      },
      onScaleEnd: (_) {
        _showFontScaleSnackBar();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        cacheExtent: 300,
        itemCount: _messages.length + (_hasMore ? 1 : 0) + (_isAiTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (_hasMore && index == 0) {
            return _buildLoadMoreButton();
          }

          final messageIndex = _hasMore ? index - 1 : index;

          if (_isAiTyping && messageIndex >= _messages.length) {
            return _buildTypingIndicator();
          }

          if (messageIndex < _messages.length) {
            final message = _messages[messageIndex];
            return MessageBubble(
              isUser: message['me'] ?? false,
              content: message['content'] ?? '',
              timestamp: _formatTimestamp(message['timestamp'] ?? ''),
              data: message['data'],
              type: message['type'] ?? 'text',
              fontScale: _fontScale,
              apiService: widget.apiService,
              authService: widget.authService,
              onProductTap: _navigateToProduct,
              onOfferTap: _navigateToOffer,
              onCopyTap: () => _copyToClipboard(message['content'] ?? ''),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return GestureDetector(
      onTap: _isLoadingMore ? null : () => _fetchChatHistory(loadMore: true),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: _isLoadingMore
              ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2),
          )
              : Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue.withOpacity(0.08), secondaryBlue.withOpacity(0.04)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryBlue.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_upward_rounded, size: 14, color: primaryBlue),
                const SizedBox(width: 6),
                Text(
                  'تحميل الرسائل السابقة',
                  style: GoogleFonts.cairo(
                    fontSize: 12 * _fontScale,
                    color: primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue.withOpacity(0.12), secondaryBlue.withOpacity(0.06)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: primaryBlue, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.04), blurRadius: 5)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(_typingAnimation1),
                const SizedBox(width: 5),
                _buildDot(_typingAnimation2),
                const SizedBox(width: 5),
                _buildDot(_typingAnimation3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardWhite,
        boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.06), blurRadius: 10)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: lightGray,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  style: GoogleFonts.cairo(fontSize: 14 * _fontScale, color: darkColor),
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'اكتب استفسارك...',
                    hintStyle: GoogleFonts.cairo(fontSize: 14 * _fontScale, color: Colors.grey.shade400),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFF57C00)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFFFF9800).withOpacity(0.3), blurRadius: 8)],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openSystemBuilder,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: const Icon(Icons.solar_power_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 8)],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSending ? null : () => _sendMessage(),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: _isSending
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedQuestions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardWhite,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SizedBox(
        height: 40 * _fontScale,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _suggestedQuestions.length,
          itemBuilder: (context, index) {
            final question = _suggestedQuestions[index];
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => _sendSuggestedQuestion(question),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryBlue.withOpacity(0.06), secondaryBlue.withOpacity(0.03)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: primaryBlue.withOpacity(0.12)),
                  ),
                  child: Text(
                    question,
                    style: GoogleFonts.cairo(fontSize: 11 * _fontScale, color: primaryBlue, fontWeight: FontWeight.w600),
                    maxLines: 1,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseAnimationController.value * 0.1),
                child: child,
              );
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primaryBlue.withOpacity(0.1), secondaryBlue.withOpacity(0.05)],
                ),
              ),
              child: const CircularProgressIndicator(color: primaryBlue, strokeWidth: 2.5),
            ),
          ),
          const SizedBox(height: 16),
          Text('جاري تحميل المحادثة...', style: GoogleFonts.cairo(fontSize: 14 * _fontScale, color: mediumGray)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.shade50,
            ),
            child: Icon(Icons.error_outline_rounded, size: 35, color: Colors.red.shade300),
          ),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: GoogleFonts.cairo(fontSize: 14 * _fontScale, color: mediumGray)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchChatHistory,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontSize: 14 * _fontScale)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          AnimatedBuilder(
            animation: _pulseAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseAnimationController.value * 0.08),
                child: child,
              );
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primaryBlue.withOpacity(0.08), secondaryBlue.withOpacity(0.04)],
                ),
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 50, color: primaryBlue),
            ),
          ),
          const SizedBox(height: 20),
          Text('المساعد الذكي للطاقة الشمسية',
              style: GoogleFonts.cairo(fontSize: 20 * _fontScale, fontWeight: FontWeight.bold, color: darkColor)),
          const SizedBox(height: 8),
          Text('اسألني عن أي شيء يتعلق بالطاقة الشمسية',
              style: GoogleFonts.cairo(fontSize: 14 * _fontScale, color: mediumGray)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue.withOpacity(0.04), secondaryBlue.withOpacity(0.02)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryBlue.withOpacity(0.1)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildExampleChip('بدي شغل مكيف 1 طن لمدة 6 ساعات'),
                _buildExampleChip('بدي شغل لابتوب 200 واط لمدة 5 ساعات'),
                _buildExampleChip('كم يحتاج منزل 3 غرف من الطاقة الشمسية؟'),
                _buildExampleChip('ما هو أفضل نوع بطارية للطاقة الشمسية؟'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleChip(String text) {
    return GestureDetector(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(text, style: GoogleFonts.cairo(fontSize: 12 * _fontScale, color: darkColor)),
      ),
    );
  }
}