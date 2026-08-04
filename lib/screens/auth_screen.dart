import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _tabIndex = 0; // 0 = Masuk, 1 = Registrasi

  final _formKeyMasuk = GlobalKey<FormState>();
  final _teleponMasukController = TextEditingController();
  final _sandiMasukController = TextEditingController();

  // Form Registrasi
  final _formKeyDaftar = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _nikController = TextEditingController();
  final _teleponDaftarController = TextEditingController();
  final _sandiDaftarController = TextEditingController();

  @override
  void dispose() {
    _teleponMasukController.dispose();
    _sandiMasukController.dispose();
    _namaController.dispose();
    _nikController.dispose();
    _teleponDaftarController.dispose();
    _sandiDaftarController.dispose();
    super.dispose();
  }

  bool get _formDaftarTerisi =>
      _namaController.text.trim().isNotEmpty &&
      _nikController.text.trim().length == 16 &&
      _teleponDaftarController.text.trim().isNotEmpty &&
      _sandiDaftarController.text.isNotEmpty;

  Future<void> _submitMasuk() async {
    if (!_formKeyMasuk.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final sukses = await auth.login(
      _teleponMasukController.text.trim(),
      _sandiMasukController.text,
    );

    if (!mounted) return;

    if (sukses) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Masuk gagal')),
      );
    }
  }

  Future<void> _submitDaftar() async {
    if (!_formKeyDaftar.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final sukses = await auth.register(
      nik: _nikController.text.trim(),
      nama: _namaController.text.trim(),
      noTelepon: _teleponDaftarController.text.trim(),
      password: _sandiDaftarController.text,
    );

    if (!mounted) return;

    if (sukses) {
      // TODO: idealnya lempar ke screen "Lengkapi Profil" dulu (tanggal
      // lahir, jenis kelamin, golongan darah -- FR-2.1) sebelum ke Home,
      // karena data itu belum dikumpulkan di form registrasi ini.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Registrasi gagal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loading = auth.status == AuthStatus.authenticating;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIllustrationCard(),
              const SizedBox(height: 24),
              _buildTabList(),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _tabIndex == 0
                    ? _buildFormMasuk(loading)
                    : _buildFormDaftar(loading),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustrationCard() {
    return SizedBox(
      height: 292,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 279,
            height: 292,
            decoration: BoxDecoration(
              color: AppColors.neutralMuted,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Container(
            width: 245,
            height: 268,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  // NOTE: placeholder Material icon. Ganti pakai SVG asli
                  // hasil export dari Figma (node 4:265) kalau udah ada.
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'Ambil antrian donor tanpa mengantre.',
                    textAlign: TextAlign.center,
                    style: AppText.headline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabList() {
    return Container(
      height: 47.5,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.tabInactiveBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              'Masuk',
              _tabIndex == 0,
              () => setState(() => _tabIndex = 0),
            ),
          ),
          Expanded(
            child: _tabButton(
              'Registrasi',
              _tabIndex == 1,
              () => setState(() => _tabIndex = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        height: 39.5,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppText.tab.copyWith(
            color: active ? AppColors.textPrimary : AppColors.neutralMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildFormMasuk(bool loading) {
    return Form(
      key: _formKeyMasuk,
      child: Column(
        key: const ValueKey('form-masuk'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildField(
            label: 'Nomor ponsel',
            controller: _teleponMasukController,
            hint: '08xx-xxxx-xxxx',
            keyboardType: TextInputType.phone,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
          ),
          _buildField(
            label: 'Kata sandi',
            controller: _sandiMasukController,
            hint: '----------',
            obscure: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
          ),
          _buildPrivacyNote(),
          const SizedBox(height: 20),
          _buildPrimaryButton(
            label: 'Masuk dengan OTP',
            enabled: true,
            loading: loading,
            onTap: _submitMasuk,
          ),
        ],
      ),
    );
  }

  Widget _buildFormDaftar(bool loading) {
    return Form(
      key: _formKeyDaftar,
      onChanged: () => setState(() {}),
      child: Column(
        key: const ValueKey('form-daftar'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildField(
            label: 'Nama lengkap',
            controller: _namaController,
            hint: 'Sesuai KTP',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
          ),
          _buildField(
            label: 'NIK',
            controller: _nikController,
            hint: '16 digit',
            keyboardType: TextInputType.number,
            maxLength: 16,
            validator: (v) =>
                (v == null || v.length != 16) ? 'NIK harus 16 digit' : null,
          ),
          _buildField(
            label: 'Nomor ponsel',
            controller: _teleponDaftarController,
            hint: '08xx-xxxx-xxxx',
            keyboardType: TextInputType.phone,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
          ),
          _buildField(
            label: 'kata sandi',
            controller: _sandiDaftarController,
            hint: '-----------',
            obscure: true,
            validator: (v) =>
                (v == null || v.length < 8) ? 'Minimal 8 karakter' : null,
          ),
          _buildPrivacyNote(),
          const SizedBox(height: 20),
          _buildPrimaryButton(
            label: 'Buat akun pendonor',
            enabled: _formDaftarTerisi,
            loading: loading,
            onTap: _submitDaftar,
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
    int? maxLength,
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
            maxLength: maxLength,
            style: AppText.inputText,
            validator: validator,
            decoration: InputDecoration(
              counterText: '',
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            // NOTE: placeholder Material icon, ganti SVG shield asli dari
            // Figma kalau sudah diekspor.
            child: Icon(
              Icons.verified_user_outlined,
              size: 14,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Data Anda terhubung ke rekam donor PMI dan hanya digunakan '
              'untuk verifikasi kelayakan.',
              style: AppText.helper,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: enabled && !loading ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.buttonDisabledBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: AppText.button.copyWith(
                  color: enabled ? Colors.white : AppColors.buttonDisabledText,
                ),
              ),
      ),
    );
  }
}
