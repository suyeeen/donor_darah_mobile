import 'jadwal_donor.dart';

enum StatusAntrian {
  menunggu,
  dipanggil,
  sedangDiproses,
  selesai,
  tidakHadir,
  dibatalkan,
}

class AntrianDonor {
  final int idAntrian;
  final JadwalDonor jadwal;
  final int nomorUrut;
  final StatusAntrian status;
  final String qrCode;
  final DateTime? batasWaktuCheckin;

  const AntrianDonor({
    required this.idAntrian,
    required this.jadwal,
    required this.nomorUrut,
    required this.status,
    required this.qrCode,
    this.batasWaktuCheckin,
  });

  String get nomorAntrian => 'A-${nomorUrut.toString().padLeft(3, '0')}';

  // GAP: mapping ini based on kolom enum `status` di tabel `antrian`
  // (menunggu, dipanggil, sedang_diproses, selesai, tidak_hadir,
  // dibatalkan). Dipake nanti pas parsing response API asli.
  static StatusAntrian statusFromString(String value) {
    switch (value) {
      case 'dipanggil':
        return StatusAntrian.dipanggil;
      case 'sedang_diproses':
        return StatusAntrian.sedangDiproses;
      case 'selesai':
        return StatusAntrian.selesai;
      case 'tidak_hadir':
        return StatusAntrian.tidakHadir;
      case 'dibatalkan':
        return StatusAntrian.dibatalkan;
      case 'menunggu':
      default:
        return StatusAntrian.menunggu;
    }
  }
}
