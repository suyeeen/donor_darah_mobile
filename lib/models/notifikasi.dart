/// Kategori notifikasi, dipakai buat filter chip di NotifikasiScreen.
enum KategoriNotifikasi { antrian, jadwal, selesai }

class NotifikasiItem {
  final int idNotifikasi;
  final KategoriNotifikasi kategori;
  final String judul;
  final String pesan;
  final DateTime waktu;
  final bool sudahDibaca;

  NotifikasiItem({
    required this.idNotifikasi,
    required this.kategori,
    required this.judul,
    required this.pesan,
    required this.waktu,
    this.sudahDibaca = false,
  });

  factory NotifikasiItem.fromJson(Map<String, dynamic> json) {
    return NotifikasiItem(
      idNotifikasi: json['id_notifikasi'] as int,
      kategori: KategoriNotifikasi.values.firstWhere(
        (k) => k.name == json['kategori'],
        orElse: () => KategoriNotifikasi.jadwal,
      ),
      judul: json['judul'] as String,
      pesan: json['pesan'] as String,
      waktu: DateTime.parse(json['waktu'] as String),
      sudahDibaca: json['sudah_dibaca'] as bool? ?? false,
    );
  }
}
