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

  // Loading khusus buat aksi jadwal ulang, dipisah dari `status` biar
  // AntrianTab tidak ikut nampilin full-screen loading pas cuma
  // menjadwalkan ulang.
  bool jadwalUlangLoading = false;

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

  /// FIX: sekarang WAJIB kirim token (lihat AntrianService.ambilNomor).
  /// Dilempar ke pemanggil (bukan disimpan sebagai errorMessage) supaya
  /// DetailJadwalScreen bisa nangkep ApiException dan nge-branch UI beda
  /// tergantung penyebabnya (kuesioner belum diisi vs sudah ada antrian
  /// aktif vs error lain).
  Future<AntrianDonor> ambilNomor({
    required int idJadwal,
    required String token,
  }) async {
    final hasil = await _service.ambilNomor(idJadwal: idJadwal, token: token);
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

  /// FR-4.4: PUT /antrian/:id/jadwal-ulang -- pindah antrian yang masih
  /// 'menunggu' ke jadwal lain. Sukses -> [antrianAktif] diganti dari
  /// respons server (nomor urut & QR baru, karena backend menerbitkan
  /// ulang keduanya untuk jadwal baru).
  Future<bool> jadwalUlang({
    required int idAntrian,
    required int idJadwalBaru,
    required String token,
  }) async {
    jadwalUlangLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final hasil = await _service.jadwalUlang(
        idAntrian: idAntrian,
        idJadwalBaru: idJadwalBaru,
        token: token,
      );
      antrianAktif = hasil;
      jadwalUlangLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      jadwalUlangLoading = false;
      notifyListeners();
      return false;
    }
  }
}
