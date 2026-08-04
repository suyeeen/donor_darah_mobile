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
}
