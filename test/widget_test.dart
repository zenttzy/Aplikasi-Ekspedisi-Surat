// Smoke test fondasi aplikasi Ekspedisi Surat.

import 'package:flutter_test/flutter_test.dart';

import 'package:ekspedisi_surat/app.dart';

void main() {
  testWidgets('App menampilkan judul beranda', (WidgetTester tester) async {
    await tester.pumpWidget(const EkspedisiSuratApp(isConfigured: false));
    await tester.pump();

    expect(find.text('Buku Ekspedisi Digital'), findsWidgets);
  });
}
