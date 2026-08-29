// lib/screens/appliances/maintenance_message_bubble.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';

class MaintenanceMessageBubble extends StatelessWidget {
  final bool isUser;
  final String content;
  final String type;
  final dynamic data;
  final List<String> images;
  final String? audioUrl;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);

  const MaintenanceMessageBubble({
    super.key,
    required this.isUser,
    required this.content,
    this.type = 'text',
    this.data,
    this.images = const [],
    this.audioUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasImages = images.isNotEmpty;
    final hasAudio = audioUrl != null && audioUrl!.isNotEmpty;
    final isDiagnosis = type == 'maintenance_diagnosis';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) _buildAvatar(),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? LinearGradient(
                    colors: [primaryBlue, secondaryBlue],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  )
                      : null,
                  color: isUser ? null : cardWhite,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                    bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                  ),
                  boxShadow: isUser
                      ? [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                      : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: isUser ? null : Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ عرض الصور
                    if (hasImages) _buildImages(),

                    // ✅ عرض الصوت
                    if (hasAudio) _buildAudioPlayer(),

                    if ((hasImages || hasAudio) && content.isNotEmpty)
                      const SizedBox(height: 8),

                    // ✅ إذا تشخيص → عرض بطاقة منسقة
                    if (isDiagnosis && data != null)
                      _buildDiagnosisCard()
                    else if (content.isNotEmpty)
                      _buildFormattedContent(context, content),
                  ],
                ),
              ),
            ),
            if (isUser) const SizedBox(width: 8),
            if (isUser) _buildAvatar(isUser: true),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({bool isUser = false}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isUser ? null : LinearGradient(
          colors: [primaryBlue, secondaryBlue],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        shape: BoxShape.circle,
        color: isUser ? Colors.grey.shade200 : null,
        boxShadow: [
          BoxShadow(
            color: isUser ? Colors.grey.withOpacity(0.2) : primaryBlue.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.build_circle_rounded,
        size: 18,
        color: isUser ? Colors.grey.shade600 : Colors.white,
      ),
    );
  }

  Widget _buildImages() {
    if (images.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: images.map((path) {
        Widget imageWidget;
        if (path.startsWith('http') || path.startsWith('https')) {
          imageWidget = CachedNetworkImage(
            imageUrl: path,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Container(
              width: 120,
              height: 120,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
        } else {
          imageWidget = Image.file(
            File(path),
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 120,
              height: 120,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageWidget,
        );
      }).toList(),
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUser ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AudioPlayerButton(url: audioUrl!, isUser: isUser),
          const SizedBox(width: 8),
          Icon(
            Icons.graphic_eq,
            color: isUser ? Colors.white : primaryBlue,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedContent(BuildContext context, String text) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MarkdownBody(
        data: text,
        selectable: true,
        softLineBreak: true,
        styleSheet: MarkdownStyleSheet(
          p: GoogleFonts.cairo(
            fontSize: 14,
            color: isUser ? Colors.white : darkColor,
            height: 1.8,
          ),
          strong: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: isUser ? Colors.white : primaryBlue,
          ),
          listBullet: GoogleFonts.cairo(
            color: isUser ? Colors.white : darkColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ✅ بطاقة التشخيص المنظمة
  Widget _buildDiagnosisCard() {
    final diagnosis = data?['diagnosis']?.toString() ?? '';
    final possibleCauses = (data?['possible_causes'] as List?) ?? [];
    final recommendations = (data?['recommendations'] as List?) ?? [];
    final severity = data?['severity']?.toString() ?? 'غير محدد';
    final needsTechnician = data?['needs_technician'] ?? false;

    // ✅ لون الخطورة
    Color severityColor;
    IconData severityIcon;
    switch (severity) {
      case 'بسيط':
        severityColor = Colors.green;
        severityIcon = Icons.check_circle_rounded;
        break;
      case 'متوسط':
        severityColor = Colors.orange;
        severityIcon = Icons.warning_rounded;
        break;
      case 'خطير':
        severityColor = Colors.red;
        severityIcon = Icons.error_rounded;
        break;
      default:
        severityColor = Colors.grey;
        severityIcon = Icons.info_rounded;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryBlue.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ العنوان
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.build_rounded, size: 16, color: primaryBlue),
                ),
                const SizedBox(width: 8),
                Text(
                  '🔧 التشخيص',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
            const Divider(thickness: 1, height: 16),

            // ✅ وصف المشكلة
            Text(
              diagnosis,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: darkColor,
                height: 1.6,
              ),
            ),

            // ✅ مستوى الخطورة
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(severityIcon, size: 14, color: severityColor),
                  const SizedBox(width: 4),
                  Text(
                    'الخطورة: $severity',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ],
              ),
            ),

            // ✅ الأسباب المحتملة (كائنات {cause, details})
            if (possibleCauses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'الأسباب المحتملة:',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),
              const SizedBox(height: 6),
              ...possibleCauses.map((cause) {
                if (cause is Map) {
                  final causeName = cause['cause']?.toString() ?? '';
                  final details = (cause['details'] as List?) ?? [];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.arrow_circle_right_rounded, size: 14, color: Colors.orange.shade700),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                causeName,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: darkColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (details.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          ...details.map((detail) => Padding(
                            padding: const EdgeInsets.only(right: 20, bottom: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.circle, size: 5, color: Colors.orange.shade400),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    detail.toString(),
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: mediumGray,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ],
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.arrow_circle_right_rounded, size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            cause.toString(),
                            style: GoogleFonts.cairo(fontSize: 12, color: mediumGray, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }),
            ],

            // ✅ التوصيات
            if (recommendations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'التوصيات:',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),
              const SizedBox(height: 4),
              ...recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: successGreen),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        rec.toString(),
                        style: GoogleFonts.cairo(fontSize: 12, color: mediumGray, height: 1.5),
                      ),
                    ),
                  ],
                ),
              )),
            ],

            // ✅ هل يحتاج فني
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: needsTechnician ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: needsTechnician ? Colors.red.shade200 : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    needsTechnician ? Icons.support_agent_rounded : Icons.thumb_up_rounded,
                    size: 16,
                    color: needsTechnician ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    needsTechnician ? 'يُنصح بطلب فني متخصص' : 'يمكن إصلاحه بنفسك',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: needsTechnician ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ مشغل الصوت
class _AudioPlayerButton extends StatefulWidget {
  final String url;
  final bool isUser;

  const _AudioPlayerButton({
    required this.url,
    required this.isUser,
  });

  @override
  State<_AudioPlayerButton> createState() => _AudioPlayerButtonState();
}

class _AudioPlayerButtonState extends State<_AudioPlayerButton> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _player.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play(UrlSource(widget.url));
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isUser ? Colors.white : primaryBlue;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: _togglePlay,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: widget.isUser ? primaryBlue : Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}