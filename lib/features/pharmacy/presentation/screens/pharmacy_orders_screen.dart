import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../../domain/entities/pharmacy_order.dart';
import '../widgets/pharmacy_order_card.dart';
import '../widgets/pharmacy_products_header.dart';
import 'pharmacy_order_details_screen.dart';

/// The pharmacy's الطلبات tab: every order as a card, newest first as handed
/// in, and "عرض الطلب" opens its details. A tab's root, so no back chip.
///
/// The shell hands in what its orders cubit holds: the orders, or [isLoading],
/// or an [errorMessage] with [onRetry].
class PharmacyOrdersScreen extends StatelessWidget {
  final List<PharmacyOrder> orders;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final PharmacyOrderDecision? onDecide;
  final PharmacyOrderLoader? onLoadDetails;

  const PharmacyOrdersScreen({
    super.key,
    this.orders = const [],
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onDecide,
    this.onLoadDetails,
  });

  @override
  Widget build(BuildContext context) {
    final error = errorMessage;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
          children: [
            const PharmacyProductsHeader(
              title: 'الطلبات',
              subtitle: 'أدر المنتجات الخاصة بك',
            ),
            SizedBox(height: 24.h),
            if (isLoading)
              Padding(
                padding: EdgeInsets.only(top: 80.h),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              ProfileLoadError(message: error, onRetry: onRetry ?? () {})
            else if (orders.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 80.h),
                child: Text(
                  'لا توجد طلبات بعد.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.settingsMutedText,
                ),
              )
            else
              for (var i = 0; i < orders.length; i++) ...[
                if (i > 0) SizedBox(height: 16.h),
                PharmacyOrderCard(
                  order: orders[i],
                  onViewTap: () => PharmacyOrderDetailsScreen.open(
                    context,
                    orders[i],
                    onDecide: onDecide,
                    onLoadDetails: onLoadDetails,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}
