import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pendonor.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticating, authenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  static const _keyToken = 'auth_token';

  AuthStatus status = AuthStatus.unknown;
  Pendonor? pendonor;
  String? token;
  String? errorMessage;

  /// Dipanggil sekali dari SplashScreen buat cek apakah ada sesi login
  /// tersimpan (auto-login), sebelum nentuin lempar ke Home atau Login.
  Future<void> cekSesiTersimpan() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_keyToken);

    if (savedToken == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final data = await _service.profil(savedToken);
      token = savedToken;
      pendonor = data;
      status = AuthStatus.authenticated;
    } catch (_) {
      await prefs.remove(_keyToken);
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String identitas, String password) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();

    try {
      final hasil = await _service.login(identitas: identitas, password: password);
      token = hasil['token'] as String;
      pendonor = hasil['pendonor'] as Pendonor;
      await _simpanToken(token!);
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String nik,
    required String nama,
    required String noTelepon,
    required String password,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    String? alamat,
  }) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();

    try {
      final hasil = await _service.register(
        nik: nik,
        nama: nama,
        noTelepon: noTelepon,
        password: password,
        tanggalLahir: tanggalLahir,
        jenisKelamin: jenisKelamin,
        alamat: alamat,
      );
      token = hasil['token'] as String;
      pendonor = hasil['pendonor'] as Pendonor;
      await _simpanToken(token!);
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    token = null;
    pendonor = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _simpanToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, value);
  }
}
