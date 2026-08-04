import 'package:flutter/material.dart';
import '../models/jadwal_donor.dart';
import '../theme/app_theme.dart';
import 'kuesioner_screen.dart';

class KuesionerIntroScreen extends StatelessWidget {
  final JadwalDonor jadwal;

  const KuesionerIntroScreen({super.key, required this.jadwal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildJadwalCard(),
              const SizedBox(height: 16),
              _buildKuotaRow(),
              const SizedBox(height: 16),
              _buildSebelumLanjutCard(),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KuesionerScreen(jadwal: jadwal),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Mulai kuesioner kesehatan',
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
                'LANGKAH 2 DARI 5',
                style: AppText.label.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.4,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Detail kegiatan donor',
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

  Widget _buildJadwalCard() {
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
            jadwal.namaKegiatan ??
                'Donor Darah Bersama ${jadwal.lokasi.namaLokasi}',
            style: AppText.headline.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.badge_outlined,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PMI ${jadwal.lokasi.namaLokasi}',
                  style: AppText.helper.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(
            Icons.calendar_today_outlined,
            'Tanggal',
            '${jadwal.tanggal.day}/${jadwal.tanggal.month}/${jadwal.tanggal.year}',
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.access_time, 'Jam operasional', jadwal.slotWaktu),
          const SizedBox(height: 12),
          _infoRow(
            Icons.location_on_outlined,
            'Lokasi',
            '${jadwal.lokasi.namaLokasi}\n${jadwal.lokasi.alamat}',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.neutralMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AppText.label.copyWith(
                  color: AppColors.neutralMuted,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: AppText.inputText.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKuotaRow() {
    return Row(
      children: [
        Expanded(child: _kuotaChip('Kuota', '${jadwal.kuotaTotal}')),
        const SizedBox(width: 8),
        Expanded(child: _kuotaChip('Terisi', '${jadwal.kuotaTerisi}')),
        const SizedBox(width: 8),
        Expanded(child: _kuotaChip('Sisa', '${jadwal.kuotaTersisa}')),
      ],
    );
  }

  Widget _kuotaChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tabInactiveBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.label.copyWith(
              color: AppColors.neutralMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppText.headline.copyWith(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSebelumLanjutCard() {
    const poin = [
      'Isi kuesioner kesehatan pra-donor (self-assessment) — sekitar 1 menit.',
      'Sistem akan memverifikasi interval donor 90 hari dan kelayakan dasar Anda.',
      'Setelah lolos, Anda dapat memilih slot waktu dan mengambil nomor antrian.',
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
            'Sebelum lanjut',
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
}
