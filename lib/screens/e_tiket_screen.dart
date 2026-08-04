import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/jadwal_donor.dart';
import '../providers/notifikasi_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/notifikasi_permission_dialog.dart';
import 'pilih_slot_waktu_screen.dart';

class ETiketScreen extends StatefulWidget {
  final JadwalDonor jadwal;
  final SlotWaktu slot;

  const ETiketScreen({super.key, required this.jadwal, required this.slot});

  @override
  State<ETiketScreen> createState() => _ETiketScreenState();
}

class _ETiketScreenState extends State<ETiketScreen> {
  JadwalDonor get jadwal => widget.jadwal;
  SlotWaktu get slot => widget.slot;

  // GAP: nomor antrian seharusnya datang dari response API "ambil nomor
  // antrian" (FR-4.2), bukan dibikin di client. Mock ini cuma buat preview UI.
  String get _nomorAntrian {
    final acak =
        Random(jadwal.idJadwal + slot.jamMulai.hashCode).nextInt(999) + 1;
    return 'A-${acak.toString().padLeft(3, '0')}';
  }

  @override
  void initState() {
    super.initState();
    // Pendonor baru aja SELESAI MENDAFTAR (dapat nomor antrian) -- ini
    // titik paling relevan buat nawarin notifikasi device, karena mulai
    // dari sini pendonor butuh kabar realtime soal posisi antriannya
    // sampai gilirannya selesai.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifProvider = context.read<NotifikasiProvider>();
      await notifProvider.cekSudahTanyaIzinDevice();
      if (!notifProvider.sudahTanyaIzinDevice && mounted) {
        showNotifikasiPermissionDialog(context);
      }
    });
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
              _buildTombolUnduh(context),
              const SizedBox(height: 10),
              _buildTombolKembali(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTiketCard() {
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
              _nomorAntrian,
              style: AppText.headline.copyWith(
                color: Colors.white,
                fontSize: 32,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              // GAP: ganti Container ini dengan widget QR asli (paket
              // qr_flutter, belum ada di pubspec.yaml) begitu backend
              // ngasih kode unik buat di-scan petugas loket.
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.tabInactiveBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  size: 80,
                  color: AppColors.neutralMuted,
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
                  Icons.calendar_today_outlined,
                  'Jadwal',
                  '${_formatTanggal(jadwal.tanggal)} · ${slot.label} WIB',
                ),
                const SizedBox(height: 14),
                _infoRow(
                  Icons.location_on_outlined,
                  'Lokasi',
                  '${jadwal.lokasi.namaLokasi}\n${jadwal.lokasi.alamat}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildTombolUnduh(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: implementasi unduh/simpan e-tiket, misal pakai package
          // screenshot atau share_plus.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fitur unduh belum tersambung ke backend'),
            ),
          );
        },
        icon: const Icon(
          Icons.download_outlined,
          color: Colors.white,
          size: 18,
        ),
        label: Text(
          'Unduh Nomor Antrian',
          style: AppText.button.copyWith(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
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
