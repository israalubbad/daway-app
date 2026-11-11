import 'dart:async';

import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/erroring/error_handler.dart';
import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../../core/models/picked_location.dart';
import '../../domain/repositories/location_repository.dart';

import '../../../../core/localization/translations.dart';
class LocationRepositoryImpl implements LocationRepository {

  final Geocoding _geocoding = Geocoding();

  // Geocoders default to the device's locale; the app is Arabic-only, so
  // every place name/address it returns should be too.
  static const _arabic = Locale('ar');

  LocationRepositoryImpl();

  @override
  Future<ApiResult<PickedLocation>> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return ApiError(
        PermissionFailure('خدمة تحديد الموقع غير مفعّلة على جهازك، يرجى تفعيلها'.tr),
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return ApiError(
        PermissionFailure('يرجى السماح بالوصول لموقعك لتحديد عنوانك، أو اختر الموقع يدوياً'.tr),
      );
    }

    try {
      // Without a time limit this can hang forever on a weak/no GPS fix
      // (e.g. indoors) — the "السماح بالوصول لموقعك" button then spins with
      // no way out but leaving the screen. 15s is enough for a normal fix;
      // past that, fail with a message the user can act on instead.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final addressResult = await reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final address = switch (addressResult) {
        Success(:final data) => data,
        ApiError() => '',
      };
      return Success(PickedLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      ));
    } on TimeoutException {
      return ApiError(
        PermissionFailure('تعذر تحديد موقعك، تأكد من تفعيل GPS وحاول مرة أخرى'.tr),
      );
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }

  @override
  Future<ApiResult<String>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) {
    return guardApi(() async {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
        locale: _arabic,
      );
      if (placemarks.isEmpty) return const Success('');

      final placemark = placemarks.first;
      final parts = <String?>[
        placemark.locality,
        placemark.administrativeArea,
        placemark.country,
      ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();
      return Success(parts.isNotEmpty ? parts.join('، '.tr) : (placemark.name ?? ''));
    });
  }

  @override
  Future<ApiResult<PickedLocation>> searchAddress(String query) {
    return guardApi(() async {
      final locations = await _geocoding.locationFromAddress(query, locale: _arabic);
      if (locations.isEmpty) {
        return ApiError(ValidationFailure('لم يتم العثور على هذا العنوان'.tr));
      }

      final location = locations.first;
      final addressResult = await reverseGeocode(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      final address = switch (addressResult) {
        Success(:final data) => data.isNotEmpty ? data : query,
        ApiError() => query,
      };
      return Success(PickedLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        address: address,
      ));
    });
  }
}
