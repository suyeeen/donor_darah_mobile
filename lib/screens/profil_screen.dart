import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pendonor.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaController;
  late final TextEditingController _emailController;
  late final TextEditingController _alamatController;
  late final TextEditingController _beratController;

  DateTime? _tanggalLahir;
  String? _jenisKelamin;
  String? _golonganDarah;

  bool _diedit = false;

  static const _opsiGolonganDarah = ['A', 'B', 'AB', 'O', 'Belum Diketahui'];

  @override
  void initState() {
    super.initState();
    final pendonor = context.read<AuthProvider>().pendonor;

    _namaController = TextEditingController(text: pendonor?.nama ?? '');
    _emailController = TextEditingController(text: pendonor?.email ?? '');
    _alamatController = TextEditingController(text: pendonor?.alamat ?? '');
    _beratController = TextEditingController(
      text: pendonor?.beratBadan != null
          ? pendonor!.beratBadan!.toStringAsFixed(0)
          : '',
    );
    _tanggalLahir = pendonor?.tanggalLahir;
    _jenisKelamin = pendonor?.jenisKelamin;
    _golonganDarah = pendonor?.golonganDarah;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _alamatController.dispose();
    _beratController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggalLahir() async {
    final sekarang = DateTime.now();
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggalLahir ?? DateTime(sekarang.year - 20),
      firstDate: DateTime(sekarang.year - 65),
      lastDate: DateTime(sekarang.year - 17),
      helpText: 'Pilih tanggal lahir',
    );
    if (hasil != null) {
      setState(() {
        _tanggalLahir = hasil;
        _diedit = true;
      });
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final lama = auth.pendonor;
    if (lama == null) return;

    final dataBaru = lama.copyWith(
      nama: _namaController.text.trim(),
      email: _emailController.text.trim(),
      alamat: _alamatController.text.trim(),
      tanggalLahir: _tanggalLahir,
      jenisKelamin: _jenisKelamin,
      golonganDarah: _golonganDarah,
      beratBadan: double.tryParse(_beratController.text.trim()),
    );

    final sukses = await auth.simpanProfil(dataBaru);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sukses ? 'Profil berhasil diperbarui.' : 'Gagal menyimpan profil.',
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
    final loading = auth.status == AuthStatus.authenticating;

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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAvatarCard(pendonor),
                      const SizedBox(height: 24),
                      _sectionTitle('Identitas'),
                      const SizedBox(height: 12),
                      _buildReadOnlyField(label: 'NIK', value: pendonor.nik),
                      _buildReadOnlyField(
                        label: 'Nomor ponsel',
                        value: pendonor.noTelepon,
                        helper:
                            'Untuk mengubah nomor ponsel, verifikasi OTP diperlukan.',
                      ),
                      _buildTextField(
                        label: 'Nama lengkap',
                        controller: _namaController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Wajib diisi'
                            : null,
                      ),
                      _buildTextField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      _sectionTitle('Data & Kesehatan Dasar'),
                      const SizedBox(height: 4),
                      Text(
                        'Data ini dipakai sistem untuk verifikasi kelayakan '
                        'awal (FR-2.1) -- keputusan akhir tetap di petugas '
                        'skrining di lokasi.',
                        style: AppText.helper,
                      ),
                      const SizedBox(height: 12),
                      _buildTanggalLahirField(),
                      _buildJenisKelaminField(),
                      _buildGolonganDarahField(),
                      _buildTextField(
                        label: 'Berat badan (kg)',
                        controller: _beratController,
                        keyboardType: TextInputType.number,
                        hint: 'contoh: 60',
                      ),
                      _buildTextField(
                        label: 'Alamat',
                        controller: _alamatController,
                        maxLines: 3,
                        hint: 'Sesuai domisili saat ini',
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (_diedit && !loading) ? _simpan : null,
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
                                  'Simpan perubahan',
                                  style: AppText.button.copyWith(
                                    color: _diedit
                                        ? Colors.white
                                        : AppColors.buttonDisabledText,
                                  ),
                                ),
                        ),
                      ),
                    ],
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
        Text('Profil Saya', style: AppText.headline.copyWith(fontSize: 20)),
      ],
    );
  }

  Widget _buildAvatarCard(Pendonor pendonor) {
    final inisial = pendonor.nama.trim().isNotEmpty
        ? pendonor.nama.trim()[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              inisial,
              style: AppText.statValue.copyWith(fontSize: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pendonor.nama,
                  style: AppText.inputText.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Golongan darah ${pendonor.golonganDarah ?? '-'}',
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
    return Text(
      title,
      style: AppText.label.copyWith(fontSize: 13, letterSpacing: 0.2),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
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
                Expanded(child: Text(value, style: AppText.inputText)),
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

  Widget _buildTanggalLahirField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tanggal lahir', style: AppText.label),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _pilihTanggalLahir,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _tanggalLahir != null
                          ? _formatTanggal(_tanggalLahir!)
                          : 'Pilih tanggal lahir',
                      style: _tanggalLahir != null
                          ? AppText.inputText
                          : AppText.placeholder,
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.neutralMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTanggal(DateTime tanggal) {
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des', //
    ];
    return '${tanggal.day} ${bulan[tanggal.month - 1]} ${tanggal.year}';
  }

  Widget _buildJenisKelaminField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Jenis kelamin', style: AppText.label),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _chipPilihan(
                  label: 'Laki-laki',
                  aktif: _jenisKelamin == 'L',
                  onTap: () => setState(() {
                    _jenisKelamin = 'L';
                    _diedit = true;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _chipPilihan(
                  label: 'Perempuan',
                  aktif: _jenisKelamin == 'P',
                  onTap: () => setState(() {
                    _jenisKelamin = 'P';
                    _diedit = true;
                  }),
                ),
              ),
            ],
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
                width: opsi == 'Belum Diketahui' ? double.infinity : 68,
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
}
