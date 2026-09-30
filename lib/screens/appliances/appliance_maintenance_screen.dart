// lib/screens/appliances/appliance_maintenance_screen.dart

import 'dart:io';

import 'package:GeniusHouse/screens/appliances/maintenance_message_bubble.dart';
import 'package:GeniusHouse/screens/workshop/workshop_request_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../chat/appliance_support_chat_screen.dart';

class ApplianceMaintenanceScreen extends StatefulWidget {
  final AuthService authService;
  final ApiService apiService;

  const ApplianceMaintenanceScreen({
    super.key,
    required this.authService,
    required this.apiService,
  });

  @override
  State<ApplianceMaintenanceScreen> createState() =>
      _ApplianceMaintenanceScreenState();
}

class _ApplianceMaintenanceScreenState
    extends State<ApplianceMaintenanceScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  File? _recordedAudioFile;
  bool _isRecording = false;

  List<Map<String, dynamic>> _messages = [];
  List<File> _selectedImages = [];
  bool _showImageGrid = false;

  bool _isLoading = true;
  bool _isSending = false;
  bool _isAiTyping = false;
  String? _errorMessage;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _audioRecorder.closeRecorder();
    super.dispose();
  }

  Future<bool> _requestMicrophonePermission() async {
    return await PermissionService.requestMicrophone();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);

    try {
      final response = await widget.apiService.getMaintenanceHistory(
        requiresAuth: true,
      );

      if (response['status'] == 'success' && mounted) {
        final data = response['data'];
        final List<dynamic> messages = data['messages'] ?? [];

        setState(() {
          _messages = messages
              .map<Map<String, dynamic>>(
                  (msg) => Map<String, dynamic>.from(msg))
              .toList();
          _isLoading = false;
        });

        _scrollToBottom();
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
          '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';

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
      _showErrorSnackBar('فشل إيقاف التسجيل');
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
            'يحتاج التطبيق إلى الوصول إلى الميكروفون لإرسال الرسائل الصوتية.\n\nيمكنك تفعيل الصلاحية من إعدادات التطبيق.',
            style:
                GoogleFonts.cairo(fontSize: 14, color: mediumGray, height: 1.6),
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
      if (_selectedImages.isEmpty) {
        _showImageGrid = false;
      }
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

  Future<void> _sendVoiceMessage() async {
    if (_recordedAudioFile == null || _isSending) return;

    setState(() {
      _isSending = true;
      _isAiTyping = true;
    });

    try {
      final response = await widget.apiService.sendMaintenanceVoice(
        audioFile: _recordedAudioFile!,
        requiresAuth: true,
      );

      if (response['status'] == 'success' && mounted) {
        setState(() {
          _isAiTyping = false;
          _isSending = false;

          _messages.add({
            'me': true,
            'role': 'user',
            'content': response['data']['transcribed_text'] ?? '',
            'type': 'voice',
            'audio_url': response['data']['audio_url'],
          });

          _messages.add({
            'me': false,
            'role': 'assistant',
            'content': response['data']['message'],
            'type': 'maintenance_diagnosis',
            'data': response['data']['data'],
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
      _showErrorSnackBar('حدث خطأ في الاتصال');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    final hasImages = _selectedImages.isNotEmpty;

    if (message.isEmpty && !hasImages) return;
    if (_isSending) return;

    final List<File> imagesCopy = List<File>.from(_selectedImages);
    final List<String> imagePaths = _selectedImages.map((f) => f.path).toList();

    setState(() {
      _messages.add({
        'me': true,
        'role': 'user',
        'content': message.isEmpty ? '📷 صورة عطل' : message,
        'type': hasImages ? 'image' : 'text',
        'images': imagePaths,
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
        response = await widget.apiService.sendMaintenanceImage(
          imageFile: imagesCopy.first,
          message: message,
          requiresAuth: true,
        );
      } else {
        response = await widget.apiService.sendMaintenanceMessage(
          message: message,
          requiresAuth: true,
        );
      }

      setState(() => _isAiTyping = false);

      if (response['status'] == 'success' && mounted) {
        setState(() {
          _messages.add({
            'me': false,
            'role': 'assistant',
            'content': response['data']['message'],
            'type': 'maintenance_diagnosis',
            'data': response['data']['data'],
          });
          _isSending = false;
        });

        _scrollToBottom();
      } else {
        setState(() => _isSending = false);
        _showErrorSnackBar(response['message'] ?? 'حدث خطأ في التشخيص');
      }
    } catch (e) {
      setState(() {
        _isSending = false;
        _isAiTyping = false;
      });
      _showErrorSnackBar('حدث خطأ في الاتصال');
    }
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
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.delete_rounded,
                  color: Colors.red.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            Text('مسح المحادثة',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, color: darkColor)),
          ],
        ),
        content: Text('هل أنت متأكد من مسح جميع رسائل المحادثة؟',
            style: GoogleFonts.cairo(fontSize: 15, color: mediumGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600, color: mediumGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('مسح',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final response = await widget.apiService
            .clearMaintenanceConversation(requiresAuth: true);
        if (response['status'] == 'success' && mounted) {
          setState(() {
            _messages = [];
            _isLoading = false;
            _isAiTyping = false;
          });
          _showSuccessSnackBar('تم مسح المحادثة بنجاح');
        } else {
          setState(() => _isLoading = false);
          _showErrorSnackBar(response['message'] ?? 'حدث خطأ');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('حدث خطأ في الاتصال');
      }
    }
  }

  void _openWorkshopRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkshopRequestScreen(
          apiService: widget.apiService,
          authService: widget.authService,
        ),
      ),
    );
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
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
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
                  child: const Icon(Icons.build_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'الصيانة الذكية',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'صور العطل واحصل على تشخيص فوري',
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
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _buildCurvedHeader(context),
            Expanded(
              child: _isLoading
                  ? _buildLoadingScreen()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : Column(
                          children: [
                            Expanded(
                              child: _messages.isEmpty
                                  ? _buildEmptyState()
                                  : _buildMessagesList(),
                            ),
                            if (_messages.isNotEmpty) _buildActionButtons(),
                            _buildInputBar(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [primaryBlue, accentCyan],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'جاري تحميل المحادثة...',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى الانتظار قليلاً',
            style: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openSupportChat,
              icon: const Icon(Icons.support_agent_rounded, size: 18),
              label: Text(
                'محادثة الدعم',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: secondaryBlue.withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openWorkshopRequest,
              icon: const Icon(Icons.build_rounded, size: 18),
              label: Text(
                'طلب فني',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: primaryBlue.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSupportChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplianceSupportChatScreen(
          authService: widget.authService,
          apiService: widget.apiService,
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

        final message = _messages[index];

        List<String> imageList = [];
        if (message['images'] != null && message['images'] is List) {
          imageList = List<String>.from(message['images']);
        } else if (message['image_url'] != null &&
            message['image_url'] is String) {
          imageList = [message['image_url'] as String];
        }

        final audioUrl = message['audio_url'] ?? message['audio_path'];

        return MaintenanceMessageBubble(
          isUser: message['me'] ?? false,
          content: message['content'] ?? '',
          type: message['type'] ?? 'text',
          data: message['data'],
          images: imageList,
          audioUrl: audioUrl is String ? audioUrl : null,
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.15),
                  accentCyan.withOpacity(0.05)
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
                const Icon(Icons.build_rounded, color: primaryBlue, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: primaryBlue.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 5),
                _buildDot(1),
                const SizedBox(width: 5),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 7,
            height: 7,
            decoration:
                const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
          ),
        );
      },
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
              BoxShadow(
                color: primaryBlue.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: _isRecording
                ? _buildRecordingStopButton()
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
                          if (_isRecording) {
                            await _stopRecording();
                          }
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: _isRecording
                                ? LinearGradient(
                                    colors: [Colors.red, Colors.redAccent])
                                : null,
                            color: _isRecording ? null : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isRecording
                                ? [
                                    BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: 6)
                                  ]
                                : null,
                          ),
                          child: Icon(
                            _isRecording
                                ? Icons.mic_rounded
                                : Icons.mic_none_rounded,
                            color: _isRecording ? Colors.white : primaryBlue,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _toggleImagePicker,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: _selectedImages.isNotEmpty
                                ? LinearGradient(
                                    colors: [primaryBlue, secondaryBlue])
                                : null,
                            color: _selectedImages.isNotEmpty
                                ? null
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _selectedImages.isNotEmpty
                                ? Icons.close_rounded
                                : Icons.photo_camera_rounded,
                            color: _selectedImages.isNotEmpty
                                ? Colors.white
                                : primaryBlue,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: lightGray,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            style: GoogleFonts.cairo(
                                fontSize: 14, color: darkColor),
                            maxLines: 3,
                            minLines: 1,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              hintText: 'صف العطل أو أرفق صورة...',
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
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: _isSending ? null : () => _sendMessage(),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 44,
                            height: 44,
                            child: _isSending
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
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

  Widget _buildRecordingStopButton() {
    return Row(
      children: [
        GestureDetector(
          onTap: _stopRecording,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 8)
              ],
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
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle)),
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
              gradient: LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.1),
                  accentCyan.withOpacity(0.05)
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.build_circle_rounded,
                size: 50, color: primaryBlue),
          ),
          const SizedBox(height: 24),
          Text('الصيانة الذكية',
              style: GoogleFonts.cairo(
                  fontSize: 22, fontWeight: FontWeight.bold, color: darkColor)),
          const SizedBox(height: 8),
          Text('صور العطل واحصل على تشخيص فوري',
              style: GoogleFonts.cairo(fontSize: 14, color: mediumGray)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.04),
                  accentCyan.withOpacity(0.02)
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryBlue.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lightbulb_rounded,
                          color: primaryBlue, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text('أمثلة شائعة',
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: darkColor)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildExampleChip('البراد ما عم يبرد'),
                    _buildExampleChip('المكيف يشتغل ويفصل'),
                    _buildExampleChip('البطارية ما تشحن'),
                    _buildExampleChip('الإنفرتر يعطي صوت'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openSupportChat,
                  icon: const Icon(Icons.support_agent_rounded, size: 20),
                  label: Text(
                    'محادثة الدعم',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openWorkshopRequest,
                  icon: const Icon(Icons.build_rounded, size: 20),
                  label: Text(
                    'طلب فني',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(text,
            style: GoogleFonts.cairo(fontSize: 12, color: darkColor)),
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
                shape: BoxShape.circle, color: Colors.red.shade50),
            child: Icon(Icons.error_outline_rounded,
                size: 35, color: Colors.red.shade300),
          ),
          const SizedBox(height: 16),
          Text(_errorMessage!,
              style: GoogleFonts.cairo(fontSize: 14, color: mediumGray)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchHistory,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label:
                Text('إعادة المحاولة', style: GoogleFonts.cairo(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
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
