import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

/// A picture from [url] that is kept on the device's disk, so it shows at once
/// the next time (and offline) instead of being downloaded again, which
/// [Image.network] does every launch. Takes what [Image.network] took, so a
/// screen swaps one for the other without changing its loading and error
/// handling.
Widget networkImage(
  String url, {
  BoxFit? fit,
  double? width,
  double? height,
  ImageErrorWidgetBuilder? errorBuilder,
  ImageLoadingBuilder? loadingBuilder,
}) {
  return Image(
    image: CachedNetworkImageProvider(url),
    fit: fit,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
    loadingBuilder: loadingBuilder,
  );
}
