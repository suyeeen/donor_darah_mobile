import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notifikasi_provider.dart';
import '../services/push_notification_service.dart';
import '../theme/app_theme.dart';

/// Dialog "Aktifkan Notifikasi pada Device".
///
/// Ditampilkan SEKALI, tepat setelah pendonor selesai mendaftar/ambil
/// nomor antrian (di ETiketScreen) -- bukan saat pertama buka Home --
/// karena di titik itulah notifikasi jadi relevan: dipakai buat ngasih
/// kabar realtime selama antrian pendonor masih aktif (nomor dipanggil,
/// tersisa sekian orang di depan, dst).
Future<void> showNotifikasiPermissionDialog(BuildContext context) async {
  final notifProvider = context.read<NotifikasiProvider>();

  await showDialog(
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
                onTap: () {
                  notifProvider.tandaiSudahTanyaIzinDevice();
                  Navigator.pop(dialogContext);
                },
                child: const Icon(Icons.close, size: 20),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
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
            const SizedBox(height: 8),
            Text(
              'Biar Anda tahu begitu nomor antrian dipanggil, walau '
              'aplikasi lagi ditutup.',
              style: AppText.helper,
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
                    onPressed: () async {
                      final diizinkan = await PushNotificationService.instance
                          .mintaIzin();

                      notifProvider.tandaiSudahTanyaIzinDevice();

                      if (diizinkan) {
                        notifProvider.aktifkanNotifikasi();

                        // Ambil token sekarang. Backend belum siap terima
                        // ini, jadi sementara cuma di-log -- begitu
                        // endpoint POST /device-token ada, kirim `token`
                        // ke situ persis di titik ini.
                        final token = await PushNotificationService.instance
                            .ambilToken();
                        debugPrint('FCM token pendonor: $token');
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
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
