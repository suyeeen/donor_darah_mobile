import 'dart:async';
import 'package:flutter/material.dart';
import '../models/papan_antrian.dart';
import '../services/api_exception.dart';
import '../services/papan_antrian_service.dart';
import '../theme/app_theme.dart';

/// FR-5.4: Papan Antrian Digital -- dipajang di layar/TV lokasi donor.
/// SENGAJA tidak butuh login (samakan dengan backend Papan.php yang
/// publik) dan cuma nampilin nomor urut, TIDAK ada data pribadi pendonor.
///
/// Auto-refresh tiap 5 detik selama layar ini terbuka -- cukup ringan
/// karena backend memang didesain buat di-poll berkala (lihat komentar
/// Notifikasi::ringkasan() soal pola polling yang sama di modul lain).
class PapanAntrianScreen extends StatefulWidget {
  final int idJadwal;
  final String? namaLokasiAwal;

  const PapanAntrianScreen({
    super.key,
    required this.idJadwal,
    this.namaLokasiAwal,
  });

  @override
  State<PapanAntrianScreen> createState() => _PapanAntrianScreenState();
}

class _PapanAntrianScreenState extends State<PapanAntrianScreen> {
  final _service = PapanAntrianService();
  Timer? _timer;

  PapanAntrian? _papan;
  String? _errorMessage;
  bool _loadingAwal = true;

  @override
  void initState() {
    super.initState();
    _muat();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _muat());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _muat() async {
    try {
      final hasil = await _service.getPapanAntrian(idJadwal: widget.idJadwal);
      if (!mounted) return;
      setState(() {
        _papan = hasil;
        _errorMessage = null;
        _loadingAwal = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _loadingAwal = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat papan antrian, mencoba lagi...';
        _loadingAwal = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.namaLokasiAwal ?? _papan?.namaLokasi ?? 'Papan Antrian',
        ),
        actions: [
          IconButton(
            onPressed: _muat,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang sekarang',
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loadingAwal) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_papan == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage ?? 'Papan antrian tidak tersedia',
            textAlign: TextAlign.center,
            style: AppText.helper.copyWith(color: Colors.white70),
          ),
        ),
      );
    }

    final papan = _papan!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_formatTanggal(papan.tanggal)} · ${papan.slotWaktu} WIB',
            textAlign: TextAlign.center,
            style: AppText.helper.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Text(
            'NOMOR SEDANG DILAYANI',
            textAlign: TextAlign.center,
            style: AppText.label.copyWith(
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            papan.nomorSedangDilayani != null
                ? '#${papan.nomorSedangDilayani}'
                : '-',
            textAlign: TextAlign.center,
            style: AppText.headline.copyWith(color: Colors.white, fontSize: 88),
          ),
          const SizedBox(height: 32),
          Text(
            '${papan.jumlahMenunggu} pendonor menunggu',
            textAlign: TextAlign.center,
            style: AppText.inputText.copyWith(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: papan.daftarMenunggu.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada yang mengantre',
                      style: AppText.helper.copyWith(color: Colors.white54),
                    ),
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: papan.daftarMenunggu
                          .map((n) => _buildChipNomor(n))
                          .toList(),
                    ),
                  ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: AppText.helper.copyWith(color: Colors.white38),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChipNomor(int nomor) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        '$nomor',
        style: AppText.inputText.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
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
    return '${hari[tanggal.weekday - 1]}, ${tanggal.day} '
        '${bulan[tanggal.month - 1]} ${tanggal.year}';
  }
}
