import 'package:flutter/foundation.dart';
import '../models/antrian_donor.dart';
import '../services/antrian_service.dart';

enum AntrianStatusFetch { idle, loading, loaded, error }

class AntrianProvider extends ChangeNotifier {
  final AntrianService _service = AntrianService();

  AntrianStatusFetch status = AntrianStatusFetch.idle;
  List<AntrianDonor> daftarAntrian = [];
  String? errorMessage;

  Future<void> muatAntrianSaya() async {
    status = AntrianStatusFetch.loading;
    notifyListeners();
    try {
      daftarAntrian = await _service.antrianSaya();
      status = AntrianStatusFetch.loaded;
    } catch (e) {
      status = AntrianStatusFetch.error;
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Dipanggil dari ETiketScreen begitu pendonor selesai ambil nomor
  /// antrian, biar langsung muncul di tab "Antrian" pas kembali ke Home --
  /// tanpa perlu re-fetch dari service (yang datanya masih dummy statis).
  /// Ditaruh di paling depan list biar antrian terbaru muncul duluan.
  void tambahAntrianBaru(AntrianDonor antrian) {
    daftarAntrian = [antrian, ...daftarAntrian];
    status = AntrianStatusFetch.loaded;
    notifyListeners();
  }
}
