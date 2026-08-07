import '../config/api_config.dart';
import '../models/riwayat_donor.dart';
import 'api_client.dart';

/// Modul Riwayat & Sertifikat Donor (FR-8.1 - FR-8.3) -- kontrak persis
/// dari Riwayat.php backend. Semua endpoint di sini wajib token + role
/// pendonor (verify_token() + verify_role(['pendonor']) di constructor
/// controller-nya).
class RiwayatService {
  final ApiClient _client = ApiClient();

  /// GET /riwayat
  /// FR-8.1: daftar lengkap riwayat kegiatan donor (semua status antrian,
  /// bukan cuma yang sudah selesai). FR-8.3: sekaligus dilampirkan info
  /// kapan pendonor boleh donor lagi (BR2, interval 3 bulan).
  Future<
    ({
      List<RiwayatDonor> daftar,
      int jumlahDonorBerhasil,
      bool bolehDonorSekarang,
      DateTime? estimasiDonorBerikutnya,
    })
  >
  riwayatSaya({required String token}) async {
    final data = await _client.get(ApiConfig.riwayat, token: token);
    final list = data['riwayat'] as List? ?? [];

    return (
      daftar: list
          .map((e) => RiwayatDonor.fromJson(e as Map<String, dynamic>))
          .toList(),
      jumlahDonorBerhasil: data['jumlah_donor_berhasil'] as int? ?? 0,
      bolehDonorSekarang: data['boleh_donor_sekarang'] as bool? ?? true,
      estimasiDonorBerikutnya: data['estimasi_donor_berikutnya'] != null
          ? DateTime.tryParse(data['estimasi_donor_berikutnya'] as String)
          : null,
    );
  }

  /// GET /riwayat/:id_antrian/sertifikat
  /// FR-8.2: file PDF sertifikat, di-generate langsung di server
  /// (Dompdf). Cuma tersedia kalau antrian.status == 'selesai' DAN
  /// hasil_donor.status_kelayakan == 'layak' -- cek dulu lewat field
  /// RiwayatDonor.sertifikatTersedia sebelum manggil ini, biar UI bisa
  /// sembunyikan tombolnya alih-alih nunggu 400 dari server.
  Future<List<int>> unduhSertifikat({
    required int idAntrian,
    required String token,
  }) {
    return _client.getBytes(
      ApiConfig.riwayatSertifikat(idAntrian),
      token: token,
    );
  }
}
