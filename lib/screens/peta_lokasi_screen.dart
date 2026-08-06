import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/lokasi_donor.dart';
import '../services/api_exception.dart';
import '../services/lokasi_service.dart';
import '../theme/app_theme.dart';

/// FR-3.2: Peta Lokasi Donor -- berdiri sendiri, PUBLIK (tanpa login),
/// pakai GET /lokasi/peta (lihat Lokasi.php backend). BEDA dari peta di
/// HasilPencarianScreen: di sana titiknya diturunkan dari hasil
/// pencarian JADWAL (cuma lokasi yang lagi punya jadwal aktif), di sini
/// nampilin SEMUA lokasi donor aktif apa adanya, terlepas dari ada
/// jadwal terbuka atau tidak -- jadi pendonor bisa lihat "PMI/UDD mana
/// aja yang ada" tanpa perlu nyari jadwal dulu.
class PetaLokasiScreen extends StatefulWidget {
  const PetaLokasiScreen({super.key});

  @override
  State<PetaLokasiScreen> createState() => _PetaLokasiScreenState();
}

enum _FilterJenis { semua, tetap, mobileUnit }

class _PetaLokasiScreenState extends State<PetaLokasiScreen> {
  final LokasiService _service = LokasiService();
  final MapController _mapController = MapController();

  List<LokasiDonor> _semuaLokasi = [];
  bool _loading = true;
  String? _error;
  _FilterJenis _filter = _FilterJenis.semua;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Ambil semua jenis sekaligus (jenis difilter di client lewat chip)
      // biar ganti filter nggak perlu round-trip API lagi.
      final hasil = await _service.getPeta();
      setState(() {
        _semuaLokasi = hasil;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat lokasi, coba lagi.';
        _loading = false;
      });
    }
  }

  List<LokasiDonor> get _terfilter {
    final berKoordinat = _semuaLokasi
        .where((l) => l.latitude != null && l.longitude != null)
        .toList();
    switch (_filter) {
      case _FilterJenis.semua:
        return berKoordinat;
      case _FilterJenis.tetap:
        return berKoordinat.where((l) => l.jenis == 'tetap').toList();
      case _FilterJenis.mobileUnit:
        return berKoordinat.where((l) => l.jenis == 'mobile_unit').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Peta lokasi donor',
          style: AppText.headline.copyWith(fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterChips(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    Widget chip(String label, _FilterJenis value) {
      final aktif = _filter == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: aktif,
          onSelected: (_) => setState(() => _filter = value),
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.tabInactiveBg,
          labelStyle: AppText.helper.copyWith(
            fontWeight: FontWeight.w700,
            color: aktif ? Colors.white : AppColors.textPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide.none,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          chip('Semua', _FilterJenis.semua),
          chip('Lokasi tetap', _FilterJenis.tetap),
          chip('Mobile unit', _FilterJenis.mobileUnit),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: AppText.helper, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(onPressed: _muat, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }

    final lokasi = _terfilter;

    if (lokasi.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Belum ada lokasi dengan koordinat GPS untuk jenis ini.',
            style: AppText.helper,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final pusatPeta = LatLng(
      lokasi.map((l) => l.latitude!).reduce((a, b) => a + b) / lokasi.length,
      lokasi.map((l) => l.longitude!).reduce((a, b) => a + b) / lokasi.length,
    );

    return RefreshIndicator(
      onRefresh: _muat,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: pusatPeta, initialZoom: 11),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.antrian_donor_darah',
              ),
              MarkerLayer(
                markers: lokasi.map((l) {
                  final mobileUnit = l.jenis == 'mobile_unit';
                  return Marker(
                    point: LatLng(l.latitude!, l.longitude!),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _tampilkanInfoLokasi(l),
                      child: Icon(
                        mobileUnit ? Icons.local_shipping : Icons.location_on,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '${lokasi.length} lokasi ditampilkan · ketuk pin untuk detail',
                style: AppText.helper.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _tampilkanInfoLokasi(LokasiDonor lokasi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    lokasi.jenis == 'mobile_unit'
                        ? Icons.local_shipping
                        : Icons.location_on,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lokasi.namaLokasi,
                      style: AppText.headline.copyWith(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(lokasi.alamat, style: AppText.helper),
              const SizedBox(height: 4),
              Text(
                lokasi.jenis == 'mobile_unit' ? 'Mobile unit' : 'Lokasi tetap',
                style: AppText.helper.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Text(
                'Untuk lihat jadwal & kuota tersedia di lokasi ini, cari lewat '
                'menu "Cari jadwal & lokasi".',
                style: AppText.helper.copyWith(fontSize: 11.5),
              ),
            ],
          ),
        );
      },
    );
  }
}
