import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/antrian_donor.dart';
import '../models/pendonor.dart';
import '../models/riwayat_donor.dart';
import '../providers/antrian_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/jadwal_provider.dart';
import '../providers/notifikasi_provider.dart';
import '../providers/riwayat_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/jadwal_card.dart';
import 'auth_screen.dart';
import 'cari_jadwal_screen.dart';
import 'detail_jadwal_screen.dart';
import 'kelola_perangkat_screen.dart';
import 'notifikasi_screen.dart';
import 'profil_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'sertifikat_screen.dart';
import 'tes_notifikasi_screen.dart';

class HomeScreen extends StatefulWidget {
  // Tab yang aktif pas HomeScreen pertama kali dibuka. Default 0 (Jadwal)
  // buat alur normal habis login -- dikasih 1 (Antrian) pas dibuka dari
  // PushNotificationService.navigatorKey.pushNamed('/antrian').
  final int initialTabIndex;

  const HomeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _navIndex =
      widget.initialTabIndex; // 0 Jadwal, 1 Antrian, 2 Riwayat, 3 Pengaturan
  String _filterLokasi = 'Semua';

  static const _filterOptions = ['Semua', 'Bandung', 'Jember'];

  @override
  void initState() {
    super.initState();
    // NOTE: dialog izin notifikasi device SUDAH DIPINDAH ke ETiketScreen,
    // muncul sekali begitu pendonor selesai mendaftar antrian (bukan di
    // sini lagi) -- lihat showNotifikasiPermissionDialog().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JadwalProvider>().cariJadwal();
      context.read<AntrianProvider>().muatAntrianSaya();
      context.read<RiwayatProvider>().muatRiwayat();
      context.read<NotifikasiProvider>().muatNotifikasi();
    });
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
                  _buildPengaturanTab(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatusUtamaCard(antrian),
        const SizedBox(height: 16),
        _buildTimelineCard(antrian),
        const SizedBox(height: 16),
        _buildTombolQr(antrian),
        const SizedBox(height: 12),
        _buildInfoOtomatis(),
      ],
    );
  }

  // Kartu paling atas: nomor antrian gede, badge status, & 3 statistik.
  Widget _buildStatusUtamaCard(AntrianDonor antrian) {
    final info = _statusAntrianInfo(antrian.status);
    final progress = _progresAntrian(antrian.status);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: info.$2.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: info.$2,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  info.$1,
                  style: AppText.chip.copyWith(color: info.$2, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(info.$3, style: AppText.helper.copyWith(fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            antrian.nomorAntrian,
            style: AppText.headline.copyWith(fontSize: 40, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.tabInactiveBg,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildStatChipTerang('Nomor Anda', antrian.nomorAntrian),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChipTerang(
                  'Di depan',
                  '${antrian.jumlahDidepan} orang',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChipTerang(
                  'Estimasi',
                  '${antrian.estimasiMenit} mnt',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChipTerang(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.tabInactiveBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.helper.copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppText.inputText.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Kartu tahapan: 1) e-ticket, 2) menunggu, 3) dipanggil,
  // 4) check-in & proses, 5) selesai.
  static const _tahapanAntrian = [
    'E-ticket diterbitkan',
    'Menunggu dalam antrian',
    'Nomor Anda dipanggil',
    'Check-in & proses donor',
    'Selesai · sertifikat terbit',
  ];

  Widget _buildTimelineCard(AntrianDonor antrian) {
    final langkahAktif = _langkahAktifAntrian(antrian.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _tahapanAntrian.length; i++)
            _buildTahapanRow(
              nomor: i + 1,
              label: _tahapanAntrian[i],
              selesai: i + 1 < langkahAktif,
              aktif: i + 1 == langkahAktif,
              terakhir: i == _tahapanAntrian.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildTahapanRow({
    required int nomor,
    required String label,
    required bool selesai,
    required bool aktif,
    required bool terakhir,
  }) {
    final lingkaranBg = aktif
        ? AppColors.primary
        : selesai
        ? AppColors.primary.withValues(alpha: 0.12)
        : AppColors.tabInactiveBg;
    final lingkaranFg = aktif
        ? Colors.white
        : selesai
        ? AppColors.primary
        : AppColors.neutralMuted;
    final teksStyle = aktif
        ? AppText.inputText.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          )
        : selesai
        ? AppText.inputText.copyWith(fontSize: 13.5)
        : AppText.inputText.copyWith(
            color: AppColors.neutralMuted,
            fontSize: 13.5,
          );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: lingkaranBg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$nomor',
                  style: AppText.chip.copyWith(
                    color: lingkaranFg,
                    fontSize: 11,
                  ),
                ),
              ),
              if (!terakhir)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: AppColors.inputBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: terakhir ? 0 : 18, top: 2),
              child: Text(label, style: teksStyle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTombolQr(AntrianDonor antrian) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _tampilkanQrCheckin(antrian),
        icon: const Icon(Icons.qr_code_2, size: 18),
        label: const Text('Tampilkan QR untuk check-in'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.inputBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // Notifikasi device ditawarkan sekali di ETiketScreen begitu pendonor
  // selesai mendaftar (bukan di sini) -- lihat showNotifikasiPermissionDialog().
  // Banner ini cuma nyerminin status izinnya: kalau sudah "Ya", notifikasi
  // dianggap tetap aktif selama antrian pendonor masih berjalan.
  Widget _buildInfoOtomatis() {
    final notifikasiAktif = context.watch<NotifikasiProvider>().notifikasiAktif;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tabInactiveBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            notifikasiAktif
                ? Icons.notifications_active_outlined
                : Icons.access_time_rounded,
            size: 16,
            color: notifikasiAktif ? AppColors.success : AppColors.neutralMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (notifikasiAktif) ...[
                  Text(
                    'Notifikasi aktif',
                    style: AppText.helper.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  'Posisi antrian bergerak otomatis. Anda akan menerima '
                  'notifikasi ketika tersisa 2 pendonor di depan Anda.',
                  style: AppText.helper,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _tampilkanQrCheckin(AntrianDonor antrian) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                antrian.nomorAntrian,
                style: AppText.headline.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                'Tunjukkan QR ini ke petugas loket saat check-in',
                style: AppText.helper,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Kode QR asli dari antrian.qrCode. GAP: nilai qrCode
              // sekarang cuma string dummy dari AntrianService/
              // ETiketScreen -- begitu backend ngasih kode unik hasil
              // INSERT ke tabel antrian, otomatis kepakai di sini tanpa
              // ubah widget-nya.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.inputBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: antrian.qrCode,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.textPrimary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                antrian.qrCode,
                style: AppText.helper.copyWith(fontSize: 10.5),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fraksi progres bar (0.0 - 1.0) berdasarkan tahapan aktif dari 5 langkah.
  double _progresAntrian(StatusAntrian status) =>
      _langkahAktifAntrian(status) / _tahapanAntrian.length;

  // Tahapan (1-5) yang sedang berjalan buat status antrian tertentu.
  int _langkahAktifAntrian(StatusAntrian status) {
    switch (status) {
      case StatusAntrian.menunggu:
        return 2;
      case StatusAntrian.dipanggil:
        return 3;
      case StatusAntrian.sedangDiproses:
        return 4;
      case StatusAntrian.selesai:
        return 5;
      case StatusAntrian.tidakHadir:
      case StatusAntrian.dibatalkan:
        return 1;
    }
  }

  // (label badge, warna, caption "Sedang ...")
  (String, Color, String) _statusAntrianInfo(StatusAntrian status) {
    switch (status) {
      case StatusAntrian.menunggu:
        return ('Sedang mengantre', AppColors.neutralMuted, 'Sedang dilayani');
      case StatusAntrian.dipanggil:
        return ('Giliran Anda sekarang', AppColors.primary, 'Sedang dilayani');
      case StatusAntrian.sedangDiproses:
        return ('Sedang diproses', AppColors.success, 'Sedang dilayani');
      case StatusAntrian.selesai:
        return ('Selesai', AppColors.success, 'Terima kasih sudah donor!');
      case StatusAntrian.tidakHadir:
        return ('Tidak hadir', AppColors.neutralMuted, 'Nomor sudah hangus');
      case StatusAntrian.dibatalkan:
        return ('Dibatalkan', AppColors.neutralMuted, 'Antrian dibatalkan');
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
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SertifikatScreen(riwayat: riwayat),
                  ),
                ),
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
  // TAB 4: PENGATURAN (FR-1.4, FR-2.1, FR-2.3)
  // ------------------------------------------------------------------

  Widget _buildPengaturanTab() {
    final auth = context.watch<AuthProvider>();
    final notif = context.watch<NotifikasiProvider>();
    final pendonor = auth.pendonor;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(21, 20, 21, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pengaturan', style: AppText.headline.copyWith(fontSize: 22)),
          const SizedBox(height: 20),
          _buildProfilRingkas(pendonor),
          const SizedBox(height: 24),
          _sectionLabel('Akun'),
          const SizedBox(height: 10),
          _buildMenuGroup([
            _MenuItemData(
              icon: Icons.person_outline,
              label: 'Profil saya',
              subtitle: 'Data diri & kesehatan dasar',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilScreen()),
              ),
            ),
            _MenuItemData(
              icon: Icons.devices_outlined,
              label: 'Kelola perangkat ',
              subtitle: 'Lihat & keluar dari sesi lain',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const KelolaPerangkatScreen(),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _sectionLabel('Preferensi'),
          const SizedBox(height: 10),
          _buildToggleTile(
            icon: Icons.notifications_outlined,
            label: 'Notifikasi push',
            subtitle: 'Kabar status antrian secara real-time',
            aktif: notif.notifikasiAktif,
            onChanged: (value) {
              if (value) {
                notif.aktifkanNotifikasi();
              } else {
                notif.nonaktifkanNotifikasi();
              }
            },
          ),
          const SizedBox(height: 12),
          _buildMenuGroup([
            _MenuItemData(
              icon: Icons.bug_report_outlined,
              label: 'Tes Notifikasi Push',
              subtitle: 'Cek token FCM & tes notifikasi masuk',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TesNotifikasiScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _sectionLabel('Lainnya'),
          const SizedBox(height: 10),
          _buildMenuGroup([
            _MenuItemData(
              icon: Icons.help_outline,
              label: 'Bantuan & dukungan',
              subtitle: 'FAQ dan kontak PMI/UDD',
              onTap: () => _tampilkanInfoSederhana(
                judul: 'Bantuan & Dukungan',
                pesan:
                    'Butuh bantuan? Hubungi call center PMI di 021-xxxxxxx '
                    'atau datangi kantor terdekat.\n\n)',
              ),
            ),
            _MenuItemData(
              icon: Icons.privacy_tip_outlined,
              label: 'Kebijakan privasi',
              subtitle: 'Cara data Anda dikelola',
              onTap: () => _tampilkanInfoSederhana(
                judul: 'Kebijakan Privasi',
                pesan:
                    'Data pribadi dan kesehatan Anda hanya diakses oleh '
                    'Anda, petugas skrining lokasi terkait, dan admin '
                    'berwenang.',
              ),
            ),
            _MenuItemData(
              icon: Icons.info_outline,
              label: 'Tentang aplikasi',
              subtitle: '',
              onTap: () => _tampilkanInfoSederhana(
                judul: 'Tentang Donor',
                pesan:
                    ' -- Sistem Antrian Online Donor Darah\nVersi '
                    '1.0.0\n\nTerintegrasi dengan PMI/UDD untuk pendaftaran '
                    'dan pelacakan antrian donor darah secara real-time.',
              ),
            ),
          ]),
          const SizedBox(height: 28),
          _buildTombolLogout(),
        ],
      ),
    );
  }

  Widget _buildProfilRingkas(Pendonor? pendonor) {
    final nama = (pendonor?.nama.isNotEmpty ?? false)
        ? pendonor!.nama
        : 'Nama Pengguna';
    final inisial = nama.trim().isNotEmpty ? nama.trim()[0].toUpperCase() : '?';
    final noTelepon = pendonor?.noTelepon ?? '-';

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                inisial,
                style: AppText.statValue.copyWith(fontSize: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: AppText.inputText.copyWith(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    noTelepon,
                    style: AppText.statLabelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: AppText.statLabel.copyWith(
        color: AppColors.neutralMuted,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildMenuGroup(List<_MenuItemData> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _buildMenuTile(items[i]),
            if (i != items.length - 1)
              const Divider(height: 1, color: AppColors.inputBorder),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuTile(_MenuItemData item) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(item.icon, size: 20, color: AppColors.textPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: AppText.inputText.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(item.subtitle, style: AppText.helper),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.neutralMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool aktif,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.inputText.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.helper),
              ],
            ),
          ),
          Switch(
            value: aktif,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTombolLogout() {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _konfirmasiLogout,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.logout, size: 18),
        label: Text('Keluar akun', style: AppText.button),
      ),
    );
  }

  void _tampilkanInfoSederhana({required String judul, required String pesan}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(judul, style: AppText.headline.copyWith(fontSize: 16)),
        content: Text(pesan, style: AppText.helper),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _konfirmasiLogout() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Keluar dari akun?',
          style: AppText.headline.copyWith(fontSize: 16),
        ),
        content: Text(
          'Anda perlu masuk kembali dengan nomor ponsel dan kata sandi '
          'untuk mengakses akun ini.',
          style: AppText.helper,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;
    if (!mounted) return;

    await context.read<AuthProvider>().logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
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
            _buildNavItem(3, Icons.settings_outlined, 'Pengaturan'),
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

/// Data satu baris menu di tab Pengaturan (lihat _buildMenuGroup /
/// _buildMenuTile). Cuma dipakai internal HomeScreen, jadi ditaruh di file
/// yang sama daripada bikin file terpisah buat satu class kecil.
class _MenuItemData {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItemData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
}
