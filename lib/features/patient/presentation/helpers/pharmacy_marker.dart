import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_fonts.dart';

/// A map marker for a pharmacy: a pill with the pharmacy icon and its name
/// and a small pointer to its exact spot, drawn on a canvas (google_maps
/// markers are bitmaps, not widgets). The selected pharmacy is drawn filled
/// with the main colour.
///
/// [pixelRatio] is the screen's device pixel ratio, so the pill is sharp
/// instead of blurry on a dense screen.
Future<BitmapDescriptor> buildPharmacyMarker({
  required String name,
  required bool selected,
  required double pixelRatio,
}) async {
  final marker = await renderPharmacyMarker(
    name: name,
    selected: selected,
    pixelRatio: pixelRatio,
  );
  return BitmapDescriptor.bytes(marker.png, width: marker.width, height: marker.height);
}

/// The drawn marker: PNG bytes plus the size it is shown at, in logical pixels.
class PharmacyMarkerImage {
  final Uint8List png;
  final double width;
  final double height;

  const PharmacyMarkerImage(this.png, this.width, this.height);
}

Future<PharmacyMarkerImage> renderPharmacyMarker({
  required String name,
  required bool selected,
  required double pixelRatio,
}) async {
  const maxTextWidth = 150.0;
  const pillHeight = 40.0;
  const pointerHeight = 8.0;
  const pointerHalfWidth = 7.0;
  const shadowPad = 6.0;
  const iconCircle = 26.0;
  const sidePadding = 8.0;
  const gap = 8.0;

  final background = selected ? AppColors.mainTeal : Colors.white;
  final foreground = selected ? Colors.white : AppColors.textDark;
  final iconBackground = selected ? Colors.white : AppColors.mainTeal;
  final iconColor = selected ? AppColors.mainTeal : Colors.white;

  final textPainter = TextPainter(
    text: TextSpan(
      text: name,
      style: AppFonts.tajawal(
        TextStyle(fontSize: 13, color: foreground, height: 1.2),
        FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.rtl,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxTextWidth);

  final iconPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(Icons.local_pharmacy.codePoint),
      style: TextStyle(
        fontFamily: Icons.local_pharmacy.fontFamily,
        package: Icons.local_pharmacy.fontPackage,
        fontSize: 16,
        color: iconColor,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final pillWidth = sidePadding + iconCircle + gap + textPainter.width + sidePadding + 4;
  final width = pillWidth + shadowPad * 2;
  final height = pillHeight + pointerHeight + shadowPad * 2;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(pixelRatio);

  final pillRect = Rect.fromLTWH(shadowPad, shadowPad, pillWidth, pillHeight);
  final pill = RRect.fromRectAndRadius(pillRect, const Radius.circular(pillHeight / 2));
  final pointer = Path()
    ..moveTo(width / 2 - pointerHalfWidth, shadowPad + pillHeight - 1)
    ..lineTo(width / 2 + pointerHalfWidth, shadowPad + pillHeight - 1)
    ..lineTo(width / 2, shadowPad + pillHeight + pointerHeight)
    ..close();
  final outline = Path()
    ..addRRect(pill)
    ..addPath(pointer, Offset.zero);

  canvas.drawShadow(outline, Colors.black.withValues(alpha: 0.45), 3, true);
  canvas.drawPath(outline, Paint()..color = background);
  canvas.drawRRect(
    pill,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.mainTeal,
  );

  // Icon on the right (this is an RTL label), the name to its left.
  final circleCenter = Offset(
    pillRect.right - sidePadding - iconCircle / 2,
    pillRect.center.dy,
  );
  canvas.drawCircle(circleCenter, iconCircle / 2, Paint()..color = iconBackground);
  iconPainter.paint(
    canvas,
    circleCenter - Offset(iconPainter.width / 2, iconPainter.height / 2),
  );
  textPainter.paint(
    canvas,
    Offset(
      pillRect.right - sidePadding - iconCircle - gap - textPainter.width,
      pillRect.center.dy - textPainter.height / 2,
    ),
  );

  final image = await recorder.endRecording().toImage(
        (width * pixelRatio).ceil(),
        (height * pixelRatio).ceil(),
      );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return PharmacyMarkerImage(Uint8List.view(bytes!.buffer), width, height);
}
