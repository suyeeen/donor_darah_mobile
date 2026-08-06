import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/jadwal_donor.dart';
import '../theme/app_theme.dart';
import 'pilih_slot_waktu_screen.dart';

class DetailJadwalScreen extends StatelessWidget {
  final JadwalDonor jadwal;

  const DetailJadwalScreen({super.key, required this.jadwal});

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
                  onPressed: habis
                      ? null
                      : () {
                          // RESTRUKTURISASI Modul 2: kuesioner kesehatan
                          // sekarang independen (diisi kapan saja lewat
                          // tab Profil), BUKAN lagi langkah wajib sebelum
                          // ambil nomor antrian. Booking langsung lanjut
                          // ke pemilihan slot waktu.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PilihSlotWaktuScreen(jadwal: jadwal),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.buttonDisabledBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
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

  // Mini map lokasi -- pakai flutter_map (bukan google_maps_flutter, biar
  // konsisten dengan pola yang sudah dipakai di HasilPencarianScreen).
  // Kalau lokasi belum punya koordinat, tampilkan placeholder informatif
  // alih-alih peta kosong.
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
          // Peta cuma buat preview visual di sini, bukan interaktif --
          // biar gak rebutan gesture sama SingleChildScrollView di
          // sekitarnya. Kalau mau full-interaktif, bungkus di halaman
          // detail-peta terpisah.
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
