import 'package:flutter/material.dart';
import '../models/jadwal_donor.dart';
import 'kuesioner_intro_screen.dart';

class DetailJadwalScreen extends StatelessWidget {
  final JadwalDonor jadwal;

  const DetailJadwalScreen({super.key, required this.jadwal});

  @override
  Widget build(BuildContext context) {
    final habis = jadwal.kuotaHabis;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail jadwal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              jadwal.lokasi.namaLokasi,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              jadwal.lokasi.alamat,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _baris(
              Icons.calendar_today_outlined,
              '${jadwal.tanggal.day}/${jadwal.tanggal.month}/${jadwal.tanggal.year}',
            ),
            _baris(Icons.schedule_outlined, jadwal.slotWaktu),
            _baris(
              Icons.people_outline,
              habis
                  ? 'Kuota penuh (${jadwal.kuotaTotal} slot)'
                  : 'Sisa ${jadwal.kuotaTersisa} dari ${jadwal.kuotaTotal} slot',
            ),
            const SizedBox(height: 24),
            // TODO: tempel mini map pakai google_maps_flutter, marker dari
            // jadwal.lokasi.latitude / jadwal.lokasi.longitude
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: habis
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                KuesionerIntroScreen(jadwal: jadwal),
                          ),
                        );
                      },
                child: Text(habis ? 'Kuota penuh' : 'Ambil nomor antrian'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _baris(IconData icon, String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Text(teks),
        ],
      ),
    );
  }
}
