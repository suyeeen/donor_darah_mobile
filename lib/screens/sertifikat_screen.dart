import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../services/api_exception.dart';
import '../services/riwayat_service.dart';
import '../theme/app_theme.dart';

enum _UnduhStatus { memuat, siap, error }

/// FR-8.2: sertifikat donor. Backend generate PDF-nya langsung di server
/// (Riwayat::sertifikat(), pakai Dompdf + font kustom) -- app cuma perlu
/// ambil bytes-nya lewat token, simpan sementara, lalu tawarkan buat
/// dibagikan/disimpan lewat share sheet OS (tidak ada PDF viewer bawaan
/// di app ini, jadi tidak ditampilkan inline).
class SertifikatScreen extends StatefulWidget {
  final int idAntrian;

  const SertifikatScreen({super.key, required this.idAntrian});

  @override
  State<SertifikatScreen> createState() => _SertifikatScreenState();
}

class _SertifikatScreenState extends State<SertifikatScreen> {
  final RiwayatService _service = RiwayatService();

  _UnduhStatus _status = _UnduhStatus.memuat;
  String? _pesanError;
  File? _fileTersimpan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unduh());
  }

  Future<void> _unduh() async {
    setState(() {
      _status = _UnduhStatus.memuat;
      _pesanError = null;
    });

    final token = context.read<AuthProvider>().token;
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _status = _UnduhStatus.error;
        _pesanError = 'Sesi login tidak ditemukan, silakan masuk kembali.';
      });
      return;
    }

    try {
      final bytes = await _service.unduhSertifikat(
        idAntrian: widget.idAntrian,
        token: token,
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/sertifikat-donor-${widget.idAntrian}.pdf');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      setState(() {
        _fileTersimpan = file;
        _status = _UnduhStatus.siap;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _UnduhStatus.error;
        _pesanError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _UnduhStatus.error;
        _pesanError = 'Gagal mengunduh sertifikat, coba lagi.';
      });
    }
  }

  Future<void> _bagikan() async {
    final file = _fileTersimpan;
    if (file == null) return;
    await Share.shareXFiles([XFile(file.path)], text: 'Sertifikat donor darah');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Sertifikat Donor',
          style: AppText.headline.copyWith(fontSize: 17),
        ),
      ),
      body: SafeArea(child: Center(child: _buildBody())),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _UnduhStatus.memuat:
        return const CircularProgressIndicator();
      case _UnduhStatus.error:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.neutralMuted,
              ),
              const SizedBox(height: 16),
              Text(
                _pesanError ?? 'Gagal mengunduh sertifikat',
                style: AppText.helper,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _unduh, child: const Text('Coba lagi')),
            ],
          ),
        );
      case _UnduhStatus.siap:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                size: 56,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Sertifikat siap diunduh',
                style: AppText.headline.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Simpan atau bagikan file PDF sertifikat donor kamu.',
                style: AppText.helper,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _bagikan,
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: const Text('Bagikan / Simpan PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
