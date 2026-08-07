import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notifikasi.dart';
import '../services/api_exception.dart';
import '../services/notifikasi_service.dart';

enum NotifikasiStatusFetch { idle, loading, loaded, error }

class NotifikasiProvider extends ChangeNotifier {
  static const _keySudahTanyaIzin = 'notif_sudah_tanya_izin';
  static const _keyNotifikasiAktif = 'notif_aktif';

  final NotifikasiService _service = NotifikasiService();

  NotifikasiStatusFetch status = NotifikasiStatusFetch.idle;
  List<NotifikasiItem> daftarNotifikasi = [];
  String? errorMessage;

  /// Dipakai buat nampilin dialog "Aktifkan Notifikasi pada Device" cuma
  /// sekali, tepat setelah pendonor selesai mendaftar/ambil nomor antrian
  /// (bukan lagi di percobaan pertama buka Home).
  bool sudahTanyaIzinDevice = false;

  /// True kalau pendonor pilih "Ya" di dialog izin notifikasi. Selama
  /// antrian pendonor masih berjalan (belum selesai/dibatalkan),
  /// notifikasi ini tetap aktif buat ngasih kabar realtime (nomor
  /// dipanggil, tersisa sekian orang di depan, dst).
  bool notifikasiAktif = false;

  /// FR-6.x: GET /notifikasi. Kalau [token] null (belum login), daftar
  /// dikosongkan begitu saja tanpa error -- wajar buat kondisi belum
  /// login (mis. dipanggil dari SplashScreen sebelum auth selesai).
  Future<void> muatNotifikasi({String? token}) async {
    if (token == null) {
      daftarNotifikasi = [];
      status = NotifikasiStatusFetch.loaded;
      notifyListeners();
      return;
    }

    status = NotifikasiStatusFetch.loading;
    errorMessage = null;
    notifyListeners();
    try {
      daftarNotifikasi = await _service.daftarNotifikasi(token: token);
      status = NotifikasiStatusFetch.loaded;
    } on ApiException catch (e) {
      status = NotifikasiStatusFetch.error;
      errorMessage = e.message;
    } catch (e) {
      status = NotifikasiStatusFetch.error;
      errorMessage = 'Terjadi kesalahan tak terduga';
    }
    notifyListeners();
  }

  List<NotifikasiItem> filter(JenisNotifikasi? jenis) {
    if (jenis == null) return daftarNotifikasi;
    return daftarNotifikasi.where((n) => n.jenis == jenis).toList();
  }

  int get jumlahBelumDibaca =>
      daftarNotifikasi.where((n) => !n.sudahDibaca).length;

  Future<void> cekSudahTanyaIzinDevice() async {
    final prefs = await SharedPreferences.getInstance();
    sudahTanyaIzinDevice = prefs.getBool(_keySudahTanyaIzin) ?? false;
    notifikasiAktif = prefs.getBool(_keyNotifikasiAktif) ?? false;
    notifyListeners();
  }

  Future<void> tandaiSudahTanyaIzinDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySudahTanyaIzin, true);
    sudahTanyaIzinDevice = true;
    notifyListeners();
  }

  /// Dipanggil begitu pendonor menyetujui dialog izin notifikasi. Status
  /// ini yang dipakai AntrianStatusScreen buat nunjukin badge "Notifikasi
  /// aktif" selama antrian pendonor masih berjalan.
  Future<void> aktifkanNotifikasi() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifikasiAktif, true);
    notifikasiAktif = true;
    notifyListeners();
  }

  /// Dipakai toggle di PengaturanScreen buat matiin notifikasi lagi kalau
  /// user berubah pikiran setelah sebelumnya mengizinkan.
  Future<void> nonaktifkanNotifikasi() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifikasiAktif, false);
    notifikasiAktif = false;
    notifyListeners();
  }
}
