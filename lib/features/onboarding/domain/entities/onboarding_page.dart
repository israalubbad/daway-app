/// Which live, animated illustration a page shows in place of a picture file.
/// The drawing itself is presentation; the page only names it.
enum OnboardingArtwork {
  /// The pharmacy home with a finger tapping the products card.
  pharmacyProducts,

  /// The pharmacy's orders screen, its cards sliding in.
  pharmacyOrders,

  /// A conversation: a message, its reply, another message, its reply.
  pharmacyChat,
}

class OnboardingPage {
  /// Null while the real illustration hasn't been delivered yet — the
  /// presentation layer renders a generic placeholder in that case.
  final String? illustrationAsset;

  /// A live illustration drawn with the app's own widgets; wins over
  /// [illustrationAsset] when both are given.
  final OnboardingArtwork? artwork;
  final String title;
  final String subtitle;

  const OnboardingPage({
    this.illustrationAsset,
    this.artwork,
    required this.title,
    required this.subtitle,
  });
}
