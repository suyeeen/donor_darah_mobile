import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

/// FR-1.1: input kode OTP 6 digit yang dikirim ke email setelah registrasi.
/// Dibuka dari AuthScreen begitu AuthProvider.status == AuthStatus.menungguOtp.
class VerifikasiOtpScreen extends StatefulWidget {
  const VerifikasiOtpScreen({super.key});

  @override
  State<VerifikasiOtpScreen> createState() => _VerifikasiOtpScreenState();
}

class _VerifikasiOtpScreenState extends State<VerifikasiOtpScreen> {
  static const _panjangOtp = 6;
  // Cooldown default awal (detik) sebelum tombol "Kirim Ulang" aktif --
  // cuma perkiraan lokal (backend tidak expose nilai
  // otp_resend_cooldown_seconds lewat API). Kalau tombol dipencet lebih
  // cepat dari cooldown asli server, _sinkronkanCooldownDariPesanError()
  // di bawah bakal koreksi otomatis dari pesan error 429.
  static const _cooldownAwalDetik = 60;

  final List<TextEditingController> _controllers = List.generate(
    _panjangOtp,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _panjangOtp,
    (_) => FocusNode(),
  );

  Timer? _timer;
  int _sisaCooldown = _cooldownAwalDetik;

  @override
  void initState() {
    super.initState();
    _mulaiCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _mulaiCooldown([int dari = _cooldownAwalDetik]) {
    _timer?.cancel();
    setState(() => _sisaCooldown = dari);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_sisaCooldown <= 1) {
        t.cancel();
        setState(() => _sisaCooldown = 0);
      } else {
        setState(() => _sisaCooldown--);
      }
    });
  }

  String get _kodeOtp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < _panjangOtp - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    // Auto-submit begitu 6 digit lengkap
    if (_kodeOtp.length == _panjangOtp) {
      FocusScope.of(context).unfocus();
      _submit();
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (_kodeOtp.length != _panjangOtp) return;

    final auth = context.read<AuthProvider>();
    final sukses = await auth.verifyOtp(_kodeOtp);

    if (!mounted) return;

    if (sukses) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      // Kosongkan input & fokus ke digit pertama biar gampang input ulang
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      _sinkronkanCooldownDariPesanError(auth.otpErrorMessage);
      setState(() {});
    }
  }

  Future<void> _kirimUlang() async {
    if (_sisaCooldown > 0) return;
    final auth = context.read<AuthProvider>();
    final sukses = await auth.resendOtp();

    if (!mounted) return;

    if (sukses) {
      _mulaiCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode OTP baru sudah dikirim')),
      );
    } else {
      _sinkronkanCooldownDariPesanError(auth.otpErrorMessage);
    }
  }

  /// Backend balikin pesan kayak "Mohon tunggu 42 detik sebelum minta kode
  /// baru" pas 429 -- kalau ketemu, sinkronkan cooldown lokal biar akurat.
  void _sinkronkanCooldownDariPesanError(String? pesan) {
    if (pesan == null) return;
    final match = RegExp(r'tunggu (\d+) detik').firstMatch(pesan);
    if (match != null) {
      final detik = int.tryParse(match.group(1) ?? '');
      if (detik != null) _mulaiCooldown(detik);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.emailMenungguOtp ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 24),
              Text('Verifikasi Email', style: AppText.headline),
              const SizedBox(height: 8),
              Text(
                'Kami sudah kirim kode OTP 6 digit ke $email. '
                'Masukkan kodenya di bawah ini${auth.otpBerlakuMenit != null ? ' (berlaku ${auth.otpBerlakuMenit} menit)' : ''}.',
                style: AppText.helper,
              ),
              if (auth.otpDevOnly != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.tabInactiveBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'DEV ONLY -- kode OTP: ${auth.otpDevOnly} '
                    '(muncul karena gateway email belum dikonfigurasi di server)',
                    style: AppText.helper.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_panjangOtp, _buildDigitBox),
              ),
              if (auth.otpErrorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  auth.otpErrorMessage!,
                  style: AppText.helper.copyWith(color: AppColors.primary),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: (auth.otpLoading || _kodeOtp.length != _panjangOtp)
                      ? null
                      : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.buttonDisabledBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: auth.otpLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Verifikasi',
                          style: AppText.button.copyWith(color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _sisaCooldown > 0 ? null : _kirimUlang,
                  child: Text(
                    _sisaCooldown > 0
                        ? 'Kirim ulang kode (${_sisaCooldown}s)'
                        : 'Kirim ulang kode',
                    style: AppText.helper.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _sisaCooldown > 0
                          ? AppColors.neutralMuted
                          : AppColors.primary,
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

  Widget _buildDigitBox(int index) {
    return SizedBox(
      width: 44,
      height: 52,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppText.headline.copyWith(fontSize: 22),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        onChanged: (value) => _onDigitChanged(index, value),
      ),
    );
  }
}
