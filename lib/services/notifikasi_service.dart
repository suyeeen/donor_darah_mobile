import '../models/notifikasi.dart';
import 'api_client.dart';

/// Modul Notifikasi (FR-6.1 - FR-6.4) -- GET /notifikasi & GET
/// /notifikasi/ringkasan. Lihat Notifikasi.php di backend.
///
/// PENTING: endpoint ini baru bisa dipakai SETELAH kolom `dibaca` +
/// `dibaca_at` ditambahkan ke tabel `notifikasi` (lihat catatan ALTER
/// TABLE) -- tanpa itu, backend bakal balikin 500 Database Error.
class NotifikasiService {
  final ApiClient _client = ApiClient();

  /// GET /notifikasi -- daftar notifikasi in-app pendonor. Membuka
  /// endpoint ini otomatis menandai SEMUA notifikasi sebagai dibaca di
  /// server (side effect dari Notifikasi::index()), tapi daftar yang
  /// dikembalikan tetap mencerminkan status dibaca SEBELUM ditandai.
  Future<List<NotifikasiItem>> daftarNotifikasi({required String token}) async {
    final data = await _client.get('/notifikasi', token: token);
    final list = data['_list'] as List? ?? [];
    return list
        .map((e) => NotifikasiItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /notifikasi/ringkasan -- dipoll bell icon, cuma hitung jumlah
  /// belum dibaca (ringan, tidak ikut menandai dibaca).
  Future<int> jumlahBelumDibaca({required String token}) async {
    final data = await _client.get('/notifikasi/ringkasan', token: token);
    return data['jumlah_belum_dibaca'] as int? ?? 0;
  }
}
