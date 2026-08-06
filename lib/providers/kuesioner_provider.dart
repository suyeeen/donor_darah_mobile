import 'package:flutter/foundation.dart';
import '../services/profil_service.dart';
import '../services/api_exception.dart';

enum KuesionerStatus { awal, memuat, siap, mengirim, terkirim, error }

/// State pengisian kuesioner kesehatan pra-donor (FR-2.2).
///
/// RESTRUKTURISASI Modul 2:
/// - Pertanyaan di-fetch dari GET /profil/kuesioner, TIDAK LAGI hardcode
///   di provider (list `semuaPertanyaanKesehatan` versi lama dibuang).
/// - TIDAK ADA LAGI logic lolos/gagal di client (dulu ada
///   lolosSemua()/lolosKuesioner()/lolosBeratBadan/dst, sebagian malah
///   pakai angka mock `_mockHariSejakDonorTerakhir`). Kelayakan final itu
///   wewenang server + petugas skrining lokasi -- provider ini cuma
///   nyimpen pertanyaan, jawaban user, dan hasil APA ADANYA dari submit.
/// - Berat badan & jam tidur DIHAPUS dari sini -- itu data profil
///   kesehatan (PUT /profil), bukan kuesioner.
class KuesionerProvider extends ChangeNotifier {
  final ProfilService _service = ProfilService();

  KuesionerStatus status = KuesionerStatus.awal;
  String? errorMessage;

  List<PertanyaanKuesioner> pertanyaan = [];
  final Map<String, String?> jawaban = {}; // kode -> 'ya'|'tidak'|null

  HasilSubmitKuesioner? hasilTerakhir;

  bool get semuaTerjawab =>
      pertanyaan.isNotEmpty && pertanyaan.every((p) => jawaban[p.kode] != null);

  /// FR-2.2: GET /profil/kuesioner
  Future<void> muatPertanyaan({required String token}) async {
    status = KuesionerStatus.memuat;
    errorMessage = null;
    notifyListeners();

    try {
      pertanyaan = await _service.getKuesionerForm(token: token);
      jawaban
        ..clear()
        ..addEntries(pertanyaan.map((p) => MapEntry(p.kode, null)));
      status = KuesionerStatus.siap;
      notifyListeners();
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = KuesionerStatus.error;
      notifyListeners();
    }
  }

  void jawab(String kode, bool ya) {
    jawaban[kode] = ya ? 'ya' : 'tidak';
    notifyListeners();
  }

  /// FR-2.2: POST /profil/kuesioner
  Future<bool> submit({required String token}) async {
    if (!semuaTerjawab) return false;

    status = KuesionerStatus.mengirim;
    errorMessage = null;
    notifyListeners();

    try {
      final jawabanFinal = jawaban.map((k, v) => MapEntry(k, v!));
      hasilTerakhir = await _service.submitKuesioner(
        token: token,
        jawaban: jawabanFinal,
      );
      status = KuesionerStatus.terkirim;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.isValidationError
          ? (e.firstFieldError ?? e.message)
          : e.message;
      status = KuesionerStatus.error;
      notifyListeners();
      return false;
    }
  }
}
