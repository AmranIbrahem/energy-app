// lib/screens/chat/message_bubble.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/screens/products/product_details_screen.dart';
import 'package:GeniusHouse/screens/offers/offer_details_screen.dart';

class MessageBubble extends StatelessWidget {
  final bool isUser;
  final String content;
  final String timestamp;
  final dynamic data;
  final String type;
  final List<String> images;
  final String? audioUrl;
  final ApiService apiService;
  final AuthService? authService;
  final Function(String slug)? onProductTap;
  final Function(String slug)? onOfferTap;
  final VoidCallback? onCopyTap;
  final double fontScale;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);

  const MessageBubble({
    super.key,
    required this.isUser,
    required this.content,
    required this.timestamp,
    this.data,
    this.type = 'text',
    this.images = const [],
    this.audioUrl,
    required this.apiService,
    this.authService,
    this.onProductTap,
    this.onOfferTap,
    this.onCopyTap,
    this.fontScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (type == 'processing') {
      return const SizedBox.shrink();
    }

    final hasImages = images.isNotEmpty;
    final hasAudio = audioUrl != null && audioUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(context),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: onCopyTap,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? primaryBlue : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft:
                        isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight:
                        isUser ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ عرض الصور
                        if (hasImages) _buildImages(context),

                        // ✅ عرض مشغل الصوت
                        if (hasAudio) _buildAudioPlayer(context),

                        if ((hasImages || hasAudio) && content.isNotEmpty)
                          const SizedBox(height: 8),
                        if (content.isNotEmpty)
                          _buildFormattedContent(context, content),
                        if (data != null && data['requirements'] != null)
                          _buildRequirementsSection(
                              context, data['requirements']),
                        if (data != null &&
                            data['matches'] != null &&
                            data['matches']['system_options'] != null)
                          _buildSystemOptionsSection(
                              context, data['matches']['system_options']),
                        if (data != null &&
                            data['matches'] != null &&
                            data['matches']['products'] != null)
                          _buildProductsSection(
                              context, data['matches']['products']),
                        if (data != null &&
                            data['matches'] != null &&
                            data['matches']['comparisons'] != null)
                          _buildComparisonsSection(
                              context, data['matches']['comparisons']),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: onCopyTap,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.copy,
                                  size: 14,
                                  color: isUser
                                      ? Colors.white70
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    timestamp,
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildAvatar(context, isUser: true),
        ],
      ),
    );
  }

  // ✅ مشغل الصوت
  Widget _buildAudioPlayer(BuildContext context) {
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
          _AudioPlayerButton(
            url: audioUrl!,
            isUser: isUser,
          ),
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

  Widget _buildImages(BuildContext context) {
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

  Widget _buildFormattedContent(BuildContext context, String text) {
    String cleanedText = text.replaceAllMapped(
      RegExp(r'(\d+)\.(\d{15,})'),
          (match) => match.group(1)!,
    );

    cleanedText = _formatMixedText(cleanedText);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: MarkdownBody(
        data: cleanedText,
        selectable: true,
        softLineBreak: true,
        styleSheet: MarkdownStyleSheet(
          p: GoogleFonts.cairo(
            fontSize: 14 * fontScale,
            color: isUser ? Colors.white : darkColor,
            height: 1.8,
          ),
          h1: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isUser ? Colors.white : primaryBlue,
          ),
          h2: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isUser ? Colors.white : secondaryBlue,
          ),
          h3: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isUser ? Colors.white : primaryBlue,
          ),
          strong: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: isUser ? Colors.white : primaryBlue,
          ),
          listBullet: GoogleFonts.cairo(
            color: isUser ? Colors.white : darkColor,
            fontSize: 14,
          ),
          blockquote: GoogleFonts.cairo(
            color: isUser ? Colors.white : Colors.orange.shade700,
            fontSize: 12,
          ),
          code: GoogleFonts.cairo(
            color: isUser ? Colors.white : secondaryBlue,
            fontSize: 12,
          ),
          em: GoogleFonts.cairo(
            color: isUser ? Colors.white70 : mediumGray,
            fontSize: 12,
          ),
          listBulletPadding: const EdgeInsets.only(right: 16),
          blockquotePadding: const EdgeInsets.only(right: 12),
        ),
      ),
    );
  }

  String _formatMixedText(String text) {
    String formatted = text;

    formatted = formatted.replaceAllMapped(
      RegExp(r'([\u0600-\u06FF])([a-zA-Z0-9])'),
          (match) => '${match.group(1)} ${match.group(2)}',
    );

    formatted = formatted.replaceAllMapped(
      RegExp(r'([a-zA-Z0-9])([\u0600-\u06FF])'),
          (match) => '${match.group(1)} ${match.group(2)}',
    );

    return formatted;
  }

  Widget _buildAvatar(BuildContext context, {bool isUser = false}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isUser
            ? null
            : const LinearGradient(colors: [primaryBlue, secondaryBlue]),
        shape: BoxShape.circle,
        color: isUser ? Colors.grey.shade300 : null,
      ),
      child: CircleAvatar(
        backgroundColor: isUser ? Colors.grey.shade300 : Colors.transparent,
        child: Icon(
          isUser ? Icons.person : Icons.auto_awesome,
          size: 18,
          color: isUser ? Colors.grey.shade600 : Colors.white,
        ),
      ),
    );
  }

  Widget _buildRequirementsSection(
      BuildContext context, Map<String, dynamic> requirements) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue.withOpacity(0.05),
            secondaryBlue.withOpacity(0.1)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  shape: BoxShape.circle,
                ),
                child:
                const Icon(Icons.calculate, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                '📊 نتيجة الحساب الهندسي',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          const Divider(thickness: 1, height: 20),
          _buildRequirementRow(
              '🔌 إجمالي القدرة', '${requirements['total_watts'] ?? 0} واط'),
          _buildRequirementRow(
              '⚡ الطاقة اليومية', '${requirements['daily_wh'] ?? 0} واط/ساعة'),
          _buildRequirementRow('🪫 الألواح المطلوبة',
              '≈ ${requirements['required_panel_watt'] ?? 0} واط'),
          _buildRequirementRow('🔋 سعة البطارية',
              '≈ ${requirements['required_battery_ah'] ?? 0} أمبير-ساعة'),
          _buildRequirementRow('🔌 قدرة الإنفرتر',
              '≈ ${requirements['required_inverter_watt'] ?? 0} واط'),
          _buildRequirementRow(
              '⚡ فولتية النظام', '${requirements['system_voltage'] ?? 0} فولت'),
          if (requirements['audit_log'] != null &&
              requirements['audit_log']['metadata'] != null &&
              requirements['audit_log']['metadata']['warnings'] != null)
            ..._buildWarnings(
                requirements['audit_log']['metadata']['warnings'] as List),
          if (requirements['recommendations'] != null)
            ..._buildRecommendations(requirements['recommendations'] as List),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 13, fontWeight: FontWeight.w500, color: darkColor)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWarnings(List<dynamic> warnings) {
    return warnings.map((warning) {
      Color iconColor;
      IconData icon;
      final warningStr = warning.toString();

      if (warningStr.contains('⚠️')) {
        icon = Icons.warning_amber;
        iconColor = Colors.orange.shade700;
      } else if (warningStr.contains('📌')) {
        icon = Icons.info;
        iconColor = primaryBlue;
      } else if (warningStr.contains('💡')) {
        icon = Icons.lightbulb;
        iconColor = Colors.amber.shade700;
      } else {
        icon = Icons.error_outline;
        iconColor = Colors.red.shade600;
      }

      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                warningStr,
                style: GoogleFonts.cairo(
                    fontSize: 12, color: mediumGray, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildRecommendations(List<dynamic> recommendations) {
    final uniqueRecommendations = recommendations.toSet().toList();
    return [
      const SizedBox(height: 8),
      const Divider(thickness: 1),
      Row(
        children: [
          Icon(Icons.auto_awesome, size: 14, color: Colors.purple.shade700),
          const SizedBox(width: 6),
          Text('توصيات ذكية',
              style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700)),
        ],
      ),
      const SizedBox(height: 6),
      ...uniqueRecommendations.map((rec) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle, size: 12, color: Colors.green.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(rec.toString(),
                    style: GoogleFonts.cairo(fontSize: 12, color: mediumGray)),
              ),
            ],
          ),
        );
      }),
    ];
  }

  Widget _buildSystemOptionsSection(
      BuildContext context, Map<String, dynamic> systemOptions) {
    final List<Widget> children = [];

    if (systemOptions['economic'] != null) {
      children.add(_buildSystemOptionCard(context, systemOptions['economic'],
          'نظام اقتصادي', Colors.teal, Icons.attach_money));
    }
    if (systemOptions['standard'] != null) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 12));
      children.add(_buildSystemOptionCard(context, systemOptions['standard'],
          'نظام متوسط', Colors.blue, Icons.bolt));
    }
    if (systemOptions['premium'] != null) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 12));
      children.add(_buildSystemOptionCard(context, systemOptions['premium'],
          'نظام ممتاز', Colors.purple, Icons.star));
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_suggest, size: 18, color: primaryBlue),
              const SizedBox(width: 6),
              Text('🛠️ خيارات النظام المتاحة',
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue)),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSystemOptionCard(
      BuildContext context,
      Map<String, dynamic> option,
      String label,
      MaterialColor color,
      IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.shade100, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: color.shade100,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 18, color: color.shade700),
                ),
                const SizedBox(width: 8),
                Text(label,
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color.shade700)),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.shade50,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('💰 ${option['total_price'] ?? 0} \$',
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color.shade700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(option['description'] ?? '',
                style: GoogleFonts.cairo(fontSize: 12, color: mediumGray)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text('العمر: ${option['estimated_lifespan'] ?? 'غير محدد'}',
                    style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
                const SizedBox(width: 12),
                Icon(Icons.verified, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text('${option['warranty'] ?? 'ضمان'}',
                    style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
              ],
            ),
            const SizedBox(height: 8),
            if (option['panels'] != null) ...[
              const SizedBox(height: 4),
              _buildProductChip(context,
                  icon: '🪫',
                  label: option['panels']['name_ar'] ?? 'لوح شمسي',
                  slug: option['panels']['slug'],
                  color: Colors.orange),
            ],
            if (option['batteries'] != null &&
                (option['batteries'] as List).isNotEmpty) ...[
              const SizedBox(height: 4),
              ...(option['batteries'] as List).map((b) => _buildProductChip(
                  context,
                  icon: '🔋',
                  label: b['name_ar'] ?? 'بطارية',
                  slug: b['slug'],
                  color: Colors.green)),
            ],
            if (option['inverter'] != null) ...[
              const SizedBox(height: 4),
              _buildProductChip(context,
                  icon: '🔌',
                  label: option['inverter']['name_ar'] ?? 'إنفرتر',
                  slug: option['inverter']['slug'],
                  color: Colors.blue),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductChip(BuildContext context,
      {required String icon,
        required String label,
        required String? slug,
        required MaterialColor color}) {
    if (slug == null || slug.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        if (onProductTap != null) {
          onProductTap!(slug);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(
                productSlug: slug,
                apiService: apiService,
                authService: authService,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: color.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.shade200)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 14, color: color.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection(
      BuildContext context, Map<String, dynamic> products) {
    final List<Widget> children = [];

    if (products['panels'] != null && (products['panels'] as List).isNotEmpty) {
      children.add(_buildSubSectionHeader('🪫 ألواح شمسية مقترحة'));
      children.add(_buildProductsHorizontalList(context, products['panels']));
    }
    if (products['batteries'] != null &&
        (products['batteries'] as List).isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 12));
      children.add(_buildSubSectionHeader('🔋 بطاريات مقترحة'));
      children
          .add(_buildProductsHorizontalList(context, products['batteries']));
    }
    if (products['inverters'] != null &&
        (products['inverters'] as List).isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 12));
      children.add(_buildSubSectionHeader('🔌 إنفرترات مقترحة'));
      children
          .add(_buildProductsHorizontalList(context, products['inverters']));
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildComparisonsSection(
      BuildContext context, Map<String, dynamic> comparisons) {
    final List<Widget> children = [];

    if (comparisons['panels'] != null &&
        (comparisons['panels'] as List).isNotEmpty) {
      children.add(_buildSubSectionHeader('📊 مقارنة الألواح'));
      for (var panel in comparisons['panels']) {
        children.add(_buildComparisonCard(context, panel));
      }
    }
    if (comparisons['batteries'] != null &&
        (comparisons['batteries'] as List).isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 8));
      children.add(_buildSubSectionHeader('📊 مقارنة البطاريات'));
      for (var battery in comparisons['batteries']) {
        children.add(_buildComparisonCard(context, battery));
      }
    }
    if (comparisons['inverters'] != null &&
        (comparisons['inverters'] as List).isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 8));
      children.add(_buildSubSectionHeader('📊 مقارنة الإنفرترات'));
      for (var inverter in comparisons['inverters']) {
        children.add(_buildComparisonCard(context, inverter));
      }
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildComparisonCard(
      BuildContext context, Map<String, dynamic> comparison) {
    return Card(
      margin: const EdgeInsets.only(top: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  primaryBlue.withOpacity(0.1),
                  secondaryBlue.withOpacity(0.05)
                ]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                comparison['type']?.toString().contains('ليثيوم') == true
                    ? Icons.battery_charging_full
                    : comparison['type']?.toString().contains('موجة جيبية') ==
                    true
                    ? Icons.electrical_services
                    : Icons.solar_power,
                size: 24,
                color: primaryBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comparison['type'] ?? '',
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue)),
                  Text(comparison['description'] ?? '',
                      style: GoogleFonts.cairo(fontSize: 11, color: mediumGray),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (comparison['total_price'] != null)
                    Text('السعر: ${comparison['total_price']} \$',
                        style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title,
          style: GoogleFonts.cairo(
              fontSize: 13, fontWeight: FontWeight.bold, color: primaryBlue)),
    );
  }

  Widget _buildProductsHorizontalList(
      BuildContext context, List<dynamic> products) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length > 5 ? 5 : products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(context, product);
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic product) {
    double finalPrice = 0;
    if (product['final_price'] != null) {
      finalPrice = double.tryParse(product['final_price'].toString()) ?? 0;
    } else if (product['price'] != null) {
      finalPrice = double.tryParse(product['price'].toString()) ?? 0;
    }

    double discountPercent = 0;
    if (product['discount_percentage'] != null) {
      discountPercent =
          double.tryParse(product['discount_percentage'].toString()) ?? 0;
    } else if (product['price'] != null && product['final_price'] != null) {
      final originalPrice = double.tryParse(product['price'].toString()) ?? 0;
      if (originalPrice > 0 && finalPrice < originalPrice) {
        discountPercent = ((originalPrice - finalPrice) / originalPrice) * 100;
      }
    }

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            final slug = product['slug'];
            if (slug != null && slug.isNotEmpty) {
              if (onProductTap != null) {
                onProductTap!(slug);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsScreen(
                      productSlug: slug,
                      apiService: apiService,
                      authService: authService,
                    ),
                  ),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: product['image'] ?? product['main_image'] ?? '',
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    height: 100,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported, size: 30),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'] ?? product['name_ar'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: darkColor)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (discountPercent > 0) ...[
                          Text(
                              '\$${double.tryParse(product['price']?.toString() ?? '0')?.toStringAsFixed(0) ?? '0'}',
                              style: GoogleFonts.cairo(
                                  fontSize: 9,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey.shade500)),
                          const SizedBox(width: 4),
                        ],
                        Text('\$${finalPrice.toStringAsFixed(0)}',
                            style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue)),
                      ],
                    ),
                    if (product['watts'] != null)
                      Text('${product['watts']} واط',
                          style: GoogleFonts.cairo(
                              fontSize: 10, color: mediumGray)),
                  ],
                ),
              ),
            ],
          ),
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

    // ✅ الاستماع للأخطاء
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
        // ✅ استخدم UrlSource للروابط
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
    final color = widget.isUser ? Colors.white : const Color(0xFF1E3A8A);

    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: widget.isUser ? const Color(0xFF1E3A8A) : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}