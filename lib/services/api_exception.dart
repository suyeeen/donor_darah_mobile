/// Dilempar oleh ApiClient tiap kali backend balas `status: "error"`, atau
/// request gagal total (timeout, no internet, response bukan JSON).
///
/// [statusCode] adalah HTTP status code asli dari backend (401, 404, 422,
/// dst) -- 0 dipakai khusus buat error jaringan (bukan dari server).
/// [fieldErrors] cuma keisi kalau backend balas 422 dengan
/// `form_validation->error_array()`, formatnya { nama_field: pesan_error }.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? fieldErrors;

  ApiException(this.message, {this.statusCode = 0, this.fieldErrors});

  bool get isValidationError => statusCode == 422 && fieldErrors != null;

  /// Ambil pesan error field pertama (buat ditampilin ringkas di SnackBar)
  /// -- kalau butuh semua pesan sekaligus, pakai [fieldErrors] langsung.
  String? get firstFieldError => fieldErrors != null && fieldErrors!.isNotEmpty
      ? fieldErrors!.values.first.toString()
      : null;

  @override
  String toString() => message;
}
