import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pendonor.dart';
import '../services/auth_service.dart';
import '../services/profil_service.dart';
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
  final ProfilService _profilService = ProfilService();
  static const _keyToken = 'auth_token';

  AuthStatus status = AuthStatus.unknown;
  Pendonor? pendonor;
  // BARU Modul 2: data kesehatan terbaru dari GET /profil (berat badan,
  // tekanan darah, hasil kuesioner, dst). Null kalau pendonor belum
  // pernah isi apa pun sama sekali.
  RiwayatKesehatan? riwayatKesehatan;
  String? token;
  String? errorMessage;

  // Loading khusus buat aksi profil (GET/PUT /profil), dipisah dari
  // `status` (`authenticating`) biar ProfilScreen gak ikut nampilin
  // full-screen loading pas cuma nyimpen profil.
  bool profilLoading = false;

  // --- State khusus alur OTP registrasi ---------------------------------
  String? emailMenungguOtp;
  int? otpBerlakuMenit;
  String? otpDevOnly; // cuma keisi kalau backend lagi mode dev/testing
  bool otpLoading = false;
  String? otpErrorMessage;

  // Password disimpan sementara CUMA selama proses register -> verifikasi
  // OTP berlangsung, biar begitu OTP sukses, pendonor bisa langsung
  // auto-login tanpa harus ngetik ulang password.
  String? _passwordSementara;

  /// Dipanggil sekali dari SplashScreen.
  ///
  /// Modul 2: sekarang BENERAN memvalidasi token dengan manggil
  /// GET /profil (dulu cuma cek token tersimpan ada atau nggak). Kalau
  /// token sudah kedaluwarsa/invalid, backend balas 401,
  /// [ApiException] ketangkep di [_muatProfilLengkap], token lokal
  /// dihapus, dan status jadi unauthenticated (user diarahkan ke login).
  Future<void> cekSesiTersimpan() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_keyToken);

    if (savedToken == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    token = savedToken;
    final berhasil = await _muatProfilLengkap();

    if (!berhasil) {
      await prefs.remove(_keyToken);
      token = null;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

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
  /// password yang tersimpan sementara dari [register].
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
        return await login(emailUntukLogin, passwordUntukLogin);
      }

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

  /// FR-1.1: minta kirim ulang OTP.
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
  ///
  /// Modul 2: setelah dapat token, langsung susulin GET /profil biar
  /// [pendonor] LENGKAP (auth/login cuma balikin id_pendonor/nama/email).
  /// Kalau pemanggilan profil gagal, login tetap dianggap sukses
  /// (best-effort) -- layar yang butuh data lengkap tinggal
  /// muatUlangProfil() sendiri.
  Future<bool> login(String email, String password) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();

    try {
      final hasil = await _service.login(email: email, password: password);
      token = hasil.token;
      pendonor = hasil.pendonor;
      await _simpanToken(token!);

      await _muatProfilLengkap();

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

  /// FR-1.3: minta link/token reset password.
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
      try {
        await _service.logout(token: token!);
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    token = null;
    pendonor = null;
    riwayatKesehatan = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// FR-2.1: PUT /profil.
  ///
  /// GANTI TOTAL dari versi lama: dulu cuma nyimpen objek [Pendonor] dari
  /// UI ke state lokal tanpa manggil API sama sekali. Sekarang beneran
  /// manggil [ProfilService.updateProfil], dan [pendonor] +
  /// [riwayatKesehatan] diupdate dari RESPONS SERVER -- bukan dari objek
  /// yang dioper si pemanggil.
  ///
  /// Parameternya SENGAJA per-field (bukan terima objek Pendonor utuh)
  /// biar match persis sama field yang memang diterima PUT /profil.
  /// Kirim null untuk field yang tidak ingin diubah.
  Future<bool> simpanProfil({
    String? golonganDarah,
    String? alamat,
    double? beratBadan,
    String? tekananDarah,
    String? penyakitBawaan,
    String? riwayatDonorSebelumnya,
  }) async {
    if (token == null) return false;

    profilLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final hasil = await _profilService.updateProfil(
        token: token!,
        golonganDarah: golonganDarah,
        alamat: alamat,
        beratBadan: beratBadan,
        tekananDarah: tekananDarah,
        penyakitBawaan: penyakitBawaan,
        riwayatDonorSebelumnya: riwayatDonorSebelumnya,
      );
      pendonor = hasil.akun;
      riwayatKesehatan = hasil.riwayatKesehatan;
      profilLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.isValidationError
          ? (e.firstFieldError ?? e.message)
          : e.message;
      profilLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// FR-2.1: GET /profil -- public, buat dipanggil manual (mis.
  /// pull-to-refresh di ProfilScreen, atau setelah isi kuesioner).
  Future<bool> muatUlangProfil() => _muatProfilLengkap();

  /// Internal: hydrate [pendonor] + [riwayatKesehatan] dari GET /profil.
  /// Dipakai dari [cekSesiTersimpan], [login], dan [muatUlangProfil].
  Future<bool> _muatProfilLengkap() async {
    if (token == null) return false;
    try {
      final hasil = await _profilService.getProfil(token: token!);
      pendonor = hasil.akun;
      riwayatKesehatan = hasil.riwayatKesehatan;
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<void> _simpanToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, value);
  }
}
