// Smoke test dasar buat AmpiraApp.
//
// Karena app ini pakai Provider (butuh sesi/async lookup) sejak SplashScreen
// tampil, test cuma pastikan app bisa di-build tanpa exception dan
// SplashScreen (entry point pertama) muncul di frame awal.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:antrian_donor_darah/main.dart';

void main() {
  testWidgets('AmpiraApp bisa di-build dan menampilkan SplashScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AmpiraApp());

    // Belum panggil pump() lanjutan supaya gak nge-trigger
    // WidgetsBinding.instance.addPostFrameCallback -> auth.cekSesiTersimpan()
    // (yang butuh SharedPreferences/plugin async, gak stabil di unit test
    // biasa tanpa mocking). Cukup pastikan splash tampil dulu.
    expect(find.text('Ampira'), findsOneWidget);
    expect(find.byIcon(Icons.bloodtype), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
