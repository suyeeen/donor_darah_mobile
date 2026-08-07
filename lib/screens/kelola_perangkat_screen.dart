import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// FR-1.4: Kelola Perangkat -- GANTI TOTAL dari versi lama yang pakai
/// data dummy. Sekarang konek ke GET /auth/sessions asli.
///
/// PENTING soal keterbatasan backend: endpoint POST /auth/logout-others
/// TIDAK menerima parameter device/sesi tertentu -- dia logout SEMUA
/// sesi lain sekaligus (lihat Auth::logout_others() & Session_model::
/// logout_all_except()). Backend juga tidak expose cara logout SATU
/// device lain secara selektif. Makanya UI di sini SENGAJA cuma punya
/// 1 tombol aksi ("Keluar dari semua perangkat lain") di bawah, bukan
/// tombol logout per baris seperti versi dummy lama -- itu janji UI
/// yang backend tidak bisa penuhi.
class KelolaPerangkatScreen extends StatefulWidget {
  const KelolaPerangkatScreen({super.key});

  @override
  State<KelolaPerangkatScreen> createState() => _KelolaPerangkatScreenState();
}

class _KelolaPerangkatScreenState extends State<KelolaPerangkatScreen> {
  final _authService = AuthService();

  List<SesiPerangkat> _daftarSesi = [];
  bool _loading = true;
  bool _memprosesLogoutOthers = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _muatSesi());
  }

  Future<void> _muatSesi() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final daftar = await _authService.sessions(token: token);
      if (!mounted) return;
      setState(() {
        _daftarSesi = daftar;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _konfirmasiLogoutOthers() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari semua perangkat lain?'),
        content: Text(
          'Semua sesi login selain perangkat yang sedang Anda pakai '
          'sekarang akan langsung logout.',
          style: AppText.helper,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _memprosesLogoutOthers = true);

    try {
      await _authService.logoutOthers(token: token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil logout dari perangkat lain')),
      );
      await _muatSesi();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _memprosesLogoutOthers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _buildHeader(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Text(
                'Perangkat yang sedang login ke akun Anda. Kalau ada yang '
                'tidak dikenali, keluarkan semua perangkat lain sekaligus '
                'demi keamanan akun.',
                style: AppText.helper,
              ),
            ),
            Expanded(child: _buildBody()),
            if (_daftarSesi.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _memprosesLogoutOthers
                        ? null
                        : _konfirmasiLogoutOthers,
                    icon: _memprosesLogoutOthers
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout, size: 18),
                    label: const Text('Keluar dari semua perangkat lain'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppText.helper,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _muatSesi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Coba lagi',
                  style: AppText.button.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_daftarSesi.isEmpty) {
      return Center(
        child: Text('Tidak ada sesi aktif ditemukan', style: AppText.helper),
      );
    }

    return RefreshIndicator(
      onRefresh: _muatSesi,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: _daftarSesi.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _buildSesiCard(_daftarSesi[i], i == 0),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        const SizedBox(width: 15),
        Text(
          'Kelola Perangkat',
          style: AppText.headline.copyWith(fontSize: 20),
        ),
      ],
    );
  }

  // GAP: backend get_active_sessions() ORDER BY last_active_at DESC --
  // artinya baris PALING ATAS itu yang paling baru aktif, BUKAN
  // dijamin selalu "perangkat ini". Dipakai sebagai proxy terbaik yang
  // ada tanpa decode JWT manual di client. Kalau butuh 100% akurat,
  // backend perlu ditambah field semacam `is_current` yang membandingkan
  // jti dari token request ini.
  Widget _buildSesiCard(SesiPerangkat sesi, bool kemungkinanPerangkatIni) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.tabInactiveBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _ikonUntukDeviceInfo(sesi.deviceInfo),
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        sesi.deviceInfo ?? 'Perangkat tidak diketahui',
                        style: AppText.inputText.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (kemungkinanPerangkatIni) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Paling baru aktif',
                          style: AppText.chip.copyWith(
                            fontSize: 9.5,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatWaktu(sesi.lastActiveAt)} · ${sesi.ipAddress ?? '-'}',
                  style: AppText.helper,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _ikonUntukDeviceInfo(String? deviceInfo) {
    final info = (deviceInfo ?? '').toLowerCase();
    if (info.contains('chrome') ||
        info.contains('firefox') ||
        info.contains('safari') ||
        info.contains('edge')) {
      return Icons.laptop_mac_outlined;
    }
    return Icons.smartphone_outlined;
  }

  String _formatWaktu(DateTime? waktu) {
    if (waktu == null) return 'Tidak diketahui';
    final selisih = DateTime.now().difference(waktu);
    if (selisih.inMinutes < 1) return 'Aktif baru saja';
    if (selisih.inMinutes < 60) return 'Aktif ${selisih.inMinutes} menit lalu';
    if (selisih.inHours < 24) return 'Aktif ${selisih.inHours} jam lalu';
    return 'Aktif ${selisih.inDays} hari lalu';
  }
}
