import '../models/pendonor.dart';
import '../utils/json_parse.dart';
import 'api_client.dart';

/// Hasil panggilan register/resend-otp -- backend kadang nyelipin
/// `otp_code_DEV_ONLY` kalau gateway OTP masih mode 'log' atau pengiriman
/// email gagal (lihat Auth::kirim_otp_registrasi() di backend). Berguna
/// banget buat testing tanpa perlu cek inbox beneran.
class HasilKirimOtp {
  final bool otpTerkirim;
  final int otpBerlakuMenit;
  final String? otpDevOnly;

  HasilKirimOtp({
    required this.otpTerkirim,
    required this.otpBerlakuMenit,
    this.otpDevOnly,
  });

  factory HasilKirimOtp.fromJson(Map<String, dynamic> json) {
    return HasilKirimOtp(
      otpTerkirim: parseBoolField(json['otp_terkirim']),
      otpBerlakuMenit: parseIntField(json['otp_berlaku_menit'], fallback: 5),
      otpDevOnly: json['otp_code_DEV_ONLY'] as String?,
    );
  }
}

class HasilRegistrasi {
  final Pendonor pendonor;
  final HasilKirimOtp otp;

  HasilRegistrasi({required this.pendonor, required this.otp});
}

class HasilLogin {
  final String token;
  final Pendonor pendonor;

  HasilLogin({required this.token, required this.pendonor});
}

class SesiPerangkat {
  final int idSesi;
  final String jti;
  final String? deviceInfo;
  final String? ipAddress;
  final DateTime? lastActiveAt;

  SesiPerangkat({
    required this.idSesi,
    required this.jti,
    this.deviceInfo,
    this.ipAddress,
    this.lastActiveAt,
  });

  factory SesiPerangkat.fromJson(Map<String, dynamic> json) {
    return SesiPerangkat(
      idSesi: parseIntField(json['id_sesi']),
      jti: json['jti'] as String,
      deviceInfo: json['device_info'] as String?,
      ipAddress: json['ip_address'] as String?,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.tryParse(json['last_active_at'] as String)
          : null,
    );
  }
}

class AuthService {
  final ApiClient _client = ApiClient();

  /// FR-1.1: POST /auth/register
  /// Backend TIDAK langsung login-in pendonor -- akun berstatus
  /// 'menunggu_verifikasi' sampai OTP diverifikasi lewat [verifyOtp].
  Future<HasilRegistrasi> register({
    required String nik,
    required String nama,
    required DateTime tanggalLahir,
    required String jenisKelamin, // 'L' | 'P'
    required String noTelp,
    required String email,
    required String password,
  }) async {
    final data = await _client.post(
      '/auth/register',
      body: {
        'nik': nik,
        'nama': nama,
        'tanggal_lahir': _formatTanggal(tanggalLahir),
        'jenis_kelamin': jenisKelamin,
        'no_telp': noTelp,
        'email': email,
        'password': password,
      },
    );

    return HasilRegistrasi(
      pendonor: Pendonor.minimalFromAuth(data),
      otp: HasilKirimOtp.fromJson(data),
    );
  }

  /// FR-1.1: POST /auth/verify-otp
  /// Sukses cuma bikin akun jadi 'aktif' -- TIDAK balikin token, jadi
  /// pendonor tetap harus login manual setelah ini (lihat komentar di
  /// Auth::verify_otp() backend).
  Future<void> verifyOtp({required String email, required String otp}) async {
    await _client.post('/auth/verify-otp', body: {'email': email, 'otp': otp});
  }

  /// FR-1.1: POST /auth/resend-otp -- ada cooldown di server (429 kalau
  /// kepencet), pesan errornya udah nyebut sisa detiknya.
  Future<HasilKirimOtp> resendOtp({required String email}) async {
    final data = await _client.post('/auth/resend-otp', body: {'email': email});
    return HasilKirimOtp.fromJson(data);
  }

  /// FR-1.2: POST /auth/login -- pakai EMAIL, bukan nomor telepon.
  Future<HasilLogin> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );

    return HasilLogin(
      token: data['token'] as String,
      pendonor: Pendonor.minimalFromAuth(data),
    );
  }

  /// FR-1.3: POST /auth/forgot-password
  /// Backend SENGAJA selalu balas sukses walau email tidak terdaftar
  /// (anti email-enumeration) -- jangan tampilkan pesan "email tidak
  /// ditemukan" di UI berdasarkan response ini.
  /// [resetTokenDevOnly] cuma keisi kalau SMTP belum dikonfigurasi di
  /// server (buat testing lokal tanpa kirim email beneran).
  Future<String?> forgotPassword({required String email}) async {
    final data = await _client.post(
      '/auth/forgot-password',
      body: {'email': email},
    );
    return data['reset_token_DEV_ONLY'] as String?;
  }

  /// FR-1.3: POST /auth/reset-password
  /// [token] didapat dari link di email (atau field DEV_ONLY di atas).
  /// Sukses = semua sesi login lain otomatis logout (Session_model::
  /// logout_all_except di backend), jadi user wajib login ulang.
  Future<void> resetPassword({
    required String token,
    required String passwordBaru,
  }) async {
    await _client.post(
      '/auth/reset-password',
      body: {'token': token, 'password_baru': passwordBaru},
    );
  }

  /// FR-1.4: GET /auth/sessions -- daftar device yang lagi login.
  Future<List<SesiPerangkat>> sessions({required String token}) async {
    final data = await _client.get('/auth/sessions', token: token);
    final list = data['_list'] as List? ?? [];
    return list
        .map((e) => SesiPerangkat.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// FR-1.4: POST /auth/logout -- logout device yang sedang dipakai saat ini.
  Future<void> logout({required String token}) async {
    await _client.post('/auth/logout', token: token);
  }

  /// FR-1.4: POST /auth/logout-others -- logout semua device LAIN,
  /// dipakai di KelolaPerangkatScreen (Modul 6).
  Future<void> logoutOthers({required String token}) async {
    await _client.post('/auth/logout-others', token: token);
  }

  String _formatTanggal(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
