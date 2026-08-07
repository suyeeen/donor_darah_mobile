import '../utils/json_parse.dart';
import 'lokasi_donor.dart';

/// Cocok sama respons ASLI `GET /jadwal/cari` (lihat Jadwal_model::cari()
/// di backend) -- BUKAN nested `{ ..., lokasi_donor: {...} }` kayak
/// asumsi lama, tapi satu row FLAT hasil JOIN `jadwal_donor` +
/// `lokasi_donor` (field lokasi nyampur rata sama field jadwal dalam
/// satu object yang sama, mis. `nama_lokasi` ada di level atas, bukan
/// di dalam sub-object).
class JadwalDonor {
  final int idJadwal;
  final LokasiDonor lokasi;
  final DateTime tanggal;
  final String slotWaktu;
  final int kuotaTotal;
  final int kuotaTersisa;

  // Backend query `cari()` SENGAJA cuma nampilin jadwal berstatus 'aktif'
  // (WHERE jadwal_donor.status = 'aktif') dan TIDAK IKUT nge-select kolom
  // `status` itu sendiri di response -- jadi field ini nullable, dan
  // kalau null bisa dianggap 'aktif' (karena filter query menjamin itu).
  final String? status;

  // `jadwal_donor.kuota_total - kuota_tersisa`, dihitung backend sebagai
  // alias `estimasi_antrian` -- dipakai buat estimasi posisi kira-kira
  // kalau ambil nomor sekarang (BUKAN posisi antrian real, itu baru ada
  // setelah benar-benar POST /antrian, lihat Modul 4).
  final int? estimasiAntrian;

  // Cuma keisi kalau request kirim lat & lng (backend hitung Haversine
  // dan urutkan ASC berdasar ini) -- null kalau pencarian tanpa lokasi
  // pengguna.
  final double? jarakKm;

  // TIDAK ADA di tabel `jadwal_donor` sama sekali -- backend nggak
  // pernah balikin field ini. Dibiarkan nullable + selalu null dari
  // fromJson supaya UI (mis. KuesionerIntroScreen/DetailJadwalScreen)
  // yang masih fallback ke "Donor Darah Bersama <nama lokasi>" tetap
  // aman, TANPA berpura-pura backend punya data yang sebenarnya tidak
  // ada. Jangan expect field ini pernah keisi dari API.
  final String? namaKegiatan;

  JadwalDonor({
    required this.idJadwal,
    required this.lokasi,
    required this.tanggal,
    required this.slotWaktu,
    required this.kuotaTotal,
    required this.kuotaTersisa,
    this.status,
    this.estimasiAntrian,
    this.jarakKm,
    this.namaKegiatan,
  });

  bool get kuotaHabis => kuotaTersisa <= 0;

  // Diturunkan dari kuotaTotal - kuotaTersisa, bukan field terpisah --
  // biar gak ada risiko dua angka ini kontradiksi satu sama lain.
  // (Nilainya identik sama `estimasiAntrian` dari server, tapi tetap
  // dihitung ulang di client biar gak gantung ke field yang bisa null.)
  int get kuotaTerisi => kuotaTotal - kuotaTersisa;

  factory JadwalDonor.fromJson(Map<String, dynamic> json) {
    return JadwalDonor(
      idJadwal: parseIntField(json['id_jadwal']),
      // LokasiDonor.fromJson dipanggil ke json YANG SAMA (bukan sub-map)
      // karena field lokasi (id_lokasi, nama_lokasi, jenis, alamat,
      // latitude, longitude) memang ada di level atas object ini.
      lokasi: LokasiDonor.fromJson(json),
      tanggal: DateTime.parse(json['tanggal'] as String),
      slotWaktu: json['slot_waktu'] as String,
      kuotaTotal: parseIntField(json['kuota_total']),
      kuotaTersisa: parseIntField(json['kuota_tersisa']),
      status: json['status'] as String?,
      estimasiAntrian: parseIntFieldOrNull(json['estimasi_antrian']),
      jarakKm: parseDoubleFieldOrNull(json['jarak_km']),
      namaKegiatan: json['nama_kegiatan'] as String?,
    );
  }
}
