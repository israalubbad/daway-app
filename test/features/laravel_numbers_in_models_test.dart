import 'package:daway_app/features/patient/data/models/category_medicine_model.dart';
import 'package:daway_app/features/patient/data/models/favorite_medicine_model.dart';
import 'package:daway_app/features/patient/data/models/medicine_pharmacy_offer_model.dart';
import 'package:daway_app/features/patient/data/models/nearby_pharmacy_model.dart';
import 'package:daway_app/features/patient/data/models/patient_address_model.dart';
import 'package:daway_app/features/patient/data/models/searched_medicine_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// The backend is Laravel: decimals and ids can arrive as strings. None of
/// these models may throw on that (a throw fails the whole list screen).
void main() {
  test('a nearby pharmacy with string coordinates', () {
    final model = NearbyPharmacyModel.fromJson({
      'id': '3',
      'pharmacy_name': 'صيدلية النور',
      'latitude': '31.5017',
      'longitude': '34.4668',
      'is_open_now': 1,
    });

    expect(model.id, 3);
    expect(model.latitude, 31.5017);
    expect(model.longitude, 34.4668);
    expect(model.isOpenNow, isTrue);
  });

  test('an address with string coordinates and a 0/1 default flag', () {
    final model = PatientAddressModel.fromJson({
      'id': 1,
      'address': 'غزة',
      'latitude': '31.5',
      'longitude': '34.47',
      'is_default': 1,
    });

    expect(model.latitude, 31.5);
    expect(model.isDefault, isTrue);
    expect(PatientAddressModel.fromJson({'is_default': 0}).isDefault, isFalse);
  });

  test('a pharmacy offer with a string price and ids', () {
    final model = MedicinePharmacyOfferModel.fromJson({
      'pharmacy_id': '5',
      'name': 'صيدلية الأمل',
      'price': '12.50',
      'distance_km': '1.2',
      'pharmacy_medicine_id': '9',
    });

    expect(model.pharmacyId, 5);
    expect(model.price, 12.5);
    expect(model.distanceKm, 1.2);
    expect(model.pharmacyMedicineId, 9);
  });

  test('a favourite medicine with a string minimum price', () {
    final model = FavoriteMedicineModel.fromJson({
      'medicine_id': '6',
      'trade_name': 'Brufen',
      'min_price': '8.00',
      'pharmacies_count': '2',
    });

    expect(model.medicineId, 6);
    expect(model.minPrice, 8.0);
    expect(model.pharmaciesCount, 2);
  });

  test('catalog and search rows with string ids', () {
    expect(CategoryMedicineModel.fromJson({'id': '4', 'trade_name': 'Adol'}).id, 4);
    expect(SearchedMedicineModel.fromJson({'id': '4', 'trade_name': 'Adol'}).id, 4);
  });

  test('a catalog or search row without an id is rejected, not shown as medicine 0', () {
    expect(() => CategoryMedicineModel.fromJson({'trade_name': 'x'}), throwsFormatException);
    expect(() => SearchedMedicineModel.fromJson({'trade_name': 'x'}), throwsFormatException);
  });
}
