import 'package:flutter/foundation.dart';
import '../models/riwayat_donor.dart';
import '../services/api_exception.dart';
import '../services/riwayat_service.dart';

enum RiwayatStatusFetch { idle, loading, loaded, error }

class RiwayatProvider extends ChangeNotifier {
  final RiwayatService _service = RiwayatService();

  RiwayatStatusFetch status = RiwayatStatusFetch.idle;
  List<RiwayatDonor> daftarRiwayat = [];
  int jumlahDonorBerhasil = 0;
  bool bolehDonorSekarang = true;
  DateTime? estimasiDonorBerikutnya;
  String? errorMessage;

  Future<void> muatRiwayat({required String token}) async {
    status = RiwayatStatusFetch.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final hasil = await _service.riwayatSaya(token: token);
      daftarRiwayat = hasil.daftar;
      jumlahDonorBerhasil = hasil.jumlahDonorBerhasil;
      bolehDonorSekarang = hasil.bolehDonorSekarang;
      estimasiDonorBerikutnya = hasil.estimasiDonorBerikutnya;
      status = RiwayatStatusFetch.loaded;
    } on ApiException catch (e) {
      status = RiwayatStatusFetch.error;
      errorMessage = e.message;
    } catch (e) {
      status = RiwayatStatusFetch.error;
      errorMessage = 'Terjadi kesalahan tak terduga';
    }
    notifyListeners();
  }
}
