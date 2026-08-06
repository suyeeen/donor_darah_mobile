/// Data akun pendonor -- cocok 1:1 sama tabel `pendonor` (minus
/// password_hash yang di-unset backend) dan sama field `akun` di respons
/// `GET/PUT /profil` (lihat Profil::index()/update() di backend).
///
/// PENTING soal kelengkapan data: endpoint auth (`/auth/login`,
/// `/auth/register`) CUMA balikin id_pendonor, nama, email -- field
/// lain (nik, tanggal_lahir, golongan_darah, dst) baru lengkap setelah
/// panggil `GET /profil` (Modul 2, belum disambung). Makanya field selain
/// id/nama/email dibuat nullable di sini, JANGAN diubah jadi required
/// tanpa mikirin alur login dulu.
class Pendonor {
  final int idPendonor;
  final String nama;
  final String? email;
  final String? nik;
  final DateTime? tanggalLahir;
  final String? jenisKelamin; // 'L' | 'P'
  final String? golonganDarah; // 'A'|'B'|'AB'|'O'|'Belum Diketahui'
  final String? noTelp;
  final String? alamat;
  final String? statusAkun; // 'menunggu_verifikasi'|'aktif'|'nonaktif'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Pendonor({
    required this.idPendonor,
    required this.nama,
    this.email,
    this.nik,
    this.tanggalLahir,
    this.jenisKelamin,
    this.golonganDarah,
    this.noTelp,
    this.alamat,
    this.statusAkun,
    this.createdAt,
    this.updatedAt,
  });

  /// Dipakai buat parsing objek `akun` dari `GET/PUT /profil`, YANG JUGA
  /// jadi bentuk paling lengkap yang tersedia dari backend.
  factory Pendonor.fromJson(Map<String, dynamic> json) {
    return Pendonor(
      idPendonor: json['id_pendonor'] as int,
      nama: json['nama'] as String,
      email: json['email'] as String?,
      nik: json['nik'] as String?,
      tanggalLahir: json['tanggal_lahir'] != null
          ? DateTime.tryParse(json['tanggal_lahir'] as String)
          : null,
      jenisKelamin: json['jenis_kelamin'] as String?,
      golonganDarah: json['golongan_darah'] as String?,
      noTelp: json['no_telp'] as String?,
      alamat: json['alamat'] as String?,
      statusAkun: json['status_akun'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Dipakai buat parsing respons `auth/register` & `auth/login` yang cuma
  /// balikin id_pendonor + nama + email (bukan objek `akun` penuh).
  factory Pendonor.minimalFromAuth(Map<String, dynamic> json) {
    return Pendonor(
      idPendonor: json['id_pendonor'] as int,
      nama: json['nama'] as String,
      email: json['email'] as String?,
    );
  }

  Pendonor copyWith({
    String? nama,
    String? email,
    String? nik,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    String? golonganDarah,
    String? noTelp,
    String? alamat,
    String? statusAkun,
  }) {
    return Pendonor(
      idPendonor: idPendonor,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      nik: nik ?? this.nik,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      golonganDarah: golonganDarah ?? this.golonganDarah,
      noTelp: noTelp ?? this.noTelp,
      alamat: alamat ?? this.alamat,
      statusAkun: statusAkun ?? this.statusAkun,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Hasil self-assessment kuesioner kesehatan pra-donor -- nested di dalam
/// `riwayat_kesehatan.hasil_kuesioner` (kolom JSON di DB). Lihat
/// Profil::kuesioner_submit() buat bentuk aslinya.
class HasilKuesioner {
  final Map<String, String> jawaban; // { kode_pertanyaan: 'ya'|'tidak' }
  final List<String> flagRisiko;
  final String
  hasilScreeningAwal; // 'lolos_screening_awal'|'perlu_pemeriksaan_lanjutan'
  final DateTime? diisiPada;

  const HasilKuesioner({
    required this.jawaban,
    required this.flagRisiko,
    required this.hasilScreeningAwal,
    this.diisiPada,
  });

  factory HasilKuesioner.fromJson(Map<String, dynamic> json) {
    return HasilKuesioner(
      jawaban: Map<String, String>.from(json['jawaban'] as Map? ?? {}),
      flagRisiko: List<String>.from(json['flag_risiko'] as List? ?? []),
      hasilScreeningAwal: json['hasil_screening_awal'] as String? ?? '',
      diisiPada: json['diisi_pada'] != null
          ? DateTime.tryParse(json['diisi_pada'] as String)
          : null,
    );
  }
}

/// Data kesehatan pendonor -- cocok sama tabel `riwayat_kesehatan`, entri
/// TERBARU per pendonor (backend selalu ambil lewat
/// Riwayat_kesehatan_model::get_latest_by_pendonor()).
class RiwayatKesehatan {
  final int idRiwayat;
  final double? beratBadan;
  final String? tekananDarah;
  final String? penyakitBawaan;
  final String? riwayatDonorSebelumnya;
  final HasilKuesioner? hasilKuesioner;
  final String? catatanMedis;
  final DateTime? createdAt;

  const RiwayatKesehatan({
    required this.idRiwayat,
    this.beratBadan,
    this.tekananDarah,
    this.penyakitBawaan,
    this.riwayatDonorSebelumnya,
    this.hasilKuesioner,
    this.catatanMedis,
    this.createdAt,
  });

  factory RiwayatKesehatan.fromJson(Map<String, dynamic> json) {
    return RiwayatKesehatan(
      idRiwayat: json['id_riwayat'] as int,
      beratBadan: (json['berat_badan'] as num?)?.toDouble(),
      tekananDarah: json['tekanan_darah'] as String?,
      penyakitBawaan: json['penyakit_bawaan'] as String?,
      riwayatDonorSebelumnya: json['riwayat_donor_sebelumnya'] as String?,
      hasilKuesioner: json['hasil_kuesioner'] != null
          ? HasilKuesioner.fromJson(
              json['hasil_kuesioner'] as Map<String, dynamic>,
            )
          : null,
      catatanMedis: json['catatan_medis'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

/// Bungkus respons penuh `GET/PUT /profil`: { akun, riwayat_kesehatan }.
/// `riwayatKesehatan` bisa null -- itu wajar buat pendonor yang belum
/// pernah isi apa pun (lihat Riwayat_kesehatan_model::get_latest_by_pendonor
/// yang bisa balikin null).
class ProfilPendonor {
  final Pendonor akun;
  final RiwayatKesehatan? riwayatKesehatan;

  const ProfilPendonor({required this.akun, this.riwayatKesehatan});

  factory ProfilPendonor.fromJson(Map<String, dynamic> json) {
    return ProfilPendonor(
      akun: Pendonor.fromJson(json['akun'] as Map<String, dynamic>),
      riwayatKesehatan: json['riwayat_kesehatan'] != null
          ? RiwayatKesehatan.fromJson(
              json['riwayat_kesehatan'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
