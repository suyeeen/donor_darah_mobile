import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class KelolaPerangkatScreen extends StatefulWidget {
  const KelolaPerangkatScreen({super.key});

  @override
  State<KelolaPerangkatScreen> createState() => _KelolaPerangkatScreenState();
}

class _SesiPerangkat {
  final String deviceInfo;
  final String ipAddress;
  final String terakhirAktif;
  final bool perangkatIni;

  _SesiPerangkat({
    required this.deviceInfo,
    required this.ipAddress,
    required this.terakhirAktif,
    this.perangkatIni = false,
  });
}

class _KelolaPerangkatScreenState extends State<KelolaPerangkatScreen> {
  late List<_SesiPerangkat> _daftarSesi;

  @override
  void initState() {
    super.initState();
    _daftarSesi = [
      _SesiPerangkat(
        deviceInfo: 'Perangkat ini (Android)',
        ipAddress: '10.20.4.11',
        terakhirAktif: 'Aktif sekarang',
        perangkatIni: true,
      ),
      _SesiPerangkat(
        deviceInfo: 'Chrome di Windows',
        ipAddress: '182.253.10.4',
        terakhirAktif: 'Aktif 2 hari lalu',
      ),
    ];
  }

  void _keluarDariSesi(_SesiPerangkat sesi) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Keluar dari perangkat ini?',
          style: AppText.headline.copyWith(fontSize: 16),
        ),
        content: Text(
          '${sesi.deviceInfo} akan langsung logout dan perlu masuk ulang.',
          style: AppText.helper,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
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
            onPressed: () {
              setState(() => _daftarSesi.remove(sesi));
              Navigator.pop(dialogContext);
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _buildHeader(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Text(
                'Perangkat yang sedang login ke akun Anda. Keluarkan '
                'perangkat yang tidak dikenali demi keamanan akun.',
                style: AppText.helper,
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: _daftarSesi.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _buildSesiCard(_daftarSesi[i]),
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
        Text(
          'Kelola Perangkat',
          style: AppText.headline.copyWith(fontSize: 20),
        ),
      ],
    );
  }

  Widget _buildSesiCard(_SesiPerangkat sesi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.tabInactiveBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              sesi.deviceInfo.contains('Chrome')
                  ? Icons.laptop_mac_outlined
                  : Icons.smartphone_outlined,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        sesi.deviceInfo,
                        style: AppText.inputText.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (sesi.perangkatIni) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Perangkat ini',
                          style: AppText.chip.copyWith(
                            fontSize: 9.5,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${sesi.terakhirAktif} · ${sesi.ipAddress}',
                  style: AppText.helper,
                ),
              ],
            ),
          ),
          if (!sesi.perangkatIni)
            TextButton(
              onPressed: () => _keluarDariSesi(sesi),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Keluar'),
            ),
        ],
      ),
    );
  }
}
