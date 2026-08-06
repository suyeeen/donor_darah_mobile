import 'package:flutter/foundation.dart';

class PertanyaanKesehatan {
  final String key;
  final String pertanyaan;
  final String subteks;

  final bool jawabanLolosAdalahYa;
  final bool khususPerempuan;

  const PertanyaanKesehatan({
    required this.key,
    required this.pertanyaan,
    required this.subteks,
    required this.jawabanLolosAdalahYa,
    this.khususPerempuan = false,
  });
}

const List<PertanyaanKesehatan> semuaPertanyaanKesehatan = [
  PertanyaanKesehatan(
    key: 'sudah_makan',
    pertanyaan: 'Apakah Anda sudah makan sebelum donor hari ini?',
    subteks: 'Donor dalam kondisi perut kosong berisiko pusing/pingsan.',
    jawabanLolosAdalahYa: true,
  ),
  PertanyaanKesehatan(
    key: 'tidur_cukup',
    pertanyaan: 'Apakah Anda tidur cukup malam sebelumnya?',
    subteks: 'Minimal sekitar 6 jam.',
    jawabanLolosAdalahYa: true,
  ),
  PertanyaanKesehatan(
    key: 'kondisi_sehat',
    pertanyaan: 'Apakah Anda merasa sehat dan bugar hari ini?',
    subteks: 'Tanpa demam, batuk, atau flu dalam 7 hari terakhir.',
    jawabanLolosAdalahYa: true,
  ),
  PertanyaanKesehatan(
    key: 'konsumsi_obat',
    pertanyaan: 'Apakah Anda sedang mengonsumsi obat resep atau antibiotik?',
    subteks: 'Termasuk obat yang diminum dalam 7 hari terakhir.',
    jawabanLolosAdalahYa: false,
  ),
  PertanyaanKesehatan(
    key: 'hamil_menyusui',
    pertanyaan: 'Apakah Anda sedang hamil atau menyusui?',
    subteks: 'Khusus pendonor perempuan.',
    jawabanLolosAdalahYa: false,
    khususPerempuan: true,
  ),
  PertanyaanKesehatan(
    key: 'transfusi_setahun',
    pertanyaan:
        'Apakah Anda pernah menerima transfusi darah dalam 1 tahun terakhir?',
    subteks: 'Termasuk transfusi karena operasi atau kecelakaan.',
    jawabanLolosAdalahYa: false,
  ),
  PertanyaanKesehatan(
    key: 'operasi_enam_bulan',
    pertanyaan: 'Apakah Anda menjalani operasi atau tindakan medis besar?',
    subteks: 'Dalam 6 bulan terakhir.',
    jawabanLolosAdalahYa: false,
  ),
];

class HasilVerifikasi {
  final String judul;
  final String subjudul;
  final bool lolos;

  const HasilVerifikasi({
    required this.judul,
    required this.subjudul,
    required this.lolos,
  });
}

class KuesionerProvider extends ChangeNotifier {
  double? beratBadan;
  double? tidurJam;

  final Map<String, bool?> jawaban = {
    for (final p in semuaPertanyaanKesehatan) p.key: null,
  };

  List<PertanyaanKesehatan> pertanyaanUntuk(String? jenisKelamin) {
    if (jenisKelamin == 'L') {
      return semuaPertanyaanKesehatan.where((p) => !p.khususPerempuan).toList();
    }
    return semuaPertanyaanKesehatan;
  }

  void setBeratBadan(String value) {
    beratBadan = double.tryParse(value);
    notifyListeners();
  }

  void setTidurJam(String value) {
    tidurJam = double.tryParse(value);
    notifyListeners();
  }

  void jawab(String key, bool value) {
    jawaban[key] = value;
    notifyListeners();
  }

  bool semuaTerjawab(String? jenisKelamin) {
    if (beratBadan == null || tidurJam == null) return false;
    return pertanyaanUntuk(jenisKelamin).every((p) => jawaban[p.key] != null);
  }

  static const int _mockHariSejakDonorTerakhir = 123;

  bool get lolosIntervalDonor => _mockHariSejakDonorTerakhir >= 90;
  bool get lolosBeratBadan => (beratBadan ?? 0) >= 45;
  bool get lolosIstirahat => (tidurJam ?? 0) >= 6;

  bool lolosKuesioner(String? jenisKelamin) {
    for (final p in pertanyaanUntuk(jenisKelamin)) {
      if (jawaban[p.key] != p.jawabanLolosAdalahYa) return false;
    }
    return true;
  }

  bool lolosSemua(String? jenisKelamin) =>
      lolosIntervalDonor &&
      lolosBeratBadan &&
      lolosIstirahat &&
      lolosKuesioner(jenisKelamin);

  List<HasilVerifikasi> daftarHasil(String? jenisKelamin) => [
    HasilVerifikasi(
      judul: 'Interval donor 90 hari',
      subjudul: '$_mockHariSejakDonorTerakhir hari sejak donor terakhir Anda.',
      lolos: lolosIntervalDonor,
    ),
    HasilVerifikasi(
      judul: 'Berat badan minimum 45 kg',
      subjudul: 'Berat badan Anda ${beratBadan?.toStringAsFixed(0) ?? '-'} kg.',
      lolos: lolosBeratBadan,
    ),
    HasilVerifikasi(
      judul: 'Istirahat cukup malam sebelumnya',
      subjudul: 'Tidur ${tidurJam?.toStringAsFixed(0) ?? '-'} jam malam tadi.',
      lolos: lolosIstirahat,
    ),
    HasilVerifikasi(
      judul: 'Kuesioner kesehatan pra-donor',
      subjudul: lolosKuesioner(jenisKelamin)
          ? 'Semua jawaban Anda memenuhi kriteria dasar.'
          : 'Ada jawaban yang belum memenuhi kriteria dasar.',
      lolos: lolosKuesioner(jenisKelamin),
    ),
  ];

  Map<String, dynamic> keJsonHasilKuesioner(String? jenisKelamin) {
    final pertanyaanAktif = pertanyaanUntuk(jenisKelamin);
    final jawabanYaTidak = {
      for (final p in pertanyaanAktif)
        p.key: (jawaban[p.key] ?? false) ? 'ya' : 'tidak',
    };
    final flagRisiko = pertanyaanAktif
        .where((p) => jawaban[p.key] != p.jawabanLolosAdalahYa)
        .map((p) => p.key)
        .toList();

    return {
      'jawaban': jawabanYaTidak,
      'diisi_pada': DateTime.now().toIso8601String(),
      'flag_risiko': flagRisiko,
      'hasil_screening_awal': flagRisiko.isEmpty
          ? 'lolos_screening_awal'
          : 'perlu_pemeriksaan_lanjutan',
    };
  }
}
