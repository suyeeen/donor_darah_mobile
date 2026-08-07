/// Backend CI3 + mysqli ini balikin SEMUA kolom mentah dari database
/// sebagai STRING di JSON -- termasuk kolom int/decimal/tinyint (mis.
/// "id_pendonor": "42" bukan 42). Ini bukan salah kirim, itu perilaku
/// default driver PHP yang dipakai backend. Field yang DIHITUNG manual
/// di PHP (bukan langsung SELECT kolom, mis. ekspresi boolean seperti
/// `sertifikat_tersedia`) tetap kekirim sebagai tipe asli.
///
/// Helper ini dipakai di semua model.fromJson() biar parsing tahan
/// banting ke DUA kemungkinan itu sekaligus, tanpa perlu tau persis
/// field mana yang "mentah dari DB" dan mana yang bukan.

int parseIntField(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? parseIntFieldOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? parseDoubleFieldOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool parseBoolField(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return fallback;
}
