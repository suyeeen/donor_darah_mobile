import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/antrian_donor.dart';
import '../providers/notifikasi_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/notifikasi_permission_dialog.dart';

/// FIX: dialog izin notifikasi ("Aktifkan Notifikasi pada Device") sekarang
/// dipicu DI SINI, bukan lagi di AuthScreen saat proses daftar. Alasannya:
/// dulu dialog itu ditampilkan sebelum OTP diverifikasi, padahal
/// AuthProvider.token masih null di titik itu -- akibatnya pendaftaran FCM
/// token ke backend (NotifikasiService.daftarkanToken) selalu gagal diam-
/// diam, SEMENTARA flag "sudah pernah tanya" di SharedPreferences sudah
/// kadung ditandai true, jadi dialog tidak pernah muncul lagi walau user
/// sudah login. Ujung-ujungnya device_tokens di backend tidak pernah
/// terisi -> notifikasi mengambang (heads-up) tidak pernah muncul saat
/// petugas memanggil nomor antrian.
///
/// Titik ini (begitu e-ticket tampil, tepat setelah ambil nomor antrian)
/// jauh lebih tepat: AuthProvider.token DIJAMIN sudah terisi (DetailJadwal-
/// Screen mensyaratkan token non-null sebelum bisa ambil nomor sama
/// sekali, lihat _ambilNomorAntrian()), dan momen ini juga lebih relevan
/// buat user -- baru dapat nomor, jadi wajar ditawari notifikasi.
class ETiketScreen extends StatefulWidget {
  final AntrianDonor antrian;

  const ETiketScreen({super.key, required this.antrian});

  @override
  State<ETiketScreen> createState() => _ETiketScreenState();
}

class _ETiketScreenState extends State<ETiketScreen> {
  AntrianDonor get antrian => widget.antrian;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tawarkanNotifikasi());
  }

  Future<void> _tawarkanNotifikasi() async {
    final notifProvider = context.read<NotifikasiProvider>();
    await notifProvider.cekSudahTanyaIzinDevice();
    if (!notifProvider.sudahTanyaIzinDevice && mounted) {
      await showNotifikasiPermissionDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(child: SingleChildScrollView(child: _buildTiketCard())),
              const SizedBox(height: 16),
              _buildTombolKembali(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTiketCard() {
    final jadwal = antrian.jadwal;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.inputBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            color: AppColors.cardDark,
            child: Text(
              antrian.nomorAntrian,
              style: AppText.headline.copyWith(
                color: Colors.white,
                fontSize: 32,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              // GAP: qr_code dari backend itu STRING HASH, bukan payload
              // gambar. Backend belum punya endpoint buat render-nya jadi
              // gambar QR (mis. via qrserver.com atau bikin sendiri).
              // Sementara pakai qr_flutter buat generate visual dari
              // string hash ini -- ganti kalau backend nanti nyediain
              // format khusus (mis. data URI base64).
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.inputBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      size: 140,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      antrian.qrCode,
                      style: AppText.helper.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.inputBorder),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(
                  Icons.info_outline,
                  'Status',
                  _labelStatus(antrian.status),
                ),
                if (jadwal != null) ...[
                  const SizedBox(height: 14),
                  _infoRow(
                    Icons.calendar_today_outlined,
                    'Jadwal',
                    '${_formatTanggal(jadwal.tanggal)} · ${jadwal.slotWaktu} WIB',
                  ),
                  const SizedBox(height: 14),
                  _infoRow(
                    Icons.location_on_outlined,
                    'Lokasi',
                    '${jadwal.namaLokasi ?? '-'}\n${jadwal.alamat ?? ''}',
                  ),
                ],
                if (antrian.batasWaktuCheckin != null) ...[
                  const SizedBox(height: 14),
                  _infoRow(
                    Icons.timer_outlined,
                    'Batas check-in',
                    _formatWaktu(antrian.batasWaktuCheckin!),
                  ),
                ],
                if (antrian.posisi != null) ...[
                  const SizedBox(height: 14),
                  _infoRow(
                    Icons.people_outline,
                    'Posisi antrian',
                    '${antrian.posisi!.jumlahDiDepan} orang di depan · '
                        'estimasi ${antrian.posisi!.estimasiMenit} menit',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _labelStatus(StatusAntrian status) {
    switch (status) {
      case StatusAntrian.menunggu:
        return 'Menunggu';
      case StatusAntrian.dipanggil:
        return 'Dipanggil';
      case StatusAntrian.sedangDiproses:
        return 'Sedang diproses';
      case StatusAntrian.selesai:
        return 'Selesai';
      case StatusAntrian.tidakHadir:
        return 'Tidak hadir (hangus)';
      case StatusAntrian.dibatalkan:
        return 'Dibatalkan';
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AppText.label.copyWith(
                  color: AppColors.neutralMuted,
                  fontSize: 10.5,
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

  String _formatTanggal(DateTime tanggal) {
    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${hari[tanggal.weekday - 1]}, ${tanggal.day} '
        '${bulan[tanggal.month - 1]} ${tanggal.year}';
  }

  String _formatWaktu(DateTime waktu) {
    final j = waktu.hour.toString().padLeft(2, '0');
    final m = waktu.minute.toString().padLeft(2, '0');
    return '${_formatTanggal(waktu)}, $j:$m WIB';
  }

  Widget _buildTombolKembali(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.inputBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Kembali ke Menu',
          style: AppText.button.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
