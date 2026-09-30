// lib/screens/legal/terms_screen.dart

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
                                    child: const Icon(Icons.description_rounded,
                                        color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'الشروط والأحكام',
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
                        const SizedBox(height: 24),
                        _buildSection(
                          '1. قبول الشروط',
                          'باستخدامك لتطبيق NEX، فإنك توافق على الالتزام بهذه الشروط والأحكام. إذا كنت لا توافق على أي جزء من هذه الشروط، يرجى عدم استخدام التطبيق.',
                        ),
                        _buildSection(
                          '2. وصف الخدمة',
                          'NEX هي منصة إلكترونية متخصصة في بيع وتوزيع منتجات وأنظمة الطاقة الشمسية والبديلة في الجمهورية العربية السورية. نوفر مجموعة متنوعة من المنتجات والخدمات المتعلقة بالطاقة المتجددة.',
                        ),
                        _buildSection(
                          '3. التسجيل والحساب',
                          'لتتمكن من استخدام كامل خدمات التطبيق، يجب عليك إنشاء حساب وتقديم معلومات صحيحة ودقيقة. أنت مسؤول عن الحفاظ على سرية معلومات حسابك وكلمة المرور الخاصة بك.',
                        ),
                        _buildSection(
                          '4. المنتجات والأسعار',
                          'نحن نبذل قصارى جهدنا لضمان دقة معلومات المنتجات والأسعار المعروضة. ومع ذلك، قد تحدث أخطاء في بعض الأحيان. نحتفظ بالحق في تصحيح أي أخطاء وتحديث المعلومات في أي وقت.',
                        ),
                        _buildSection(
                          '5. الطلبات والدفع',
                          'يتم تأكيد الطلبات بعد استلام الدفع. نقبل طرق الدفع المتاحة في التطبيق. الأسعار المعروضة لا تشمل رسوم الشحن والتركيب ما لم يُذكر خلاف ذلك.',
                        ),
                        _buildSection(
                          '6. الشحن والتركيب',
                          'نقوم بتوصيل المنتجات إلى جميع المحافظات السورية. مدة التوصيل تعتمد على موقعك وتوفر المنتجات. خدمة التركيب متاحة بشكل منفصل ويمكن طلبها مع المنتج.',
                        ),
                        _buildSection(
                          '7. الضمان والصيانة',
                          'جميع المنتجات تأتي مع ضمان حسب سياسة الشركة المصنعة. نحن نوفر خدمة صيانة لما بعد البيع للمنتجات التي تم شراؤها من خلال منصتنا.',
                        ),
                        _buildSection(
                          '8. الخصوصية',
                          'نحن نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية. يرجى مراجعة سياسة الخصوصية الخاصة بنا لفهم كيفية جمع واستخدام معلوماتك.',
                        ),
                        _buildSection(
                          '9. التعديلات',
                          'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إخبارك بأي تغييرات جوهرية. استمرارك في استخدام التطبيق بعد التعديلات يعتبر موافقة على الشروط الجديدة.',
                        ),
                        _buildSection(
                          '10. الاتصال بنا',
                          'إذا كان لديك أي أسئلة حول هذه الشروط، يرجى الاتصال بنا عبر:\n📧 البريد الإلكتروني: support@nexsy.com',
                        ),
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
              Icons.description_rounded,
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
                  'الشروط والأحكام',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
