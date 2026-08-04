import 'lokasi_donor.dart';

enum StatusKelayakan { layak, tidakLayak, ditunda }

class RiwayatDonor {
  final int idHasil;
  final DateTime tanggal;
  final LokasiDonor lokasi;
  final StatusKelayakan statusKelayakan;
  final double? volumeDarah;
  final String? catatanPetugas;

  const RiwayatDonor({
    required this.idHasil,
    required this.tanggal,
    required this.lokasi,
    required this.statusKelayakan,
    this.volumeDarah,
    this.catatanPetugas,
  });

  // GAP: mapping ini based on kolom enum `status_kelayakan` di tabel
  // `hasil_donor` (layak, tidak_layak, ditunda).
  static StatusKelayakan statusFromString(String value) {
    switch (value) {
      case 'tidak_layak':
        return StatusKelayakan.tidakLayak;
      case 'ditunda':
        return StatusKelayakan.ditunda;
      case 'layak':
      default:
        return StatusKelayakan.layak;
    }
  }
}
