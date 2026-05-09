import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:energy_store_app/services/api_service.dart';
import 'package:energy_store_app/services/auth_service.dart';
import 'package:energy_store_app/screens/chat/message_bubble.dart';
import 'package:energy_store_app/screens/offers/offer_details_screen.dart';
import 'package:energy_store_app/screens/products/product_details_screen.dart';

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

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _messages = [];
  List<String> _suggestedQuestions = [];

  bool _isLoading = true;
  bool _isSending = false;
  bool _hasMore = false;
  int _currentOffset = 0;
  final int _limit = 20;
  String? _errorMessage;

  String? _processingCalculationId;

  @override
  void initState() {
    super.initState();
    _fetchChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchChatHistory({bool loadMore = false}) async {
    if (loadMore && !_hasMore) return;

    setState(() {
      _isLoading = !loadMore;
      _errorMessage = null;
    });

    try {
      final response = await widget.apiService.get(
        '/v1/user/chat/history?limit=$_limit&offset=${loadMore ? _currentOffset : 0}',
        requiresAuth: true,
      );

      if (response['status'] == 'success' && mounted) {
        final data = response['data'];
        final List<dynamic> messages = data['messages'] ?? [];
        final pagination = data['pagination'];

        setState(() {
          if (loadMore) {
            final olderMessages = List<Map<String, dynamic>>.from(messages.reversed);
            _messages.insertAll(0, olderMessages);
          } else {
            _messages = List<Map<String, dynamic>>.from(messages.reversed);
          }

          _hasMore = pagination['has_more'] ?? false;
          _currentOffset = pagination['next_offset'] ?? _currentOffset + _limit;
          _isLoading = false;

          if (_messages.isNotEmpty) {
            final lastMessage = _messages.last;
            if (!lastMessage['me'] && lastMessage.containsKey('data')) {
              _suggestedQuestions = List<String>.from(
                  lastMessage['data']?['suggested_questions'] ?? []
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
          _errorMessage = response['message'] ?? 'حدث خطأ في تحميل المحادثة';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ في الاتصال';
      });
    }
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
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

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
      _suggestedQuestions = [];
    });

    _scrollToBottom();

    try {
      final response = await widget.apiService.post(
        '/v1/user/chat/send',
        requiresAuth: true,
        data: {'message': message},
      );

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
              response['data']['suggested_questions'] ?? []
          );
        });

        _scrollToBottom();
      }
      else if (response['status'] == 'processing' && mounted) {
        _processingCalculationId = response['calculation_id'];
        _showProcessingSnackBar();
        _pollCalculationResult();
      }
      else {
        setState(() {
          _isSending = false;
        });
        _showErrorSnackBar(response['message'] ?? 'حدث خطأ في إرسال الرسالة');
      }
    } catch (e) {
      setState(() {
        _isSending = false;
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
            _processingCalculationId = null;
            _suggestedQuestions = List<String>.from(
                response['data']['suggested_questions'] ?? []
            );
          });

          _scrollToBottom();
          return;
        }
        else if (response['status'] == 'error' && mounted) {
          setState(() {
            _isSending = false;
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
        _processingCalculationId = null;
      });
      _showErrorSnackBar('انتهت مهلة الانتظار، يرجى المحاولة مرة أخرى');
    }
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('مسح المحادثة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من مسح جميع رسائل المحادثة؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('مسح', style: GoogleFonts.cairo()),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  void _showProcessingSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري حساب احتياجاتك... سيتم عرض النتيجة قريباً'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade700]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المساعد الذكي', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('نظام الطاقة الشمسية', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (_messages.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clearChat),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                ? _buildErrorState()
                : _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessagesList(),
          ),
          if (_suggestedQuestions.isNotEmpty && !_isSending) _buildSuggestedQuestions(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      reverse: false,
      itemCount: _messages.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _hasMore) {
          return _buildLoadMoreIndicator();
        }

        final message = _messages[index];

        final bool isUser = message['me'];
        final String content = message['content'];
        final String timestamp = _formatTimestamp(message['timestamp'] ?? '');
        final dynamic data = message['data'];
        final String type = message['type'] ?? 'text';

        return MessageBubble(
          isUser: isUser,
          content: content,
          timestamp: timestamp,
          data: data,
          type: type,
          apiService: widget.apiService,
          authService: widget.authService,
          onProductTap: _navigateToProduct,
          onOfferTap: _navigateToOffer,
        );
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator(color: Colors.green.shade400, strokeWidth: 2)),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(25)),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  style: GoogleFonts.cairo(fontSize: 14),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'اكتب استفسارك عن الطاقة الشمسية...',
                    hintStyle: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade700]),
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSending ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: _isSending
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _suggestedQuestions.map((question) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(question, style: GoogleFonts.cairo(fontSize: 12), maxLines: 1),
                onSelected: (_) => _sendSuggestedQuestion(question),
                backgroundColor: Colors.grey.shade100,
                selectedColor: Colors.green.shade100,
                labelStyle: GoogleFonts.cairo(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade700]),
              shape: BoxShape.circle,
            ),
            child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          ),
          const SizedBox(height: 16),
          Text('جاري تحميل المحادثة...', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchChatHistory,
            icon: const Icon(Icons.refresh),
            label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade700]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text('المساعد الذكي للطاقة الشمسية', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Text('اسألني عن أي شيء يتعلق بالطاقة الشمسية\nوسأساعدك في اختيار النظام المناسب', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600, height: 1.5)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Row(children: [Icon(Icons.tips_and_updates, color: Colors.green.shade700), const SizedBox(width: 8), Text('أمثلة للأسئلة:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.green.shade700))]),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildExampleChip('بدي شغل مكيف 1 طن لمدة 6 ساعات'),
                      _buildExampleChip('بدي شغل لابتوب 200 واط لمدة 5 ساعات'),
                      _buildExampleChip('كم يحتاج منزل 3 غرف من الطاقة الشمسية؟'),
                      _buildExampleChip('ما هو أفضل نوع بطارية للطاقة الشمسية؟'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleChip(String text) {
    return ActionChip(
      label: Text(text, style: GoogleFonts.cairo(fontSize: 12)),
      onPressed: () {
        _messageController.text = text;
        _sendMessage();
      },
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.green.shade200),
      labelStyle: GoogleFonts.cairo(),
    );
  }
}