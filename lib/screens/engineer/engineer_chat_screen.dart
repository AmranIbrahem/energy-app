// lib/screens/engineer/engineer_chat_screen.dart

import 'dart:io';

import 'package:GeniusHouse/screens/chat/message_bubble.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/permission_service.dart';
import 'package:GeniusHouse/services/pusher_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class EngineerChatScreen extends StatefulWidget {
  final ApiService apiService;
  final AuthService? authService;
  final String domainKey;
  final String domainLabel;
  final Color domainColor;

  const EngineerChatScreen({
    super.key,
    required this.apiService,
    this.authService,
    required this.domainKey,
    required this.domainLabel,
    required this.domainColor,
  });

  @override
  State<EngineerChatScreen> createState() => _EngineerChatScreenState();
}

class _EngineerChatScreenState extends State<EngineerChatScreen>
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
  late Animation<double> _typingAnimation1;
  late Animation<double> _typingAnimation2;
  late Animation<double> _typingAnimation3;

  bool get _isLoggedIn =>
      widget.authService != null && widget.authService!.isAuthenticated;

  IconData get _domainIcon {
    switch (widget.domainKey) {
      case 'solar':
        return Icons.solar_power_rounded;
      case 'lighting':
        return Icons.lightbulb_rounded;
      default:
        return Icons.electrical_services_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSession();
    });
  }

  void _initAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

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
    super.dispose();
  }

  Future<void> _initSession() async {
    _governorate = 'دمشق';
    setState(() => _isLoading = false);
    _scrollToBottom();
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
          '${tempDir.path}/engineer_voice_${DateTime.now().millisecondsSinceEpoch}.wav';

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

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((x) => File(x.path)).toList();
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

  Future<Map<String, dynamic>> _sendTextMessage(String message) async {
    final requiresAuth = _isLoggedIn;

    switch (widget.domainKey) {
      case 'solar':
        return widget.apiService.sendSupportMessage(
          message: message,
          requiresAuth: requiresAuth,
          sessionId: _sessionId,
          governorate: _governorate,
        );
      case 'lighting':
        return widget.apiService.sendLightingSupportMessage(
          message: message,
          requiresAuth: requiresAuth,
          sessionId: _sessionId,
          governorate: _governorate,
        );
      case 'electricity':
      default:
        return widget.apiService.sendApplianceSupportMessage(
          message: message,
          requiresAuth: requiresAuth,
          sessionId: _sessionId,
          governorate: _governorate,
        );
    }
  }

  Future<Map<String, dynamic>> _sendImage(File image, String message) async {
    final requiresAuth = _isLoggedIn;

    switch (widget.domainKey) {
      case 'solar':
        return widget.apiService.sendSupportMessageWithImage(
          message: message,
          images: [image],
          requiresAuth: requiresAuth,
          sessionId: _sessionId,
          governorate: _governorate,
        );
      case 'lighting':
        return widget.apiService.sendLightingSupportImage(
          message: message,
          imageFile: image,
          requiresAuth: requiresAuth,
          sessionId: _sessionId,
          governorate: _governorate,
        );
      case 'electricity':
      default:
        return widget.apiService.sendApplianceSupportImage(
          message: message,
          imageFile: image,
          requiresAuth: requiresAuth,
          sessionId: _sessionId,
          governorate: _governorate,
        );
    }
  }

  Future<Map<String, dynamic>> _sendVoice(File audio) async {
    final requiresAuth = _isLoggedIn;

    switch (widget.domainKey) {
      case 'solar':
        return widget.apiService.sendSupportVoiceMessage(
          audioFile: audio,
          requiresAuth: requiresAuth,
          sessionId: _sessionId,
          governorate: _governorate,
        );
      case 'lighting':
        return widget.apiService.sendLightingSupportVoice(
          audioFile: audio,
          requiresAuth: requiresAuth,
          sessionId: _sessionId,
          governorate: _governorate,
        );
      case 'electricity':
      default:
        return widget.apiService.sendApplianceSupportVoice(
          audioFile: audio,
          requiresAuth: requiresAuth,
          sessionId: _sessionId,
          governorate: _governorate,
        );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    final hasImages = _selectedImages.isNotEmpty;

    if (message.isEmpty && !hasImages) return;
    if (_isSending) return;

    final imagesCopy = List<File>.from(_selectedImages);

    setState(() {
      _messages.add({
        'me': true,
        'role': 'user',
        'content': message.isEmpty ? '📷 صورة' : message,
        'timestamp': DateTime.now().toIso8601String(),
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
        response = await _sendImage(imagesCopy.first, message);
      } else {
        response = await _sendTextMessage(message);
      }

      setState(() => _isAiTyping = false);

      if (response['status'] == 'success' && mounted) {
        setState(() {
          _messages.add({
            'me': false,
            'role': 'support',
            'content': response['data']?['message']?.toString() ?? '',
            'timestamp': DateTime.now().toIso8601String(),
            'type': 'text',
            'data': {},
          });
          _isSending = false;
        });
        _scrollToBottom();
      } else {
        setState(() => _isSending = false);
        _showErrorSnackBar(response['message'] ?? 'حدث خطأ');
      }
    } catch (e) {
      setState(() {
        _isSending = false;
        _isAiTyping = false;
      });
      _showErrorSnackBar('خطأ في الاتصال');
    }
  }

  Future<void> _sendVoiceMessage() async {
    if (_recordedAudioFile == null || _isSending) return;

    setState(() {
      _isSending = true;
      _isAiTyping = true;
    });

    try {
      final response = await _sendVoice(_recordedAudioFile!);

      if (response['status'] == 'success' && mounted) {
        setState(() {
          _isAiTyping = false;
          _isSending = false;
          _messages.add({
            'me': true,
            'role': 'user',
            'content': '🎤 رسالة صوتية',
            'timestamp': DateTime.now().toIso8601String(),
            'type': 'voice',
            'audio_url': response['data']?['audio_url']?.toString(),
            'data': {},
          });
          _messages.add({
            'me': false,
            'role': 'support',
            'content': response['data']?['message']?.toString() ?? '',
            'timestamp': DateTime.now().toIso8601String(),
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

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dateTime);
      if (diff.inDays > 0) {
        return DateFormat('MMM dd, hh:mm a').format(dateTime);
      } else if (diff.inHours > 0) {
        return 'منذ ${diff.inHours} ساعة';
      } else if (diff.inMinutes > 0) {
        return 'منذ ${diff.inMinutes} دقيقة';
      }
      return 'الآن';
    } catch (e) {
      return '';
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));
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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_domainIcon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مهندس نيكس',
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text('استشارة ${widget.domainLabel}',
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: Colors.white.withOpacity(0.85))),
              ],
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _messages.isEmpty ? _buildEmptyState() : _buildMessagesList(),
          ),
          _buildInputBar(),
        ],
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
        if (index < 0 || index >= _messages.length) {
          return const SizedBox.shrink();
        }

        final message = _messages[index];
        final content = message['content']?.toString() ?? '';

        List<String> imageList = [];
        if (message['images'] != null && message['images'] is List) {
          imageList = List<String>.from(message['images']);
        } else if (message['image_url'] != null) {
          imageList = [message['image_url'].toString()];
        }

        final audioUrl = message['audio_url'];

        return MessageBubble(
          isUser: message['me'] ?? false,
          content: content,
          timestamp: _formatTimestamp(message['timestamp']?.toString() ?? ''),
          data: {},
          type: message['type']?.toString() ?? 'text',
          images: imageList,
          audioUrl: audioUrl is String ? audioUrl : null,
          fontScale: 1.0,
          apiService: widget.apiService,
          authService: widget.authService,
          onCopyTap: () => Clipboard.setData(ClipboardData(text: content)),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                primaryBlue.withOpacity(0.12),
                secondaryBlue.withOpacity(0.06),
              ]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_domainIcon, color: primaryBlue, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(_typingAnimation1),
                const SizedBox(width: 5),
                _dot(_typingAnimation2),
                const SizedBox(width: 5),
                _dot(_typingAnimation3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Transform.scale(
        scale: animation.value,
        child: Container(
          width: 7,
          height: 7,
          decoration:
              const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Column(
      children: [
        if (_showImageGrid && _selectedImages.isNotEmpty) _buildImageGrid(),
        if (_isRecording) _buildRecordingIndicator(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cardWhite,
            boxShadow: [
              BoxShadow(color: primaryBlue.withOpacity(0.06), blurRadius: 10),
            ],
          ),
          child: SafeArea(
            child: _isRecording
                ? _stopRecordButton()
                : Row(
                    children: [
                      GestureDetector(
                        onLongPressStart: (_) async {
                          final hasPermission =
                              await _requestMicrophonePermission();
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _isRecording
                                ? Colors.red.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isRecording
                                ? Icons.mic_rounded
                                : Icons.mic_none_rounded,
                            color: _isRecording
                                ? Colors.red
                                : Colors.grey.shade600,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _toggleImagePicker,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _selectedImages.isNotEmpty
                                ? primaryBlue.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _selectedImages.isNotEmpty
                                ? Icons.close_rounded
                                : Icons.photo_library_rounded,
                            color: _selectedImages.isNotEmpty
                                ? primaryBlue
                                : Colors.grey.shade600,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
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
                            style: GoogleFonts.cairo(
                                fontSize: 14, color: darkColor),
                            maxLines: 3,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: 'اكتب رسالتك للمهندس...',
                              hintStyle: GoogleFonts.cairo(
                                  fontSize: 14, color: Colors.grey.shade400),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [primaryBlue, secondaryBlue]),
                          shape: BoxShape.circle,
                        ),
                        child: InkWell(
                          onTap: _isSending ? null : _sendMessage,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 44,
                            height: 44,
                            child: _isSending
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _stopRecordButton() {
    return Row(
      children: [
        GestureDetector(
          onTap: _stopRecording,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stop_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('إيقاف التسجيل',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red.withOpacity(0.05),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('جاري التسجيل...',
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          final image = _selectedImages[index];
          return Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                      image: FileImage(image), fit: BoxFit.cover),
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
                        color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          );
        },
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
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [
                primaryBlue.withOpacity(0.08),
                secondaryBlue.withOpacity(0.04),
              ]),
            ),
            child: Icon(_domainIcon, size: 50, color: primaryBlue),
          ),
          const SizedBox(height: 20),
          Text(
            'مرحباً بك',
            style: GoogleFonts.cairo(
                fontSize: 22, fontWeight: FontWeight.bold, color: darkColor),
          ),
          const SizedBox(height: 8),
          Text(
            'أنا مهندس نيكس المختص في ${widget.domainLabel}.\nكيف أقدر أساعدك؟',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.cairo(fontSize: 14, color: mediumGray, height: 1.7),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: secondaryBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_rounded,
                    color: secondaryBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'يمكنك إرسال نص أو صورة أو رسالة صوتية',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
