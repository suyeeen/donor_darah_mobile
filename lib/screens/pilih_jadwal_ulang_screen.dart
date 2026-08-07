import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/antrian_donor.dart';
import '../models/jadwal_donor.dart';
import '../providers/antrian_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/jadwal_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/jadwal_card.dart';

/// FR-4.4: pilih jadwal baru buat memindahkan antrian yang masih
/// 'menunggu'. Sumber daftar jadwal dipakai ulang dari [JadwalProvider]
/// (sudah di-fetch di HomeScreen) -- jadwal yang sama dengan antrian
/// saat ini disembunyikan karena backend menolak id_jadwal_baru yang
/// sama persis (lihat Antrian::jadwal_ulang()).
class PilihJadwalUlangScreen extends StatefulWidget {
  final AntrianDonor antrianSaatIni;

  const PilihJadwalUlangScreen({super.key, required this.antrianSaatIni});

  @override
  State<PilihJadwalUlangScreen> createState() => _PilihJadwalUlangScreenState();
}

class _PilihJadwalUlangScreenState extends State<PilihJadwalUlangScreen> {
  bool _memproses = false;

  Future<void> _pilih(JadwalDonor jadwal) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _memproses = true);

    final sukses = await context.read<AntrianProvider>().jadwalUlang(
      idAntrian: widget.antrianSaatIni.idAntrian,
      idJadwalBaru: jadwal.idJadwal,
      token: token,
    );

    if (!mounted) return;
    setState(() => _memproses = false);

    if (sukses) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Antrian berhasil dijadwalkan ulang')),
      );
    } else {
      final pesan = context.read<AntrianProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesan ?? 'Gagal menjadwalkan ulang')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final jadwalProvider = context.watch<JadwalProvider>();
    final daftarJadwal = jadwalProvider.hasil
        .where((j) => j.idJadwal != widget.antrianSaatIni.jadwal?.idJadwal)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Jadwal ulang antrian',
          style: AppText.headline.copyWith(fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (daftarJadwal.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Tidak ada jadwal lain yang tersedia saat ini.',
                    textAlign: TextAlign.center,
                    style: AppText.helper,
                  ),
                ),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                itemCount: daftarJadwal.length,
                itemBuilder: (context, i) {
                  final jadwal = daftarJadwal[i];
                  return JadwalCard(
                    jadwal: jadwal,
                    onTap: _memproses ? () {} : () => _pilih(jadwal),
                  );
                },
              ),
            if (_memproses)
              Container(
                color: Colors.black.withValues(alpha: 0.05),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
