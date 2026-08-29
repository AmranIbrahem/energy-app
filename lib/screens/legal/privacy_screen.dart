// lib/screens/legal/privacy_screen.dart

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
        title: Text(
          'سياسة الخصوصية',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSection(
              '1. المعلومات التي نجمعها',
              'نقوم بجمع المعلومات التالية:\n• المعلومات الشخصية (الاسم، البريد الإلكتروني، رقم الهاتف، العنوان)\n• معلومات الجهاز (نوع الجهاز، نظام التشغيل)\n• بيانات الاستخدام (الصفحات المزارة، الوقت المنقضي)',
            ),
            _buildSection(
              '2. كيفية استخدام المعلومات',
              'نستخدم معلوماتك من أجل:\n• تقديم خدماتنا وتحسينها\n• معالجة طلباتك ومدفوعاتك\n• التواصل معك بخصوص طلباتك وعروضنا\n• تخصيص تجربتك في التطبيق\n• الامتثال للمتطلبات القانونية',
            ),
            _buildSection(
              '3. مشاركة المعلومات',
              'نحن لا نبيع معلوماتك الشخصية لأطراف ثالثة. قد نشارك معلوماتك مع:\n• شركات الشحن لتوصيل طلباتك\n• مزودي خدمات الدفع لمعالجة المدفوعات\n• السلطات القانونية عند الطلب',
            ),
            _buildSection(
              '4. أمان المعلومات',
              'نحن نتخذ إجراءات أمنية مناسبة لحماية معلوماتك من الوصول غير المصرح به أو التغيير أو الإفصاح أو الإتلاف. نستخدم تشفير SSL لجميع البيانات المنقولة.',
            ),
            _buildSection(
              '5. ملفات تعريف الارتباط',
              'نستخدم ملفات تعريف الارتباط لتحسين تجربتك. يمكنك تعطيل ملفات تعريف الارتباط في إعدادات متصفحك، ولكن هذا قد يؤثر على وظائف التطبيق.',
            ),
            _buildSection(
              '6. حقوق المستخدم',
              'لديك الحق في:\n• الوصول إلى بياناتك الشخصية\n• تصحيح المعلومات غير الدقيقة\n• حذف حسابك وبياناتك\n• الاعتراض على معالجة بياناتك\n• سحب موافقتك في أي وقت',
            ),
            _buildSection(
              '7. الاحتفاظ بالبيانات',
              'نحتفظ بمعلوماتك طالما كان حسابك نشطاً أو حسب الحاجة لتقديم خدماتنا. بعد حذف حسابك، قد نحتفظ ببعض المعلومات للامتثال القانوني.',
            ),
            _buildSection(
              '8. خصوصية الأطفال',
              'خدماتنا غير مخصصة للأطفال دون سن 13 عاماً. نحن لا نجمع معلومات عن قصد من الأطفال. إذا كنت ولي أمر وتعتقد أن طفلك قدم لنا معلومات، يرجى الاتصال بنا.',
            ),
            _buildSection(
              '9. التعديلات على سياسة الخصوصية',
              'قد نقوم بتحديث سياسة الخصوصية من وقت لآخر. سنخطرك بأي تغييرات عن طريق نشر السياسة الجديدة على هذه الصفحة.',
            ),
            _buildSection(
              '10. الاتصال بنا',
              'للاستفسارات حول سياسة الخصوصية:\n📧 البريد الإلكتروني: privacy@nexsy.com\nا',
            ),
          ],
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
                  'آخر تحديث: 1 اغسطس 2026',
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

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              content,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: mediumGray,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
