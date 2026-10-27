import 'package:daway_app/features/chat/data/repositories/chatbot_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

/// The response of `POST /patient/assistant/chat` for "وين بلاقي بروفين".
const _foundResponse = {
  'success': true,
  'analysis': {
    'intent': 'medicine_search',
    'drug_name': 'بروفين',
    'confidence': null,
  },
  'medicine': {
    'id': 8,
    'name': 'Brufen',
    'trade_name_ar': 'بروفين',
    'active_ingredient': 'Paracetamol 500 mg',
    'image_url': 'https://res.cloudinary.com/x/brufen.jpg',
  },
  'pharmacies': [
    {
      'pharmacy_id': 1,
      'name': 'صيدلية الأمل',
      'price': 10,
      'quantity': 50,
      'availability': 'available',
      'distance_km': null,
      'phone': '+970591234567',
      'latitude': 31.5016,
      'longitude': 34.4668,
      'is_open_now': true,
      'rating': 0,
      'address': 'غزة، شارع الوحدة',
      'region': 'غزه',
    },
    {
      'pharmacy_id': 2,
      'name': 'صيدلية الشفاء',
      'price': 12.5,
      'quantity': 28,
      'availability': 'available',
      'distance_km': 3.25,
      'is_open_now': false,
      'address': 'نابلس، شارع حطين',
    },
  ],
  'alternatives': [],
  'total_found': 2,
  'requires_location': true,
};

void main() {
  group('ChatbotRepositoryImpl.parseReply', () {
    test('reads the medicine, the pharmacies and the total of a search', () {
      final reply = ChatbotRepositoryImpl.parseReply(_foundResponse);

      expect(reply.text, isNull);
      expect(reply.hasResults, isTrue);
      expect(reply.isEmpty, isFalse);
      expect(reply.totalFound, 2);

      final medicine = reply.medicine!;
      expect(medicine.id, 8);
      expect(medicine.name, 'Brufen');
      expect(medicine.nameAr, 'بروفين');
      expect(medicine.activeIngredient, 'Paracetamol 500 mg');
      expect(medicine.imageUrl, 'https://res.cloudinary.com/x/brufen.jpg');

      expect(reply.pharmacies, hasLength(2));
      final first = reply.pharmacies.first;
      expect(first.pharmacyId, 1);
      expect(first.name, 'صيدلية الأمل');
      expect(first.price, 10);
      expect(first.quantity, 50);
      expect(first.availabilityLabel, 'متوفر');
      expect(first.distanceKm, isNull);
      expect(first.isOpenNow, isTrue);
      expect(first.address, 'غزة، شارع الوحدة');

      final second = reply.pharmacies.last;
      expect(second.price, 12.5);
      expect(second.distanceKm, 3.25);
      expect(second.isOpenNow, isFalse);
    });

    test('a greeting has words and no results', () {
      final reply = ChatbotRepositoryImpl.parseReply({
        'success': false,
        'analysis': {'intent': 'greeting', 'reply': 'أهلًا وسهلًا!'},
      });

      expect(reply.text, 'أهلًا وسهلًا!');
      expect(reply.hasResults, isFalse);
      expect(reply.pharmacies, isEmpty);
    });

    test('a response with nothing in it is empty', () {
      expect(
        ChatbotRepositoryImpl.parseReply({
          'success': true,
          'analysis': {},
        }).isEmpty,
        isTrue,
      );
      expect(ChatbotRepositoryImpl.parseReply(null).isEmpty, isTrue);
    });

    test('reads alternatives as medicines and skips rows with no id', () {
      final reply = ChatbotRepositoryImpl.parseReply({
        'medicine': {'id': 8, 'name': 'Brufen'},
        'alternatives': [
          {'id': 9, 'name': 'Advil', 'trade_name_ar': 'ادفيل'},
          {'name': 'no id'},
          'junk',
        ],
      });

      expect(reply.alternatives.map((m) => m.name), ['Advil']);
    });

    test('an unknown availability word is not shown', () {
      final reply = ChatbotRepositoryImpl.parseReply({
        'medicine': {'id': 8, 'name': 'Brufen'},
        'pharmacies': [
          {'pharmacy_id': 1, 'name': 'ص', 'availability': 'something_new'},
        ],
      });

      expect(reply.pharmacies.single.availabilityLabel, isNull);
    });

    test(
      'a medicine with no pharmacy keeps the API message and its alternatives',
      () {
        // The response for "باندول": found, but in no pharmacy.
        final reply = ChatbotRepositoryImpl.parseReply({
          'success': true,
          'analysis': {
            'intent': 'medicine_search',
            'drug_name': 'باندول',
            'confidence': null,
          },
          'medicine': {
            'id': 1,
            'name': 'Panadol',
            'trade_name_ar': null,
            'active_ingredient': 'Paracetamol',
            'image_url': null,
          },
          'pharmacies': [],
          'alternatives': [
            {
              'id': 18,
              'trade_name': 'ACAMOL 500MG TAB 20 TAB',
              'active_ingredient': 'Paracetamol',
              'is_available': true,
            },
          ],
          'total_found': 0,
          'requires_location': true,
          'message': 'لم أجد الصيدليات التي يتوفر فيها الدواء حاليًا.',
        });

        expect(reply.text, 'لم أجد الصيدليات التي يتوفر فيها الدواء حاليًا.');
        expect(reply.medicine?.name, 'Panadol');
        expect(reply.medicine?.nameAr, isNull);
        expect(reply.pharmacies, isEmpty);
        expect(reply.totalFound, 0);
        final alternative = reply.alternatives.single;
        expect(alternative.id, 18);
        expect(alternative.name, 'ACAMOL 500MG TAB 20 TAB');
        expect(alternative.isAvailable, isTrue);
      },
    );
  });
}
