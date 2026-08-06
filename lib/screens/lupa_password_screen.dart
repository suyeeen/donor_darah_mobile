import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// FR-1.3: Lupa Kata Sandi. Backend cuma expose 2 endpoint terpisah
/// (forgot-password kirim link/token ke email, reset-password submit
/// token+password baru) -- TIDAK ada deep link handling di app ini
/// (reset_link di email berbentuk URL web `<base_url>/reset-password?
/// token=...`), jadi screen ini dibikin 2 tahap manual:
///   Tahap 1: masukin email -> server "kirim" instruksi ke email
///   Tahap 2: user tempel token dari email + isi password baru
class LupaPasswordScreen extends StatefulWidget {
  const LupaPasswordScreen({super.key});

  @override
  State<LupaPasswordScreen> createState() => _LupaPasswordScreenState();
}

class _LupaPasswordScreenState extends State<LupaPasswordScreen> {
  int _tahap = 1;
  bool _loading = false;
  String? _pesanError;
  String? _pesanSukses;

  final _formKey1 = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  final _formKey2 = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordBaruController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordBaruController.dispose();
    super.dispose();
  }

  Future<void> _submitTahap1() async {
    if (!_formKey1.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _pesanError = null;
    });

    final auth = context.read<AuthProvider>();
    final devToken = await auth.lupaPassword(_emailController.text.trim());

    if (!mounted) return;
    setState(() {
      _loading = false;
      _pesanSukses =
          'Jika email terdaftar, instruksi atur ulang kata sandi telah '
          'dikirim. Buka email tersebut, salin tokennya, lalu lanjutkan '
          'di bawah.';
      _tahap = 2;
      // Backend cuma nyelipin token asli kalau SMTP belum aktif di
      // server (testing lokal) -- kalau ada, isikan otomatis biar nggak
      // perlu copy-paste manual dari log server.
      if (devToken != null) _tokenController.text = devToken;
    });
  }

  Future<void> _submitTahap2() async {
    if (!_formKey2.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _pesanError = null;
    });

    final auth = context.read<AuthProvider>();
    final sukses = await auth.resetPassword(
      token: _tokenController.text.trim(),
      passwordBaru: _passwordBaruController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (sukses) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kata sandi berhasil diatur ulang, silakan masuk kembali',
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      setState(() => _pesanError = auth.errorMessage ?? 'Gagal reset password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text('Lupa Kata Sandi', style: AppText.label),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 24),
          child: _tahap == 1 ? _buildTahap1() : _buildTahap2(),
        ),
      ),
    );
  }

  Widget _buildTahap1() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Masukkan email akun kamu. Kami akan kirim instruksi atur '
            'ulang kata sandi ke email tersebut.',
            style: AppText.helper,
          ),
          const SizedBox(height: 20),
          _buildField(
            label: 'Email',
            controller: _emailController,
            hint: 'nama@email.com',
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@'))
                ? 'Masukkan email yang valid'
                : null,
          ),
          if (_pesanError != null) ...[
            const SizedBox(height: 8),
            Text(
              _pesanError!,
              style: AppText.helper.copyWith(color: AppColors.primary),
            ),
          ],
          const SizedBox(height: 12),
          _buildButton('Kirim Instruksi', _submitTahap1),
        ],
      ),
    );
  }

  Widget _buildTahap2() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_pesanSukses != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tabInactiveBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_pesanSukses!, style: AppText.helper),
            ),
            const SizedBox(height: 20),
          ],
          _buildField(
            label: 'Token dari email',
            controller: _tokenController,
            hint: 'Tempel token di sini',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
          ),
          _buildField(
            label: 'Kata sandi baru',
            controller: _passwordBaruController,
            hint: 'Minimal 8 karakter',
            obscure: true,
            validator: (v) =>
                (v == null || v.length < 8) ? 'Minimal 8 karakter' : null,
          ),
          if (_pesanError != null) ...[
            const SizedBox(height: 8),
            Text(
              _pesanError!,
              style: AppText.helper.copyWith(color: AppColors.primary),
            ),
          ],
          const SizedBox(height: 12),
          _buildButton('Atur Ulang Kata Sandi', _submitTahap2),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _tahap = 1;
                _pesanError = null;
              }),
              child: Text(
                'Belum dapat token? Kirim ulang',
                style: AppText.helper.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: AppText.inputText,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppText.placeholder,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 17,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onTap) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label, style: AppText.button.copyWith(color: Colors.white)),
      ),
    );
  }
}
