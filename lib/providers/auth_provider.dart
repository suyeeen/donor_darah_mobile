import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pendonor.dart';
import '../services/auth_service.dart';
import '../services/api_exception.dart';

enum AuthStatus {
  unknown,
  unauthenticated,
  authenticating,
  // Akun sudah register, nunggu input kode OTP (FR-1.1) -- di status ini
  // AuthScreen harus sudah pindah ke VerifikasiOtpScreen.
  menungguOtp,
  authenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  static const _keyToken = 'auth_token';

  AuthStatus status = AuthStatus.unknown;
  Pendonor? pendonor;
  String? token;
  String? errorMessage;

  // --- State khusus alur OTP registrasi ---------------------------------
  String? emailMenungguOtp;
  int? otpBerlakuMenit;
  String? otpDevOnly; // cuma keisi kalau backend lagi mode dev/testing
  bool otpLoading = false;
  String? otpErrorMessage;

  // Password disimpan sementara CUMA selama proses register -> verifikasi
  // OTP berlangsung, biar begitu OTP sukses, pendonor bisa langsung
  // auto-login tanpa harus ngetik ulang password (backend memang tidak
  // balikin token dari verify-otp, lihat AuthService.verifyOtp). Selalu
  // dibersihkan di _bersihkanStateOtp().
  String? _passwordSementara;

  /// Dipanggil sekali dari SplashScreen. CATATAN: backend belum punya
  /// endpoint "cek token masih valid" yang ringan (mis. /auth/me) --
  /// validasi token sebenarnya baru kejadian pas Modul 2 (ProfilService)
  /// manggil GET /profil pertama kali. Di sini kita cuma cek token
  /// TERSIMPAN ada atau tidak; kalau ternyata token sudah kedaluwarsa,
  /// request API pertama akan gagal 401 dan pemanggil wajib redirect ke
  /// login lagi (tangani di http interceptor Modul 2 nanti).
  Future<void> cekSesiTersimpan() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_keyToken);

    if (savedToken == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    token = savedToken;
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// FR-1.1: registrasi. Sukses TIDAK langsung login -- pindah ke status
  /// [AuthStatus.menungguOtp], UI wajib navigasi ke VerifikasiOtpScreen.
  Future<bool> register({
    required String nik,
    required String nama,
    required DateTime tanggalLahir,
    required String jenisKelamin,
    required String noTelp,
    required String email,
    required String password,
  }) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();

    try {
      final hasil = await _service.register(
        nik: nik,
        nama: nama,
        tanggalLahir: tanggalLahir,
        jenisKelamin: jenisKelamin,
        noTelp: noTelp,
        email: email,
        password: password,
      );

      emailMenungguOtp = email;
      otpBerlakuMenit = hasil.otp.otpBerlakuMenit;
      otpDevOnly = hasil.otp.otpDevOnly;
      _passwordSementara = password;

      status = AuthStatus.menungguOtp;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.isValidationError
          ? (e.firstFieldError ?? e.message)
          : e.message;
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// FR-1.1: verifikasi OTP. Sukses -> otomatis lanjut login pakai email +
  /// password yang tersimpan sementara dari [register], biar pendonor
  /// langsung masuk tanpa isi form login lagi.
  Future<bool> verifyOtp(String otp) async {
    if (emailMenungguOtp == null) return false;

    otpLoading = true;
    otpErrorMessage = null;
    notifyListeners();

    try {
      final emailUntukLogin = emailMenungguOtp!;
      await _service.verifyOtp(email: emailUntukLogin, otp: otp);

      final passwordUntukLogin = _passwordSementara;
      _bersihkanStateOtp();

      if (passwordUntukLogin != null) {
        // Auto-login pakai kredensial yang baru saja dipakai daftar.
        return await login(emailUntukLogin, passwordUntukLogin);
      }

      // Fallback kalau password sementara somehow kosong: anggap
      // verifikasi tetap sukses, tapi lempar balik ke layar Masuk.
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      otpErrorMessage = e.message;
      otpLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// FR-1.1: minta kirim ulang OTP -- server yang nentuin cooldown-nya
  /// (429 kalau kepencet, pesannya udah nyebut sisa detik). UI (OTP
  /// screen) tinggal tangkap [otpErrorMessage] buat ditampilin.
  Future<bool> resendOtp() async {
    if (emailMenungguOtp == null) return false;

    otpLoading = true;
    otpErrorMessage = null;
    notifyListeners();

    try {
      final hasil = await _service.resendOtp(email: emailMenungguOtp!);
      otpBerlakuMenit = hasil.otpBerlakuMenit;
      otpDevOnly = hasil.otpDevOnly;
      otpLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      otpErrorMessage = e.message;
      otpLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _bersihkanStateOtp() {
    emailMenungguOtp = null;
    otpBerlakuMenit = null;
    otpDevOnly = null;
    otpLoading = false;
    otpErrorMessage = null;
    _passwordSementara = null;
  }

  /// FR-1.2: login pakai EMAIL + password.
  Future<bool> login(String email, String password) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();

    try {
      final hasil = await _service.login(email: email, password: password);
      token = hasil.token;
      pendonor = hasil.pendonor;
      await _simpanToken(token!);
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// FR-1.3: minta link/token reset password. Selalu "sukses" dari sisi
  /// server (anti email-enumeration) -- [devOnlyToken] cuma keisi pas
  /// SMTP server belum aktif, buat testing.
  Future<String?> lupaPassword(String email) async {
    try {
      return await _service.forgotPassword(email: email);
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  /// FR-1.3: submit token (dari email) + password baru.
  Future<bool> resetPassword({
    required String token,
    required String passwordBaru,
  }) async {
    try {
      await _service.resetPassword(token: token, passwordBaru: passwordBaru);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (token != null) {
      // Best-effort -- kalau gagal (mis. sudah offline), tetap lanjut
      // hapus sesi lokal supaya user nggak "kejebak" login.
      try {
        await _service.logout(token: token!);
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    token = null;
    pendonor = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// GAP: masih nyimpen ke state lokal doang -- Modul 2 (ProfilService)
  /// bakal ganti body method ini jadi manggil PUT /profil, lalu update
  /// [pendonor] dari response server (bukan dari objek yang dioper UI).
  Future<bool> simpanProfil(Pendonor dataBaru) async {
    if (pendonor == null) return false;
    pendonor = dataBaru;
    notifyListeners();
    return true;
  }

  Future<void> _simpanToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, value);
  }
}
