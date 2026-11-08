import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../domain/entities/accounting_overview.dart';
import '../helpers/accounting_styles.dart';

/// The overview's sales chart: a line over a soft area, the day labels along
/// the bottom and three amount guides. With no sales at all it says so.
class SalesLineChart extends StatelessWidget {
  final List<SalesPoint> points;

  const SalesLineChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final hasSales = points.any((p) => p.amount > 0);
    return SizedBox(
      height: 170.h,
      child: points.isEmpty || !hasSales
          ? Center(child: Text('لا توجد مبيعات في هذه الفترة', style: AccountingStyles.muted))
          : CustomPaint(
              size: Size.infinite,
              painter: _SalesChartPainter(
                points: points,
                labelStyle: AccountingStyles.muted.copyWith(fontSize: 10.sp),
              ),
            ),
    );
  }
}

class _SalesChartPainter extends CustomPainter {
  final List<SalesPoint> points;
  final TextStyle labelStyle;

  _SalesChartPainter({required this.points, required this.labelStyle});

  @override
  void paint(Canvas canvas, Size size) {
    const leftGutter = 36.0;
    const bottomGutter = 20.0;
    final plot = Rect.fromLTWH(leftGutter, 4, size.width - leftGutter - 4, size.height - bottomGutter - 8);
    final maxAmount = points.map((p) => p.amount).reduce((a, b) => a > b ? a : b);
    final top = _niceCeiling(maxAmount);

    final guide = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = plot.bottom - plot.height * i / 2;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), guide);
      _paintText(
        canvas,
        (top * i / 2).round().toString(),
        Offset(plot.left - 6, y),
        alignRight: true,
      );
    }

    // The chart reads right to left like the page: the first day is rightmost.
    Offset at(int i) {
      final fraction = points.length == 1 ? 0.5 : i / (points.length - 1);
      return Offset(plot.right - plot.width * fraction, plot.bottom - plot.height * points[i].amount / top);
    }

    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    final area = Path.from(line)
      ..lineTo(at(points.length - 1).dx, plot.bottom)
      ..lineTo(at(0).dx, plot.bottom)
      ..close();
    canvas.drawPath(area, Paint()..color = AppColors.mainTeal.withValues(alpha: 0.10));
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.mainTeal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    final dot = Paint()..color = AppColors.mainTeal;
    // Dots only while they stay readable; a month of them would be a blur.
    if (points.length <= 10) {
      for (var i = 0; i < points.length; i++) {
        canvas.drawCircle(at(i), 3, dot);
      }
    }

    final step = points.length <= 10 ? 1 : (points.length / 7).ceil();
    for (var i = 0; i < points.length; i += step) {
      _paintText(canvas, points[i].label, Offset(at(i).dx, plot.bottom + 12), centered: true);
    }
  }

  /// A round top for the amount scale: 10, 20, 50, 100, 200, ...
  double _niceCeiling(double value) {
    if (value <= 10) return 10;
    var magnitude = 1.0;
    while (magnitude * 10 <= value) {
      magnitude *= 10;
    }
    for (final factor in [1.0, 2.0, 5.0, 10.0]) {
      if (magnitude * factor >= value) return magnitude * factor;
    }
    return magnitude * 10;
  }

  void _paintText(Canvas canvas, String text, Offset anchor, {bool alignRight = false, bool centered = false}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = centered ? anchor.dx - painter.width / 2 : (alignRight ? anchor.dx - painter.width : anchor.dx);
    painter.paint(canvas, Offset(dx, anchor.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _SalesChartPainter oldDelegate) => oldDelegate.points != points;
}
