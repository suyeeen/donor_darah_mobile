import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/antrian_donor.dart';
import '../models/jadwal_donor.dart';
import '../providers/antrian_provider.dart';
import '../providers/notifikasi_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/notifikasi_permission_dialog.dart';
import 'pilih_slot_waktu_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
  int get _nomorUrutAntrian =>
      Random(jadwal.idJadwal + slot.jamMulai.hashCode).nextInt(999) + 1;

  String get _nomorAntrian =>
      'A-${_nomorUrutAntrian.toString().padLeft(3, '0')}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Daftarin antrian yang baru diambil ini ke AntrianProvider, biar
      // langsung muncul di tab "Antrian" pas kembali ke Home -- sebelumnya
      // e-tiket cuma tampil di layar ini doang lalu hilang begitu ditutup.
      final jumlahDidepan = slot.pendaftar;
      context.read<AntrianProvider>().tambahAntrianBaru(
        AntrianDonor(
          idAntrian: DateTime.now().millisecondsSinceEpoch,
          jadwal: jadwal,
          nomorUrut: _nomorUrutAntrian,
          status: StatusAntrian.menunggu,
          qrCode: 'QR-DEMO-$_nomorAntrian',
          batasWaktuCheckin: null,
          jumlahDidepan: jumlahDidepan,
          // ASUMSI: rata-rata 8 menit per pendonor (skrining + proses
          // donor). Gak ada acuan resmi dari PMI/FRD -- sesuaikan kalau
          // ada standar waktu proses yang lebih akurat.
          estimasiMenit: jumlahDidepan * 8,
        ),
      );

      // Pendonor baru aja SELESAI MENDAFTAR (dapat nomor antrian) -- ini
      // titik fallback buat nawarin notifikasi device (trigger utamanya
      // sekarang di AuthScreen abis registrasi). Gak akan muncul dobel,
      // karena dicek lewat flag sudahTanyaIzinDevice yang sama.
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
              // Kode QR asli, di-generate langsung di device dari string
              // qrCode. GAP: string-nya sendiri masih di-generate random
              // di client (lihat _nomorUrutAntrian) -- begitu backend
              // ngasih kode unik hasil INSERT ke tabel antrian, ganti
              // sumber data QR-nya ke situ, widget QR ini gak perlu
              // berubah sama sekali.
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.inputBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: 'QR-DEMO-$_nomorAntrian',
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.textPrimary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.textPrimary,
                  ),
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
