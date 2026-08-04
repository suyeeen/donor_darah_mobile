import '../models/pendonor.dart';

/// MODE UI-ONLY: semua kode yang berhubungan dengan backend/API sengaja
/// dihapus dari file ini. Tujuannya biar tampilan & navigasi bisa dites
/// penuh tanpa server nyala sama sekali. Login & registrasi apa pun
/// (identitas & password apa pun) langsung dianggap sukses.
///
/// Kalau backend Laravel udah siap nanti, file ini perlu ditulis ulang
/// buat manggil endpoint asli (http.post ke /auth/login, /auth/register,
/// /auth/me) -- bukan sekadar nyalain saklar lagi, karena kode http-nya
/// udah dibuang total, bukan cuma dinonaktifkan.
class AuthService {
  Pendonor _pendonorPalsu({
    String? nik,
    String? nama,
    String? noTelepon,
  }) {
    return Pendonor(
      idPendonor: 1,
      nik: nik ?? '3302012345670001',
      nama: nama ?? 'Budi Santoso',
      tanggalLahir: DateTime(1998, 5, 17),
      jenisKelamin: 'L',
      golonganDarah: 'O',
      noTelepon: noTelepon ?? '081234567890',
      email: 'budi.santoso@contoh.id',
      alamat: 'Jl. Merdeka No. 10, Jember',
    );
  }

  Future<Map<String, dynamic>> login({
    required String identitas, // email atau no. telepon
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return {
      'token': 'mock-token-demo',
      'pendonor': _pendonorPalsu(noTelepon: identitas),
    };
  }

  Future<Map<String, dynamic>> register({
    required String nik,
    required String nama,
    required String noTelepon,
    required String password,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    String? alamat,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return {
      'token': 'mock-token-demo',
      'pendonor': _pendonorPalsu(nik: nik, nama: nama, noTelepon: noTelepon),
    };
  }

  Future<Pendonor> profil(String token) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (token == 'mock-token-demo') return _pendonorPalsu();
    throw Exception('Sesi tidak valid');
  }
}
