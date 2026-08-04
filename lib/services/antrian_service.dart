import '../models/antrian_donor.dart';
import '../models/jadwal_donor.dart';
import '../models/lokasi_donor.dart';
import '../models/riwayat_donor.dart';

/// MODE UI-ONLY, sama kayak AuthService & JadwalService: murni data
/// dummy, belum manggil backend sama sekali.
///
/// GAP PENTING: tabel `jadwal_donor` di database cuma punya SATU
/// `slot_waktu` per baris (bukan slot granular per 45 menit kayak di
/// mockup "Pilih Slot Waktu"), dan tabel `antrian` juga gak punya kolom
/// waktu slot sendiri. Field slotWaktu di data dummy jadwal ini sekadar
/// representasi UI -- perlu diklarifikasi ulang ke tim backend sebelum
/// pola ini diimplementasi ke API beneran.
class AntrianService {
  static final List<AntrianDonor> _antrianPalsu = [
    AntrianDonor(
      idAntrian: 1,
      jadwal: JadwalDonor(
        idJadwal: 2,
        lokasi: LokasiDonor(
          idLokasi: 2,
          namaLokasi: 'PMI Kabupaten Jember',
          jenis: 'tetap',
          alamat: 'Jl. Kalimantan No. 15, Jember',
        ),
        tanggal: DateTime.now(),
        slotWaktu: '10:00 - 10:45',
        kuotaTotal: 30,
        kuotaTersisa: 4,
        status: 'buka',
        namaKegiatan: 'Donor Darah Bersama PMI Kabupaten Jember',
      ),
      nomorUrut: 19,
      status: StatusAntrian.dipanggil,
      qrCode: 'QR-DEMO-A019',
      batasWaktuCheckin: DateTime.now().add(const Duration(minutes: 12)),
      // Status "dipanggil" = giliran sekarang, jadi gak ada lagi orang
      // di depan & estimasi waktu tunggu.
      jumlahDidepan: 0,
      estimasiMenit: 0,
    ),
  ];

  static final List<RiwayatDonor> _riwayatPalsu = [
    RiwayatDonor(
      idHasil: 1,
      tanggal: DateTime.now().subtract(const Duration(days: 95)),
      lokasi: LokasiDonor(
        idLokasi: 1,
        namaLokasi: 'PMI Kota Bandung',
        jenis: 'tetap',
        alamat: 'Jl. Jenderal Sudirman No. 32, Bandung',
      ),
      statusKelayakan: StatusKelayakan.layak,
      volumeDarah: 350,
    ),
    RiwayatDonor(
      idHasil: 2,
      tanggal: DateTime.now().subtract(const Duration(days: 210)),
      lokasi: LokasiDonor(
        idLokasi: 3,
        namaLokasi: 'Mobile Unit PMI Bandung - Kampus Polije',
        jenis: 'mobile_unit',
        alamat: 'Kampus Politeknik Negeri Jember, Jember',
      ),
      statusKelayakan: StatusKelayakan.ditunda,
      catatanPetugas: 'Hb di bawah ambang batas minimum saat pemeriksaan.',
    ),
    RiwayatDonor(
      idHasil: 3,
      tanggal: DateTime.now().subtract(const Duration(days: 300)),
      lokasi: LokasiDonor(
        idLokasi: 2,
        namaLokasi: 'PMI Kabupaten Jember',
        jenis: 'tetap',
        alamat: 'Jl. Kalimantan No. 15, Jember',
      ),
      statusKelayakan: StatusKelayakan.layak,
      volumeDarah: 350,
    ),
  ];

  Future<List<AntrianDonor>> antrianSaya() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _antrianPalsu;
  }

  Future<List<RiwayatDonor>> riwayatSaya() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _riwayatPalsu;
  }
}
