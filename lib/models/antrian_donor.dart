/// Model Modul 4 -- cocok persis sama bentuk respons Antrian::format_e_ticket()
/// di backend (lihat Antrian.php). SEMUA field di sini nullable/opsional
/// sesuai kondisi nyata: `jadwal` & `posisi` bisa null tergantung konteks.
enum StatusAntrian {
  menunggu,
  dipanggil,
  sedangDiproses,
  selesai,
  tidakHadir,
  dibatalkan;

  static StatusAntrian fromApi(String value) {
    switch (value) {
      case 'dipanggil':
        return StatusAntrian.dipanggil;
      case 'sedang_diproses':
        return StatusAntrian.sedangDiproses;
      case 'selesai':
        return StatusAntrian.selesai;
      case 'tidak_hadir':
        return StatusAntrian.tidakHadir;
      case 'dibatalkan':
        return StatusAntrian.dibatalkan;
      case 'menunggu':
      default:
        return StatusAntrian.menunggu;
    }
  }

  /// Antrian dianggap "masih berjalan" kalau statusnya salah satu dari
  /// ini -- dipakai buat nentuin apakah field `posisi` bakal ada isinya.
  bool get aktif =>
      this == StatusAntrian.menunggu ||
      this == StatusAntrian.dipanggil ||
      this == StatusAntrian.sedangDiproses;
}

/// Info jadwal versi RINGKAS yang nempel di respons e-ticket -- BEDA dari
/// JadwalDonor penuh (Modul 3), cuma punya field yang backend beneran
/// kirim di sini: id_jadwal, tanggal, slot_waktu, id_lokasi, nama_lokasi,
/// alamat. TIDAK ada kuota/latitude/longitude di objek ini.
class JadwalRingkasAntrian {
  final int idJadwal;
  final DateTime tanggal;
  final String slotWaktu;
  final int idLokasi;
  final String? namaLokasi;
  final String? alamat;

  const JadwalRingkasAntrian({
    required this.idJadwal,
    required this.tanggal,
    required this.slotWaktu,
    required this.idLokasi,
    this.namaLokasi,
    this.alamat,
  });

  factory JadwalRingkasAntrian.fromJson(Map<String, dynamic> json) {
    return JadwalRingkasAntrian(
      idJadwal: json['id_jadwal'] as int,
      tanggal: DateTime.parse(json['tanggal'] as String),
      slotWaktu: json['slot_waktu'] as String,
      idLokasi: json['id_lokasi'] as int,
      namaLokasi: json['nama_lokasi'] as String?,
      alamat: json['alamat'] as String?,
    );
  }
}

/// Cuma ada isinya kalau status antrian masih aktif (lihat
/// StatusAntrian.aktif) -- backend sengaja balikin null begitu status
/// jadi terminal (selesai/tidak_hadir/dibatalkan), karena "posisi" udah
/// gak relevan lagi.
class PosisiAntrian {
  final int? nomorSedangDilayani;
  final int jumlahDiDepan;
  final int estimasiMenit;

  const PosisiAntrian({
    required this.nomorSedangDilayani,
    required this.jumlahDiDepan,
    required this.estimasiMenit,
  });

  factory PosisiAntrian.fromJson(Map<String, dynamic> json) {
    return PosisiAntrian(
      nomorSedangDilayani: json['nomor_sedang_dilayani'] as int?,
      jumlahDiDepan: json['jumlah_di_depan'] as int? ?? 0,
      estimasiMenit: json['estimasi_menit'] as int? ?? 0,
    );
  }
}

class AntrianDonor {
  final int idAntrian;
  final int nomorUrut;
  final StatusAntrian status;
  final String qrCode;
  final DateTime? batasWaktuCheckin;
  final JadwalRingkasAntrian? jadwal;
  final PosisiAntrian? posisi;

  const AntrianDonor({
    required this.idAntrian,
    required this.nomorUrut,
    required this.status,
    required this.qrCode,
    this.batasWaktuCheckin,
    this.jadwal,
    this.posisi,
  });

  String get nomorAntrian => 'A-${nomorUrut.toString().padLeft(3, '0')}';

  factory AntrianDonor.fromJson(Map<String, dynamic> json) {
    return AntrianDonor(
      idAntrian: json['id_antrian'] as int,
      nomorUrut: json['nomor_urut'] as int,
      status: StatusAntrian.fromApi(json['status'] as String),
      qrCode: json['qr_code'] as String,
      batasWaktuCheckin: json['batas_waktu_checkin'] != null
          ? DateTime.tryParse(json['batas_waktu_checkin'] as String)
          : null,
      jadwal: json['jadwal'] != null
          ? JadwalRingkasAntrian.fromJson(
              json['jadwal'] as Map<String, dynamic>,
            )
          : null,
      posisi: json['posisi'] != null
          ? PosisiAntrian.fromJson(json['posisi'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Satu baris riwayat dari GET /antrian/saya (field "riwayat") -- GAP:
/// backend ambil ini dari Antrian_model::get_riwayat_by_pendonor(), gue
/// belum baca isi model itu jadi bentuknya nebak berdasarkan pola
/// Riwayat::index() yang mirip. Kalau field-nya beda pas dites, ini yang
/// pertama perlu dicek.
class RiwayatAntrianRingkas {
  final int idAntrian;
  final int nomorUrut;
  final StatusAntrian status;
  final DateTime tanggal;
  final String slotWaktu;
  final String? namaLokasi;

  const RiwayatAntrianRingkas({
    required this.idAntrian,
    required this.nomorUrut,
    required this.status,
    required this.tanggal,
    required this.slotWaktu,
    this.namaLokasi,
  });

  factory RiwayatAntrianRingkas.fromJson(Map<String, dynamic> json) {
    return RiwayatAntrianRingkas(
      idAntrian: json['id_antrian'] as int,
      nomorUrut: json['nomor_urut'] as int,
      status: StatusAntrian.fromApi(json['status'] as String),
      tanggal: DateTime.parse(json['tanggal'] as String),
      slotWaktu: json['slot_waktu'] as String,
      namaLokasi: json['nama_lokasi'] as String?,
    );
  }
}
