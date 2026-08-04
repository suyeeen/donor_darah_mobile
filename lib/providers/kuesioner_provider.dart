import 'package:flutter/foundation.dart';

class PertanyaanKesehatan {
  final String pertanyaan;
  final String subteks;

  /// true = jawaban "ya" yang dianggap lolos, false = jawaban "tidak"
  /// yang dianggap lolos. Beda-beda tergantung isi pertanyaannya.
  final bool jawabanLolosAdalahYa;

  const PertanyaanKesehatan({
    required this.pertanyaan,
    required this.subteks,
    required this.jawabanLolosAdalahYa,
  });
}

/// GAP PENTING: di file Figma (node 4:1338 / "Android Compact - 14"), cuma
/// pertanyaan #1 yang punya teks asli. 3 kartu pertanyaan lainnya di desain
/// itu COPY PERSIS dari kartu pertama (placeholder yang belum diisi
/// designer-nya). 3 pertanyaan di bawah ini (index 1-3) gue susun sendiri
/// berdasarkan kriteria skrining donor darah yang umum dipakai PMI/WHO --
/// INI BUKAN KEPUTUSAN FINAL, wajib direview & disahkan tim medis/PMI
/// sebelum dipakai di app beneran.
const List<PertanyaanKesehatan> daftarPertanyaanKesehatan = [
  PertanyaanKesehatan(
    pertanyaan: 'Apakah Anda merasa sehat dan bugar hari ini?',
    subteks: 'Tanpa demam, batuk, atau flu dalam 7 hari terakhir.',
    jawabanLolosAdalahYa: true,
  ),
  PertanyaanKesehatan(
    pertanyaan: 'Apakah Anda sedang mengonsumsi obat resep atau antibiotik?',
    subteks: 'Termasuk obat yang diminum dalam 7 hari terakhir.',
    jawabanLolosAdalahYa: false,
  ),
  PertanyaanKesehatan(
    pertanyaan:
        'Apakah Anda membuat tato, tindik, atau menjalani operasi kecil?',
    subteks: 'Dalam 6 bulan terakhir.',
    jawabanLolosAdalahYa: false,
  ),
  PertanyaanKesehatan(
    pertanyaan: 'Apakah Anda mengonsumsi alkohol dalam 24 jam terakhir?',
    subteks: 'Termasuk minuman beralkohol dalam bentuk apa pun.',
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
  final List<bool?> jawaban = List<bool?>.filled(
    daftarPertanyaanKesehatan.length,
    null,
  );

  void setBeratBadan(String value) {
    beratBadan = double.tryParse(value);
    notifyListeners();
  }

  void setTidurJam(String value) {
    tidurJam = double.tryParse(value);
    notifyListeners();
  }

  void jawab(int index, bool value) {
    jawaban[index] = value;
    notifyListeners();
  }

  bool get semuaTerjawab =>
      beratBadan != null && tidurJam != null && !jawaban.contains(null);

  // GAP: interval donor 90 hari butuh tanggal donor terakhir dari endpoint
  // riwayat donor pendonor yang sedang login. Endpoint itu belum ada, jadi
  // di-mock dulu di sini biar alur UI bisa didemokan. Ganti angka ini jadi
  // hasil hitung asli begitu API riwayat donor siap.
  static const int _mockHariSejakDonorTerakhir = 123;

  bool get lolosIntervalDonor => _mockHariSejakDonorTerakhir >= 90;
  bool get lolosBeratBadan => (beratBadan ?? 0) >= 45;

  // ASUMSI: ambang batas "istirahat cukup" gue tetapkan >= 6 jam. Angka ini
  // gak ada acuan medisnya di desain, cuma tebakan wajar -- sesuaikan kalau
  // ada standar resmi dari PMI.
  bool get lolosIstirahat => (tidurJam ?? 0) >= 6;

  bool get lolosKuesioner {
    for (var i = 0; i < daftarPertanyaanKesehatan.length; i++) {
      final harusJawab = daftarPertanyaanKesehatan[i].jawabanLolosAdalahYa;
      if (jawaban[i] != harusJawab) return false;
    }
    return true;
  }

  bool get lolosSemua =>
      lolosIntervalDonor && lolosBeratBadan && lolosIstirahat && lolosKuesioner;

  List<HasilVerifikasi> get daftarHasil => [
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
      subjudul: lolosKuesioner
          ? 'Semua jawaban Anda memenuhi kriteria dasar.'
          : 'Ada jawaban yang belum memenuhi kriteria dasar.',
      lolos: lolosKuesioner,
    ),
  ];
}
