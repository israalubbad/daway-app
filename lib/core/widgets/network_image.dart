import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// The pictures kept on the device: at most [_maxPictures] files, none older
/// than two weeks, so the folder stays at a few tens of megabytes at worst
/// (the library's default is 200 files for a month).
final CacheManager _pictureCache = CacheManager(
  Config('dawak_pictures', stalePeriod: const Duration(days: 14), maxNrOfCacheObjects: _maxPictures),
);
const _maxPictures = 120;

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
    image: CachedNetworkImageProvider(url, cacheManager: _pictureCache),
    fit: fit,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
    loadingBuilder: loadingBuilder,
  );
}
