import '../domain/entities/onboarding_page.dart';

import '../../../core/localization/translations.dart';

List<OnboardingPage> get patientOnboardingPages => [
  OnboardingPage(
    illustrationAsset: 'assets/images/onboarding/onboarding_image1.png',
    title: 'ابحث أو امسح وصفتك'.tr,
    subtitle: 'اعثر على أدويتك بطريقة أسهل.'.tr,
  ),
  OnboardingPage(
    illustrationAsset: 'assets/images/onboarding/onboarding_image2.png',
    title: 'قارن الصيدليات'.tr,
    subtitle: 'قارن الأسعار والتقييم والمسافة واختر الأنسب لك.'.tr,
  ),
  OnboardingPage(
    illustrationAsset: 'assets/images/onboarding/onboarding_image3.png',
    title: 'اطلب من أكثر من صيدلية'.tr,
    subtitle: 'اجمع منتجاتك في طلب واحد، حتى لو كانت من صيدليات مختلفة.'.tr,
  ),
];

/// Illustrations aren't ready yet from design — [OnboardingPageContent]
/// renders a placeholder box when `illustrationAsset` is null.
List<OnboardingPage> get pharmacyOnboardingPages => [
  OnboardingPage(
    artwork: OnboardingArtwork.pharmacyProducts,
    title: 'تحكم بمنتجات صيدليتك'.tr,
    subtitle: 'حدّث الأسعار والمخزون وتوفر المنتجات بكل سهولة.'.tr,
  ),
  OnboardingPage(
    artwork: OnboardingArtwork.pharmacyOrders,
    title: 'استقبل طلباتك بسهولة'.tr,
    subtitle: 'استقبل طلبات العملاء وراجع تفاصيلها قبل قبولها أو رفضها.'.tr,
  ),
  OnboardingPage(
    artwork: OnboardingArtwork.pharmacyChat,
    title: 'تواصل مباشرة مع عملائك'.tr,
    subtitle: 'أجب عن استفسارات العملاء وتابع محادثاتهم من مكان واحد.'.tr,
  ),
];
