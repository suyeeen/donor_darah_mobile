import '../models/pendonor.dart';
import 'api_client.dart';

/// Service Modul 2 -- GET/PUT /profil + GET/POST /profil/kuesioner.
/// Lihat Profil.php di backend buat kontrak lengkapnya.
class ProfilService {
  final ApiClient _client = ApiClient();

  /// FR-2.1: GET /profil
  /// Balikin data akun + data kesehatan terbaru (bisa null kalau pendonor
  /// belum pernah isi apa pun -- lihat ProfilPendonor.riwayatKesehatan).
  Future<ProfilPendonor> getProfil({required String token}) async {
    final data = await _client.get('/profil', token: token);
    return ProfilPendonor.fromJson(data);
  }

  /// FR-2.1: PUT /profil
  /// Kirim cuma field yang mau diubah (partial update, backend nerima
  /// permit_empty). Field yang BISA dikirim (lihat Profil::update()):
  ///   golongan_darah, alamat                    -> tabel `pendonor`
  ///   berat_badan, tekanan_darah,
  ///   penyakit_bawaan, riwayat_donor_sebelumnya -> tabel `riwayat_kesehatan`
  ///
  /// PENTING: nama, email, nik, tanggal_lahir, jenis_kelamin, no_telp
  /// TIDAK diproses backend sama sekali di endpoint ini -- jangan kirim,
  /// dan jangan bikin UI yang seolah-olah bisa mengubahnya lewat sini.
  ///
  /// golonganDarah cuma boleh 'A'|'B'|'AB'|'O' (backend validasi
  /// in_list, TIDAK menerima 'Belum Diketahui' sebagai input).
  Future<ProfilPendonor> updateProfil({
    required String token,
    String? golonganDarah,
    String? alamat,
    double? beratBadan,
    String? tekananDarah,
    String? penyakitBawaan,
    String? riwayatDonorSebelumnya,
  }) async {
    final body = <String, dynamic>{};
    if (golonganDarah != null && golonganDarah.isNotEmpty) {
      body['golongan_darah'] = golonganDarah;
    }
    if (alamat != null && alamat.isNotEmpty) body['alamat'] = alamat;
    if (beratBadan != null) body['berat_badan'] = beratBadan;
    if (tekananDarah != null && tekananDarah.isNotEmpty) {
      body['tekanan_darah'] = tekananDarah;
    }
    if (penyakitBawaan != null && penyakitBawaan.isNotEmpty) {
      body['penyakit_bawaan'] = penyakitBawaan;
    }
    if (riwayatDonorSebelumnya != null && riwayatDonorSebelumnya.isNotEmpty) {
      body['riwayat_donor_sebelumnya'] = riwayatDonorSebelumnya;
    }

    final data = await _client.put('/profil', body: body, token: token);
    return ProfilPendonor.fromJson(data);
  }

  /// FR-2.2: GET /profil/kuesioner -- daftar pertanyaan {kode, teks}.
  /// CATATAN: backend TIDAK membedakan pertanyaan per jenis kelamin --
  /// semua pendonor (L maupun P) menerima daftar yang SAMA PERSIS,
  /// termasuk 'hamil_menyusui'. Submit akan 422 kalau ada satu kode saja
  /// yang tidak dijawab. Jangan filter pertanyaan berdasar gender di
  /// client tanpa tetap mengirim jawabannya.
  Future<List<PertanyaanKuesioner>> getKuesionerForm({
    required String token,
  }) async {
    final data = await _client.get('/profil/kuesioner', token: token);
    final list = data['pertanyaan'] as List? ?? [];
    return list
        .map((e) => PertanyaanKuesioner.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// FR-2.2: POST /profil/kuesioner
  /// Body: { "jawaban": { kode: "ya"|"tidak", ... } } -- harus mencakup
  /// SEMUA kode dari [getKuesionerForm].
  Future<HasilSubmitKuesioner> submitKuesioner({
    required String token,
    required Map<String, String> jawaban,
  }) async {
    final data = await _client.post(
      '/profil/kuesioner',
      body: {'jawaban': jawaban},
      token: token,
    );
    return HasilSubmitKuesioner.fromJson(data);
  }
}

/// Satu pertanyaan dari GET /profil/kuesioner.
///
/// [jawabanBerisiko] ikut dikirim backend (config-nya di-passthrough apa
/// adanya oleh Profil::kuesioner_form()), tapi SENGAJA tidak dipakai
/// untuk menghitung lolos/gagal di client -- itu keputusan server +
/// petugas skrining, bukan UI. Field ini disimpan cuma buat referensi/
/// debug, bukan buat logic tampilan.
class PertanyaanKuesioner {
  final String kode;
  final String teks;
  final String? jawabanBerisiko;

  const PertanyaanKuesioner({
    required this.kode,
    required this.teks,
    this.jawabanBerisiko,
  });

  factory PertanyaanKuesioner.fromJson(Map<String, dynamic> json) {
    return PertanyaanKuesioner(
      kode: json['kode'] as String,
      teks: json['teks'] as String,
      jawabanBerisiko: json['jawaban_berisiko'] as String?,
    );
  }
}

/// Hasil POST /profil/kuesioner -- APA ADANYA dari server, tidak diolah.
class HasilSubmitKuesioner {
  /// 'lolos_screening_awal' | 'perlu_pemeriksaan_lanjutan'
  final String hasilScreeningAwal;
  final List<String> flagRisiko;
  final String catatan;

  const HasilSubmitKuesioner({
    required this.hasilScreeningAwal,
    required this.flagRisiko,
    required this.catatan,
  });

  factory HasilSubmitKuesioner.fromJson(Map<String, dynamic> json) {
    return HasilSubmitKuesioner(
      hasilScreeningAwal: json['hasil_screening_awal'] as String? ?? '',
      flagRisiko: List<String>.from(json['flag_risiko'] as List? ?? []),
      catatan: json['catatan'] as String? ?? '',
    );
  }
}
