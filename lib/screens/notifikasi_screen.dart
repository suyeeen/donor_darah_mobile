import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notifikasi.dart';
import '../providers/auth_provider.dart';
import '../providers/notifikasi_provider.dart';
import '../theme/app_theme.dart';

/// Modul Notifikasi (FR-6.1 - FR-6.4). Daftar notifikasi in-app pendonor,
/// nyambung ke GET /notifikasi lewat NotifikasiProvider.
///
/// PENTING: endpoint ini butuh kolom `dibaca`/`dibaca_at` di tabel
/// `notifikasi` backend -- tanpa itu, backend balikin 500. Lihat catatan
/// ALTER TABLE yang sudah dibahas.
class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  JenisNotifikasi? _filterAktif; // null = semua

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _muatUlang());
  }

  Future<void> _muatUlang() async {
    final token = context.read<AuthProvider>().token;
    await context.read<NotifikasiProvider>().muatNotifikasi(token: token);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotifikasiProvider>();
    final daftar = provider.filter(_filterAktif);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _buildHeader(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: _buildFilterChips(),
            ),
            Expanded(child: _buildBody(provider, daftar)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        const SizedBox(width: 15),
        Text('Notifikasi', style: AppText.headline.copyWith(fontSize: 20)),
      ],
    );
  }

  Widget _buildFilterChips() {
    final opsi = <(String, JenisNotifikasi?)>[
      ('Semua', null),
      ('Pendaftaran', JenisNotifikasi.konfirmasiPendaftaran),
      ('Pengingat', JenisNotifikasi.pengingatH1),
      ('Giliran', JenisNotifikasi.giliranMendekati),
      ('Perubahan Jadwal', JenisNotifikasi.perubahanJadwal),
    ];

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: opsi.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, jenis) = opsi[i];
          final active = jenis == _filterAktif;
          return GestureDetector(
            onTap: () => setState(() => _filterAktif = jenis),
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

  Widget _buildBody(NotifikasiProvider provider, List<NotifikasiItem> daftar) {
    if (provider.status == NotifikasiStatusFetch.loading ||
        provider.status == NotifikasiStatusFetch.idle) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == NotifikasiStatusFetch.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gagal memuat notifikasi.\n${provider.errorMessage ?? ''}',
                textAlign: TextAlign.center,
                style: AppText.helper,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _muatUlang,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Coba lagi',
                  style: AppText.button.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (daftar.isEmpty) {
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
                child: const Icon(
                  Icons.notifications_none_outlined,
                  size: 28,
                  color: AppColors.neutralMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada notifikasi',
                style: AppText.headline.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Kabar soal antrian dan jadwal donor Anda bakal muncul di sini.',
                style: AppText.helper,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _muatUlang,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: daftar.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _buildNotifikasiCard(daftar[i]),
      ),
    );
  }

  Widget _buildNotifikasiCard(NotifikasiItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.sudahDibaca ? AppColors.inputBorder : AppColors.primary,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.tabInactiveBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _ikonUntukJenis(item.jenis),
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.judul,
                        style: AppText.inputText.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    if (!item.sudahDibaca)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8, top: 3),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.pesan,
                  style: AppText.helper.copyWith(fontSize: 12.5),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatWaktu(item.waktu),
                  style: AppText.helper.copyWith(
                    fontSize: 10.5,
                    color: AppColors.neutralMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _ikonUntukJenis(JenisNotifikasi jenis) {
    switch (jenis) {
      case JenisNotifikasi.konfirmasiPendaftaran:
        return Icons.confirmation_number_outlined;
      case JenisNotifikasi.pengingatH1:
        return Icons.event_available_outlined;
      case JenisNotifikasi.giliranMendekati:
        return Icons.notifications_active_outlined;
      case JenisNotifikasi.perubahanJadwal:
        return Icons.update_outlined;
    }
  }

  String _formatWaktu(DateTime waktu) {
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final j = waktu.hour.toString().padLeft(2, '0');
    final m = waktu.minute.toString().padLeft(2, '0');
    return '${waktu.day} ${bulan[waktu.month - 1]} ${waktu.year}, $j:$m WIB';
  }
}
