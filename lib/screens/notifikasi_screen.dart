import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notifikasi.dart';
import '../providers/notifikasi_provider.dart';
import '../theme/app_theme.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  // null = tab "Semua"
  KategoriNotifikasi? _filterAktif;

  static const _tabs = <String, KategoriNotifikasi?>{
    'Semua': null,
    'Antrian': KategoriNotifikasi.antrian,
    'Jadwal': KategoriNotifikasi.jadwal,
    'Selesai': KategoriNotifikasi.selesai,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotifikasiProvider>().muatNotifikasi();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildTabChips(),
                ],
              ),
            ),
            Expanded(
              child: Consumer<NotifikasiProvider>(
                builder: (context, provider, _) => _buildBody(provider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _backButton(context),
        const SizedBox(width: 15),
        Text('Notifikasi', style: AppText.headline.copyWith(fontSize: 20)),
      ],
    );
  }

  Widget _backButton(BuildContext context) {
    return Container(
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
    );
  }

  Widget _buildTabChips() {
    final entries = _tabs.entries.toList();
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = entries[i].key;
          final kategori = entries[i].value;
          final active = kategori == _filterAktif;
          return GestureDetector(
            onTap: () => setState(() => _filterAktif = kategori),
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

  Widget _buildBody(NotifikasiProvider provider) {
    if (provider.status == NotifikasiStatusFetch.loading ||
        provider.status == NotifikasiStatusFetch.idle) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == NotifikasiStatusFetch.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Gagal memuat notifikasi.\n${provider.errorMessage ?? ''}',
            textAlign: TextAlign.center,
            style: AppText.helper,
          ),
        ),
      );
    }

    final daftar = provider.filter(_filterAktif);

    if (daftar.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: daftar.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _buildNotifikasiCard(daftar[i]),
    );
  }

  Widget _buildEmptyState() {
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
                Icons.notifications_off_outlined,
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
              'Konfirmasi antrian, pengingat giliran, dan penerbitan '
              'sertifikat akan muncul di sini.',
              style: AppText.helper,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifikasiCard(NotifikasiItem item) {
    final info = _kategoriInfo(item.kategori);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.sudahDibaca ? AppColors.inputBorder : AppColors.primary,
          width: item.sudahDibaca ? 1 : 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: info.$2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(info.$1, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.judul,
                  style: AppText.inputText.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(item.pesan, style: AppText.helper),
                const SizedBox(height: 8),
                Text(
                  _formatWaktu(item.waktu),
                  style: AppText.helper.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
          if (!item.sudahDibaca) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  (IconData, Color) _kategoriInfo(KategoriNotifikasi kategori) {
    switch (kategori) {
      case KategoriNotifikasi.antrian:
        return (Icons.confirmation_number_outlined, AppColors.primary);
      case KategoriNotifikasi.jadwal:
        return (Icons.calendar_month_outlined, AppColors.cardDark);
      case KategoriNotifikasi.selesai:
        return (Icons.workspace_premium_outlined, AppColors.success);
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
    return '${waktu.day} ${bulan[waktu.month - 1]} ${waktu.year} · $j:$m WIB';
  }
}
