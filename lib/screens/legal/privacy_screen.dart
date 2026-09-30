// lib/screens/legal/privacy_screen.dart

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEFF6FF), Color(0xFFF5F7FA)],
            ),
          ),
          child: Column(
            children: [
              ClipPath(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.privacy_tip_rounded,
                                        color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'سياسة الخصوصية',
                                    style: GoogleFonts.cairo(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildIntro(),
                        const SizedBox(height: 24),

                        // ─── 1. مقدمة ───
                        _buildSection(
                          '1. مقدمة ونطاق التطبيق',
                          'نحن في NEX ("المنصة"، "نحن"، "لنا") نلتزم بحماية خصوصية مستخدمينا وضمان أمان بياناتهم الشخصية. '
                              'تنطبق سياسة الخصوصية هذه على تطبيق NEX للهواتف المحمولة، وموقع الويب، وجميع الخدمات المرتبطة به، بما في ذلك:\n'
                              '• تصميم وتركيب الأنظمة الشمسية\n'
                              '• تصميم الإنارة الذكية والديكور\n'
                              '• تشخيص الأعطال بالذكاء الاصطناعي\n'
                              '• المحادثات الذكية والدعم البشري\n'
                              '• فحص توافق الأجهزة الكهربائية\n'
                              '• حاسبة التوفير وجدولة تشغيل الأجهزة\n'
                              '• طلبات الصيانة والتركيب من الورش\n'
                              '• الاستشارات الهندسية\n'
                              '• متجر المنتجات والعروض الإلكتروني\n'
                              '• حسابات الشركات ولوحات التحكم\n\n'
                              'باستخدامك للمنصة، فإنك توافق على جمع واستخدام المعلومات وفقاً لهذه السياسة. إذا لم توافق على أي بند، يرجى التوقف عن استخدام المنصة.',
                        ),

                        // ─── 2. المعلومات التي نجمعها ───
                        _buildSection(
                          '2. المعلومات التي نجمعها',
                          'نجمع أنواعاً متعددة من المعلومات لتقديم خدماتنا وتحسينها:',
                        ),
                        _buildSubSection(
                          '2.1 المعلومات الشخصية',
                          '• الاسم الكامل، البريد الإلكتروني، رقم الهاتف\n'
                              '• المحافظة، المنطقة، العنوان التفصيلي\n'
                              '• الصورة الشخصية (اختياري)\n'
                              '• نوع الحساب (فرد / شركة / زائر)',
                        ),
                        _buildSubSection(
                          '2.2 معلومات الحساب والشركة',
                          '• بيانات تسجيل الدخول (بريد إلكتروني، كلمة مرور مشفرة)\n'
                              '• رمز التفعيل ومعرّف الجلسة\n'
                              '• بيانات الشركة (الاسم التجاري، السجل التجاري، العنوان، الشعار)\n'
                              '• حالة الحساب والصلاحيات',
                        ),
                        _buildSubSection(
                          '2.3 معلومات الأنظمة الشمسية والتصميم',
                          '• نوع المبنى (منزلي / صناعي / زراعي)\n'
                              '• بيانات الموقع (المدينة، المساحة)\n'
                              '• قائمة الأجهزة الكهربائية (النوع، القدرة، ساعات التشغيل)\n'
                              '• تفاصيل المنظومة الشمسية (الألواح، الإنفرتر، البطاريات)\n'
                              '• الصور المرفوعة للموقع أو الأجهزة',
                        ),
                        _buildSubSection(
                          '2.4 معلومات تصميم الإنارة',
                          '• نوع الغرفة وأبعادها (الطول، العرض، الارتفاع)\n'
                              '• وجود جبس أو أسقف مستعارة\n'
                              '• الصور المرفوعة للغرفة\n'
                              '• تفضيلات الإضاءة ولون الضوء\n'
                              '• العناصر المعتمدة في التصميم',
                        ),
                        _buildSubSection(
                          '2.5 معلومات تشخيص الأعطال',
                          '• رمز الخطأ على شاشة المحول (إن وجد)\n'
                              '• وصف المشكلة أو الأعراض\n'
                              '• نوع الجهاز وماركته\n'
                              '• إجاباتك على أسئلة التشخيص\n'
                              '• نتائج الفحص والخطوات المنجزة',
                        ),
                        _buildSubSection(
                          '2.6 محتوى المحادثات',
                          '• الرسائل النصية المتبادلة مع المساعد الذكي أو الدعم البشري\n'
                              '• الصور المرفقة في المحادثات\n'
                              '• الرسائل الصوتية وتسجيلات الميكروفون\n'
                              '• سجل المحادثات السابقة',
                        ),
                        _buildSubSection(
                          '2.7 معلومات الطلبات والمشتريات',
                          '• بيانات سلة التسوق والمنتجات المفضلة\n'
                              '• قائمة العروض والمقارنات\n'
                              '• الطلبات (الفواتير، الحالة، المبالغ)\n'
                              '• عنوان التوصيل وبيانات الشحن حسب المحافظة\n'
                              '• طريقة الدفع المختارة (نقداً / تحويل بنكي / محفظة إلكترونية)',
                        ),
                        _buildSubSection(
                          '2.8 معلومات الدفع',
                          'ملاحظة هامة: لا نقوم بتخزين بيانات بطاقات الائتمان أو بيانات الدفع الحساسة على خوادمنا. '
                              'تتم معالجة المدفوعات عبر بوابات دفع آمنة ومعتمدة. نحتفظ فقط بسجل المعاملات (رقم الفاتورة، المبلغ، التاريخ، الحالة).',
                        ),
                        _buildSubSection(
                          '2.9 معلومات الورش والصيانة',
                          '• نوع الورشة (تركيب / صيانة)\n'
                              '• الفني المختار والوقت المتاح\n'
                              '• الموقع الجغرافي (الإحداثيات والعنوان)\n'
                              '• الصور المرفقة للمشكلة\n'
                              '• تقييمك للخدمة المقدمة',
                        ),
                        _buildSubSection(
                          '2.10 معلومات الجهاز والتقنية',
                          '• نوع الجهاز ونظام التشغيل وإصداره\n'
                              '• معرّف الجهاز (Device ID)\n'
                              '• عنوان IP ونوع الشبكة\n'
                              '• لغة التطبيق وإعدادات العرض (حجم الخط، العملة)\n'
                              '• رمز Firebase Cloud Messaging (FCM) للإشعارات',
                        ),

                        // ─── 3. كيف نستخدم المعلومات ───
                        _buildSection(
                          '3. كيف نستخدم معلوماتك',
                          'نستخدم المعلومات التي نجمعها للأغراض التالية:',
                        ),
                        _buildSubSection(
                          '3.1 تقديم الخدمات الأساسية',
                          '• إنشاء وإدارة حسابك\n'
                              '• معالجة طلبات التصميم الشمسي والإنارة\n'
                              '• تنفيذ عمليات التشخيص الذكي\n'
                              '• معالجة الطلبات والمشتريات\n'
                              '• إدارة طلبات الصيانة والتركيب',
                        ),
                        _buildSubSection(
                          '3.2 تحسين الخدمة بالذكاء الاصطناعي',
                          '• تحليل بياناتك لتقديم توصيات مخصصة\n'
                              '• تحسين دقة نتائج التشخيص\n'
                              '• تحسين خطط التصميم والاقتراحات\n'
                              '• تدريب نماذج الذكاء الاصطناعي على بيانات مجهولة الهوية',
                        ),
                        _buildSubSection(
                          '3.3 التواصل معك',
                          '• إرسال إشعارات حول طلباتك وحالة مشاريعك\n'
                              '• الرد على استفساراتك وطلباتك\n'
                              '• إبلاغك بالعروض والمنتجات الجديدة\n'
                              '• تأكيد الطلبات والتذكير بالسلة',
                        ),
                        _buildSubSection(
                          '3.4 الأمان والامتثال',
                          '• حماية حسابك من الوصول غير المصرح به\n'
                              '• كشف ومنع الاحتيال\n'
                              '• الامتثال للمتطلبات القانونية والتنظيمية\n'
                              '• حل النزاعات وتنفيذ الاتفاقيات',
                        ),

                        // ─── 4. مشاركة المعلومات ───
                        _buildSection(
                          '4. مشاركة المعلومات مع أطراف ثالثة',
                          'نحن لا نبيع أو نؤجر معلوماتك الشخصية لأي طرف ثالث. قد نشارك معلوماتك في الحالات التالية فقط:',
                        ),
                        _buildSubSection(
                          '4.1 مع مزودي الخدمات',
                          '• شركات الشحن لتوصيل طلباتك\n'
                              '• بوابات الدفع الآمنة لمعالجة المعاملات\n'
                              '• خدمات الإشعارات (Firebase Cloud Messaging)\n'
                              '• خدمات الاستضافة السحابية\n'
                              '• خدمات الـ Pusher للاتصالات الفورية',
                        ),
                        _buildSubSection(
                          '4.2 مع الشركات المسجلة',
                          '• عند تقديم طلب لمنتج أو عرض من شركة معينة، يتم إرسال بيانات الطلب الضرورية (الاسم، العنوان، رقم الهاتف) لتلك الشركة لإتمام التوصيل.',
                        ),
                        _buildSubSection(
                          '4.3 مع الفنيين والورش',
                          '• عند طلب خدمة صيانة أو تركيب، تتم مشاركة اسمك وعنوانك ورقم هاتفك مع الفني أو الورشة المسؤولة عن تنفيذ الخدمة.',
                        ),
                        _buildSubSection(
                          '4.4 المتطلبات القانونية',
                          '• عند الطلب من السلطات المختصة بموجب القانون\n'
                              '• لحماية حقوقنا أو ممتلكاتنا أو سلامة المستخدمين\n'
                              '• للتحقيق في مخالفات محتملة لشروط الاستخدام',
                        ),

                        // ─── 5. أمان البيانات ───
                        _buildSection(
                          '5. أمان البيانات',
                          'نأخذ أمان بياناتك على محمل الجد ونستخدم تدابير أمنية متعددة الطبقات لحمايتها:',
                        ),
                        _buildSubSection(
                          '5.1 إجراءات الحماية التقنية',
                          '• تشفير SSL/TLS لجميع البيانات المنقولة\n'
                              '• تشفير كلمات المرور باستخدام خوارزميات آمنة (bcrypt)\n'
                              '• نظام التحقق بخطوتين عبر رمز البريد الإلكتروني\n'
                              '• تحديث تلقائي لرموز الوصول (Auto Token Refresh)\n'
                              '• انتهاء صلاحية الرموز بعد 30 يوماً',
                        ),
                        _buildSubSection(
                          '5.2 إجراءات الحماية التنظيمية',
                          '• تقييد الوصول إلى البيانات الشخصية للموظفين المخولين فقط\n'
                              '• تدريب الموظفين على ممارسات حماية البيانات\n'
                              '• مراجعة دورية لإجراءات الأمان\n'
                              '• سجل تدقيق للعمليات الحساسة',
                        ),

                        // ─── 6. ملفات تعريف الارتباط ───
                        _buildSection(
                          '6. ملفات تعريف الارتباط (Cookies) والتخزين المحلي',
                          'نستخدم أنواعاً مختلفة من التخزين المحلي لتحسين تجربتك:',
                        ),
                        _buildSubSection(
                          '6.1 على تطبيق الموبايل',
                          '• SharedPreferences لتخزين: رمز الجلسة، تفضيلات العملة، حجم الخط، آخر محافظة، إعدادات الإشعارات\n'
                              '• Hive للبيانات المؤقتة: آخر تحديث للصفحة الرئيسية، تفاصيل المنتجات والعروض، الإشعارات، الطلبات',
                        ),
                        _buildSubSection(
                          '6.2 على الويب',
                          '• ملفات تعريف الارتباط الأساسية لتسجيل الدخول ووظائف الموقع\n'
                              '• ملفات تحليلية لفهم كيفية استخدام المنصة\n'
                              '• يمكنك التحكم في ملفات تعريف الارتباط من إعدادات المتصفح',
                        ),

                        // ─── 7. الاحتفاظ بالبيانات ───
                        _buildSection(
                          '7. الاحتفاظ بالبيانات',
                          '• نحتفظ ببياناتك الشخصية طالما كان حسابك نشطاً أو حسب الحاجة لتقديم الخدمات\n'
                              '• بعد حذف الحساب، يتم حذف البيانات الشخصية نهائياً خلال 30 يوماً\n'
                              '• نحتفظ ببعض السجلات للامتثال القانوني (مثل الفواتير والمعاملات لمدة 5 سنوات)\n'
                              '• بيانات المحادثات تُحفظ لمدة 12 شهراً لأغراض تحسين الخدمة',
                        ),

                        // ─── 8. حقوقك ───
                        _buildSection(
                          '8. حقوقك كمستخدم',
                          'لديك الحقوق التالية فيما يتعلق ببياناتك الشخصية:',
                        ),
                        _buildSubSection(
                          '8.1 حق الوصول',
                          '• يمكنك الوصول إلى بياناتك الشخصية من خلال صفحة الملف الشخصي في التطبيق',
                        ),
                        _buildSubSection(
                          '8.2 حق التصحيح',
                          '• يمكنك تعديل بياناتك الشخصية في أي وقت من خلال "تعديل الملف الشخصي"',
                        ),
                        _buildSubSection(
                          '8.3 حق الحذف',
                          '• يمكنك حذف حسابك وبياناتك نهائياً من خلال إعدادات الحساب\n'
                              '• يتطلب الحذف تأكيد كلمة المرور',
                        ),
                        _buildSubSection(
                          '8.4 حق الاعتراض',
                          '• يمكنك تعطيل الإشعارات التسويقية من الإعدادات\n'
                              '• يمكنك الاعتراض على معالجة بياناتك بالتواصل معنا',
                        ),
                        _buildSubSection(
                          '8.5 حق سحب الموافقة',
                          '• يمكنك سحب موافقتك على معالجة البيانات في أي وقت\n'
                              '• قد يؤدي سحب الموافقة إلى تقييد وصولك لبعض الخدمات',
                        ),

                        // ─── 9. خصوصية الأطفال ───
                        _buildSection(
                          '9. خصوصية الأطفال',
                          'خدمات NEX غير مخصصة للأطفال دون سن 13 عاماً. نحن لا نجمع معلومات شخصية عن قصد من الأطفال. '
                              'إذا كنت ولي أمر وتعتقد أن طفلك قد قدم لنا معلومات شخصية، يرجى الاتصال بنا فوراً وسنتخذ الخطوات اللازمة لحذف تلك المعلومات.',
                        ),

                        // ─── 10. النقل الدولي ───
                        _buildSection(
                          '10. نقل البيانات',
                          'قد يتم نقل بياناتك ومعالجتها في خوادم تقع خارج سوريا. نضمن أن جميع عمليات النقل تتم وفقاً لمعايير حماية البيانات المعتمدة دولياً، '
                              'ونحرص على أن جميع مزودي الخدمات يلتزمون بمعايير الخصوصية والأمان المطلوبة.',
                        ),

                        // ─── 11. التعديلات ───
                        _buildSection(
                          '11. التعديلات على سياسة الخصوصية',
                          '• قد نقوم بتحديث سياسة الخصوصية من وقت لآخر لتعكس التغييرات في خدماتنا أو المتطلبات القانونية\n'
                              '• سنخطرك بأي تغييرات جوهرية عبر إشعار في التطبيق أو بريد إلكتروني\n'
                              '• تاريخ آخر تحديث مذكور في أعلى هذه الصفحة\n'
                              '• استمرارك في استخدام المنصة بعد التعديلات يعني موافقتك عليها',
                        ),

                        // ─── 12. الاتصال بنا ───
                        _buildSection(
                          '12. الاتصال بنا',
                          'إذا كان لديك أي أسئلة أو استفسارات أو شكاوى حول سياسة الخصوصية أو معالجة بياناتك، يمكنك الاتصال بنا عبر:',
                        ),
                        _buildContactCard(),

                        const SizedBox(height: 20),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryBlue.withOpacity(0.08),
            secondaryBlue.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryBlue.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.15),
                  secondaryBlue.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.privacy_tip_rounded,
              color: primaryBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سياسة الخصوصية',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'آخر تحديث: 1 يناير 2026',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: mediumGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentBlue.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_rounded, color: secondaryBlue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'نحن في NEX نضع خصوصيتك في المقام الأول. توضح هذه السياسة بشفافية كاملة كيف نجمع بياناتك ونستخدمها ونحميها عبر جميع خدمات المنصة.',
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                color: darkColor,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, secondaryBlue],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              content,
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                color: mediumGray,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, right: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: secondaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              content,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: mediumGray,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryBlue.withOpacity(0.06),
            secondaryBlue.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryBlue.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          _buildContactRow(Icons.email_rounded, 'البريد الإلكتروني',
              'privacy@nexsy.com'),
          const SizedBox(height: 10),
          _buildContactRow(Icons.support_agent_rounded, 'الدعم العام',
              'support@nexsy.shop'),
          const SizedBox(height: 10),
          _buildContactRow(Icons.location_on_rounded, 'الموقع',
              'دمشق، سوريا'),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryBlue, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  color: mediumGray,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  color: darkColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '© 2026 NEX — جميع الحقوق محفوظة.\nباستخدامك للمنصة، أنت توافق على سياسة الخصوصية وشروط الاستخدام.',
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontSize: 11.5,
          color: mediumGray,
          height: 1.7,
        ),
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