import 'package:flutter/foundation.dart';
import '../models/jadwal_donor.dart';
import '../services/jadwal_service.dart';

enum JadwalStatus { idle, loading, loaded, error }

class JadwalProvider extends ChangeNotifier {
  final JadwalService _service = JadwalService();

  JadwalStatus status = JadwalStatus.idle;
  List<JadwalDonor> hasil = [];
  String? errorMessage;

  String? filterLokasi;
  DateTime? filterTanggal;
  double? filterRadius;

  void setFilter({String? lokasi, DateTime? tanggal, double? radius}) {
    filterLokasi = lokasi;
    filterTanggal = tanggal;
    filterRadius = radius;
  }

  Future<void> cariJadwal({double? lat, double? lng}) async {
    status = JadwalStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      hasil = await _service.cariJadwal(
        lokasi: filterLokasi,
        tanggal: filterTanggal,
        latitude: lat,
        longitude: lng,
        radiusKm: filterRadius,
      );
      status = JadwalStatus.loaded;
    } catch (e) {
      status = JadwalStatus.error;
      errorMessage = e.toString();
    }
    notifyListeners();
  }
}
