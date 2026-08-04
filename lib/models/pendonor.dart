class Pendonor {
  final int idPendonor;
  final String nik;
  final String nama;
  final DateTime tanggalLahir;
  final String jenisKelamin; // 'L' | 'P'
  final String? golonganDarah;
  final String noTelepon;
  final String? email;
  final String? alamat;

  Pendonor({
    required this.idPendonor,
    required this.nik,
    required this.nama,
    required this.tanggalLahir,
    required this.jenisKelamin,
    this.golonganDarah,
    required this.noTelepon,
    this.email,
    this.alamat,
  });

  factory Pendonor.fromJson(Map<String, dynamic> json) {
    return Pendonor(
      idPendonor: json['id_pendonor'] as int,
      nik: json['nik'] as String,
      nama: json['nama'] as String,
      tanggalLahir: DateTime.parse(json['tanggal_lahir'] as String),
      jenisKelamin: json['jenis_kelamin'] as String,
      golonganDarah: json['golongan_darah'] as String?,
      noTelepon: json['no_telepon'] as String,
      email: json['email'] as String?,
      alamat: json['alamat'] as String?,
    );
  }
}
