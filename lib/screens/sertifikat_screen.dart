import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/pendonor.dart';
import '../models/riwayat_donor.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class SertifikatScreen extends StatefulWidget {
  final RiwayatDonor riwayat;

  const SertifikatScreen({super.key, required this.riwayat});

  @override
  State<SertifikatScreen> createState() => _SertifikatScreenState();
}

class _SertifikatScreenState extends State<SertifikatScreen> {
  final GlobalKey _sertifikatKey = GlobalKey();
  bool _sedangUnduh = false;

  // GAP: nomor sertifikat seharusnya dari backend, dibuat sekali saat
  // status antrian jadi "Selesai" (FR-8.2). Ini deterministik di client
  // cuma buat kebutuhan preview UI, BUKAN sumber kebenaran.
  String get _nomorSertifikat {
    final t = widget.riwayat.tanggal;
    final bulan = t.month.toString().padLeft(2, '0');
    final hari = t.day.toString().padLeft(2, '0');
    final urut = widget.riwayat.idHasil.toString().padLeft(3, '0');
    return 'SERT-${t.year}-$bulan$hari-$urut';
  }

  Future<void> _unduhSertifikat() async {
    if (_sedangUnduh) return;
    setState(() => _sedangUnduh = true);

    try {
      final boundary =
          _sertifikatKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/sertifikat-$_nomorSertifikat.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Sertifikat donor darah $_nomorSertifikat');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan sertifikat: $e')));
    } finally {
      if (mounted) setState(() => _sedangUnduh = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendonor = context.watch<AuthProvider>().pendonor;
    final namaTampil = (pendonor?.nama.isNotEmpty ?? false)
        ? pendonor!.nama
        : 'Pendonor';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: RepaintBoundary(
                    key: _sertifikatKey,
                    child: _buildKartuSertifikat(namaTampil, pendonor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 49.5,
                child: ElevatedButton.icon(
                  onPressed: _sedangUnduh ? null : _unduhSertifikat,
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
                          Icons.file_download_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                  label: Text(
                    _sedangUnduh ? 'Menyimpan...' : 'Unduh sertifikat PDF',
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
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  // Tombol ini nyimpen versi GAMBAR (PNG) hasil screenshot
                  // kartu, BUKAN file PDF asli -- generate PDF beneran
                  // butuh backend.
                  'Sementara diunduh sebagai gambar, bukan PDF asli',
                  style: AppText.helper.copyWith(fontSize: 10.5),
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
        Text('Sertifikat', style: AppText.headline.copyWith(fontSize: 19)),
      ],
    );
  }

  Widget _buildKartuSertifikat(String namaTampil, Pendonor? pendonor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBFA),
        border: Border.all(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          Text(
            'PALANG MERAH INDONESIA',
            style: AppText.label.copyWith(
              color: AppColors.primary,
              letterSpacing: 2.2,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 28),
          // Area ini KOSONG di desain Figma asli (node 4:3673) -- gue isi
          // sendiri dengan nama pendonor & ringkasan kegiatan.
          Icon(
            Icons.workspace_premium_outlined,
            size: 40,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 14),
          Text(
            namaTampil,
            textAlign: TextAlign.center,
            style: AppText.headline.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'telah mendonorkan darah pada',
            textAlign: TextAlign.center,
            style: AppText.helper.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            _formatTanggal(widget.riwayat.tanggal),
            textAlign: TextAlign.center,
            style: AppText.inputText.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'di ${widget.riwayat.lokasi.namaLokasi}',
            textAlign: TextAlign.center,
            style: AppText.helper.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOMOR SERTIFIKAT',
                      style: AppText.label.copyWith(
                        color: AppColors.neutralMuted,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _nomorSertifikat,
                      style: AppText.inputText.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: AppColors.textLabel,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'GOLONGAN DARAH',
                      style: AppText.label.copyWith(
                        color: AppColors.neutralMuted,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // Sesuai enum asli di database: cuma A/B/AB/O/Belum
                      // Diketahui -- TIDAK ada rhesus (+/-).
                      pendonor?.golonganDarah ?? 'Belum Diketahui',
                      style: AppText.headline.copyWith(
                        color: AppColors.primary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 86,
                height: 86,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.inputBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: _nomorSertifikat,
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Sertifikat ini terbit otomatis saat status antrian Anda menjadi '
            '"Selesai" dan dapat diverifikasi melalui QR di atas.',
            textAlign: TextAlign.center,
            style: AppText.helper.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  String _formatTanggal(DateTime tanggal) {
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
    return '${tanggal.day} ${bulan[tanggal.month - 1]} ${tanggal.year}';
  }
}
