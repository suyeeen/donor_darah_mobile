import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service tunggal buat semua urusan push notification: minta izin ke OS,
/// ambil FCM token device, dan nampilin notifikasi lokal pas app lagi
/// dibuka (foreground) karena FCM nggak otomatis nongolin banner di
/// kondisi itu.
class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  /// Dipasang ke MaterialApp.navigatorKey biar bisa navigasi dari luar
  /// widget tree (misal pas notifikasi di-tap).
  static final navigatorKey = GlobalKey<NavigatorState>();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'antrian_donor_channel',
    'Status Antrian Donor',
    description: 'Notifikasi status antrian & nomor dipanggil',
    importance: Importance.high,
  );

  Future<void> initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotif.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        // Notif di-tap pas app lagi foreground/background (bukan
        // terminated) -- arahkan ke halaman antrian.
        navigatorKey.currentState?.pushNamed('/antrian');
      },
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Notif diterima SAAT app foreground -> FCM gak otomatis nongolin
    // banner, jadi ditampilin manual lewat local notification.
    FirebaseMessaging.onMessage.listen((message) {
      final notif = message.notification;
      if (notif == null) return;
      _localNotif.show(
        notif.hashCode,
        notif.title,
        notif.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });

    // App di-minimize, lalu notif di-tap -> app dibuka lagi.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      navigatorKey.currentState?.pushNamed('/antrian');
    });
  }

  /// Minta izin notifikasi ke OS. Dipanggil dari tombol "Ya" di
  /// notifikasi_permission_dialog.dart. Return true kalau user kasih izin.
  Future<bool> mintaIzin() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Ambil FCM token device ini. Sementara belum ada backend, cukup
  /// ditampilin/di-log dulu -- begitu endpoint POST /device-token siap,
  /// kirim hasil ini ke sana.
  Future<String?> ambilToken() => _fcm.getToken();

  /// Cek apakah app ini dibuka DARI notifikasi (state: terminated).
  Future<RemoteMessage?> cekPesanAwal() => _fcm.getInitialMessage();
}
