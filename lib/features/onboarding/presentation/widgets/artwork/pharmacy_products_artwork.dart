import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../core/localization/translations.dart';
import '../../../../../core/theming/app_colors.dart';
import '../../../../../core/theming/app_text_styles.dart';
import '../../../../../core/widgets/header_icon_button.dart';
import '../../../../pharmacy/domain/entities/pharmacy_order.dart';
import '../../../../pharmacy/presentation/widgets/pharmacy_orders_section.dart';
import '../../../../pharmacy/presentation/widgets/pharmacy_stat_tiles.dart';
import '../../../../pharmacy/presentation/widgets/pharmacy_summary_cards.dart';
import 'onboarding_phone_frame.dart';

/// "تحكم بمنتجات صيدليتك": the pharmacy home, drawn with the app's own widgets,
/// and a finger that comes to the products card, taps it (the card grows, then
/// settles) and leaves — three times, then the picture rests.
class PharmacyProductsArtwork extends StatefulWidget {
  const PharmacyProductsArtwork({super.key});

  @override
  State<PharmacyProductsArtwork> createState() => _PharmacyProductsArtworkState();
}

class _PharmacyProductsArtworkState extends State<PharmacyProductsArtwork>
    with SingleTickerProviderStateMixin {
  static const _taps = 3;
  static const _tapDuration = Duration(milliseconds: 3400);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _tapDuration * _taps,
  );
  final _stackKey = GlobalKey();
  final _cardKey = GlobalKey();

  /// Where the finger lands: the products card's centre, in the picture's own
  /// coordinates. Measured after layout, so it follows the language.
  Offset? _target;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    _controller.forward(from: 0);
  }

  void _measure() {
    final card = _cardKey.currentContext?.findRenderObject();
    final stack = _stackKey.currentContext?.findRenderObject();
    if (!mounted || card is! RenderBox || stack is! RenderBox || !card.hasSize) return;
    final center = stack.globalToLocal(card.localToGlobal(card.size.center(Offset.zero)));
    if (center != _target) setState(() => _target = center);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Progress of [t] between [from] and [to], eased, and 0 / 1 outside them.
  static double _ramp(double t, double from, double to) =>
      Curves.easeInOut.transform(((t - from) / (to - from)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return OnboardingPhoneFrame(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // One tap's worth of progress, 0 to 1, repeated for each tap.
          final t = _controller.value == 1 ? 1.0 : (_controller.value * _taps) % 1.0;
          final press = _ramp(t, 0.30, 0.40) - _ramp(t, 0.44, 0.58);
          final cardScale = 1 + 0.08 * press;
          final target = _target;

          return Stack(
            key: _stackKey,
            clipBehavior: Clip.none,
            children: [
              _HomeMock(
                productsCardBuilder: (card) => KeyedSubtree(
                  key: _cardKey,
                  child: Transform.scale(scale: cardScale, child: card),
                ),
              ),
              if (target != null && _controller.isAnimating)
                _Finger(target: target, t: t),
            ],
          );
        },
      ),
    );
  }
}

/// The finger and the ripple under it, for one tap at progress [t].
class _Finger extends StatelessWidget {
  final Offset target;
  final double t;

  const _Finger({required this.target, required this.t});

  @override
  Widget build(BuildContext context) {
    final arrive = _PharmacyProductsArtworkState._ramp(t, 0.0, 0.30);
    final leave = _PharmacyProductsArtworkState._ramp(t, 0.60, 0.80);
    final pressed = _PharmacyProductsArtworkState._ramp(t, 0.30, 0.40) -
        _PharmacyProductsArtworkState._ramp(t, 0.44, 0.52);
    final ripple = _PharmacyProductsArtworkState._ramp(t, 0.32, 0.58);

    // Comes in from below and to the side, goes back the same way.
    final away = (1 - arrive) + leave;
    final offset = Offset(60.w, 90.h) * away;
    final opacity = (arrive * (1 - leave)).clamp(0.0, 1.0);
    final size = 44.r;

    return Positioned(
      left: target.dx - size / 2,
      top: target.dy - size / 2,
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: offset,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (ripple > 0 && ripple < 1)
                  Container(
                    width: size * (0.5 + ripple),
                    height: size * (0.5 + ripple),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mainTeal.withValues(alpha: 0.28 * (1 - ripple)),
                    ),
                  ),
                Transform.scale(
                  scale: 1 - 0.18 * pressed,
                  child: Icon(
                    Icons.touch_app_rounded,
                    size: size,
                    color: AppColors.textDark,
                    shadows: const [Shadow(color: Colors.white, blurRadius: 6)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The pharmacy home as the design pictures it. Sample figures, no cubits.
class _HomeMock extends StatelessWidget {
  final Widget Function(Widget card) productsCardBuilder;

  const _HomeMock({required this.productsCardBuilder});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: 6.w),
                      child: Text.rich(
                        TextSpan(
                          style: AppTextStyles.homeGreetingRegular,
                          children: [
                            TextSpan(text: 'أهلا بك '.tr),
                            TextSpan(
                              text: 'صيدلية النور'.tr,
                              style: AppTextStyles.pharmacyGreetingName,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        SvgPicture.asset('assets/icons/location_icon.svg', width: 24.w, height: 24.w),
                        SizedBox(width: 4.w),
                        Text('غزة - الرمال'.tr, style: AppTextStyles.homeLocationText),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: HeaderIconButton(
                  assetName: 'assets/icons/notification_icon.svg',
                  iconSize: 26,
                  onTap: () {},
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          PharmacySummaryCards(
            totalProducts: 120,
            monthlySales: 1200,
            onProductsTap: () {},
            productsCardBuilder: productsCardBuilder,
          ),
          SizedBox(height: 16.h),
          PharmacyStatTiles(
            available: 45,
            lowStock: 12,
            outOfStock: 5,
            averageRating: 4.5,
            onRatingsTap: () {},
          ),
          SizedBox(height: 24.h),
          PharmacyOrdersSection(
            orders: [sampleOnboardingOrder(1, 'DW-1021')],
            onViewAllTap: () {},
            onOrderTap: (_) {},
          ),
        ],
      ),
    );
  }
}

/// An order for the pictures: a few minutes old, three medicines.
PharmacyOrder sampleOnboardingOrder(int id, String number) => PharmacyOrder(
  id: id,
  orderNumber: number,
  createdAt: DateTime.now().subtract(Duration(minutes: 5 * id)),
  itemsCount: 3,
  total: 85,
  area: 'غزة - النصر'.tr,
);
