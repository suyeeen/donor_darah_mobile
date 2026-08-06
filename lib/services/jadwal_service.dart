import '../config/api_config.dart';
import '../models/jadwal_donor.dart';
import 'api_client.dart';

/// Modul 3 -- GET /jadwal/cari (publik, TANPA token, lihat Jadwal.php
/// backend: controller ini sengaja tidak manggil verify_token() karena
/// FR-3.1/FR-3.3 harus bisa diakses walau pendonor belum login).
class JadwalService {
  final ApiClient _client = ApiClient();

  /// [lokasi] dikirim sebagai query param `nama_lokasi` (backend pakai
  /// LIKE match ke lokasi_donor.nama_lokasi, lihat Jadwal_model::cari()).
  ///
  /// [radiusKm] SENGAJA TIDAK dikirim ke backend -- endpoint ini tidak
  /// punya filter radius sama sekali, cuma ORDER BY jarak (Haversine)
  /// kalau [latitude]+[longitude] dikirim. Parameter ini dipertahankan
  /// di signature biar JadwalProvider tidak perlu diubah, tapi difilter
  /// ulang di CLIENT setelah hasil balik kalau memang mau dibatasi radius.
  Future<List<JadwalDonor>> cariJadwal({
    String? lokasi,
    DateTime? tanggal,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int? limit,
    int? offset,
  }) async {
    final query = <String, String>{
      if (lokasi != null && lokasi.trim().isNotEmpty)
        'nama_lokasi': lokasi.trim(),
      if (tanggal != null) 'tanggal': _formatTanggal(tanggal),
      if (latitude != null) 'lat': latitude.toString(),
      if (longitude != null) 'lng': longitude.toString(),
      if (limit != null) 'limit': limit.toString(),
      if (offset != null) 'offset': offset.toString(),
    };

    final data = await _client.get(ApiConfig.jadwalCari, query: query);
    final list = data['_list'] as List? ?? [];
    var hasil = list
        .map((e) => JadwalDonor.fromJson(e as Map<String, dynamic>))
        .toList();

    // Filter radius di client, karena backend tidak menyediakannya.
    if (radiusKm != null && latitude != null && longitude != null) {
      hasil = hasil
          .where((j) => j.jarakKm == null || j.jarakKm! <= radiusKm)
          .toList();
    }

    return hasil;
  }

  /// GAP: backend TIDAK punya endpoint "detail satu jadwal" publik
  /// (cuma ada `cari()` yang balikin list, dan `get_by_id_with_lokasi()`
  /// di model yang cuma dipakai internal oleh Antrian.php buat e-tiket).
  /// Jadi detail jadwal di app ini diambil dari hasil `cariJadwal()` yang
  /// sudah di-cache di JadwalProvider, BUKAN panggilan API terpisah --
  /// kalau butuh data super fresh, panggil ulang [cariJadwal] dan cari
  /// idnya di hasilnya.
  Future<JadwalDonor?> detailDariCache(
    List<JadwalDonor> cache,
    int idJadwal,
  ) async {
    try {
      return cache.firstWhere((j) => j.idJadwal == idJadwal);
    } catch (_) {
      return null;
    }
  }

  String _formatTanggal(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
