import 'package:GeniusHouse/screens/cart/cart_screen.dart';
import 'package:GeniusHouse/screens/settings_screen.dart';
import 'package:GeniusHouse/screens/system_builder/system_builder_screen.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/cart_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/services/system_builder_draft_service.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

bool _hasShownInThisSession = false;

Future<void> showUnifiedReminderDialog(BuildContext context) async {
  if (_hasShownInThisSession) return;

  final storageService = StorageService();
  if (!storageService.isShowUnifiedReminder()) {
    return;
  }

  final cartService = CartService.instance;
  final draftService = SystemBuilderDraftService.instance;

  await cartService.loadCart();
  await draftService.loadDraft();

  final bool hasCart = cartService.items.isNotEmpty;
  final bool hasDraft = draftService.hasDraft;

  if (!hasCart && !hasDraft) return;

  _hasShownInThisSession = true;

  final int cartItemCount = cartService.itemCount;
  final double cartTotal = cartService.totalPrice;
  final int draftItemCount = draftService.totalItems;

  HapticFeedback.mediumImpact();

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'تذكير',
    barrierColor: Colors.black.withOpacity(0.6),
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation, secondaryAnimation) {
      return SafeArea(
        child: Center(
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E3A8A).withOpacity(0.95),
                      const Color(0xFF3B82F6).withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Stack(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 20),
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.bounceOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                  scale: value, child: child);
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              child: Icon(
                                hasCart && hasDraft
                                    ? Icons.shopping_bag_rounded
                                    : hasCart
                                        ? Icons.shopping_cart_rounded
                                        : Icons.design_services_rounded,
                                size: 45,
                                color: Colors.yellow,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'لديك عناصر غير مكتملة!',
                            style: GoogleFonts.cairo(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 15),
                          if (hasCart) ...[
                            _buildReminderSection(
                              context: context,
                              icon: Icons.shopping_cart_rounded,
                              title: 'سلة المشتريات',
                              description:
                                  'لديك $cartItemCount ${cartItemCount == 1 ? 'منتج' : 'منتجات'} بقيمة ${Helpers.formatPrice(cartTotal)}',
                              buttonText: 'الذهاب للسلة',
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CartScreen(),
                                  ),
                                );
                              },
                            ),
                            if (hasDraft) const SizedBox(height: 15),
                          ],
                          if (hasDraft)
                            _buildReminderSection(
                              context: context,
                              icon: Icons.design_services_rounded,
                              title: 'مصمم المنظومة',
                              description:
                                  'لديك $draftItemCount ${draftItemCount == 1 ? 'عنصر' : 'عناصر'} مختارة في تصميم المنظومة',
                              buttonText: 'الذهاب لمصمم المنظومة',
                              onPressed: () {
                                Navigator.pop(context);
                                final storageService = StorageService();
                                final authService =
                                    AuthService(storageService: storageService);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SystemBuilderScreen(
                                      authService: authService,
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 18),
                          _buildSettingsHint(context),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.15),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 12),
                            ),
                            child: Text(
                              'متابعة التصفح',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildSettingsHint(BuildContext parentContext) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      splashColor: Colors.white.withOpacity(0.08),
      highlightColor: Colors.white.withOpacity(0.04),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(parentContext);
        Navigator.push(
          parentContext,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'يمكنك التحكم بهذا التذكير',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'من الإعدادات ← التذكيرات',
                    style: GoogleFonts.cairo(
                      fontSize: 10.5,
                      color: Colors.white.withOpacity(0.72),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildReminderSection({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String description,
  required String buttonText,
  required VoidCallback onPressed,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.yellow, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E3A8A),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              buttonText,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
