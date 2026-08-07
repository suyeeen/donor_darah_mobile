import '../utils/json_parse.dart';

class LokasiDonor {
  final int idLokasi;
  final String namaLokasi;
  final String jenis; // 'tetap' | 'mobile_unit'
  final String alamat;
  final double? latitude;
  final double? longitude;

  LokasiDonor({
    required this.idLokasi,
    required this.namaLokasi,
    required this.jenis,
    required this.alamat,
    this.latitude,
    this.longitude,
  });

  factory LokasiDonor.fromJson(Map<String, dynamic> json) {
    return LokasiDonor(
      idLokasi: parseIntField(json['id_lokasi']),
      namaLokasi: json['nama_lokasi'] as String,
      jenis: json['jenis'] as String,
      alamat: json['alamat'] as String,
      latitude: parseDoubleFieldOrNull(json['latitude']),
      longitude: parseDoubleFieldOrNull(json['longitude']),
    );
  }
}
