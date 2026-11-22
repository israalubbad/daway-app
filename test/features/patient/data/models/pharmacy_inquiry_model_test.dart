import 'package:daway_app/features/patient/data/models/pharmacy_inquiry_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a normal row', () {
    final model = PharmacyInquiryModel.fromJson({
      'id': 4,
      'message': 'هل متوفر؟',
      'status': 'pending',
      'pharmacy': {'id': 2, 'pharmacy_name': 'صيدلية النور'},
      'medicine': {'id': 6, 'trade_name': 'Brufen'},
      'last_message': {'message': 'نعم'},
      'unread_messages_count': 2,
      'created_at': '2026-10-25T10:00:00Z',
    });

    expect(model.id, 4);
    expect(model.pharmacyName, 'صيدلية النور');
    expect(model.medicineName, 'Brufen');
    expect(model.lastMessage, 'نعم');
    expect(model.unreadCount, 2);
  });

  test('fields of an unexpected type do not fail the row', () {
    final model = PharmacyInquiryModel.fromJson({
      'id': '7',
      'message': [5],
      'reply': {'text': 'x'},
      'status': 3,
      'pharmacy': [1, 2],
      'medicine': 'Brufen',
      'created_at': 12345,
      'replied_at': {'a': 1},
      'unread_messages_count': 'two',
    });

    expect(model.id, 7);
    expect(model.message, '');
    expect(model.reply, isNull);
    expect(model.pharmacyId, 0);
    expect(model.medicineName, isNull);
    expect(model.unreadCount, 0);
  });
}
