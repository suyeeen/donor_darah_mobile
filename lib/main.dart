import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/jadwal_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/antrian_provider.dart';
import 'providers/notifikasi_provider.dart';
import 'providers/riwayat_provider.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';

// Handler background HARUS top-level function (bukan method di dalam
// class), ini syarat dari Firebase -- dijalanin di isolate terpisah pas
// app dalam keadaan tertutup total/killed.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // GAP: di titik ini biasanya cukup nyimpen notifikasi ke local storage
  // (SharedPreferences/SQLite) buat ditampilin di NotifikasiScreen pas app
  // dibuka lagi -- nggak bisa update Provider di sini karena app belum
  // "hidup" (isolate terpisah dari UI).
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  await PushNotificationService.instance.initLocalNotifications();

  runApp(const AmpiraApp());
}

class AmpiraApp extends StatelessWidget {
  const AmpiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JadwalProvider()),
        ChangeNotifierProvider(create: (_) => AntrianProvider()),
        ChangeNotifierProvider(create: (_) => NotifikasiProvider()),
        ChangeNotifierProvider(create: (_) => RiwayatProvider()),
      ],
      child: MaterialApp(
        title: 'Ampira - Donor Darah',
        debugShowCheckedModeBanner: false,
        navigatorKey: PushNotificationService.navigatorKey,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            surface: AppColors.background,
          ),
          textTheme: Typography.material2021().black.apply(
            fontFamily: AppText.inputText.fontFamily,
          ),
        ),
        home: const SplashScreen(),
        // Dipakai PushNotificationService buat lempar user ke tab Antrian
        // pas notifikasi di-tap (dari kondisi app di-minimize ataupun
        // ke-tutup total).
        onGenerateRoute: (settings) {
          if (settings.name == '/antrian') {
            return MaterialPageRoute(
              builder: (_) => const HomeScreen(initialTabIndex: 1),
            );
          }
          return null;
        },
      ),
    );
  }
}
