import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kuesioner_provider.dart';
import '../theme/app_theme.dart';

/// FR-2.2: tampilan hasil kuesioner kesehatan pra-donor.
///
/// GANTI TOTAL dari VerifikasiKelayakanScreen versi lama: dulu layar ini
/// MENGHITUNG lolos/gagal instan di client (interval 90 hari, berat
/// badan, jam tidur -- semua data mock) lalu jadi gerbang ke
/// PilihSlotWaktuScreen. Sekarang cuma menampilkan `hasil_screening_awal`
/// APA ADANYA dari respons POST /profil/kuesioner:
/// - TIDAK ADA logic lolos/gagal di client.
/// - TIDAK ADA tombol lanjut ke booking (kuesioner sudah lepas total dari
///   alur booking -- lihat KuesionerIntroScreen).
/// - Catatan dari server SELALU ditampilkan, karena keputusan akhir
///   kelayakan donor selalu ada di tangan petugas medis/skrining di
///   lokasi, apa pun hasil self-assessment ini.
class HasilKuesionerScreen extends StatelessWidget {
  const HasilKuesionerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasil = context.watch<KuesionerProvider>().hasilTerakhir;

    if (hasil == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final lolos = hasil.hasilScreeningAwal == 'lolos_screening_awal';

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
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildHasilCard(lolos, hasil.hasilScreeningAwal),
                    const SizedBox(height: 16),
                    _buildCatatanCard(hasil.catatan),
                    if (hasil.flagRisiko.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildFlagRisikoCard(hasil.flagRisiko),
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
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Selesai',
                    style: AppText.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HASIL SELF-ASSESSMENT',
          style: AppText.label.copyWith(
            color: AppColors.primary,
            letterSpacing: 1.4,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kuesioner kesehatan pra-donor',
          style: AppText.headline.copyWith(fontSize: 19),
        ),
      ],
    );
  }

  Widget _buildHasilCard(bool lolos, String hasilMentah) {
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
              lolos ? Icons.verified_outlined : Icons.info_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lolos ? 'Lolos screening awal' : 'Perlu pemeriksaan lanjutan',
            textAlign: TextAlign.center,
            style: AppText.headline.copyWith(color: Colors.white, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            hasilMentah,
            textAlign: TextAlign.center,
            style: AppText.helper.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatatanCard(String catatan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.neutralMuted,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(catatan, style: AppText.helper)),
        ],
      ),
    );
  }

  Widget _buildFlagRisikoCard(List<String> flagRisiko) {
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
            'Poin yang ditandai',
            style: AppText.headline.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 8),
          for (final kode in flagRisiko)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '•  $kode',
                style: AppText.helper.copyWith(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
