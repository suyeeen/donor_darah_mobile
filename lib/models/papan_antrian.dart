/// Model Modul 5 -- cocok persis respons Papan::antrian() di backend
/// (GET /papan-antrian?id_jadwal=X). Publik, TIDAK ada data pribadi
/// pendonor -- cuma nomor urut mentah.
class PapanAntrian {
  final int idJadwal;
  final String namaLokasi;
  final DateTime tanggal;
  final String slotWaktu;
  final int? nomorSedangDilayani;
  final List<int> daftarMenunggu;
  final int jumlahMenunggu;

  const PapanAntrian({
    required this.idJadwal,
    required this.namaLokasi,
    required this.tanggal,
    required this.slotWaktu,
    required this.nomorSedangDilayani,
    required this.daftarMenunggu,
    required this.jumlahMenunggu,
  });

  factory PapanAntrian.fromJson(Map<String, dynamic> json) {
    final jadwal = json['jadwal'] as Map<String, dynamic>;
    return PapanAntrian(
      idJadwal: jadwal['id_jadwal'] as int,
      namaLokasi: jadwal['nama_lokasi'] as String? ?? '-',
      tanggal: DateTime.parse(jadwal['tanggal'] as String),
      slotWaktu: jadwal['slot_waktu'] as String,
      nomorSedangDilayani: json['nomor_sedang_dilayani'] as int?,
      daftarMenunggu: List<int>.from(json['daftar_menunggu'] as List? ?? []),
      jumlahMenunggu: json['jumlah_menunggu'] as int? ?? 0,
    );
  }
}
