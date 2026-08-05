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

  // GAP: kolom ini sebenarnya milik tabel `riwayat_kesehatan` (bukan
  // `pendonor`) di db_antrian_donor.sql, dicatat ulang tiap sesi donor
  // (bisa berubah-ubah). Ditaruh di sini sementara cuma biar form
  // "Lengkapi Profil" (FR-2.1) di ProfilScreen bisa lengkap dari sisi UI.
  // Begitu API riwayat_kesehatan siap besok, pindahkan ke model terpisah
  // dan ambil dari entri riwayat_kesehatan TERBARU, bukan disimpan di sini.
  final double? beratBadan;

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
    this.beratBadan,
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
      beratBadan: (json['berat_badan'] as num?)?.toDouble(),
    );
  }

  Pendonor copyWith({
    String? nama,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    String? golonganDarah,
    String? email,
    String? alamat,
    double? beratBadan,
  }) {
    return Pendonor(
      idPendonor: idPendonor,
      nik: nik,
      nama: nama ?? this.nama,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      golonganDarah: golonganDarah ?? this.golonganDarah,
      noTelepon: noTelepon,
      email: email ?? this.email,
      alamat: alamat ?? this.alamat,
      beratBadan: beratBadan ?? this.beratBadan,
    );
  }
}
