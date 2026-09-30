// lib/screens/chat/guest_lighting_support_chat_screen.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:GeniusHouse/screens/chat/governorate_picker.dart';
import 'package:GeniusHouse/screens/chat/message_bubble.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/permission_service.dart';
import 'package:GeniusHouse/services/pusher_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class GuestLightingSupportChatScreen extends StatefulWidget {
  final ApiService apiService;
  final StorageService storageService;
  final String? initialGovernorate;

  const GuestLightingSupportChatScreen({
    super.key,
    required this.apiService,
    required this.storageService,
    this.initialGovernorate,
  });

  @override
  State<GuestLightingSupportChatScreen> createState() =>
      _GuestLightingSupportChatScreenState();
}

class _GuestLightingSupportChatScreenState
    extends State<GuestLightingSupportChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  File? _recordedAudioFile;
  bool _isRecording = false;

  List<Map<String, dynamic>> _messages = [];
  List<File> _selectedImages = [];
  bool _showImageGrid = false;

  String? _sessionId;
  String? _governorate;

  bool _isLoading = true;
  bool _isSending = false;
  bool _isAiTyping = false;
  String? _errorMessage;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  final PusherService _pusherService = PusherService();
  int? _conversationId;

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
      _initGuestSession();
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
          curve: const Interval(0.0, 0.33, curve: Curves.easeInOut)),
    );
    _typingAnimation2 = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
          parent: _typingAnimationController,
          curve: const Interval(0.33, 0.66, curve: Curves.easeInOut)),
    );
    _typingAnimation3 = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
          parent: _typingAnimationController,
          curve: const Interval(0.66, 1.0, curve: Curves.easeInOut)),
    );
  }

  @override
  void dispose() {
    _pusherService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  Future<bool> _requestMicrophonePermission() async {
    return await PermissionService.requestMicrophone();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        _showPermissionDeniedDialog();
        return;
      }

      await _audioRecorder.openRecorder();
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/lighting_support_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder.startRecorder(
        toFile: filePath,
        codec: Codec.pcm16WAV,
        numChannels: 1,
        sampleRate: 44100,
      );

      setState(() => _isRecording = true);
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showErrorSnackBar('فشل بدء التسجيل');
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: Colors.orange.shade50, shape: BoxShape.circle),
              child: Icon(Icons.mic_off_rounded,
                  color: Colors.orange.shade700, size: 30),
            ),
            const SizedBox(height: 12),
            Text('صلاحية الميكروفون مطلوبة',
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkColor),
                textAlign: TextAlign.center),
          ],
        ),
        content: Text(
            'يحتاج التطبيق إلى الوصول إلى الميكروفون لإرسال الرسائل الصوتية.',
            style: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
            textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء',
                style: GoogleFonts.cairo(
                    color: mediumGray, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await PermissionService.openAppSettings();
            },
            icon: const Icon(Icons.settings_rounded, size: 18),
            label: Text('فتح الإعدادات',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stopRecorder();
      await _audioRecorder.closeRecorder();

      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          setState(() {
            _recordedAudioFile = file;
            _isRecording = false;
          });
          _sendVoiceMessage();
        }
      }
    } catch (e) {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _sendVoiceMessage() async {
    if (_recordedAudioFile == null || _isSending || _sessionId == null) return;

    setState(() {
      _isSending = true;
      _isAiTyping = true;
    });

    try {
      final response = await widget.apiService.sendLightingSupportVoice(
        audioFile: _recordedAudioFile!,
        requiresAuth: false,
        sessionId: _sessionId,
        governorate: _governorate,
      );

      if (response['status'] == 'success' && mounted) {
        setState(() {
          _isAiTyping = false;
          _isSending = false;
          _messages.add({
            'me': true,
            'role': 'user',
            'content': '🎤 رسالة صوتية',
            'type': 'voice',
            'audio_url': response['data']['audio_url']?.toString(),
            'data': {},
          });
          _messages.add({
            'me': false,
            'role': 'support',
            'content': response['data']['message']?.toString() ?? '',
            'type': 'text',
            'data': {},
          });
        });
        _recordedAudioFile = null;
        _scrollToBottom();
      } else {
        setState(() {
          _isSending = false;
          _isAiTyping = false;
        });
      }
    } catch (e) {
      setState(() {
        _isSending = false;
        _isAiTyping = false;
      });
    }
  }

  Future<void> _initGuestSession() async {
    String? savedGovernorate = widget.initialGovernorate;
    if (savedGovernorate == null || savedGovernorate.isEmpty) {
      savedGovernorate = widget.storageService.getGuestGovernorate();
    }
    _governorate = (savedGovernorate != null && savedGovernorate.isNotEmpty)
        ? savedGovernorate
        : 'دمشق';

    final savedSessionId =
        widget.storageService.getGuestLightingSupportSessionId();
    if (savedSessionId != null) {
      _sessionId = savedSessionId;
      await _fetchChatHistory();
    } else {
      await _createNewSession();
    }
  }

  Future<void> _createNewSession() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await widget.apiService.startGuestLightingSupportSession();
      if (response['status'] == 'success' && mounted) {
        _sessionId = response['data']['session_id']?.toString();
        await widget.storageService
            .saveGuestLightingSupportSessionId(_sessionId!);
        await _fetchChatHistory();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل في بدء الجلسة';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ في الاتصال';
      });
    }
  }

  Future<void> _fetchChatHistory() async {
    if (_sessionId == null) return;
    setState(() => _isLoading = true);

    try {
      final response = await widget.apiService.getLightingSupportHistory(
        requiresAuth: false,
        sessionId: _sessionId,
      );

      if (response['status'] == 'success' && mounted) {
        final data = response['data'];
        final rawMessages = data['messages'];
        _conversationId = data['conversation_id'];

        if (rawMessages is! List) {
          setState(() {
            _messages = [];
            _isLoading = false;
          });
          return;
        }

        final processedMessages = rawMessages.reversed
            .where((msg) => msg is Map)
            .map<Map<String, dynamic>>((msg) {
          final map = Map<String, dynamic>.from(msg as Map);
          map['content'] = map['content']?.toString() ?? '';
          return map;
        }).toList();

        setState(() {
          _messages = processedMessages;
          _isLoading = false;
        });

        if (_messages.isNotEmpty) _scrollToBottom();
        if (_conversationId != null) _initPusher(_conversationId!);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initPusher(int conversationId) async {
    await _pusherService.init();
    await _pusherService.subscribeToConversation(conversationId, (message) {
      if (mounted) {
        setState(() {
          _messages.add({
            'me': message['role'] == 'user',
            'role': message['role'] ?? 'support',
            'content': message['content']?.toString() ?? '',
            'type': 'text',
            'data': {},
          });
        });
        _scrollToBottom();
      }
    });
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

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((xFile) => File(xFile.path)).toList();
        _showImageGrid = true;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (_selectedImages.isEmpty) _showImageGrid = false;
    });
  }

  void _toggleImagePicker() {
    if (_selectedImages.isNotEmpty) {
      setState(() {
        _selectedImages.clear();
        _showImageGrid = false;
      });
    } else {
      _pickImages();
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    final hasImages = _selectedImages.isNotEmpty;

    if (message.isEmpty && !hasImages) return;
    if (_isSending || _sessionId == null) return;

    final List<File> imagesCopy = List<File>.from(_selectedImages);

    setState(() {
      _messages.add({
        'me': true,
        'role': 'user',
        'content': message.isEmpty ? '📷 صورة' : message,
        'type': hasImages ? 'image_text' : 'text',
        'images': _selectedImages.map((f) => f.path).toList(),
        'data': {},
      });
      _messageController.clear();
      _isSending = true;
      _isAiTyping = true;
      _selectedImages.clear();
      _showImageGrid = false;
    });

    _scrollToBottom();
    _focusNode.unfocus();

    try {
      Map<String, dynamic> response;

      if (hasImages) {
        response = await widget.apiService.sendLightingSupportImage(
          message: message,
          imageFile: imagesCopy.first,
          requiresAuth: false,
          sessionId: _sessionId,
          governorate: _governorate,
        );
      } else {
        response = await widget.apiService.sendLightingSupportMessage(
          message: message,
          requiresAuth: false,
          sessionId: _sessionId,
          governorate: _governorate,
        );
      }

      setState(() => _isAiTyping = false);

      if (response['status'] == 'success' && mounted) {
        setState(() {
          _messages.add({
            'me': false,
            'role': 'support',
            'content': response['data']['message']?.toString() ?? '',
            'type': 'text',
            'data': {},
          });
          _isSending = false;
        });
        _scrollToBottom();
      } else {
        setState(() => _isSending = false);
      }
    } catch (e) {
      setState(() {
        _isSending = false;
        _isAiTyping = false;
      });
    }
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.delete_rounded,
                  color: Colors.red.shade700, size: 24)),
          const SizedBox(width: 12),
          Text('مسح المحادثة',
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold, color: darkColor)),
        ]),
        content: Text('هل أنت متأكد من مسح جميع رسائل المحادثة؟',
            style: GoogleFonts.cairo(fontSize: 15, color: mediumGray)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600, color: mediumGray))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: Text('مسح',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true && _sessionId != null) {
      try {
        final response =
            await widget.apiService.clearLightingSupportConversation(
          requiresAuth: false,
          sessionId: _sessionId,
        );
        if (response['status'] == 'success' && mounted) {
          setState(() {
            _messages = [];
            _conversationId = null;
            _selectedImages.clear();
            _showImageGrid = false;
          });
        }
      } catch (e) {}
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      if (difference.inDays > 0)
        return DateFormat('MMM dd, hh:mm a').format(dateTime);
      if (difference.inHours > 0) return 'منذ ${difference.inHours} ساعة';
      if (difference.inMinutes > 0) return 'منذ ${difference.inMinutes} دقيقة';
      return 'الآن';
    } catch (e) {
      return '';
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.cairo()),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _buildCurvedHeader(BuildContext context) {
    return ClipPath(
      clipper: _BottomCurveClipper(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryBlue, secondaryBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.lightbulb_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'دعم الإنارة والديكور',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'وضع الزوار • ${_governorate ?? "دمشق"}',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.85),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_messages.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.white, size: 22),
                      onPressed: _clearChat,
                    ),
                  ),
                if (_governorate != null)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.location_on_outlined,
                          color: Colors.white, size: 22),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20))),
                          builder: (context) => GovernoratePicker(
                            selectedGovernorate: _governorate,
                            onSelected: (gov) {
                              Navigator.pop(context);
                              setState(() => _governorate = gov);
                              widget.storageService.saveGuestGovernorate(gov);
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Column(
          children: [
            _buildCurvedHeader(context),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryBlue))
                  : Column(
                      children: [
                        Expanded(
                          child: _messages.isEmpty
                              ? _buildEmptyState()
                              : _buildMessagesList(),
                        ),
                        _buildInputBar(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length + (_isAiTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isAiTyping && index >= _messages.length) {
          return _buildTypingIndicator();
        }
        if (index < 0 || index >= _messages.length)
          return const SizedBox.shrink();

        final message = _messages[index];
        final content = message['content']?.toString() ?? '';

        List<String> imageList = [];
        if (message['images'] != null && message['images'] is List) {
          imageList = List<String>.from(message['images']);
        } else if (message['image_url'] != null) {
          imageList = [message['image_url'].toString()];
        }

        return MessageBubble(
          isUser: message['me'] ?? false,
          content: content,
          timestamp: _formatTimestamp(message['timestamp']?.toString() ?? ''),
          data: {},
          type: message['type']?.toString() ?? 'text',
          images: imageList,
          audioUrl:
              message['audio_url'] is String ? message['audio_url'] : null,
          fontScale: 1.0,
          apiService: widget.apiService,
          authService: null,
          onCopyTap: () => _copyToClipboard(content),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  primaryBlue.withOpacity(0.12),
                  secondaryBlue.withOpacity(0.06)
                ]),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.lightbulb_rounded,
                color: primaryBlue, size: 18)),
        const SizedBox(width: 8),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: cardWhite, borderRadius: BorderRadius.circular(18)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _buildDot(_typingAnimation1),
              const SizedBox(width: 5),
              _buildDot(_typingAnimation2),
              const SizedBox(width: 5),
              _buildDot(_typingAnimation3),
            ])),
      ]),
    );
  }

  Widget _buildDot(Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform.scale(
          scale: animation.value,
          child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                  color: primaryBlue, shape: BoxShape.circle))),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showImageGrid && _selectedImages.isNotEmpty) _buildImageGrid(),
          if (_isRecording) _buildRecordingIndicator(),
          SafeArea(
            top: false,
            bottom: true,
            minimum: const EdgeInsets.only(bottom: 0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
              child:
                  _isRecording ? _buildStopRecordingButton() : _buildInputRow(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GestureDetector(
          onLongPressStart: (_) async {
            final hasPermission = await _requestMicrophonePermission();
            if (hasPermission) {
              await _startRecording();
            } else {
              _showPermissionDeniedDialog();
            }
          },
          onLongPressEnd: (_) async {
            if (_isRecording) await _stopRecording();
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _isRecording
                  ? Colors.red.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(
              _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _isRecording ? Colors.red : Colors.grey.shade600,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 2),
        GestureDetector(
          onTap: _toggleImagePicker,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _selectedImages.isNotEmpty
                  ? primaryBlue.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(
              _selectedImages.isNotEmpty
                  ? Icons.close_rounded
                  : Icons.photo_library_rounded,
              color: _selectedImages.isNotEmpty
                  ? primaryBlue
                  : Colors.grey.shade600,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 38, maxHeight: 100),
            decoration: BoxDecoration(
              color: lightGray,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك...',
                hintStyle: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: _isSending ? null : _sendMessage,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue, secondaryBlue],
              ),
              shape: BoxShape.circle,
            ),
            child: _isSending
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStopRecordingButton() {
    return GestureDetector(
      onTap: _stopRecording,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stop_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'إيقاف التسجيل وإرسال',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: Colors.red.withOpacity(0.05),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _pulseAnimationController.drive(
              Tween<double>(begin: 0.4, end: 1.0).chain(
                CurveTween(curve: Curves.easeInOut),
              ),
            ),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'جاري التسجيل...',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          final image = _selectedImages[index];
          return Stack(children: [
            Container(
              width: 90,
              height: 90,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(image),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: Colors.grey.shade200),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(height: 40),
        Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  primaryBlue.withOpacity(0.08),
                  secondaryBlue.withOpacity(0.04)
                ])),
            child: const Icon(Icons.lightbulb_rounded,
                size: 50, color: primaryBlue)),
        const SizedBox(height: 20),
        Text('دعم الإنارة والديكور',
            style: GoogleFonts.cairo(
                fontSize: 20, fontWeight: FontWeight.bold, color: darkColor)),
        const SizedBox(height: 8),
        Text('تواصل مع فريقنا المتخصص لحل مشكلتك',
            style: GoogleFonts.cairo(fontSize: 14, color: mediumGray)),
        const SizedBox(height: 8),
        Text('⏰ ساعات العمل: الاحد - الخميس (10 صباحاً - 4 مساءً)',
            style: GoogleFonts.cairo(fontSize: 12, color: mediumGray)),
      ]),
    );
  }
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(0, size.height, 30, size.height);
    path.lineTo(size.width - 30, size.height);
    path.quadraticBezierTo(
        size.width, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
