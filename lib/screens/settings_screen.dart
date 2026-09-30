// lib/screens/settings_screen.dart

import 'dart:ui' as ui;

import 'package:GeniusHouse/screens/legal/privacy_screen.dart';
import 'package:GeniusHouse/screens/legal/terms_screen.dart';
import 'package:GeniusHouse/services/font_scale_manager.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  late AnimationController _pulseController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

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
                                  AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, child) =>
                                        Transform.scale(
                                      scale:
                                          1.0 + (_pulseController.value * 0.1),
                                      child: child,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.settings_rounded,
                                          color: Colors.white, size: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'الإعدادات',
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
                  padding: const EdgeInsets.all(16),
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
                        _buildSectionHeader('المظهر', Icons.palette_rounded),
                        const SizedBox(height: 12),
                        _buildFontSizeCard(context),
                        const SizedBox(height: 24),
                        _buildCurrencyCard(context),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                            'واجهة البداية', Icons.dashboard_customize_rounded),
                        const SizedBox(height: 12),
                        _buildEntryHubCard(context),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                            'التذكيرات', Icons.notifications_active_rounded),
                        const SizedBox(height: 12),
                        _buildUnifiedReminderCard(context),
                        const SizedBox(height: 24),
                        _buildSectionHeader('قانوني', Icons.gavel_rounded),
                        const SizedBox(height: 12),
                        _buildLegalCard(context),
                        const SizedBox(height: 24),
                        _buildAppInfoCard(),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryBlue.withOpacity(0.12),
                secondaryBlue.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: primaryBlue),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeCard(BuildContext context) {
    return Consumer<FontScaleNotifier>(
      builder: (context, fontScaleNotifier, child) {
        return _buildBaseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIconBox(Icons.text_fields_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حجم الخط',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: darkColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${fontScaleNotifier.label} (${fontScaleNotifier.percentage.round()}%)',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (fontScaleNotifier.scale != 1.0)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          fontScaleNotifier.reset();
                          _showSnackBar(context, 'تم إعادة تعيين حجم الخط');
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightGray,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معاينة النص',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: mediumGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'هذا مثال توضيحي لحجم الخط الحالي في التطبيق',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: darkColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'يمكنك تغيير حجم الخط من الشريط أدناه',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.text_decrease_rounded,
                      size: 22, color: Colors.grey.shade500),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: primaryBlue,
                        inactiveTrackColor: Colors.grey.shade200,
                        thumbColor: primaryBlue,
                        overlayColor: primaryBlue.withOpacity(0.2),
                        trackHeight: 6,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 10),
                      ),
                      child: Slider(
                        value: fontScaleNotifier.scale,
                        min: 0.7,
                        max: 2.0,
                        divisions: 13,
                        onChanged: (value) {
                          fontScaleNotifier.setScale(value);
                        },
                        onChangeEnd: (value) {
                          HapticFeedback.selectionClick();
                        },
                      ),
                    ),
                  ),
                  Icon(Icons.text_increase_rounded,
                      size: 22, color: Colors.grey.shade500),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildQuickSizeButton(
                    fontScaleNotifier,
                    label: 'صغير',
                    scale: 0.8,
                    currentScale: fontScaleNotifier.scale,
                  ),
                  const SizedBox(width: 8),
                  _buildQuickSizeButton(
                    fontScaleNotifier,
                    label: 'عادي',
                    scale: 1.0,
                    currentScale: fontScaleNotifier.scale,
                  ),
                  const SizedBox(width: 8),
                  _buildQuickSizeButton(
                    fontScaleNotifier,
                    label: 'كبير',
                    scale: 1.5,
                    currentScale: fontScaleNotifier.scale,
                  ),
                  const SizedBox(width: 8),
                  _buildQuickSizeButton(
                    fontScaleNotifier,
                    label: 'كبير جداً',
                    scale: 2.0,
                    currentScale: fontScaleNotifier.scale,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencyCard(BuildContext context) {
    final storageService = context.read<StorageService>();
    final currentCurrency = storageService.getPreferredCurrency();
    final isUsd = currentCurrency == StorageService.currencyUsd;

    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconBox(Icons.attach_money_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'عملة عرض الأسعار',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUsd
                          ? 'الأسعار تظهر بالدولار الأمريكي (\$)'
                          : 'الأسعار تظهر بالليرة السورية (ل.س)',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHubOption(
            title: 'الدولار الأمريكي (\$)',
            subtitle: 'عرض الأسعار بعملة الدولار',
            icon: Icons.attach_money_rounded,
            isSelected: isUsd,
            onTap: () async {
              HapticFeedback.selectionClick();
              await storageService.savePreferredCurrency(
                StorageService.currencyUsd,
              );
              if (mounted) {
                setState(() {});
                _showSnackBar(context, 'تم اختيار الدولار الأمريكي');
              }
            },
          ),
          const SizedBox(height: 10),
          _buildHubOption(
            title: 'الليرة السورية (ل.س)',
            subtitle: 'عرض الأسعار بعملة الليرة السورية',
            icon: Icons.currency_exchange_rounded,
            isSelected: !isUsd,
            onTap: () async {
              HapticFeedback.selectionClick();
              await storageService.savePreferredCurrency(
                StorageService.currencySyp,
              );
              if (mounted) {
                setState(() {});
                _showSnackBar(context, 'تم اختيار الليرة السورية');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSizeButton(
    FontScaleNotifier notifier, {
    required String label,
    required double scale,
    required double currentScale,
  }) {
    final isSelected = (currentScale - scale).abs() < 0.05;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        notifier.setScale(scale);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [primaryBlue, secondaryBlue])
              : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildEntryHubCard(BuildContext context) {
    final storageService = context.read<StorageService>();
    final isAlwaysShowHub = storageService.isAlwaysShowHub();

    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconBox(Icons.dashboard_customize_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'شاشة الدخول',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'تحكم في الشاشة التي تظهر عند فتح التطبيق',
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
          const SizedBox(height: 16),
          _buildHubOption(
            title: 'عرض واجهة البداية دائماً',
            subtitle: 'شاشة اختيار الأقسام (تصفح، صيانة، شمسية، إنارة)',
            icon: Icons.apps_rounded,
            isSelected: isAlwaysShowHub,
            onTap: () async {
              HapticFeedback.selectionClick();
              await storageService.saveAlwaysShowHub(true);
              if (mounted) {
                setState(() {});
                _showSnackBar(context, 'سيتم عرض واجهة البداية دائماً');
              }
            },
          ),
          const SizedBox(height: 10),
          _buildHubOption(
            title: 'الدخول مباشرة إلى التطبيق',
            subtitle: 'تجاوز واجهة البداية والانتقال للصفحة الرئيسية',
            icon: Icons.home_rounded,
            isSelected: !isAlwaysShowHub,
            onTap: () async {
              HapticFeedback.selectionClick();
              await storageService.saveAlwaysShowHub(false);
              if (mounted) {
                setState(() {});
                _showSnackBar(context, 'سيتم الدخول مباشرة إلى التطبيق');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedReminderCard(BuildContext context) {
    final storageService = context.read<StorageService>();
    final isShowReminder = storageService.isShowUnifiedReminder();

    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconBox(Icons.notifications_active_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تذكير السلة والتصميم',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'تنبيه يظهر عند وجود عناصر غير مكتملة',
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
          const SizedBox(height: 16),
          _buildHubOption(
            title: 'إظهار التذكير عند فتح التطبيق',
            subtitle: 'سيظهر تنبيه في حال وجود عناصر في السلة أو مسودة تصميم',
            icon: Icons.notifications_on_rounded,
            isSelected: isShowReminder,
            onTap: () async {
              HapticFeedback.selectionClick();
              await storageService.saveShowUnifiedReminder(true);
              if (mounted) {
                setState(() {});
                _showSnackBar(context, 'سيظهر التذكير عند فتح التطبيق');
              }
            },
          ),
          const SizedBox(height: 10),
          _buildHubOption(
            title: 'عدم إظهار التذكير',
            subtitle: 'لن يظهر التنبيه التلقائي عند فتح التطبيق',
            icon: Icons.notifications_off_rounded,
            isSelected: !isShowReminder,
            onTap: () async {
              HapticFeedback.selectionClick();
              await storageService.saveShowUnifiedReminder(false);
              if (mounted) {
                setState(() {});
                _showSnackBar(context, 'لن يظهر التذكير تلقائياً');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHubOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    primaryBlue.withOpacity(0.08),
                    secondaryBlue.withOpacity(0.04),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                )
              : null,
          color: isSelected ? null : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primaryBlue.withOpacity(0.4)
                : Colors.grey.shade200,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryBlue.withOpacity(0.12)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? primaryBlue : Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? darkColor : mediumGray,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: mediumGray,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primaryBlue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? primaryBlue : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalCard(BuildContext context) {
    return _buildBaseCard(
      child: Column(
        children: [
          _buildLegalItem(
            context,
            icon: Icons.description_rounded,
            title: 'الشروط والأحكام',
            subtitle: 'تعرف على شروط استخدام التطبيق',
            iconColor: Colors.blue,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermsScreen()),
              );
            },
          ),
          const Divider(height: 24),
          _buildLegalItem(
            context,
            icon: Icons.privacy_tip_rounded,
            title: 'سياسة الخصوصية',
            subtitle: 'كيف نحمي بياناتك وخصوصيتك',
            iconColor: Colors.purple,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegalItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withOpacity(0.12),
                      iconColor.withOpacity(0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: darkColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return _buildBaseCard(
      child: Column(
        children: [
          _buildInfoRow('الإصدار', 'v1.0.0'),
          const Divider(height: 20),
          _buildInfoRow('العلامة التجارية', 'NEX'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: mediumGray,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: darkColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBaseCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryBlue.withOpacity(0.12),
            secondaryBlue.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: primaryBlue, size: 24),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(message, style: GoogleFonts.cairo(fontSize: 13)),
          ],
        ),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 1),
      ));
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
