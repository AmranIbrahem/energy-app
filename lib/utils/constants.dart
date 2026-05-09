class AppConstants {
  // API Base URL
  static const String baseUrl = 'https://aa-dev.site/energy/api';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String governorateKey = 'user_governorate';
  static const String isOnboardingSeenKey = 'onboarding_seen';
  static const String isGuestModeKey = 'is_guest_mode';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxProductsPerPage = 20;

  // Syrian Governorates
  static const List<String> syrianGovernorates = [
    'دمشق',
    'ريف دمشق',
    'حلب',
    'حمص',
    'حماة',
    'اللاذقية',
    'طرطوس',
    'إدلب',
    'دير الزور',
    'الحسكة',
    'الرقة',
    'درعا',
    'السويداء',
    'القنيطرة',
  ];

  // Colors
  static const int primaryColorValue = 0xFF4CAF50;
  static const int secondaryColorValue = 0xFFFF9800;
  static const int darkColorValue = 0xFF1B5E20;

  // Onboarding Data
  static final List<Map<String, String>> onboardingData = [
    {
      'title': 'مرحباً بك في متجر الطاقة البديلة',
      'description': 'أكبر متجر إلكتروني متخصص في الطاقة الشمسية والبديلة في سوريا',
      'image': 'assets/images/onboarding1.png',
    },
    {
      'title': 'منتجات أصلية بأسعار منافسة',
      'description': 'نوفر لك أفضل العلامات التجارية مع ضمان الجودة وأسعار تنافسية',
      'image': 'assets/images/onboarding2.png',
    },
    {
      'title': 'استشارات مجانية ودعم فني',
      'description': 'فريقنا المتخصص يقدم لك استشارات مجانية ويدعمك في اختيار النظام المناسب',
      'image': 'assets/images/onboarding3.png',
    },
  ];
}