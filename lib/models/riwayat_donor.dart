import '../utils/json_parse.dart';
import 'antrian_donor.dart';

enum StatusKelayakan { layak, tidakLayak, ditunda }

/// Model Modul Riwayat (FR-8.1-8.3) -- cocok persis sama bentuk satu item
/// respons Riwayat::index() di backend (lihat Riwayat.php). Field-nya BEDA
/// dari AntrianDonor/RiwayatAntrianRingkas (Modul 4): endpoint ini
/// menambahkan status_kelayakan, volume_darah, dan sertifikat_tersedia
/// yang dilampirkan dari tabel `hasil_donor`, sementara lokasi cuma
/// dikirim sebagai nama_lokasi (String), BUKAN object LokasiDonor penuh
/// (tidak ada alamat/lat/lng di respons ini).
class RiwayatDonor {
  final int idAntrian;
  final int nomorUrut;
  final StatusAntrian status;
  final DateTime tanggal;
  final String slotWaktu;
  final String? namaLokasi;
  // Null kalau petugas belum sempat mencatat hasil skrining donor ini
  // (mis. status antrian belum "selesai", atau sudah selesai tapi hasil
  // belum diinput) -- lihat Hasil_donor_model & kolom `status_kelayakan`
  // yang nullable di tabel `hasil_donor`.
  final StatusKelayakan? statusKelayakan;
  final double? volumeDarah;
  // Persis flag `sertifikat_tersedia` dari backend: true hanya kalau
  // status antrian == 'selesai' DAN status_kelayakan == 'layak' -- jangan
  // hitung ulang syarat ini di client, backend yang sumber kebenarannya.
  final bool sertifikatTersedia;

  const RiwayatDonor({
    required this.idAntrian,
    required this.nomorUrut,
    required this.status,
    required this.tanggal,
    required this.slotWaktu,
    this.namaLokasi,
    this.statusKelayakan,
    this.volumeDarah,
    required this.sertifikatTersedia,
  });

  // Mapping kolom enum `status_kelayakan` di tabel `hasil_donor`
  // (layak, tidak_layak, ditunda).
  static StatusKelayakan statusKelayakanFromString(String value) {
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

  factory RiwayatDonor.fromJson(Map<String, dynamic> json) {
    return RiwayatDonor(
      idAntrian: parseIntField(json['id_antrian']),
      nomorUrut: parseIntField(json['nomor_urut']),
      status: StatusAntrian.fromApi(json['status'] as String),
      tanggal: DateTime.parse(json['tanggal'] as String),
      slotWaktu: json['slot_waktu'] as String,
      namaLokasi: json['nama_lokasi'] as String?,
      statusKelayakan: json['status_kelayakan'] != null
          ? statusKelayakanFromString(json['status_kelayakan'] as String)
          : null,
      volumeDarah: parseDoubleFieldOrNull(json['volume_darah']),
      sertifikatTersedia: parseBoolField(json['sertifikat_tersedia']),
    );
  }
}
