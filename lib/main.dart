import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/jadwal_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/antrian_provider.dart';
import 'providers/riwayat_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
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
        ChangeNotifierProvider(create: (_) => RiwayatProvider()),
      ],
      child: MaterialApp(
        title: 'Ampira - Donor Darah',
        debugShowCheckedModeBanner: false,
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
      ),
    );
  }
}
