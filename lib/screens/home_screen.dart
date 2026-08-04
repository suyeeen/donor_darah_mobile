import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/antrian_donor.dart';
import '../models/riwayat_donor.dart';
import '../providers/antrian_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/jadwal_provider.dart';
import '../providers/notifikasi_provider.dart';
import '../providers/riwayat_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/jadwal_card.dart';
import 'cari_jadwal_screen.dart';
import 'detail_jadwal_screen.dart';
import 'notifikasi_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0; // 0 Jadwal, 1 Antrian, 2 Riwayat
  String _filterLokasi = 'Semua';

  static const _filterOptions = ['Semua', 'Bandung', 'Jember'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<JadwalProvider>().cariJadwal();
      context.read<AntrianProvider>().muatAntrianSaya();
      context.read<RiwayatProvider>().muatRiwayat();

      final notifProvider = context.read<NotifikasiProvider>();
      await notifProvider.muatNotifikasi();
      await notifProvider.cekSudahTanyaIzinDevice();
      if (!notifProvider.sudahTanyaIzinDevice && mounted) {
        _tampilkanDialogIzinNotifikasi();
      }
    });
  }

  void _tampilkanDialogIzinNotifikasi() {
    final notifProvider = context.read<NotifikasiProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () => Navigator.pop(dialogContext),
                  child: const Icon(Icons.close, size: 20),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.tabInactiveBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  size: 26,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Aktifkan Notifikasi pada Device',
                style: AppText.headline.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        notifProvider.tandaiSudahTanyaIzinDevice();
                        Navigator.pop(dialogContext);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Tidak'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: sambungin ke request izin notifikasi device
                        // asli (mis. firebase_messaging / permission_handler)
                        // begitu paket push notification dipasang.
                        notifProvider.tandaiSudahTanyaIzinDevice();
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Ya'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _navIndex,
                children: [
                  _buildJadwalTab(),
                  _buildAntrianTab(),
                  _buildRiwayatTab(),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // TAB 1: JADWAL
  // ------------------------------------------------------------------

  Widget _buildJadwalTab() {
    final auth = context.watch<AuthProvider>();
    final pendonor = auth.pendonor;
    final jadwalProvider = context.watch<JadwalProvider>();

    final daftarJadwal = _filterLokasi == 'Semua'
        ? jadwalProvider.hasil
        : jadwalProvider.hasil
              .where((j) => j.lokasi.namaLokasi.contains(_filterLokasi))
              .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(21, 20, 21, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGreetingHeader(pendonor?.nama),
          const SizedBox(height: 20),
          _buildStatCard(
            golonganDarah: pendonor?.golonganDarah ?? '-',
            siapDonor: true,
            totalDonor: '- kali',
            sejakTerakhir: '- hari',
          ),
          const SizedBox(height: 24),
          _buildSearchField(),
          const SizedBox(height: 16),
          _buildFilterChips(),
          const SizedBox(height: 16),
          _buildDaftarJadwal(jadwalProvider, daftarJadwal),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CariJadwalScreen()),
            ),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Cari jadwal & lokasi'),
          ),
        ],
      ),
    );
  }

  Widget _buildDaftarJadwal(JadwalProvider provider, List daftarJadwal) {
    if (provider.status == JadwalStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.status == JadwalStatus.error) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Gagal memuat jadwal.\n${provider.errorMessage ?? ''}',
            textAlign: TextAlign.center,
            style: AppText.helper,
          ),
        ),
      );
    }

    if (daftarJadwal.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('masih belum ada.', style: AppText.helper)),
      );
    }

    return Column(
      children: daftarJadwal
          .map<Widget>(
            (jadwal) => JadwalCard(
              jadwal: jadwal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailJadwalScreen(jadwal: jadwal),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ------------------------------------------------------------------
  // TAB 2: ANTRIAN (FR-5.1, FR-5.2)
  // ------------------------------------------------------------------

  Widget _buildAntrianTab() {
    final provider = context.watch<AntrianProvider>();

    if (provider.status == AntrianStatusFetch.loading ||
        provider.status == AntrianStatusFetch.idle) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == AntrianStatusFetch.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Gagal memuat antrian.\n${provider.errorMessage ?? ''}',
            textAlign: TextAlign.center,
            style: AppText.helper,
          ),
        ),
      );
    }

    if (provider.daftarAntrian.isEmpty) {
      return _buildEmptyState(
        icon: Icons.confirmation_number_outlined,
        judul: 'Belum ada antrian aktif',
        pesan:
            'Ambil nomor antrian dulu lewat jadwal donor buat lihat status di sini.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(21, 20, 21, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final antrian in provider.daftarAntrian) ...[
            _buildAntrianCard(antrian),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildAntrianCard(AntrianDonor antrian) {
    final statusInfo = _statusAntrianInfo(antrian.status);
    final urgent = antrian.status == StatusAntrian.dipanggil;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: urgent ? AppColors.primary : AppColors.inputBorder,
          width: urgent ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            color: AppColors.cardDark,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    antrian.nomorAntrian,
                    style: AppText.headline.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusInfo.$2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusInfo.$1,
                    style: AppText.chip.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRowSimpel(
                  Icons.calendar_today_outlined,
                  '${_formatTanggal(antrian.jadwal.tanggal)} · '
                  '${antrian.jadwal.slotWaktu} WIB',
                ),
                const SizedBox(height: 10),
                _infoRowSimpel(
                  Icons.location_on_outlined,
                  '${antrian.jadwal.lokasi.namaLokasi}\n'
                  '${antrian.jadwal.lokasi.alamat}',
                ),
                if (urgent && antrian.batasWaktuCheckin != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBEAEA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Segera menuju loket! Check-in sebelum '
                            '${_formatJam(antrian.batasWaktuCheckin!)} WIB, '
                            'kalau tidak nomor akan hangus.',
                            style: AppText.helper.copyWith(
                              color: AppColors.primary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _statusAntrianInfo(StatusAntrian status) {
    switch (status) {
      case StatusAntrian.menunggu:
        return ('Menunggu', AppColors.neutralMuted);
      case StatusAntrian.dipanggil:
        return ('Dipanggil', AppColors.primary);
      case StatusAntrian.sedangDiproses:
        return ('Sedang diproses', AppColors.success);
      case StatusAntrian.selesai:
        return ('Selesai', AppColors.success);
      case StatusAntrian.tidakHadir:
        return ('Tidak hadir', AppColors.neutralMuted);
      case StatusAntrian.dibatalkan:
        return ('Dibatalkan', AppColors.neutralMuted);
    }
  }

  // ------------------------------------------------------------------
  // TAB 3: RIWAYAT (FR-8.1, FR-8.2)
  // ------------------------------------------------------------------

  Widget _buildRiwayatTab() {
    final provider = context.watch<RiwayatProvider>();

    if (provider.status == RiwayatStatusFetch.loading ||
        provider.status == RiwayatStatusFetch.idle) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == RiwayatStatusFetch.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Gagal memuat riwayat.\n${provider.errorMessage ?? ''}',
            textAlign: TextAlign.center,
            style: AppText.helper,
          ),
        ),
      );
    }

    if (provider.daftarRiwayat.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        judul: 'Belum ada riwayat donor',
        pesan:
            'Riwayat donor Anda bakal muncul di sini setelah donor pertama selesai.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(21, 20, 21, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final riwayat in provider.daftarRiwayat) ...[
            _buildRiwayatCard(riwayat),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildRiwayatCard(RiwayatDonor riwayat) {
    final statusInfo = _statusKelayakanInfo(riwayat.statusKelayakan);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      riwayat.lokasi.namaLokasi,
                      style: AppText.inputText.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatTanggal(riwayat.tanggal),
                      style: AppText.helper.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusInfo.$2,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusInfo.$1,
                  style: AppText.chip.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (riwayat.volumeDarah != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.bloodtype_outlined,
                  size: 15,
                  color: AppColors.neutralMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  '${riwayat.volumeDarah!.toStringAsFixed(0)} ml darah terkumpul',
                  style: AppText.helper.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ],
          if (riwayat.catatanPetugas != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.tabInactiveBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                riwayat.catatanPetugas!,
                style: AppText.helper.copyWith(fontSize: 11),
              ),
            ),
          ],
          if (riwayat.statusKelayakan == StatusKelayakan.layak) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: implementasi unduh sertifikat donor (FR-8.2),
                  // butuh endpoint backend buat generate PDF sertifikat.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Fitur sertifikat belum tersambung ke backend',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.workspace_premium_outlined, size: 16),
                label: const Text('Lihat Sertifikat'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.inputBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (String, Color) _statusKelayakanInfo(StatusKelayakan status) {
    switch (status) {
      case StatusKelayakan.layak:
        return ('Layak', AppColors.success);
      case StatusKelayakan.tidakLayak:
        return ('Tidak layak', AppColors.primary);
      case StatusKelayakan.ditunda:
        return ('Ditunda', AppColors.neutralMuted);
    }
  }

  // ------------------------------------------------------------------
  // WIDGET BERSAMA
  // ------------------------------------------------------------------

  Widget _buildEmptyState({
    required IconData icon,
    required String judul,
    required String pesan,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.tabInactiveBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 28, color: AppColors.neutralMuted),
            ),
            const SizedBox(height: 16),
            Text(
              judul,
              style: AppText.headline.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(pesan, style: AppText.helper, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _infoRowSimpel(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.neutralMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: AppText.inputText.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTanggal(DateTime tanggal) {
    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${hari[tanggal.weekday - 1]}, ${tanggal.day} '
        '${bulan[tanggal.month - 1]} ${tanggal.year}';
  }

  String _formatJam(DateTime waktu) {
    final j = waktu.hour.toString().padLeft(2, '0');
    final m = waktu.minute.toString().padLeft(2, '0');
    return '$j:$m';
  }

  Widget _buildGreetingHeader(String? nama) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo !! 👋',
                style: AppText.inputText.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                nama?.isNotEmpty == true ? nama! : 'Nama Pengguna',
                style: AppText.headline.copyWith(fontSize: 22),
              ),
            ],
          ),
        ),
        _buildNotifikasiButton(),
      ],
    );
  }

  Widget _buildNotifikasiButton() {
    final jumlahBelumDibaca = context
        .watch<NotifikasiProvider>()
        .jumlahBelumDibaca;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotifikasiScreen()),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
          if (jumlahBelumDibaca > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  '$jumlahBelumDibaca',
                  textAlign: TextAlign.center,
                  style: AppText.chip.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String golonganDarah,
    required bool siapDonor,
    required String totalDonor,
    required String sejakTerakhir,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Golongan darah', style: AppText.statLabel),
                    const SizedBox(height: 4),
                    Text(golonganDarah, style: AppText.statValue),
                  ],
                ),
              ),
              if (siapDonor)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Siap donor',
                    style: AppText.chip.copyWith(color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatChip('Total donor', totalDonor)),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChip('Sejak donor terakhir', sejakTerakhir),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.statLabelSmall),
          const SizedBox(height: 4),
          Text(value, style: AppText.statValueSmall),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CariJadwalScreen()),
      ),
      child: Container(
        height: 45.5,
        padding: const EdgeInsets.symmetric(horizontal: 17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              size: 18,
              color: AppColors.textPlaceholder,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cari lokasi atau penyelenggara',
                style: AppText.placeholder.copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = _filterOptions[i];
          final active = label == _filterLokasi;
          return GestureDetector(
            onTap: () => setState(() => _filterLokasi = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: active
                    ? null
                    : Border.all(color: AppColors.inputBorder),
              ),
              child: Text(
                label,
                style: AppText.chip.copyWith(
                  color: active ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBFA).withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppColors.inputBorder)),
      ),
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.calendar_month_outlined, 'Jadwal'),
            _buildNavItem(1, Icons.confirmation_number_outlined, 'Antrian'),
            _buildNavItem(2, Icons.history, 'Riwayat'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final active = index == _navIndex;
    final color = active ? AppColors.primary : AppColors.neutralMuted;

    return GestureDetector(
      onTap: () => setState(() => _navIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(height: 5),
            Text(label, style: AppText.navLabel.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
