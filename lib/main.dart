import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:GeniusHouse/utils/constants.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/services/font_scale_manager.dart';
import 'package:GeniusHouse/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:GeniusHouse/services/notification_service.dart';
import 'package:GeniusHouse/services/cart_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();
  await Firebase.initializeApp();

  await NotificationService().init();

  final authService = AuthService(storageService: storageService);

  await CartService.instance.loadCart();

  await FontScaleManager.load();

  runApp(MyApp(
    authService: authService,
    storageService: storageService,
  ));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final StorageService storageService;

  const MyApp({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        Provider.value(value: storageService),

        ChangeNotifierProvider<FontScaleNotifier>(
          create: (_) => FontScaleNotifier(),
        ),
      ],
      child: Consumer<FontScaleNotifier>(
        builder: (context, fontScaleNotifier, child) {
          return MaterialApp(
            title: 'متجر الطاقة البديلة',
            debugShowCheckedModeBanner: false,

            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: fontScaleNotifier.scale,
                ),
                child: child!,
              );
            },
            theme: ThemeData(
              primaryColor: const Color(AppConstants.primaryColorValue),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(AppConstants.primaryColorValue),
                primary: const Color(AppConstants.primaryColorValue),
                secondary: const Color(AppConstants.secondaryColorValue),
              ),
              fontFamily: 'Cairo',
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                elevation: 0,
                centerTitle: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                titleTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Color(AppConstants.primaryColorValue),
                unselectedItemColor: Colors.grey,
                showUnselectedLabels: true,
              ),
            ),
            home: SplashScreen(
              authService: authService,
              storageService: storageService,
            ),
          );
        },
      ),
    );
  }
}