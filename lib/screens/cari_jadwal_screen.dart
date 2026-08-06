import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jadwal_provider.dart';
import 'hasil_pencarian_screen.dart';
import 'peta_lokasi_screen.dart';

class CariJadwalScreen extends StatefulWidget {
  const CariJadwalScreen({super.key});

  @override
  State<CariJadwalScreen> createState() => _CariJadwalScreenState();
}

class _CariJadwalScreenState extends State<CariJadwalScreen> {
  final _lokasiController = TextEditingController();
  DateTime? _tanggalDipilih;
  double _radius = 10;

  @override
  void dispose() {
    _lokasiController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final hasil = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (hasil != null) {
      setState(() => _tanggalDipilih = hasil);
    }
  }

  void _cariSekarang() {
    final provider = context.read<JadwalProvider>();
    provider.setFilter(
      lokasi: _lokasiController.text.trim(),
      tanggal: _tanggalDipilih,
      radius: _radius,
    );
    provider.cariJadwal();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HasilPencarianScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari jadwal & lokasi'),
        actions: [
          // FR-3.2: peta lokasi donor berdiri sendiri (semua lokasi
          // aktif, bukan cuma yang lagi punya jadwal terbuka).
          IconButton(
            tooltip: 'Peta lokasi donor',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PetaLokasiScreen()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _lokasiController,
              decoration: const InputDecoration(
                labelText: 'Nama lokasi / cabang',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pilihTanggal,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _tanggalDipilih == null
                      ? 'Semua tanggal'
                      : '${_tanggalDipilih!.day}/${_tanggalDipilih!.month}/${_tanggalDipilih!.year}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Radius pencarian: ${_radius.toStringAsFixed(0)} km'),
            Slider(
              value: _radius,
              min: 1,
              max: 50,
              divisions: 49,
              label: '${_radius.toStringAsFixed(0)} km',
              onChanged: (v) => setState(() => _radius = v),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _cariSekarang,
                icon: const Icon(Icons.search),
                label: const Text('Cari jadwal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
