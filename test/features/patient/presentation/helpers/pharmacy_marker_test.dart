import 'dart:io';

import 'package:daway_app/features/patient/presentation/helpers/pharmacy_marker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('draws a pill sized to the name, at the screen pixel ratio', (tester) async {
    await tester.runAsync(() async {
      final short = await renderPharmacyMarker(name: 'الأمل', selected: false, pixelRatio: 2);
      final long = await renderPharmacyMarker(
        name: 'صيدلية الشفاء المركزية الكبرى للأدوية',
        selected: false,
        pixelRatio: 2,
      );

      expect(short.png.length, greaterThan(100));
      // PNG signature.
      expect(short.png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      expect(long.width, greaterThan(short.width));
      // A long name is cut with an ellipsis instead of growing without limit.
      expect(long.width, lessThan(260));
      expect(short.height, greaterThan(40));
    });
  });

  testWidgets('the selected pharmacy is drawn differently', (tester) async {
    await tester.runAsync(() async {
      final normal = await renderPharmacyMarker(name: 'الأمل', selected: false, pixelRatio: 2);
      final selected = await renderPharmacyMarker(name: 'الأمل', selected: true, pixelRatio: 2);

      expect(selected.png, isNot(normal.png));
      expect(selected.width, normal.width);
      // For a look at the result: build/pharmacy_marker_*.png when asked.
      if (Platform.environment['SAVE_MARKER'] == '1') {
        File('build/pharmacy_marker_normal.png').writeAsBytesSync(normal.png);
        File('build/pharmacy_marker_selected.png').writeAsBytesSync(selected.png);
      }
    });
  });
}
