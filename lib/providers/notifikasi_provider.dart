import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notifikasi.dart';

enum NotifikasiStatusFetch { idle, loading, loaded, error }

class NotifikasiProvider extends ChangeNotifier {
  static const _keySudahTanyaIzin = 'notif_sudah_tanya_izin';

  NotifikasiStatusFetch status = NotifikasiStatusFetch.idle;
  List<NotifikasiItem> daftarNotifikasi = [];
  String? errorMessage;

  /// Dipakai buat nampilin dialog "Aktifkan Notifikasi pada Device" cuma
  /// sekali di percobaan pertama buka Home.
  bool sudahTanyaIzinDevice = false;

  // TODO: sambungin ke endpoint backend notifikasi (belum tersedia),
  // sementara list-nya kosong biar UI empty state kepakai dulu.
  Future<void> muatNotifikasi() async {
    status = NotifikasiStatusFetch.loading;
    notifyListeners();
    try {
      daftarNotifikasi = [];
      status = NotifikasiStatusFetch.loaded;
    } catch (e) {
      status = NotifikasiStatusFetch.error;
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  List<NotifikasiItem> filter(KategoriNotifikasi? kategori) {
    if (kategori == null) return daftarNotifikasi;
    return daftarNotifikasi.where((n) => n.kategori == kategori).toList();
  }

  int get jumlahBelumDibaca =>
      daftarNotifikasi.where((n) => !n.sudahDibaca).length;

  Future<void> cekSudahTanyaIzinDevice() async {
    final prefs = await SharedPreferences.getInstance();
    sudahTanyaIzinDevice = prefs.getBool(_keySudahTanyaIzin) ?? false;
    notifyListeners();
  }

  Future<void> tandaiSudahTanyaIzinDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySudahTanyaIzin, true);
    sudahTanyaIzinDevice = true;
    notifyListeners();
  }
}
