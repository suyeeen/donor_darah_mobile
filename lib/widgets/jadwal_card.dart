import 'package:flutter/material.dart';
import '../models/jadwal_donor.dart';

class JadwalCard extends StatelessWidget {
  final JadwalDonor jadwal;
  final VoidCallback onTap;

  const JadwalCard({super.key, required this.jadwal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final habis = jadwal.kuotaHabis;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: habis ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jadwal.lokasi.namaLokasi,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${jadwal.tanggal.day}/${jadwal.tanggal.month}/${jadwal.tanggal.year} • ${jadwal.slotWaktu}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      jadwal.lokasi.alamat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: habis ? Colors.grey.shade300 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  habis ? 'Penuh' : 'Sisa ${jadwal.kuotaTersisa}',
                  style: TextStyle(
                    color: habis ? Colors.grey.shade700 : Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
