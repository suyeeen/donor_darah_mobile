import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/jadwal_donor.dart';
import '../providers/kuesioner_provider.dart';
import '../theme/app_theme.dart';
import 'verifikasi_kelayakan_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class KuesionerScreen extends StatefulWidget {
  final JadwalDonor jadwal;

  const KuesionerScreen({super.key, required this.jadwal});

  @override
  State<KuesionerScreen> createState() => _KuesionerScreenState();
}

class _KuesionerScreenState extends State<KuesionerScreen> {
  final KuesionerProvider _provider = KuesionerProvider();
  final _beratController = TextEditingController();
  final _tidurController = TextEditingController();

  @override
  void dispose() {
    _beratController.dispose();
    _tidurController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jenisKelamin = context.read<AuthProvider>().pendonor?.jenisKelamin;

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<KuesionerProvider>(
        builder: (context, provider, _) {
          final daftarPertanyaan = provider.pertanyaanUntuk(jenisKelamin);

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
                          _buildProgress(),
                          const SizedBox(height: 20),
                          _buildUkuranRow(provider),
                          const SizedBox(height: 16),
                          for (final pertanyaan in daftarPertanyaan) ...[
                            _buildPertanyaanCard(provider, pertanyaan),
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
                        onPressed: provider.semuaTerjawab(jenisKelamin)
                            ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: provider,
                                    child: VerifikasiKelayakanScreen(
                                      jadwal: widget.jadwal,
                                    ),
                                  ),
                                ),
                              )
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
                          'Konfirmasi',
                          style: AppText.button.copyWith(
                            color: provider.semuaTerjawab(jenisKelamin)
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
        },
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
                'LANGKAH 3 DARI 5',
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

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress',
          style: AppText.helper.copyWith(
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: const LinearProgressIndicator(
            value: 0.3, // langkah 3 dari 10
            minHeight: 7,
            backgroundColor: Color(0xFFD9D9D9),
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildUkuranRow(KuesionerProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _numberField(
            label: 'Berat badan (kg)',
            controller: _beratController,
            onChanged: provider.setBeratBadan,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _numberField(
            label: 'Tidur (jam)',
            controller: _tidurController,
            onChanged: provider.setTidurJam,
          ),
        ),
      ],
    );
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required void Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          style: AppText.inputText,
          decoration: InputDecoration(
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
    );
  }

  Widget _buildPertanyaanCard(
    KuesionerProvider provider,
    PertanyaanKesehatan pertanyaan,
  ) {
    final jawabanSaatIni = provider.jawaban[pertanyaan.key];

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
            pertanyaan.pertanyaan,
            style: AppText.inputText.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pertanyaan.subteks,
            style: AppText.helper.copyWith(fontSize: 11.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _jawabanButton(
                  label: 'ya',
                  aktif: jawabanSaatIni == true,
                  onTap: () => provider.jawab(pertanyaan.key, true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _jawabanButton(
                  label: 'tidak',
                  aktif: jawabanSaatIni == false,
                  onTap: () => provider.jawab(pertanyaan.key, false),
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
