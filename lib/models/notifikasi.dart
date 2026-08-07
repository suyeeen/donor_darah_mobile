import '../utils/json_parse.dart';

/// Kategori notifikasi -- MAPPING LANGSUNG dari kolom enum
/// `notifikasi.jenis` di backend: 'konfirmasi_pendaftaran',
/// 'pengingat_h1', 'giliran_mendekati', 'perubahan_jadwal'.
/// (Sebelumnya model ini salah asumsi field bernama `kategori` dengan
/// value 'antrian'/'jadwal'/'selesai' -- backend TIDAK PERNAH kirim
/// field itu, yang ada cuma `jenis` dengan value di atas.)
enum JenisNotifikasi {
  konfirmasiPendaftaran,
  pengingatH1,
  giliranMendekati,
  perubahanJadwal;

  static JenisNotifikasi fromApi(String value) {
    switch (value) {
      case 'pengingat_h1':
        return JenisNotifikasi.pengingatH1;
      case 'giliran_mendekati':
        return JenisNotifikasi.giliranMendekati;
      case 'perubahan_jadwal':
        return JenisNotifikasi.perubahanJadwal;
      case 'konfirmasi_pendaftaran':
      default:
        return JenisNotifikasi.konfirmasiPendaftaran;
    }
  }

  /// Backend TIDAK kirim judul terpisah (cuma `isi_pesan` polos) --
  /// judul singkat ini diturunkan di client dari jenis notifikasinya.
  String get judul {
    switch (this) {
      case JenisNotifikasi.konfirmasiPendaftaran:
        return 'Pendaftaran Antrian';
      case JenisNotifikasi.pengingatH1:
        return 'Pengingat Jadwal Donor';
      case JenisNotifikasi.giliranMendekati:
        return 'Giliran Anda';
      case JenisNotifikasi.perubahanJadwal:
        return 'Perubahan Jadwal';
    }
  }
}

class NotifikasiItem {
  final int idNotifikasi;
  final JenisNotifikasi jenis;
  final String pesan;
  final DateTime waktu;
  final bool sudahDibaca;

  NotifikasiItem({
    required this.idNotifikasi,
    required this.jenis,
    required this.pesan,
    required this.waktu,
    this.sudahDibaca = false,
  });

  String get judul => jenis.judul;

  factory NotifikasiItem.fromJson(Map<String, dynamic> json) {
    return NotifikasiItem(
      idNotifikasi: parseIntField(json['id_notifikasi']),
      jenis: JenisNotifikasi.fromApi(json['jenis'] as String? ?? ''),
      pesan: json['isi_pesan'] as String? ?? '',
      waktu:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      sudahDibaca: parseBoolField(json['dibaca']),
    );
  }
}
