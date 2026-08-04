import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notifikasi.dart';

enum NotifikasiStatusFetch { idle, loading, loaded, error }

class NotifikasiProvider extends ChangeNotifier {
  static const _keySudahTanyaIzin = 'notif_sudah_tanya_izin';
  static const _keyNotifikasiAktif = 'notif_aktif';

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
