import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _mulai());
  }

  Future<void> _mulai() async {
    final auth = context.read<AuthProvider>();
    await auth.cekSesiTersimpan();
    if (!mounted) return;

    final tujuan = auth.status == AuthStatus.authenticated
        ? const HomeScreen()
        : const AuthScreen();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => tujuan),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bloodtype, size: 72, color: AppColors.primary),
            SizedBox(height: 16),
            Text('Ampira', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
            SizedBox(height: 24),
            CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
