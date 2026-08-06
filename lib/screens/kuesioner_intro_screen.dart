import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pendonor.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'kuesioner_screen.dart';

/// FR-2.2: pintu masuk kuesioner kesehatan pra-donor.
///
/// RESTRUKTURISASI Modul 2: dulu dibuka dari DetailJadwalScreen dengan
/// parameter [jadwal] (nempel ke satu booking, langkah 2 dari 5). Sekarang
/// berdiri sendiri di tab Pengaturan > Profil saya, TIDAK butuh jadwal
/// apa pun -- kuesioner adalah bagian dari profil kesehatan pendonor,
/// bisa diisi/diperbarui kapan saja, independen dari sedang booking atau
/// tidak.
class KuesionerIntroScreen extends StatelessWidget {
  const KuesionerIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final riwayat = context.watch<AuthProvider>().riwayatKesehatan;
    final hasilKuesioner = riwayat?.hasilKuesioner;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              if (hasilKuesioner != null) ...[
                _buildStatusTerakhirCard(hasilKuesioner),
                const SizedBox(height: 16),
              ],
              _buildInfoCard(),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KuesionerScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    hasilKuesioner != null
                        ? 'Isi ulang kuesioner'
                        : 'Mulai kuesioner kesehatan',
                    style: AppText.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backButton(context),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROFIL KESEHATAN',
                style: AppText.label.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.4,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Kuesioner kesehatan pra-donor',
                style: AppText.headline.copyWith(fontSize: 19),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _backButton(BuildContext context) {
    return Container(
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
    );
  }

  Widget _buildStatusTerakhirCard(HasilKuesioner hasil) {
    final lolos = hasil.hasilScreeningAwal == 'lolos_screening_awal';
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: lolos ? AppColors.success : AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(
            lolos ? Icons.verified_outlined : Icons.info_outline,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lolos
                      ? 'Hasil terakhir: lolos self-assessment'
                      : 'Hasil terakhir: perlu pemeriksaan lanjutan',
                  style: AppText.inputText.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (hasil.diisiPada != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Diisi ${_formatTanggal(hasil.diisiPada!)}',
                    style: AppText.helper.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    const poin = [
      'Jawab sejujurnya -- ini self-assessment awal, bukan keputusan final.',
      'Hasilnya HANYA gambaran awal; kelayakan donor tetap ditentukan '
          'petugas medis/skrining saat Anda datang ke lokasi.',
      'Bisa diisi ulang kapan saja lewat halaman ini kalau ada perubahan '
          'kondisi kesehatan.',
    ];

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yang perlu diketahui',
            style: AppText.headline.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 12),
          for (final p in poin)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '•  $p',
                style: AppText.helper.copyWith(fontSize: 12.5),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTanggal(DateTime tanggal) {
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${tanggal.day} ${bulan[tanggal.month - 1]} ${tanggal.year}';
  }
}
