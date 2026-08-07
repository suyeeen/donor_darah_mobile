import '../config/api_config.dart';
import '../models/papan_antrian.dart';
import 'api_client.dart';

/// Modul 5 (FR-5.4) -- GET /papan-antrian?id_jadwal=X, publik TANPA token
/// (lihat Papan.php backend: controller ini sengaja tidak verify_token()
/// karena dipajang di layar/TV lokasi, bukan buat pendonor login).
class PapanAntrianService {
  final ApiClient _client = ApiClient();

  Future<PapanAntrian> getPapanAntrian({required int idJadwal}) async {
    final data = await _client.get(
      ApiConfig.papanAntrian,
      query: {'id_jadwal': idJadwal.toString()},
    );
    return PapanAntrian.fromJson(data);
  }
}
