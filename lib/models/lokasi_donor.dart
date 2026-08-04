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
      idLokasi: json['id_lokasi'] as int,
      namaLokasi: json['nama_lokasi'] as String,
      jenis: json['jenis'] as String,
      alamat: json['alamat'] as String,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }
}
