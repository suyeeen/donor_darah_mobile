import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/push_notification_service.dart';
import '../theme/app_theme.dart';

/// Halaman DEBUG buat mastiin push notification beneran nyambung ke
/// Firebase: cek izin OS, lihat & copy FCM token, tes notifikasi lokal,
/// dan nampilin log real-time tiap pesan FCM yang masuk pas app foreground.
class TesNotifikasiScreen extends StatefulWidget {
  const TesNotifikasiScreen({super.key});

  @override
  State<TesNotifikasiScreen> createState() => _TesNotifikasiScreenState();
}

class _TesNotifikasiScreenState extends State<TesNotifikasiScreen> {
  String? _token;
  bool _loadingToken = true;
  AuthorizationStatus? _statusIzin;
  StreamSubscription<RemoteMessage>? _sub;
  final List<_LogPesan> _log = [];

  @override
  void initState() {
    super.initState();
    _muatToken();
    _cekIzin();
    _sub = PushNotificationService.instance.pesanMasuk.listen((message) {
      setState(() {
        _log.insert(
          0,
          _LogPesan(
            waktu: DateTime.now(),
            judul: message.notification?.title,
            isi: message.notification?.body,
            data: message.data,
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _muatToken() async {
    setState(() => _loadingToken = true);
    final token = await PushNotificationService.instance.ambilToken();
    if (!mounted) return;
    setState(() {
      _token = token;
      _loadingToken = false;
    });
  }

  Future<void> _cekIzin() async {
    final settings = await PushNotificationService.instance.cekStatusIzin();
    if (!mounted) return;
    setState(() => _statusIzin = settings.authorizationStatus);
  }

  Future<void> _mintaIzin() async {
    await PushNotificationService.instance.mintaIzin();
    await _cekIzin();
  }

  void _copyToken() {
    if (_token == null) return;
    Clipboard.setData(ClipboardData(text: _token!));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Token disalin ke clipboard')));
  }

  (String, Color) _labelStatusIzin(AuthorizationStatus? status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return ('Diizinkan', AppColors.success);
      case AuthorizationStatus.provisional:
        return ('Diizinkan (provisional)', AppColors.success);
      case AuthorizationStatus.denied:
        return ('Ditolak', AppColors.primary);
      case AuthorizationStatus.notDetermined:
        return ('Belum ditentukan', AppColors.neutralMuted);
      case null:
        return ('Mengecek...', AppColors.neutralMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (labelStatus, warnaStatus) = _labelStatusIzin(_statusIzin);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _buildHeader(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  _buildStatusCard(labelStatus, warnaStatus),
                  const SizedBox(height: 14),
                  _buildTokenCard(),
                  const SizedBox(height: 14),
                  _buildAksiCard(),
                  const SizedBox(height: 20),
                  Text('Log Pesan Masuk (Foreground)', style: AppText.label),
                  const SizedBox(height: 4),
                  Text(
                    'Pesan FCM yang diterima pas app lagi dibuka bakal '
                    'muncul di sini secara real-time.',
                    style: AppText.helper,
                  ),
                  const SizedBox(height: 10),
                  _buildLogList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          'Tes Notifikasi Push',
          style: AppText.headline.copyWith(fontSize: 20),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: child,
    );
  }

  Widget _buildStatusCard(String label, Color warna) {
    return _buildCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: warna,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Izin Notifikasi',
                  style: AppText.inputText.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(label, style: AppText.helper.copyWith(color: warna)),
              ],
            ),
          ),
          if (_statusIzin != AuthorizationStatus.authorized &&
              _statusIzin != AuthorizationStatus.provisional)
            TextButton(
              onPressed: _mintaIzin,
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Minta Izin'),
            ),
        ],
      ),
    );
  }

  Widget _buildTokenCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'FCM Token Device Ini',
                style: AppText.inputText.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: _muatToken,
                tooltip: 'Ambil ulang token',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.tabInactiveBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _loadingToken
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : SelectableText(
                    _token ??
                        'Token tidak tersedia (cek izin & koneksi internet)',
                    style: AppText.helper.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _token == null ? null : _copyToken,
              icon: const Icon(Icons.copy_outlined, size: 16),
              label: const Text('Copy Token'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.inputBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAksiCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tes Notifikasi Lokal',
            style: AppText.inputText.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  PushNotificationService.instance.tampilkanNotifikasiTes(),
              icon: const Icon(
                Icons.notifications_outlined,
                size: 18,
                color: Colors.white,
              ),
              label: const Text(
                'Kirim Notifikasi Tes',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    if (_log.isEmpty) {
      return _buildCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Belum ada pesan masuk.\nKirim tes dari Firebase Console '
              'sambil halaman ini kebuka.',
              textAlign: TextAlign.center,
              style: AppText.helper,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _log
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.mark_email_read_outlined,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${item.waktu.hour.toString().padLeft(2, '0')}:'
                          '${item.waktu.minute.toString().padLeft(2, '0')}:'
                          '${item.waktu.second.toString().padLeft(2, '0')}',
                          style: AppText.helper,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.judul ??
                          '(tanpa judul -- kemungkinan data-only message)',
                      style: AppText.inputText.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.isi != null) ...[
                      const SizedBox(height: 2),
                      Text(item.isi!, style: AppText.helper),
                    ],
                    if (item.data.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'data: ${item.data}',
                        style: AppText.helper.copyWith(fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LogPesan {
  final DateTime waktu;
  final String? judul;
  final String? isi;
  final Map<String, dynamic> data;

  _LogPesan({required this.waktu, this.judul, this.isi, this.data = const {}});
}
