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
  static const String baseUrl = 'http://localhost/sistem-antrian-donor/api';

  static const Duration timeout = Duration(seconds: 15);

  static const String authRegister = '/auth/register';
  static const String authVerifyOtp = '/auth/verify-otp';
  static const String authResendOtp = '/auth/resend-otp';
  static const String authLogin = '/auth/login';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';
  static const String authSessions = '/auth/sessions';
  static const String authLogout = '/auth/logout';
  static const String authLogoutOthers = '/auth/logout-others';
  static const String profil = '/profil'; // GET & PUT
  static const String profilKuesioner = '/profil/kuesioner'; // GET & POST
  static const String profilKartuDonor = '/profil/kartu-donor';
  static const String jadwalCari = '/jadwal/cari';
  static const String lokasiPeta = '/lokasi/peta';
  static const String antrian = '/antrian'; // POST ambil nomor
  static const String antrianSaya = '/antrian/saya';
  static String antrianDetail(int idAntrian) => '/antrian/$idAntrian';
  static String antrianBatalkan(int idAntrian) =>
      '/antrian/$idAntrian/batalkan';
  static String antrianJadwalUlang(int idAntrian) =>
      '/antrian/$idAntrian/jadwal-ulang';
  static const String papanAntrian = '/papan-antrian';
  static const String riwayat = '/riwayat';
  static String riwayatSertifikat(int idAntrian) =>
      '/riwayat/$idAntrian/sertifikat';

  static Uri uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }
}
