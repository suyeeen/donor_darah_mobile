import '../config/api_config.dart';
import '../models/lokasi_donor.dart';
import 'api_client.dart';

/// Modul 3 -- GET /lokasi/peta (publik, TANPA token, lihat Lokasi.php
/// backend). BARU dibuat -- sebelumnya belum ada LokasiService sama
/// sekali, titik-titik lokasi di peta cuma diturunkan dari hasil
/// `JadwalService.cariJadwal()` (lihat HasilPencarianScreen), bukan dari
/// endpoint lokasi khusus.
///
/// Bedanya sama data lokasi yang nempel di JadwalDonor: endpoint ini
/// balikin SEMUA titik lokasi donor aktif (tetap & mobile unit), TERLEPAS
/// dari ada jadwal terbuka atau tidak -- cocok buat layar "Peta Lokasi
/// Donor" yang berdiri sendiri (FR-3.2), beda dari peta di hasil
/// pencarian jadwal yang cuma nampilin lokasi yang PUNYA jadwal aktif.
class LokasiService {
  final ApiClient _client = ApiClient();

  /// [jenis] opsional: 'tetap' atau 'mobile_unit'. Kirim null buat ambil
  /// semua jenis lokasi sekaligus.
  Future<List<LokasiDonor>> getPeta({String? jenis}) async {
    final query = <String, String>{if (jenis != null) 'jenis': jenis};

    final data = await _client.get(ApiConfig.lokasiPeta, query: query);
    final list = data['_list'] as List? ?? [];
    return list
        .map((e) => LokasiDonor.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
