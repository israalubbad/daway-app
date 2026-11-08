import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../domain/entities/accounting_overview.dart';
import '../helpers/accounting_format.dart';
import '../helpers/accounting_styles.dart';
import 'accounting_empty_state.dart';

/// The month's expenses by category: a donut with its legend. With no expenses
/// it shows the empty state.
class ExpenseDonut extends StatelessWidget {
  final List<ExpenseSlice> slices;

  const ExpenseDonut({super.key, required this.slices});

  /// The slice colours, in the app's blues with the status orange and green
  /// for contrast.
  static const _palette = [
    AppColors.mainTeal,
    AppColors.statLowStock,
    AppColors.statAvailable,
    AppColors.primaryTeal,
    AppColors.statRatings,
    AppColors.authInputBorder,
  ];

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.amount);
    if (slices.isEmpty || total <= 0) {
      return const AccountingEmptyState(icon: Icons.pie_chart_outline_rounded, title: 'لا توجد مصروفات مسجلة');
    }
    return Row(
      children: [
        SizedBox(
          width: 120.r,
          height: 120.r,
          child: CustomPaint(
            painter: _DonutPainter(
              values: [for (final s in slices) s.amount],
              colors: [for (var i = 0; i < slices.length; i++) _palette[i % _palette.length]],
            ),
            child: Center(
              child: Text(
                formatMoney(total),
                textDirection: TextDirection.ltr,
                style: AccountingStyles.cardTitle.copyWith(fontSize: 12.sp),
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            children: [
              for (var i = 0; i < slices.length; i++)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    children: [
                      Container(
                        width: 10.r,
                        height: 10.r,
                        decoration: BoxDecoration(
                          color: _palette[i % _palette.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(child: Text(slices[i].category, style: AccountingStyles.body)),
                      Text(
                        formatMoney(slices[i].amount),
                        textDirection: TextDirection.ltr,
                        style: AccountingStyles.label,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _DonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    final stroke = size.width * 0.16;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = 2 * math.pi * values[i] / total;
      canvas.drawArc(
        rect,
        start,
        // A hairline gap between slices keeps neighbours apart.
        math.max(sweep - 0.03, 0.001),
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}
