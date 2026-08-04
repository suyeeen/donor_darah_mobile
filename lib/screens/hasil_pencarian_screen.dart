import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jadwal_provider.dart';
import '../widgets/jadwal_card.dart';
import 'detail_jadwal_screen.dart';

class HasilPencarianScreen extends StatefulWidget {
  const HasilPencarianScreen({super.key});

  @override
  State<HasilPencarianScreen> createState() => _HasilPencarianScreenState();
}

class _HasilPencarianScreenState extends State<HasilPencarianScreen> {
  bool _tampilPeta = false;

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
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(provider.errorMessage ?? 'Terjadi kesalahan',
                        textAlign: TextAlign.center),
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
            // TODO: integrasi google_maps_flutter di sini.
            // Marker diambil dari provider.hasil[i].lokasi.latitude/longitude
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Tampilan peta belum aktif — tambahkan paket google_maps_flutter '
                  'dan API key Maps dulu.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
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
}
