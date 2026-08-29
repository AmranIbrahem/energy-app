// lib/screens/chat/guest_solar_chat_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:GeniusHouse/services/permission_service.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/screens/chat/message_bubble.dart';
import 'package:GeniusHouse/screens/chat/governorate_picker.dart';

class GuestSolarChatScreen extends StatefulWidget {
  final ApiService apiService;
  final StorageService storageService;
  final String? initialGovernorate;

  const GuestSolarChatScreen({
    super.key,
    required this.apiService,
    required this.storageService,
    this.initialGovernorate,
  });

  @override
  State<GuestSolarChatScreen> createState() => _GuestSolarChatScreenState();
}

class _GuestSolarChatScreenState extends State<GuestSolarChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
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

  double _fontScale = 1.0;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
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
      CurvedAnimation(parent: _typingAnimationController, curve: const Interval(0.0, 0.33, curve: Curves.easeInOut)),
    );
    _typingAnimation2 = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _typingAnimationController, curve: const Interval(0.33, 0.66, curve: Curves.easeInOut)),
    );
    _typingAnimation3 = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _typingAnimationController, curve: const Interval(0.66, 1.0, curve: Curves.easeInOut)),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimationController.dispose();
    _pulseAnimationController.dispose();
    _audioPlayer.dispose();
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
      final filePath = '${tempDir.path}/solar_voice_${DateTime.now().millisecondsSinceEpoch}.wav';

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
              decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
              child: Icon(Icons.mic_off_rounded, color: Colors.orange.shade700, size: 30),
            ),
            const SizedBox(height: 12),
            Text('صلاحية الميكروفون مطلوبة', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor), textAlign: TextAlign.center),
          ],
        ),
        content: Text('يحتاج التطبيق إلى الوصول إلى الميكروفون لإرسال الرسائل الصوتية.', style: GoogleFonts.cairo(fontSize: 14, color: mediumGray), textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: mediumGray, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await PermissionService.openAppSettings();
            },
            icon: const Icon(Icons.settings_rounded, size: 18),
            label: Text('فتح الإعدادات', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        if (!await file.exists()) {
          setState(() => _isRecording = false);
          return;
        }

        setState(() {
          _recordedAudioFile = file;
          _isRecording = false;
        });

        _sendVoiceMessage();
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
      final response = await widget.apiService.sendSolarVoiceMessage(
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
            'content': response['data']['transcribed_text']?.toString() ?? '',
            'timestamp': DateTime.now().toIso8601String(),
            'type': 'voice',
            'audio_url': response['data']['audio_url']?.toString(),
            'data': {},
          });
          _messages.add({
            'me': false,
            'role': 'assistant',
            'content': response['data']['message']?.toString() ?? '',
            'timestamp': DateTime.now().toIso8601String(),
            'type': 'voice_response',
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
        _showErrorSnackBar(response['message'] ?? 'حدث خطأ');
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
    _governorate = (savedGovernorate != null && savedGovernorate.isNotEmpty) ? savedGovernorate : 'دمشق';

    final savedSessionId = widget.storageService.getGuestSolarSessionId();
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
      final response = await widget.apiService.startGuestSolarSession();
      if (response['status'] == 'success' && mounted) {
        _sessionId = response['data']['session_id']?.toString();
        await widget.storageService.saveGuestSolarSessionId(_sessionId!);
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
      final response = await widget.apiService.getSolarChatHistory(
        requiresAuth: false,
        sessionId: _sessionId,
        limit: 20,
        offset: 0,
      );

      if (response['status'] == 'success' && mounted) {
        final data = response['data'];
        final rawMessages = data['messages'];

        if (rawMessages is! List) {
          setState(() {
            _messages = [];
            _isLoading = false;
          });
          return;
        }

        final List<dynamic> messages = rawMessages;

        final processedMessages = messages.reversed
            .where((msg) => msg is Map)
            .map<Map<String, dynamic>>((msg) {
          final map = Map<String, dynamic>.from(msg as Map);

          // ✅ تحويل data من List إلى Map
          if (map['data'] is List || map['data'] == null || map['data'] is! Map) {
            map['data'] = {};
          }

          // ✅ ضمان content
          map['content'] = map['content']?.toString() ?? '';

          return map;
        })
            .toList();

        setState(() {
          _messages = processedMessages;
          _isLoading = false;
        });

        if (_messages.isNotEmpty) _scrollToBottom();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
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

    if (_governorate == null || _governorate!.isEmpty) {
      _governorate = 'دمشق';
    }

    final List<File> imagesCopy = List<File>.from(_selectedImages);

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
        response = await widget.apiService.sendSolarMessageWithImage(
          message: message,
          images: imagesCopy,
          requiresAuth: false,
          sessionId: _sessionId,
          governorate: _governorate,
        );
      } else {
        response = await widget.apiService.sendSolarMessage(
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
            'role': 'assistant',
            'content': response['data']['message']?.toString() ?? '',
            'timestamp': DateTime.now().toIso8601String(),
            'type': response['data']['type']?.toString() ?? 'text',
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
    }
  }

  Future<void> _clearChat() async {
    if (_sessionId == null) return;
    try {
      final response = await widget.apiService.clearSolarChat(
        requiresAuth: false,
        sessionId: _sessionId,
      );
      if (response['status'] == 'success' && mounted) {
        setState(() {
          _messages = [];
          _selectedImages.clear();
          _showImageGrid = false;
          _recordedAudioFile = null;
          _isRecording = false;
        });
        _showSuccessSnackBar('تم مسح المحادثة');
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ');
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ النص', style: GoogleFonts.cairo()),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      if (difference.inDays > 0) return DateFormat('MMM dd, hh:mm a').format(dateTime);
      if (difference.inHours > 0) return 'منذ ${difference.inHours} ساعة';
      if (difference.inMinutes > 0) return 'منذ ${difference.inMinutes} دقيقة';
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
        content: Row(children: [const Icon(Icons.error_rounded, color: Colors.white, size: 20), const SizedBox(width: 10), Expanded(child: Text(message, style: GoogleFonts.cairo()))]),
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
        content: Row(children: [const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20), const SizedBox(width: 10), Expanded(child: Text(message, style: GoogleFonts.cairo()))]),
        backgroundColor: primaryBlue,
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
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.solar_power_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المستشار الشمسي', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('وضع الزوار • ${_governorate ?? "دمشق"}', style: GoogleFonts.cairo(fontSize: 11, color: Colors.white.withOpacity(0.85))),
              ],
            ),
          ],
        ),
        elevation: 0,
        actions: [
          if (_governorate != null)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: const Icon(Icons.location_on_outlined, color: Colors.white, size: 22),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
          if (_messages.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                onPressed: _clearChat,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? _buildEmptyState() : _buildMessagesList(),
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

        dynamic messageData = message['data'];
        if (messageData is List || messageData == null || messageData is! Map) {
          messageData = {};
        }

        return MessageBubble(
          isUser: message['me'] ?? false,
          content: content,
          timestamp: _formatTimestamp(message['timestamp']?.toString() ?? ''),
          data: messageData,
          type: message['type']?.toString() ?? 'text',
          images: imageList,
          audioUrl: audioUrl is String ? audioUrl : null,
          fontScale: _fontScale,
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
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryBlue.withOpacity(0.12), secondaryBlue.withOpacity(0.06)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.solar_power_rounded, color: primaryBlue, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(18)),
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
      builder: (context, child) => Transform.scale(
        scale: animation.value,
        child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle)),
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
          decoration: BoxDecoration(color: cardWhite, boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.06), blurRadius: 10)]),
          child: SafeArea(
            child: _isRecording
                ? _buildRecordingStopButton()
                : Row(
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_isRecording ? Icons.mic_rounded : Icons.mic_none_rounded, color: _isRecording ? Colors.red : Colors.grey.shade600, size: 24),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _toggleImagePicker,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedImages.isNotEmpty ? primaryBlue.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_selectedImages.isNotEmpty ? Icons.close_rounded : Icons.photo_library_rounded, color: _selectedImages.isNotEmpty ? primaryBlue : Colors.grey.shade600, size: 24),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: lightGray, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey.shade200)),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: GoogleFonts.cairo(fontSize: 14 * _fontScale, color: darkColor),
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'اسأل عن الطاقة الشمسية...',
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
                    gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
                    shape: BoxShape.circle,
                  ),
                  child: InkWell(
                    onTap: _isSending ? null : _sendMessage,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 44,
                      height: 44,
                      child: _isSending
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

  Widget _buildRecordingStopButton() {
    return Row(
      children: [
        GestureDetector(
          onTap: _stopRecording,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(25)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stop_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('إيقاف التسجيل', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
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
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('جاري التسجيل...', style: GoogleFonts.cairo(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
          const Spacer(),
          AnimatedBuilder(
            animation: _pulseAnimationController,
            builder: (context, child) => Row(
              children: List.generate(5, (index) {
                final height = 10.0 + (_pulseAnimationController.value * 20) * (index % 2 == 0 ? 1 : 0.5);
                return Container(width: 3, height: height, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(2)));
              }),
            ),
          ),
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
                  image: DecorationImage(image: FileImage(image), fit: BoxFit.cover),
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
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          );
        },
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
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [primaryBlue.withOpacity(0.1), secondaryBlue.withOpacity(0.05)]),
            ),
            child: const CircularProgressIndicator(color: primaryBlue, strokeWidth: 2.5),
          ),
          const SizedBox(height: 16),
          Text('جاري التحميل...', style: GoogleFonts.cairo(fontSize: 14, color: mediumGray)),
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
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [primaryBlue.withOpacity(0.08), secondaryBlue.withOpacity(0.04)]),
            ),
            child: const Icon(Icons.solar_power_rounded, size: 50, color: primaryBlue),
          ),
          const SizedBox(height: 20),
          Text('المستشار الشمسي', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: darkColor)),
          const SizedBox(height: 8),
          Text('اسألني عن أي شيء يتعلق بالطاقة الشمسية', style: GoogleFonts.cairo(fontSize: 14, color: mediumGray)),
        ],
      ),
    );
  }
}