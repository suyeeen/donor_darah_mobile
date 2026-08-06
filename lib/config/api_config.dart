/// Konfigurasi terpusat buat komunikasi ke backend "sistem-antrian-donor"
/// (CodeIgniter 3, punya temen). Semua Service HARUS ambil base URL dan
/// path endpoint dari sini -- jangan hardcode string URL di file lain.
///
/// Endpoint & response shape di bawah ini disalin persis dari source
/// controller backend (Auth.php, Profil.php, Antrian.php, Jadwal.php,
/// Lokasi.php, Papan.php) + routes.php, bukan dari FRD/dokumen -- jadi
/// dijamin cocok sama implementasi asli per 2026-08-06.
class ApiConfig {
  ApiConfig._();

  // =========================================================================
  // BLOCKER: ganti nilai ini begitu dapet base URL dari temen.
  //
  // Backend routing-nya clean URL tanpa index.php (lihat routes.php +
  // .htaccess), base_url CI3 di server itu 'http://localhost/sistem-antrian-donor'
  // buat dev lokal temen -- jadi pola base URL API kemungkinan:
  //   http://<host-atau-ip>/sistem-antrian-donor/api
  // atau kalau di-deploy di root domain:
  //   http://<host-atau-ip>/api
  //
  // Untuk emulator Android yang ngakses server di localhost mesin dev,
  // pakai 10.0.2.2 (bukan 127.0.0.1/localhost), atau IP LAN kalau test di
  // HP fisik.
  // =========================================================================
  static const String baseUrl = 'http://10.0.2.2/sistem-antrian-donor/api';

  static const Duration timeout = Duration(seconds: 15);

  // ---------------------------------------------------------------------
  // Auth (Modul 1) -- semua publik (tanpa token) KECUALI sessions,
  // logout, logout-others yang wajib Authorization: Bearer <token>.
  // ---------------------------------------------------------------------
  static const String authRegister = '/auth/register';
  static const String authVerifyOtp = '/auth/verify-otp';
  static const String authResendOtp = '/auth/resend-otp';
  static const String authLogin = '/auth/login';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';
  static const String authSessions = '/auth/sessions';
  static const String authLogout = '/auth/logout';
  static const String authLogoutOthers = '/auth/logout-others';

  // ---------------------------------------------------------------------
  // Profil & Kuesioner (Modul 2) -- semua wajib token.
  // ---------------------------------------------------------------------
  static const String profil = '/profil'; // GET & PUT
  static const String profilKuesioner = '/profil/kuesioner'; // GET & POST
  static const String profilKartuDonor = '/profil/kartu-donor';

  // ---------------------------------------------------------------------
  // Jadwal & Lokasi (Modul 3) -- publik, tanpa token.
  // ---------------------------------------------------------------------
  static const String jadwalCari = '/jadwal/cari';
  static const String lokasiPeta = '/lokasi/peta';

  // ---------------------------------------------------------------------
  // Antrian (Modul 4) -- semua wajib token & role pendonor.
  // ---------------------------------------------------------------------
  static const String antrian = '/antrian'; // POST ambil nomor
  static const String antrianSaya = '/antrian/saya';
  static String antrianDetail(int idAntrian) => '/antrian/$idAntrian';
  static String antrianBatalkan(int idAntrian) =>
      '/antrian/$idAntrian/batalkan';
  static String antrianJadwalUlang(int idAntrian) =>
      '/antrian/$idAntrian/jadwal-ulang';

  // ---------------------------------------------------------------------
  // Papan Antrian Digital (Modul 5) -- publik, tanpa token.
  // ---------------------------------------------------------------------
  static const String papanAntrian = '/papan-antrian';

  static Uri uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }
}
