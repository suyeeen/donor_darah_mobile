import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/jadwal_donor.dart';
import '../providers/antrian_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_exception.dart';
import '../theme/app_theme.dart';
import 'e_tiket_screen.dart';
import 'hasil_kuesioner_screen.dart';

class DetailJadwalScreen extends StatefulWidget {
  final JadwalDonor jadwal;

  const DetailJadwalScreen({super.key, required this.jadwal});

  @override
  State<DetailJadwalScreen> createState() => _DetailJadwalScreenState();
}

class _DetailJadwalScreenState extends State<DetailJadwalScreen> {
  bool _sedangProses = false;

  JadwalDonor get jadwal => widget.jadwal;

  /// FR-4.1: langsung POST /antrian -- TIDAK ada lagi langkah "pilih slot
  /// waktu" (backend cuma punya 1 slot_waktu tetap per jadwal_donor, jadi
  /// PilihSlotWaktuScreen yang lama sudah tidak relevan buat alur ini).
  Future<void> _ambilNomorAntrian() async {
    setState(() => _sedangProses = true);

    final antrianProvider = context.read<AntrianProvider>();

    try {
      final antrian = await antrianProvider.ambilNomor(
        idJadwal: jadwal.idJadwal,
      );
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ETiketScreen(antrian: antrian)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sedangProses = false);

      // 422 spesifik: kuesioner kesehatan (Modul 2) belum pernah diisi
      // sama sekali -- backend nolak sebelum itu kelar (lihat
      // Antrian::ambil() di backend).
      if (e.message.toLowerCase().contains('kuesioner')) {
        _tampilkanDialogKuesionerBelumDiisi();
        return;
      }

      // 409: sudah punya antrian aktif lain
      if (e.statusCode == 409) {
        _tampilkanDialogSudahPunyaAntrian(e.message);
        return;
      }

      // Sisanya (BR2 interval 90 hari, kuota habis, dll) -- tampilkan
      // pesan asli dari server apa adanya, itu sudah cukup jelas.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _sedangProses = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan, coba lagi')),
      );
    }
  }

  void _tampilkanDialogKuesionerBelumDiisi() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lengkapi kuesioner dulu'),
        content: const Text(
          'Anda perlu mengisi kuesioner kesehatan pra-donor minimal sekali '
          'sebelum bisa mengambil nomor antrian.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HasilKuesionerScreen()),
              );
            },
            child: const Text('Isi sekarang'),
          ),
        ],
      ),
    );
  }

  void _tampilkanDialogSudahPunyaAntrian(String pesan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sudah ada antrian aktif'),
        content: Text(pesan),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habis = jadwal.kuotaHabis;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Detail jadwal',
          style: AppText.headline.copyWith(fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(jadwal.lokasi.namaLokasi, style: AppText.headline),
                    const SizedBox(height: 4),
                    Text(jadwal.lokasi.alamat, style: AppText.helper),
                    const SizedBox(height: 20),
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    _buildPeta(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: (habis || _sedangProses)
                      ? null
                      : _ambilNomorAntrian,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.buttonDisabledBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _sedangProses
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          habis ? 'Kuota penuh' : 'Ambil nomor antrian',
                          style: AppText.button.copyWith(
                            color: habis
                                ? AppColors.buttonDisabledText
                                : Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final habis = jadwal.kuotaHabis;
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
          _baris(
            Icons.calendar_today_outlined,
            '${jadwal.tanggal.day}/${jadwal.tanggal.month}/${jadwal.tanggal.year}',
          ),
          const SizedBox(height: 12),
          _baris(Icons.schedule_outlined, jadwal.slotWaktu),
          const SizedBox(height: 12),
          _baris(
            Icons.people_outline,
            habis
                ? 'Kuota penuh (${jadwal.kuotaTotal} slot)'
                : 'Sisa ${jadwal.kuotaTersisa} dari ${jadwal.kuotaTotal} slot',
          ),
          if (jadwal.namaKegiatan != null) ...[
            const SizedBox(height: 12),
            _baris(Icons.campaign_outlined, jadwal.namaKegiatan!),
          ],
        ],
      ),
    );
  }

  Widget _baris(IconData icon, String teks) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.neutralMuted),
        const SizedBox(width: 10),
        Expanded(child: Text(teks, style: AppText.inputText)),
      ],
    );
  }

  Widget _buildPeta() {
    final lat = jadwal.lokasi.latitude;
    final lng = jadwal.lokasi.longitude;

    if (lat == null || lng == null) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Text('Koordinat lokasi belum tersedia', style: AppText.helper),
      );
    }

    final titik = LatLng(lat, lng);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 160,
        child: IgnorePointer(
          child: FlutterMap(
            options: MapOptions(initialCenter: titik, initialZoom: 15),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.antrian_donor_darah',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: titik,
                    width: 36,
                    height: 36,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
