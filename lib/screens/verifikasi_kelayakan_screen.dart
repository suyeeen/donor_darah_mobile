import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/jadwal_donor.dart';
import '../providers/kuesioner_provider.dart';
import '../theme/app_theme.dart';
import 'pilih_slot_waktu_screen.dart';

class VerifikasiKelayakanScreen extends StatelessWidget {
  final JadwalDonor jadwal;

  const VerifikasiKelayakanScreen({super.key, required this.jadwal});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KuesionerProvider>();
    final lolos = provider.lolosSemua;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildHasilCard(lolos),
                    const SizedBox(height: 24),
                    for (final hasil in provider.daftarHasil) ...[
                      _buildChecklistItem(hasil),
                      const SizedBox(height: 12),
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
                  onPressed: lolos
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PilihSlotWaktuScreen(jadwal: jadwal),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.buttonDisabledBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    lolos ? 'Pilih Slot Waktu' : 'Belum memenuhi syarat',
                    style: AppText.button.copyWith(
                      color: lolos
                          ? Colors.white
                          : AppColors.buttonDisabledText,
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
                'LANGKAH 4 DARI 10',
                style: AppText.label.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.4,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sistem memeriksa interval donor dan kriteria dasar dari '
                'jawaban Anda.',
                style: AppText.helper.copyWith(fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHasilCard(bool lolos) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lolos ? AppColors.success : AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              lolos ? Icons.verified_outlined : Icons.error_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lolos ? 'Anda memenuhi syarat' : 'Belum memenuhi syarat',
            textAlign: TextAlign.center,
            style: AppText.headline.copyWith(color: Colors.white, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(
            lolos
                ? 'Silakan lanjut memilih slot waktu untuk mengambil nomor antrian.'
                : 'Cek kembali detail di bawah -- Anda bisa mengulang kuesioner '
                      'kalau ada jawaban yang perlu diperbaiki.',
            textAlign: TextAlign.center,
            style: AppText.helper.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(HasilVerifikasi hasil) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: hasil.lolos
                  ? const Color(0xFFE4F2E8)
                  : const Color(0xFFFBEAEA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasil.lolos ? Icons.check : Icons.close,
              size: 13,
              color: hasil.lolos ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasil.judul,
                  style: AppText.inputText.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasil.subjudul,
                  style: AppText.helper.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
