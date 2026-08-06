import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/kuesioner_provider.dart';
import '../services/profil_service.dart';
import '../theme/app_theme.dart';
import 'hasil_kuesioner_screen.dart';

/// FR-2.2: form isi kuesioner kesehatan pra-donor.
///
/// RESTRUKTURISASI Modul 2:
/// - Pertanyaan di-fetch dari GET /profil/kuesioner lewat
///   [KuesionerProvider.muatPertanyaan] -- TIDAK hardcode lagi.
/// - Field berat badan & jam tidur DIHAPUS -- itu data profil kesehatan
///   (PUT /profil), diisi lewat ProfilScreen, bukan di sini.
/// - TIDAK ada parameter `jadwal` -- berdiri sendiri, lepas dari booking.
class KuesionerScreen extends StatefulWidget {
  const KuesionerScreen({super.key});

  @override
  State<KuesionerScreen> createState() => _KuesionerScreenState();
}

class _KuesionerScreenState extends State<KuesionerScreen> {
  late final KuesionerProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = KuesionerProvider();
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      // Ditunda ke frame berikutnya biar gak notifyListeners() pas widget
      // masih dalam proses build pertama kali.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _provider.muatPertanyaan(token: token);
      });
    }
  }

  Future<void> _submit() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final sukses = await _provider.submit(token: token);
    if (!mounted) return;

    if (sukses) {
      // Sinkronin AuthProvider.riwayatKesehatan biar KuesionerIntroScreen
      // & ProfilScreen langsung nunjukin hasil terbaru tanpa perlu logout.
      unawaited(context.read<AuthProvider>().muatUlangProfil());

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: _provider,
            child: const HasilKuesionerScreen(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.errorMessage ?? 'Gagal mengirim kuesioner.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<KuesionerProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(child: _buildBody(context, provider)),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, KuesionerProvider provider) {
    if (provider.status == KuesionerStatus.memuat ||
        provider.status == KuesionerStatus.awal) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == KuesionerStatus.error &&
        provider.pertanyaan.isEmpty) {
      return _buildErrorState(context, provider);
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                for (final p in provider.pertanyaan) ...[
                  _buildPertanyaanCard(provider, p),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed:
                  (provider.semuaTerjawab &&
                      provider.status != KuesionerStatus.mengirim)
                  ? _submit
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.buttonDisabledBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: provider.status == KuesionerStatus.mengirim
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Kirim jawaban',
                      style: AppText.button.copyWith(
                        color: provider.semuaTerjawab
                            ? Colors.white
                            : AppColors.buttonDisabledText,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, KuesionerProvider provider) {
    final token = context.read<AuthProvider>().token;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage ?? 'Gagal memuat pertanyaan kuesioner.',
              textAlign: TextAlign.center,
              style: AppText.helper,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: token == null
                  ? null
                  : () => provider.muatPertanyaan(token: token),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KUESIONER KESEHATAN',
                style: AppText.label.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.4,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Jawab sejujurnya. Jawaban ini akan diverifikasi ulang '
                'oleh petugas di lokasi.',
                style: AppText.helper.copyWith(fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPertanyaanCard(
    KuesionerProvider provider,
    PertanyaanKuesioner p,
  ) {
    final jawabanSaatIni = provider.jawaban[p.kode];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.teks,
            style: AppText.inputText.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _jawabanButton(
                  label: 'ya',
                  aktif: jawabanSaatIni == 'ya',
                  onTap: () => provider.jawab(p.kode, true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _jawabanButton(
                  label: 'tidak',
                  aktif: jawabanSaatIni == 'tidak',
                  onTap: () => provider.jawab(p.kode, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _jawabanButton({
    required String label,
    required bool aktif,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 41.5,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: aktif ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: aktif ? AppColors.primary : AppColors.inputBorder,
          ),
        ),
        child: Text(
          label,
          style: AppText.tab.copyWith(
            fontSize: 13,
            color: aktif ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
