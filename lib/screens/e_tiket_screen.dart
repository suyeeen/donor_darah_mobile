import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
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

  final GlobalKey _tiketKey = GlobalKey();
  bool _sedangUnduh = false;

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
          estimasiMenit: jumlahDidepan * 8,
        ),
      );

      final notifProvider = context.read<NotifikasiProvider>();
      await notifProvider.cekSudahTanyaIzinDevice();
      if (!notifProvider.sudahTanyaIzinDevice && mounted) {
        showNotifikasiPermissionDialog(context);
      }
    });
  }

  Future<void> _unduhTiket() async {
    if (_sedangUnduh) return;
    setState(() => _sedangUnduh = true);

    try {
      final boundary =
          _tiketKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/e-tiket-$_nomorAntrian.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'E-tiket antrian donor darah $_nomorAntrian');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan e-tiket: $e')));
    } finally {
      if (mounted) setState(() => _sedangUnduh = false);
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
              Expanded(
                child: SingleChildScrollView(
                  child: RepaintBoundary(
                    key: _tiketKey,
                    child: _buildTiketCard(),
                  ),
                ),
              ),
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
        onPressed: _sedangUnduh ? null : _unduhTiket,
        icon: _sedangUnduh
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.download_outlined,
                color: Colors.white,
                size: 18,
              ),
        label: Text(
          _sedangUnduh ? 'Menyimpan...' : 'Unduh Nomor Antrian',
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
