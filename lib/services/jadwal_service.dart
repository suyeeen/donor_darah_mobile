import '../models/jadwal_donor.dart';
import '../models/lokasi_donor.dart';

/// MODE UI-ONLY: semua kode yang berhubungan dengan backend/API sengaja
/// dihapus dari file ini. `cariJadwal()` & `detailJadwal()` selalu jawab
/// pakai data dummy di bawah, biar seluruh alur (Home -> Detail ->
/// Kuesioner -> Verifikasi -> Pilih Slot -> E-Tiket) bisa dites penuh
/// tanpa server nyala sama sekali.
///
/// Kalau backend Laravel udah siap nanti, file ini perlu ditulis ulang
/// buat manggil endpoint asli (http.get ke /jadwal-donor, dst) -- bukan
/// sekadar nyalain saklar lagi, karena kode http-nya udah dibuang total,
/// bukan cuma dinonaktifkan.
class JadwalService {
  static final List<JadwalDonor> _jadwalPalsu = [
    JadwalDonor(
      idJadwal: 1,
      lokasi: LokasiDonor(
        idLokasi: 1,
        namaLokasi: 'PMI Kota Bandung',
        jenis: 'tetap',
        alamat: 'Jl. Jenderal Sudirman No. 32, Bandung',
        latitude: -6.9175,
        longitude: 107.6191,
      ),
      tanggal: DateTime.now().add(const Duration(days: 1)),
      slotWaktu: '08:00 - 16:00',
      kuotaTotal: 40,
      kuotaTersisa: 23,
      status: 'buka',
      namaKegiatan: 'Donor Darah Bersama PMI Kota Bandung',
    ),
    JadwalDonor(
      idJadwal: 2,
      lokasi: LokasiDonor(
        idLokasi: 2,
        namaLokasi: 'PMI Kabupaten Jember',
        jenis: 'tetap',
        alamat: 'Jl. Kalimantan No. 15, Jember',
        latitude: -8.1725,
        longitude: 113.7002,
      ),
      tanggal: DateTime.now().add(const Duration(days: 2)),
      slotWaktu: '09:00 - 15:00',
      kuotaTotal: 30,
      kuotaTersisa: 4,
      status: 'buka',
      namaKegiatan: 'Donor Darah Bersama PMI Kabupaten Jember',
    ),
    JadwalDonor(
      idJadwal: 3,
      lokasi: LokasiDonor(
        idLokasi: 3,
        namaLokasi: 'Mobile Unit PMI Jember - Kampus Polije',
        jenis: 'mobile_unit',
        alamat: 'Kampus Politeknik Negeri Jember, Jember',
        latitude: -8.1601,
        longitude: 113.7183,
      ),
      tanggal: DateTime.now().add(const Duration(days: 5)),
      slotWaktu: '10:00 - 14:00',
      kuotaTotal: 25,
      kuotaTersisa: 0,
      status: 'buka',
      namaKegiatan: 'Donor Darah Bersama Mobile Unit Kampus Polije',
    ),
    JadwalDonor(
      idJadwal: 4,
      lokasi: LokasiDonor(
        idLokasi: 4,
        namaLokasi: 'PMI Kota Bandung - Cabang Antapani',
        jenis: 'tetap',
        alamat: 'Jl. Terusan Jakarta No. 5, Antapani, Bandung',
        latitude: -6.9137,
        longitude: 107.6613,
      ),
      tanggal: DateTime.now().add(const Duration(days: 3)),
      slotWaktu: '08:30 - 12:30',
      kuotaTotal: 20,
      kuotaTersisa: 20,
      status: 'buka',
      namaKegiatan: 'Donor Darah Bersama PMI Cabang Antapani',
    ),
    JadwalDonor(
      idJadwal: 5,
      lokasi: LokasiDonor(
        idLokasi: 5,
        namaLokasi: 'PMI Kabupaten Jember - Balai Desa Sumbersari',
        jenis: 'mobile_unit',
        alamat: 'Balai Desa Sumbersari, Jember',
        latitude: -8.1522,
        longitude: 113.7231,
      ),
      tanggal: DateTime.now().add(const Duration(days: 7)),
      slotWaktu: '13:00 - 17:00',
      kuotaTotal: 15,
      kuotaTersisa: 2,
      status: 'buka',
      namaKegiatan: 'Donor Darah Bersama PMI Desa Sumbersari',
    ),
  ];

  Future<List<JadwalDonor>> cariJadwal({
    String? lokasi,
    DateTime? tanggal,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return _jadwalPalsu.where((j) {
      final cocokLokasi =
          lokasi == null ||
          lokasi.isEmpty ||
          j.lokasi.namaLokasi.toLowerCase().contains(lokasi.toLowerCase());
      final cocokTanggal =
          tanggal == null ||
          (j.tanggal.year == tanggal.year &&
              j.tanggal.month == tanggal.month &&
              j.tanggal.day == tanggal.day);
      return cocokLokasi && cocokTanggal;
    }).toList();
  }

  Future<JadwalDonor> detailJadwal(int idJadwal) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _jadwalPalsu.firstWhere(
      (j) => j.idJadwal == idJadwal,
      orElse: () => throw Exception('Jadwal tidak ditemukan'),
    );
  }
}
