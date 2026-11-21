import '../../../../core/helpers/arabic_plural.dart';

import '../../../../core/localization/translations.dart';

/// "متوفر في صيدلية واحدة" / "متوفر في صيدليتين" / "متوفر في 5 صيدليات" /
/// "متوفر في 12 صيدلية" — the availability line of the medicine cards, with
/// the noun agreeing with the count.
String pharmaciesAvailabilityLabel(int pharmaciesCount) {
  final pharmacies = arabicCountedNoun(
    pharmaciesCount,
    singular: 'صيدلية'.tr,
    dual: 'صيدليتين'.tr,
    plural: 'صيدليات'.tr,
    one: 'صيدلية واحدة'.tr,
  );
  return 'متوفر في {0}'.trArgs([pharmacies]);
}
