import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_exception.dart';

/// Wrapper tipis di atas package `http` yang ngerti bentuk envelope respons
/// backend: `{ "status": "success"|"error", "message": "...", "data": ... }`
/// (lihat helpers/api_response_helper.php di backend).
///
/// Semua Service (AuthService, ProfilService, dst) HARUS lewat sini biar:
/// - Header Authorization ditambahin otomatis kalau [token] dikasih
/// - Timeout & error jaringan ditangani satu tempat
/// - Error dari backend (status:"error") konsisten dilempar sebagai
///   [ApiException], termasuk error validasi 422
class ApiClient {
  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    String? token,
  }) => _send('GET', path, query: query, token: token);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) => _send('POST', path, body: body, token: token);

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) => _send('PUT', path, body: body, token: token);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = ApiConfig.uri(path, query);
    final headers = _headers(token: token);

    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http
              .get(uri, headers: headers)
              .timeout(ApiConfig.timeout);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(ApiConfig.timeout);
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(ApiConfig.timeout);
          break;
        default:
          throw ArgumentError('Method $method tidak didukung');
      }
    } on SocketException {
      throw ApiException(
        'Tidak bisa terhubung ke server. Cek koneksi internet atau '
        'pastikan base URL API di ApiConfig sudah benar.',
      );
    } on HttpException {
      throw ApiException('Gagal menghubungi server, coba lagi.');
    } on FormatException {
      throw ApiException('Respons server tidak valid.');
    } catch (e) {
      // Termasuk TimeoutException dari .timeout()
      throw ApiException('Waktu permintaan habis, coba lagi. ($e)');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Respons server tidak bisa dibaca (status ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    final status = decoded['status'] as String?;
    final message = decoded['message'] as String? ?? '';
    final data = decoded['data'];

    if (status != 'success') {
      // FR: 422 dari form_validation->error_array() balikin Map<field, pesan>
      final fieldErrors = (response.statusCode == 422 && data is Map)
          ? Map<String, dynamic>.from(data)
          : null;

      throw ApiException(
        message.isNotEmpty ? message : 'Terjadi kesalahan, coba lagi.',
        statusCode: response.statusCode,
        fieldErrors: fieldErrors,
      );
    }

    // Beberapa endpoint (mis. logout, verify-otp) balikin data: null pas
    // sukses -- normalisasi jadi {} biar pemanggil nggak perlu null-check.
    if (data is Map<String, dynamic>) return data;
    if (data == null) return {};
    // Endpoint yang datanya berupa List (mis. jadwal/cari, lokasi/peta,
    // auth/sessions) dibungkus di sini biar tipe kembalian tetap konsisten
    // Map -- pemanggil ambil lewat key '_list'.
    return {'_list': data};
  }
}
