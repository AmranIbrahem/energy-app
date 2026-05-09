// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_markdown/flutter_markdown.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:energy_store_app/services/api_service.dart';
// import 'package:energy_store_app/services/auth_service.dart';
// import 'package:energy_store_app/screens/products/product_details_screen.dart';
// import 'package:energy_store_app/screens/offers/offer_details_screen.dart';
// import 'package:energy_store_app/widgets/offer_card.dart';
// import 'package:energy_store_app/widgets/product_card.dart';
//
// class MessageBubble extends StatelessWidget {
//   final bool isUser;
//   final String content;
//   final String timestamp;
//   final dynamic data;
//   final ApiService apiService;
//   final AuthService? authService;  // ✅ جعله اختيارياً
//
//   const MessageBubble({
//     super.key,
//     required this.isUser,
//     required this.content,
//     required this.timestamp,
//     this.data,
//     required this.apiService,
//     this.authService,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (!isUser) _buildAvatar(context),
//           const SizedBox(width: 8),
//           Flexible(
//             child: Column(
//               crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: isUser ? Colors.green.shade400 : Colors.white,
//                     borderRadius: BorderRadius.only(
//                       topLeft: const Radius.circular(16),
//                       topRight: const Radius.circular(16),
//                       bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
//                       bottomRight: isUser ? Radius.zero : const Radius.circular(16),
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         blurRadius: 5,
//                         offset: const Offset(0, 1),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Markdown Content
//                       MarkdownBody(
//                         data: content,
//                         styleSheet: MarkdownStyleSheet(
//                           p: GoogleFonts.cairo(
//                             fontSize: 14,
//                             color: isUser ? Colors.white : Colors.black87,
//                             height: 1.5,
//                           ),
//                           h1: GoogleFonts.cairo(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: isUser ? Colors.white : Colors.black87,
//                           ),
//                           h2: GoogleFonts.cairo(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: isUser ? Colors.white : Colors.black87,
//                           ),
//                           strong: GoogleFonts.cairo(
//                             fontWeight: FontWeight.bold,
//                             color: isUser ? Colors.white : Colors.green.shade700,
//                           ),
//                           listBullet: GoogleFonts.cairo(
//                             color: isUser ? Colors.white : Colors.black87,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//
//                       // Products Section
//                       if (data != null && data['products'] != null)
//                         _buildProductsSection(context, data['products']),
//
//                       // Offers Section
//                       if (data != null && data['offers'] != null && (data['offers'] as List).isNotEmpty)
//                         _buildOffersSection(context, data['offers']),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 8),
//                   child: Text(
//                     timestamp,
//                     style: GoogleFonts.cairo(
//                       fontSize: 10,
//                       color: Colors.grey.shade500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (isUser) const SizedBox(width: 8),
//           if (isUser) _buildAvatar(context, isUser: true),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAvatar(BuildContext context, {bool isUser = false}) {
//     return Container(
//       width: 36,
//       height: 36,
//       decoration: BoxDecoration(
//         gradient: isUser
//             ? null
//             : LinearGradient(
//           colors: [Colors.green.shade400, Colors.green.shade700],
//         ),
//         shape: BoxShape.circle,
//         color: isUser ? Colors.grey.shade300 : null,
//       ),
//       child: CircleAvatar(
//         backgroundColor: isUser ? Colors.grey.shade300 : Colors.transparent,
//         child: Icon(
//           isUser ? Icons.person : Icons.auto_awesome,
//           size: 18,
//           color: isUser ? Colors.grey.shade600 : Colors.white,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildProductsSection(BuildContext context, Map<String, dynamic> products) {
//     final List<Widget> children = [];
//
//     // Panels
//     if (products['panels'] != null && (products['panels'] as List).isNotEmpty) {
//       children.add(_buildSubSectionHeader('🪫 ألواح شمسية مقترحة'));
//       children.add(_buildProductsHorizontalList(context, products['panels']));
//     }
//
//     // Batteries
//     if (products['batteries'] != null && (products['batteries'] as List).isNotEmpty) {
//       children.add(const SizedBox(height: 12));
//       children.add(_buildSubSectionHeader('🔋 بطاريات مقترحة'));
//       children.add(_buildProductsHorizontalList(context, products['batteries']));
//     }
//
//     // Inverters
//     if (products['inverters'] != null && (products['inverters'] as List).isNotEmpty) {
//       children.add(const SizedBox(height: 12));
//       children.add(_buildSubSectionHeader('🔌 إنفرترات مقترحة'));
//       children.add(_buildProductsHorizontalList(context, products['inverters']));
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: children,
//     );
//   }
//
//   Widget _buildSubSectionHeader(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Text(
//         title,
//         style: GoogleFonts.cairo(
//           fontSize: 13,
//           fontWeight: FontWeight.bold,
//           color: Colors.green.shade700,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildProductsHorizontalList(BuildContext context, List<dynamic> products) {
//     return SizedBox(
//       height: 220,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: products.length > 5 ? 5 : products.length,
//         itemBuilder: (context, index) {
//           final product = products[index];
//           return _buildProductCard(context, product);
//         },
//       ),
//     );
//   }
//
//   Widget _buildProductCard(BuildContext context, dynamic product) {
//     final formattedProduct = {
//       'id': product['id'],
//       'name_ar': product['name_ar'],
//       'slug': product['slug'],
//       'price': product['price'],
//       'final_price': product['price'],
//       'main_image': product['image'],
//       'discount_percentage': 0,
//       'is_favorite': false,
//     };
//
//     return Container(
//       width: 160,
//       margin: const EdgeInsets.only(right: 8),
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: InkWell(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => ProductDetailsScreen(
//                   productSlug: product['slug'],
//                   apiService: apiService,
//                   authService: authService,
//                 ),
//               ),
//             );
//           },
//           borderRadius: BorderRadius.circular(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               ClipRRect(
//                 borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//                 child: CachedNetworkImage(
//                   imageUrl: product['image'],
//                   height: 100,
//                   width: double.infinity,
//                   fit: BoxFit.cover,
//                   errorWidget: (context, url, error) => Container(
//                     height: 100,
//                     color: Colors.grey.shade200,
//                     child: const Icon(Icons.image_not_supported),
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(8),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       product['name_ar'],
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: GoogleFonts.cairo(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       '\$${product['price']}',
//                       style: GoogleFonts.cairo(
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green.shade700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildOffersSection(BuildContext context, List<dynamic> offers) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildSubSectionHeader('🛒 العروض المناسبة لك'),
//         SizedBox(
//           height: 260,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: offers.length > 5 ? 5 : offers.length,
//             itemBuilder: (context, index) {
//               final offer = offers[index];
//               final formattedOffer = {
//                 'id': offer['id'],
//                 'name_ar': offer['name_ar'],
//                 'slug': offer['slug'],
//                 'price': offer['price'],
//                 'final_price': offer['price'],
//                 'cover_image': offer['image'],
//                 'total_wattage': offer['wattage'],
//                 'discount_percentage': 0,
//                 'is_favorite': false,
//               };
//               return Container(
//                 width: 280,
//                 margin: const EdgeInsets.only(right: 8),
//                 child: OfferCard(
//                   offer: formattedOffer,
//                   apiService: apiService,
//                   authService: authService,
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }





import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:energy_store_app/services/api_service.dart';
import 'package:energy_store_app/services/auth_service.dart';
import 'package:energy_store_app/screens/products/product_details_screen.dart';
import 'package:energy_store_app/screens/offers/offer_details_screen.dart';

class MessageBubble extends StatelessWidget {
  final bool isUser;
  final String content;
  final String timestamp;
  final dynamic data;
  final String type;
  final ApiService apiService;
  final AuthService? authService;
  final Function(String slug)? onProductTap;
  final Function(String slug)? onOfferTap;

  const MessageBubble({
    super.key,
    required this.isUser,
    required this.content,
    required this.timestamp,
    this.data,
    this.type = 'text',
    required this.apiService,
    this.authService,
    this.onProductTap,
    this.onOfferTap,
  });

  @override
  Widget build(BuildContext context) {
    if (type == 'processing') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(context),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.green.shade400 : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isUser ? Radius.zero : const Radius.circular(16),
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
                      // ✅ عرض النص المحسن باستخدام Markdown مع تنسيق أفضل
                      if (content.isNotEmpty)
                        _buildFormattedContent(context, content),

                      // ✅ عرض قسم الاحتياجات المحسوبة (Requirements)
                      if (data != null && data['requirements'] != null)
                        _buildRequirementsSection(context, data['requirements']),

                      // ✅ عرض خيارات الأنظمة (System Options) مع إمكانية الضغط على المنتجات
                      if (data != null &&
                          data['matches'] != null &&
                          data['matches']['system_options'] != null)
                        _buildSystemOptionsSection(context, data['matches']['system_options']),

                      // ✅ عرض المنتجات المقترحة (Products)
                      if (data != null &&
                          data['matches'] != null &&
                          data['matches']['products'] != null)
                        _buildProductsSection(context, data['matches']['products']),

                      // ✅ عرض المقارنات (Comparisons)
                      if (data != null &&
                          data['matches'] != null &&
                          data['matches']['comparisons'] != null)
                        _buildComparisonsSection(context, data['matches']['comparisons']),

                      const SizedBox(height: 8),
                    ],
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

  // ✅ دالة لعرض النص المنسق بشكل أفضل
  Widget _buildFormattedContent(BuildContext context, String text) {
    // تنظيف النص من الأرقام العشرية الزائدة
    String cleanedText = text.replaceAllMapped(
      RegExp(r'(\d+)\.(\d{15,})'),
          (match) => match.group(1)!,
    );

    return MarkdownBody(
      data: cleanedText,
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.cairo(
          fontSize: 14,
          color: isUser ? Colors.white : Colors.black87,
          height: 1.6,
        ),
        h1: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isUser ? Colors.white : Colors.green.shade800,
        ),
        h2: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isUser ? Colors.white : Colors.green.shade700,
        ),
        strong: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          color: isUser ? Colors.white : Colors.green.shade700,
        ),
        listBullet: GoogleFonts.cairo(
          color: isUser ? Colors.white : Colors.black87,
          fontSize: 14,
        ),
        blockquote: GoogleFonts.cairo(
          color: isUser ? Colors.white : Colors.orange.shade700,
          fontSize: 12,
        ),
        code: GoogleFonts.cairo(
          color: isUser ? Colors.white : Colors.blue.shade700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, {bool isUser = false}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isUser
            ? null
            : LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade700],
        ),
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

  // ✅ قسم الاحتياجات المحسوبة
  Widget _buildRequirementsSection(BuildContext context, Map<String, dynamic> requirements) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calculate, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                '📊 نتيجة الحساب الهندسي',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const Divider(thickness: 1, height: 20),
          _buildRequirementRow('🔌 إجمالي القدرة', '${requirements['total_watts']} واط'),
          _buildRequirementRow('⚡ الطاقة اليومية', '${requirements['daily_wh']} واط/ساعة'),
          _buildRequirementRow('🪫 الألواح المطلوبة', '≈ ${requirements['required_panel_watt']} واط'),
          _buildRequirementRow('🔋 سعة البطارية', '≈ ${requirements['required_battery_ah']} أمبير-ساعة'),
          _buildRequirementRow('🔌 قدرة الإنفرتر', '≈ ${requirements['required_inverter_watt']} واط'),
          _buildRequirementRow('⚡ فولتية النظام', '${requirements['system_voltage']} فولت'),

          // عرض التحذيرات إذا وجدت
          if (requirements['audit_log'] != null &&
              requirements['audit_log']['metadata'] != null &&
              requirements['audit_log']['metadata']['warnings'] != null)
            ..._buildWarnings(requirements['audit_log']['metadata']['warnings'] as List),

          // عرض التوصيات
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
          Text(
            label,
            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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
      if (warning.toString().contains('⚠️')) {
        icon = Icons.warning_amber;
        iconColor = Colors.orange.shade700;
      } else if (warning.toString().contains('📌')) {
        icon = Icons.info;
        iconColor = Colors.blue.shade600;
      } else if (warning.toString().contains('💡')) {
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
                warning.toString(),
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
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
          Text(
            'توصيات ذكية',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
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
                child: Text(
                  rec.toString(),
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        );
      }),
    ];
  }

  // ✅ قسم خيارات الأنظمة مع إمكانية الضغط على المنتجات
  Widget _buildSystemOptionsSection(BuildContext context, Map<String, dynamic> systemOptions) {
    final List<Widget> children = [];

    if (systemOptions['economic'] != null) {
      children.add(_buildSystemOptionCard(context, systemOptions['economic'], 'نظام اقتصادي', Colors.teal, Icons.attach_money));
    }
    if (systemOptions['standard'] != null) {
      children.add(const SizedBox(height: 12));
      children.add(_buildSystemOptionCard(context, systemOptions['standard'], 'نظام متوسط', Colors.blue, Icons.bolt));
    }
    if (systemOptions['premium'] != null) {
      children.add(const SizedBox(height: 12));
      children.add(_buildSystemOptionCard(context, systemOptions['premium'], 'نظام ممتاز', Colors.purple, Icons.star));
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_suggest, size: 18, color: Colors.green.shade700),
              const SizedBox(width: 6),
              Text(
                '🛠️ خيارات النظام المتاحة',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSystemOptionCard(BuildContext context, Map<String, dynamic> option, String label, MaterialColor color, IconData icon) {
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color.shade700),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color.shade700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '💰 ${option['total_price']} \$',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              option['description'] ?? '',
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'العمر: ${option['estimated_lifespan'] ?? 'غير محدد'}',
                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Icon(Icons.verified, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${option['warranty'] ?? 'ضمان'}',
                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ✅ المنتجات في النظام مع إمكانية الضغط
            if (option['panels'] != null) ...[
              const SizedBox(height: 4),
              _buildProductChip(
                context,
                icon: '🪫',
                label: option['panels']['name_ar'] ?? 'لوح شمسي',
                slug: option['panels']['slug'],
                color: Colors.orange,
              ),
            ],

            if (option['batteries'] != null && (option['batteries'] as List).isNotEmpty) ...[
              const SizedBox(height: 4),
              ...(option['batteries'] as List).map((b) => _buildProductChip(
                context,
                icon: '🔋',
                label: b['name_ar'] ?? 'بطارية',
                slug: b['slug'],
                color: Colors.green,
              )),
            ],

            if (option['inverter'] != null) ...[
              const SizedBox(height: 4),
              _buildProductChip(
                context,
                icon: '🔌',
                label: option['inverter']['name_ar'] ?? 'إنفرتر',
                slug: option['inverter']['slug'],
                color: Colors.blue,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ شريط منتج قابل للنقر
  Widget _buildProductChip(BuildContext context, {
    required String icon,
    required String label,
    required String? slug,
    required MaterialColor color,
  }) {
    if (slug == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        if (onProductTap != null) {
          onProductTap!(slug);
        } else {
          // Fallback للتوافق مع الكود القديم
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
          border: Border.all(color: color.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 14, color: color.shade400),
          ],
        ),
      ),
    );
  }

  // ✅ قسم المنتجات
  Widget _buildProductsSection(BuildContext context, Map<String, dynamic> products) {
    final List<Widget> children = [];

    if (products['panels'] != null && (products['panels'] as List).isNotEmpty) {
      children.add(_buildSubSectionHeader('🪫 ألواح شمسية مقترحة'));
      children.add(_buildProductsHorizontalList(context, products['panels']));
    }

    if (products['batteries'] != null && (products['batteries'] as List).isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(_buildSubSectionHeader('🔋 بطاريات مقترحة'));
      children.add(_buildProductsHorizontalList(context, products['batteries']));
    }

    if (products['inverters'] != null && (products['inverters'] as List).isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(_buildSubSectionHeader('🔌 إنفرترات مقترحة'));
      children.add(_buildProductsHorizontalList(context, products['inverters']));
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ✅ قسم المقارنات
  Widget _buildComparisonsSection(BuildContext context, Map<String, dynamic> comparisons) {
    final List<Widget> children = [];

    if (comparisons['panels'] != null && (comparisons['panels'] as List).isNotEmpty) {
      children.add(_buildSubSectionHeader('📊 مقارنة الألواح'));
      for (var panel in comparisons['panels']) {
        children.add(_buildComparisonCard(context, panel));
      }
    }

    if (comparisons['batteries'] != null && (comparisons['batteries'] as List).isNotEmpty) {
      children.add(const SizedBox(height: 8));
      children.add(_buildSubSectionHeader('📊 مقارنة البطاريات'));
      for (var battery in comparisons['batteries']) {
        children.add(_buildComparisonCard(context, battery));
      }
    }

    if (comparisons['inverters'] != null && (comparisons['inverters'] as List).isNotEmpty) {
      children.add(const SizedBox(height: 8));
      children.add(_buildSubSectionHeader('📊 مقارنة الإنفرترات'));
      for (var inverter in comparisons['inverters']) {
        children.add(_buildComparisonCard(context, inverter));
      }
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context, Map<String, dynamic> comparison) {
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
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                comparison['type']?.contains('ليثيوم') == true ? Icons.battery_charging_full :
                comparison['type']?.contains('موجة جيبية') == true ? Icons.electrical_services :
                Icons.solar_power,
                size: 24,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comparison['type'] ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  Text(
                    comparison['description'] ?? '',
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (comparison['total_price'] != null)
                    Text(
                      'السعر: ${comparison['total_price']} \$',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
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

  Widget _buildSubSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade700,
        ),
      ),
    );
  }

  Widget _buildProductsHorizontalList(BuildContext context, List<dynamic> products) {
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
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            if (onProductTap != null && product['slug'] != null) {
              onProductTap!(product['slug']);
            } else if (product['slug'] != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(
                    productSlug: product['slug'],
                    apiService: apiService,
                    authService: authService,
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: product['image'] ?? '',
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
                    Text(
                      product['name'] ?? product['name_ar'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product['price'] ?? product['final_price']}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    if (product['watts'] != null)
                      Text(
                        '${product['watts']} واط',
                        style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade600),
                      ),
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