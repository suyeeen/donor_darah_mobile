import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/jadwal_donor.dart';
import '../providers/jadwal_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/jadwal_card.dart';
import 'detail_jadwal_screen.dart';

class HasilPencarianScreen extends StatefulWidget {
  const HasilPencarianScreen({super.key});

  @override
  State<HasilPencarianScreen> createState() => _HasilPencarianScreenState();
}

class _HasilPencarianScreenState extends State<HasilPencarianScreen> {
  bool _tampilPeta = false;
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil pencarian'),
        actions: [
          IconButton(
            icon: Icon(_tampilPeta ? Icons.list : Icons.map_outlined),
            tooltip: _tampilPeta ? 'Tampilan list' : 'Tampilan peta',
            onPressed: () => setState(() => _tampilPeta = !_tampilPeta),
          ),
        ],
      ),
      body: Consumer<JadwalProvider>(
        builder: (context, provider, _) {
          if (provider.status == JadwalStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.status == JadwalStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      provider.errorMessage ?? 'Terjadi kesalahan',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => provider.cariJadwal(),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.hasil.isEmpty) {
            return const Center(
              child: Text('Belum ada jadwal ditemukan untuk filter ini'),
            );
          }

          if (_tampilPeta) {
            return _buildPeta(provider.hasil);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.hasil.length,
            itemBuilder: (context, i) {
              final jadwal = provider.hasil[i];
              return JadwalCard(
                jadwal: jadwal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailJadwalScreen(jadwal: jadwal),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPeta(List<JadwalDonor> daftarJadwal) {
    // GAP: jadwal yang lokasinya belum punya koordinat (latitude/longitude
    // null) gak bisa ditaruh di peta -- disaring di sini, bukan error.
    final berKoordinat = daftarJadwal
        .where((j) => j.lokasi.latitude != null && j.lokasi.longitude != null)
        .toList();

    if (berKoordinat.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Belum ada lokasi dengan koordinat GPS untuk ditampilkan di peta.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final pusatPeta = LatLng(
      berKoordinat.map((j) => j.lokasi.latitude!).reduce((a, b) => a + b) /
          berKoordinat.length,
      berKoordinat.map((j) => j.lokasi.longitude!).reduce((a, b) => a + b) /
          berKoordinat.length,
    );

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: pusatPeta, initialZoom: 12),
          children: [
            // Tile server gratis dari OpenStreetMap. Buat production
            // beneran (bukan skripsi/demo), disaranin pindah ke tile
            // provider berbayar-ringan (mis. MapTiler/Stadia Maps) biar
            // gak numpang trafik ke server OSM publik terus-terusan.
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.antrian_donor_darah',
            ),
            MarkerLayer(
              markers: berKoordinat.map((jadwal) {
                return Marker(
                  point: LatLng(
                    jadwal.lokasi.latitude!,
                    jadwal.lokasi.longitude!,
                  ),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _tampilkanInfoLokasi(jadwal),
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '${berKoordinat.length} lokasi ditampilkan · ketuk pin untuk lihat detail',
              style: AppText.helper.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  void _tampilkanInfoLokasi(JadwalDonor jadwal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                jadwal.lokasi.namaLokasi,
                style: AppText.headline.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(jadwal.lokasi.alamat, style: AppText.helper),
              const SizedBox(height: 4),
              Text(
                '${jadwal.slotWaktu} · sisa ${jadwal.kuotaTersisa} kuota',
                style: AppText.helper.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailJadwalScreen(jadwal: jadwal),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Lihat detail',
                    style: AppText.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
