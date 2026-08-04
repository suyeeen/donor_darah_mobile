import 'lokasi_donor.dart';

class JadwalDonor {
  final int idJadwal;
  final LokasiDonor lokasi;
  final DateTime tanggal;
  final String slotWaktu;
  final int kuotaTotal;
  final int kuotaTersisa;
  final String status;

  // Dipakai di KuesionerIntroScreen. Nullable karena belum tentu tiap
  // jadwal punya nama kegiatan khusus -- kalau null, UI fallback ke
  // "Donor Darah Bersama <nama lokasi>".
  final String? namaKegiatan;

  JadwalDonor({
    required this.idJadwal,
    required this.lokasi,
    required this.tanggal,
    required this.slotWaktu,
    required this.kuotaTotal,
    required this.kuotaTersisa,
    required this.status,
    this.namaKegiatan,
  });

  bool get kuotaHabis => kuotaTersisa <= 0;

  // Diturunkan dari kuotaTotal - kuotaTersisa, bukan field terpisah --
  // biar gak ada risiko dua angka ini kontradiksi satu sama lain.
  int get kuotaTerisi => kuotaTotal - kuotaTersisa;

  // NOTE: sesuaikan key JSON di sini kalau response API Laravel lo beda.
  // Struktur ini nebak field snake_case sesuai skema database
  // (jadwal_donor + relasi lokasi_donor).
  factory JadwalDonor.fromJson(Map<String, dynamic> json) {
    return JadwalDonor(
      idJadwal: json['id_jadwal'] as int,
      lokasi: LokasiDonor.fromJson(
        (json['lokasi_donor'] ?? json['lokasi']) as Map<String, dynamic>,
      ),
      tanggal: DateTime.parse(json['tanggal'] as String),
      slotWaktu: json['slot_waktu'] as String,
      kuotaTotal: json['kuota_total'] as int,
      kuotaTersisa: json['kuota_tersisa'] as int,
      status: json['status'] as String,
      namaKegiatan: json['nama_kegiatan'] as String?,
    );
  }
}
