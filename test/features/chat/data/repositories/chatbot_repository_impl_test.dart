import 'package:flutter_test/flutter_test.dart';

import 'package:daway_app/features/chat/data/repositories/chatbot_repository_impl.dart';

void main() {
  group('ChatbotRepositoryImpl.replyText', () {
    test('reads a top-level reply', () {
      expect(ChatbotRepositoryImpl.replyText({'reply': ' مرحبا '}), 'مرحبا');
    });

    test('reads a message nested under data', () {
      expect(
        ChatbotRepositoryImpl.replyText({
          'success': true,
          'data': {'message': 'متوفر في صيدلية الأمل'},
        }),
        'متوفر في صيدلية الأمل',
      );
    });

    test('returns null when the body has no text', () {
      expect(ChatbotRepositoryImpl.replyText({'success': false, 'analysis': {}}), isNull);
      expect(ChatbotRepositoryImpl.replyText(null), isNull);
    });
  });
}
