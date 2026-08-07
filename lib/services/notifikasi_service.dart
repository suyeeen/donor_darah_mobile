import 'dart:io';

import '../models/notifikasi.dart';
import 'api_client.dart';

/// Modul Notifikasi (FR-6.1 - FR-6.4) -- GET /notifikasi, GET
/// /notifikasi/ringkasan, & POST /notifikasi/device-token. Lihat
/// Notifikasi.php di backend.
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

  /// POST /notifikasi/device-token -- daftarkan FCM token device ini ke
  /// backend supaya bisa dikirimi push notification asli (nomor
  /// dipanggil, giliran mendekati, dst) lewat Firebase Cloud Messaging.
  /// Dipanggil dari notifikasi_permission_dialog.dart tepat setelah user
  /// mengizinkan notifikasi.
  Future<void> daftarkanToken({
    required String token,
    required String fcmToken,
  }) async {
    await _client.post(
      '/notifikasi/device-token',
      token: token,
      body: {
        'fcm_token': fcmToken,
        'platform': Platform.isIOS ? 'ios' : 'android',
      },
    );
  }
}
