import '../models/antrian_donor.dart';
import 'api_client.dart';
// import 'api_exception.dart';

/// Modul 4 -- kontrak persis dari Antrian.php backend. Semua endpoint di
/// sini wajib token (Antrian.php manggil verify_token() + verify_role
/// (['pendonor']) di constructor-nya, berlaku buat semua method).
class AntrianService {
  final ApiClient _client = ApiClient();

  /// FR-4.1+4.2+4.3: POST /antrian
  /// Body: id_jadwal. Kemungkinan error yang PENTING ditangani beda-beda
  /// di UI (bukan cuma tampilin message generik):
  /// - 422 "Lengkapi kuesioner..." -> kuesioner (Modul 2) belum pernah diisi
  /// - 409 "Anda sudah memiliki nomor antrian aktif..." -> field
  ///   fieldErrors kosong, tapi ApiException.message-nya jelas nyebut ini;
  ///   backend nyisipin `id_antrian` yang udah aktif di data (belum
  ///   di-expose ApiClient krn cuma balikin Map data biasa -- kalau perlu
  ///   id itu, tangkap lewat try/catch manual di pemanggil).
  /// - 422 "Belum memenuhi interval minimal donor darah..." -> BR2
  Future<AntrianDonor> ambilNomor({
    required int idJadwal,
    required String token,
  }) async {
    final data = await _client.post(
      '/antrian',
      body: {'id_jadwal': idJadwal},
      token: token,
    );
    return AntrianDonor.fromJson(data);
  }

  /// GET /antrian/saya
  Future<({AntrianDonor? antrianAktif, List<RiwayatAntrianRingkas> riwayat})>
  antrianSaya({required String token}) async {
    final data = await _client.get('/antrian/saya', token: token);

    final aktifJson = data['antrian_aktif'] as Map<String, dynamic>?;
    final riwayatJson = data['riwayat'] as List? ?? [];

    return (
      antrianAktif: aktifJson != null ? AntrianDonor.fromJson(aktifJson) : null,
      riwayat: riwayatJson
          .map((e) => RiwayatAntrianRingkas.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// GET /antrian/:id
  Future<AntrianDonor> detail({
    required int idAntrian,
    required String token,
  }) async {
    final data = await _client.get('/antrian/$idAntrian', token: token);
    return AntrianDonor.fromJson(data);
  }

  /// PUT /antrian/:id/batalkan -- cuma bisa kalau status masih 'menunggu'
  /// DAN jadwal belum mulai (dicek server, bukan client).
  Future<void> batalkan({required int idAntrian, required String token}) async {
    await _client.put('/antrian/$idAntrian/batalkan', token: token);
  }

  /// PUT /antrian/:id/jadwal-ulang
  /// Body: id_jadwal_baru
  Future<AntrianDonor> jadwalUlang({
    required int idAntrian,
    required int idJadwalBaru,
    required String token,
  }) async {
    final data = await _client.put(
      '/antrian/$idAntrian/jadwal-ulang',
      body: {'id_jadwal_baru': idJadwalBaru},
      token: token,
    );
    return AntrianDonor.fromJson(data);
  }
}
