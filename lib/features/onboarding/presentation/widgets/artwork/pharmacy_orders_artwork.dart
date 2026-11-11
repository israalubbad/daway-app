import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/localization/translations.dart';
import '../../../../pharmacy/presentation/widgets/pharmacy_order_card.dart';
import '../../../../pharmacy/presentation/widgets/pharmacy_products_header.dart';
import 'onboarding_phone_frame.dart';
import 'pharmacy_products_artwork.dart' show sampleOnboardingOrder;

/// "استقبل طلباتك بسهولة": the pharmacy's orders screen; the order cards slide
/// in one after the other when the page comes on show.
class PharmacyOrdersArtwork extends StatefulWidget {
  const PharmacyOrdersArtwork({super.key});

  @override
  State<PharmacyOrdersArtwork> createState() => _PharmacyOrdersArtworkState();
}

class _PharmacyOrdersArtworkState extends State<PharmacyOrdersArtwork>
    with SingleTickerProviderStateMixin {
  static const _cards = 3;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// How far card [index] has come in, 0 to 1. A page that is not on show
  /// draws its cards in place, so one swiped to half way is never empty.
  double _progress(int index) {
    final start = index * 0.22;
    final raw = ((_controller.value - start) / 0.45).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(raw);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingPhoneFrame(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Padding(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PharmacyProductsHeader(
                title: 'الطلبات'.tr,
                subtitle: 'أدر المنتجات الخاصة بك'.tr,
                onBack: () {},
              ),
              SizedBox(height: 24.h),
              for (var i = 0; i < _cards; i++) ...[
                if (i > 0) SizedBox(height: 16.h),
                Opacity(
                  opacity: _progress(i),
                  child: Transform.translate(
                    offset: Offset(0, 28.h * (1 - _progress(i))),
                    child: PharmacyOrderCard(
                      order: sampleOnboardingOrder(i + 1, 'DW-${1042 - i}'),
                      onViewTap: () {},
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
