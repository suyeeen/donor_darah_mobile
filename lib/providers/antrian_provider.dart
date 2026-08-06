import 'package:flutter/foundation.dart';
import '../models/antrian_donor.dart';
import '../services/antrian_service.dart';
import '../services/api_exception.dart';

enum AntrianStatusFetch { idle, loading, loaded, error }

class AntrianProvider extends ChangeNotifier {
  final AntrianService _service = AntrianService();

  AntrianStatusFetch status = AntrianStatusFetch.idle;
  AntrianDonor? antrianAktif;
  List<RiwayatAntrianRingkas> riwayat = [];
  String? errorMessage;

  Future<void> muatAntrianSaya({required String token}) async {
    status = AntrianStatusFetch.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final hasil = await _service.antrianSaya(token: token);
      antrianAktif = hasil.antrianAktif;
      riwayat = hasil.riwayat;
      status = AntrianStatusFetch.loaded;
    } on ApiException catch (e) {
      status = AntrianStatusFetch.error;
      errorMessage = e.message;
    } catch (e) {
      status = AntrianStatusFetch.error;
      errorMessage = 'Terjadi kesalahan tak terduga';
    }
    notifyListeners();
  }

  /// Dilempar ke pemanggil (bukan disimpan sebagai errorMessage) supaya
  /// DetailJadwalScreen bisa nangkep ApiException dan nge-branch UI beda
  /// tergantung penyebabnya (kuesioner belum diisi vs sudah ada antrian
  /// aktif vs error lain) -- lihat pemakaiannya di detail_jadwal_screen.dart.
  Future<AntrianDonor> ambilNomor({required int idJadwal}) async {
    final hasil = await _service.ambilNomor(idJadwal: idJadwal);
    antrianAktif = hasil;
    notifyListeners();
    return hasil;
  }

  Future<void> batalkan({required int idAntrian, required String token}) async {
    await _service.batalkan(idAntrian: idAntrian, token: token);
    if (antrianAktif?.idAntrian == idAntrian) {
      antrianAktif = null;
      notifyListeners();
    }
  }
}
