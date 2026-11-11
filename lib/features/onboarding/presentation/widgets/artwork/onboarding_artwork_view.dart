import 'package:flutter/widgets.dart';

import '../../../domain/entities/onboarding_page.dart';
import 'pharmacy_chat_artwork.dart';
import 'pharmacy_orders_artwork.dart';
import 'pharmacy_products_artwork.dart';

/// The live illustration [artwork] names. It plays when it is built, which a
/// page view does as the page comes into view, so it plays on every visit.
class OnboardingArtworkView extends StatelessWidget {
  final OnboardingArtwork artwork;

  const OnboardingArtworkView({super.key, required this.artwork});

  @override
  Widget build(BuildContext context) {
    return switch (artwork) {
      OnboardingArtwork.pharmacyProducts => const PharmacyProductsArtwork(),
      OnboardingArtwork.pharmacyOrders => const PharmacyOrdersArtwork(),
      OnboardingArtwork.pharmacyChat => const PharmacyChatArtwork(),
    };
  }
}
