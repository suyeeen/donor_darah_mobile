import 'package:flutter/foundation.dart';
import '../models/riwayat_donor.dart';
import '../services/antrian_service.dart';

enum RiwayatStatusFetch { idle, loading, loaded, error }

class RiwayatProvider extends ChangeNotifier {
  final AntrianService _service = AntrianService();

  RiwayatStatusFetch status = RiwayatStatusFetch.idle;
  List<RiwayatDonor> daftarRiwayat = [];
  String? errorMessage;

  Future<void> muatRiwayat() async {
    status = RiwayatStatusFetch.loading;
    notifyListeners();
    try {
      daftarRiwayat = await _service.riwayatSaya();
      status = RiwayatStatusFetch.loaded;
    } catch (e) {
      status = RiwayatStatusFetch.error;
      errorMessage = e.toString();
    }
    notifyListeners();
  }
}
