import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pendonor.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'kuesioner_intro_screen.dart';

/// FR-2.1: Lihat & lengkapi profil pendonor.
///
/// RESTRUKTURISASI Modul 2 -- field yang bisa diedit di sini disesuaikan
/// PERSIS dengan apa yang diterima backend di PUT /profil:
///   - golongan_darah, alamat            -> tabel `pendonor`
///   - berat_badan, tekanan_darah,
///     penyakit_bawaan,
///     riwayat_donor_sebelumnya          -> tabel `riwayat_kesehatan`
///
/// Field LAIN (nama, email, NIK, tanggal lahir, jenis kelamin, no
/// telepon) TIDAK diproses sama sekali oleh endpoint ini -- backend diam-
/// diam mengabaikannya kalau dikirim. Makanya di versi ini semua field
/// itu jadi READ-ONLY (data dari saat registrasi), BUKAN form yang bisa
/// disimpan seolah-olah nyambung ke API.
///
/// Kuesioner kesehatan JUGA TIDAK LAGI ada di sini sebagai input angka
/// (berat/tidur) -- sudah pindah total jadi alur tersendiri lewat
/// KuesionerIntroScreen (kartu "Kuesioner Kesehatan" di bawah).
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _alamatController;
  late final TextEditingController _beratController;
  late final TextEditingController _tekananController;
  late final TextEditingController _penyakitController;
  late final TextEditingController _riwayatDonorController;

  String? _golonganDarah;
  bool _diedit = false;

  static const _opsiGolonganDarah = ['A', 'B', 'AB', 'O'];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final pendonor = auth.pendonor;
    final riwayat = auth.riwayatKesehatan;

    _alamatController = TextEditingController(text: pendonor?.alamat ?? '');
    _beratController = TextEditingController(
      text: riwayat?.beratBadan != null
          ? riwayat!.beratBadan!.toStringAsFixed(0)
          : '',
    );
    _tekananController = TextEditingController(
      text: riwayat?.tekananDarah ?? '',
    );
    _penyakitController = TextEditingController(
      text: riwayat?.penyakitBawaan ?? '',
    );
    _riwayatDonorController = TextEditingController(
      text: riwayat?.riwayatDonorSebelumnya ?? '',
    );
    _golonganDarah = pendonor?.golonganDarah;

    WidgetsBinding.instance.addPostFrameCallback((_) => _muatUlang());
  }

  @override
  void dispose() {
    _alamatController.dispose();
    _beratController.dispose();
    _tekananController.dispose();
    _penyakitController.dispose();
    _riwayatDonorController.dispose();
    super.dispose();
  }

  Future<void> _muatUlang() async {
    await context.read<AuthProvider>().muatUlangProfil();
    if (!mounted || _diedit) return;

    final auth = context.read<AuthProvider>();
    final pendonor = auth.pendonor;
    final riwayat = auth.riwayatKesehatan;
    setState(() {
      _alamatController.text = pendonor?.alamat ?? '';
      _beratController.text = riwayat?.beratBadan != null
          ? riwayat!.beratBadan!.toStringAsFixed(0)
          : '';
      _tekananController.text = riwayat?.tekananDarah ?? '';
      _penyakitController.text = riwayat?.penyakitBawaan ?? '';
      _riwayatDonorController.text = riwayat?.riwayatDonorSebelumnya ?? '';
      _golonganDarah = pendonor?.golonganDarah;
    });
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final sukses = await auth.simpanProfil(
      golonganDarah: _golonganDarah,
      alamat: _alamatController.text.trim(),
      beratBadan: double.tryParse(_beratController.text.trim()),
      tekananDarah: _tekananController.text.trim(),
      penyakitBawaan: _penyakitController.text.trim(),
      riwayatDonorSebelumnya: _riwayatDonorController.text.trim(),
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sukses
              ? 'Profil berhasil diperbarui.'
              : (auth.errorMessage ?? 'Gagal menyimpan profil.'),
        ),
        backgroundColor: sukses ? AppColors.success : AppColors.primary,
      ),
    );
    if (sukses) setState(() => _diedit = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pendonor = auth.pendonor;
    final riwayat = auth.riwayatKesehatan;
    final loading = auth.profilLoading;

    if (pendonor == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          onChanged: () => setState(() => _diedit = true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: _buildHeader(context),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _muatUlang,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAvatarCard(pendonor),
                        const SizedBox(height: 24),
                        _sectionTitle('Identitas'),
                        const SizedBox(height: 4),
                        Text(
                          'Data ini diisi saat registrasi dan tidak bisa '
                          'diubah dari sini.',
                          style: AppText.helper,
                        ),
                        const SizedBox(height: 12),
                        _buildReadOnlyField(label: 'NIK', value: pendonor.nik),
                        _buildReadOnlyField(
                          label: 'Nama lengkap',
                          value: pendonor.nama,
                        ),
                        _buildReadOnlyField(
                          label: 'Email',
                          value: pendonor.email,
                        ),
                        _buildReadOnlyField(
                          label: 'Nomor ponsel',
                          value: pendonor.noTelp,
                        ),
                        _buildReadOnlyField(
                          label: 'Tanggal lahir',
                          value: pendonor.tanggalLahir != null
                              ? _formatTanggal(pendonor.tanggalLahir!)
                              : null,
                        ),
                        _buildReadOnlyField(
                          label: 'Jenis kelamin',
                          value: pendonor.jenisKelamin == 'L'
                              ? 'Laki-laki'
                              : pendonor.jenisKelamin == 'P'
                              ? 'Perempuan'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        _sectionTitle('Alamat & Golongan Darah'),
                        const SizedBox(height: 12),
                        _buildGolonganDarahField(),
                        _buildTextField(
                          label: 'Alamat',
                          controller: _alamatController,
                          maxLines: 3,
                          hint: 'Sesuai domisili saat ini',
                        ),
                        const SizedBox(height: 8),
                        _sectionTitle('Data Kesehatan Dasar'),
                        const SizedBox(height: 4),
                        Text(
                          'Data ini dipakai sistem untuk verifikasi kelayakan '
                          'awal (FR-2.1) -- keputusan akhir tetap di petugas '
                          'skrining di lokasi.',
                          style: AppText.helper,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          label: 'Berat badan (kg)',
                          controller: _beratController,
                          keyboardType: TextInputType.number,
                          hint: 'contoh: 60',
                        ),
                        _buildTextField(
                          label: 'Tekanan darah',
                          controller: _tekananController,
                          hint: 'contoh: 120/80',
                        ),
                        _buildTextField(
                          label: 'Penyakit bawaan',
                          controller: _penyakitController,
                          maxLines: 2,
                          hint: 'Kosongkan kalau tidak ada',
                        ),
                        _buildTextField(
                          label: 'Riwayat donor sebelumnya',
                          controller: _riwayatDonorController,
                          maxLines: 2,
                          hint: 'Kosongkan kalau belum pernah donor',
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: (_diedit && !loading) ? _simpan : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor:
                                  AppColors.buttonDisabledBg,
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
                                    'Simpan perubahan',
                                    style: AppText.button.copyWith(
                                      color: _diedit
                                          ? Colors.white
                                          : AppColors.buttonDisabledText,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _sectionTitle('Kuesioner Kesehatan'),
                        const SizedBox(height: 12),
                        _buildKuesionerCard(context, riwayat?.hasilKuesioner),
                      ],
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

  Widget _buildKuesionerCard(BuildContext context, HasilKuesioner? hasil) {
    final sudahDiisi = hasil != null;
    final lolos = hasil?.hasilScreeningAwal == 'lolos_screening_awal';

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const KuesionerIntroScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: sudahDiisi
                    ? (lolos
                          ? const Color(0xFFE4F2E8)
                          : const Color(0xFFFBEAEA))
                    : AppColors.tabInactiveBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                sudahDiisi
                    ? Icons.fact_check_outlined
                    : Icons.assignment_outlined,
                color: sudahDiisi
                    ? (lolos ? AppColors.success : AppColors.primary)
                    : AppColors.neutralMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sudahDiisi ? 'Sudah diisi' : 'Belum diisi',
                    style: AppText.inputText.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sudahDiisi
                        ? (lolos
                              ? 'Lolos self-assessment awal'
                              : 'Perlu pemeriksaan lanjutan')
                        : 'Isi kuesioner kesehatan pra-donor',
                    style: AppText.helper.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.neutralMuted,
            ),
          ],
        ),
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
        Text('Profil saya', style: AppText.headline.copyWith(fontSize: 19)),
      ],
    );
  }

  Widget _buildAvatarCard(Pendonor pendonor) {
    final inisial = pendonor.nama.trim().isNotEmpty
        ? pendonor.nama.trim()[0].toUpperCase()
        : '?';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              inisial,
              style: AppText.statValue.copyWith(fontSize: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pendonor.nama,
                  style: AppText.inputText.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  pendonor.golonganDarah ?? 'Golongan darah belum diketahui',
                  style: AppText.statLabelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: AppText.headline.copyWith(fontSize: 14));
  }

  Widget _buildReadOnlyField({
    required String label,
    String? value,
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.tabInactiveBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value?.isNotEmpty == true ? value! : '-',
                    style: AppText.inputText,
                  ),
                ),
                const Icon(
                  Icons.lock_outline,
                  size: 15,
                  color: AppColors.neutralMuted,
                ),
              ],
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 6),
            Text(helper, style: AppText.helper),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
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
            maxLines: maxLines,
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

  Widget _buildGolonganDarahField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Golongan darah', style: AppText.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _opsiGolonganDarah.map((opsi) {
              return SizedBox(
                width: 68,
                child: _chipPilihan(
                  label: opsi,
                  aktif: _golonganDarah == opsi,
                  onTap: () => setState(() {
                    _golonganDarah = opsi;
                    _diedit = true;
                  }),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Text(
            'Golongan darah cuma bisa diverifikasi ulang lewat pemeriksaan '
            'di lokasi -- pilih di sini kalau Anda sudah tahu dari '
            'pemeriksaan sebelumnya.',
            style: AppText.helper,
          ),
        ],
      ),
    );
  }

  Widget _chipPilihan({
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
          color: aktif ? AppColors.primary : Colors.white,
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
