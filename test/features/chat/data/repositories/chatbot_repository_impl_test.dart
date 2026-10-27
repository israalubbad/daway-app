import 'package:daway_app/features/chat/data/repositories/chatbot_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatbotRepositoryImpl.replyText', () {
    test('reads the reply of the assistant analysis, as the API sent it', () {
      expect(
        ChatbotRepositoryImpl.replyText({
          'success': true,
          'analysis': {
            'source': 'ai',
            'intent': 'search_medicine',
            'drug_name': 'pandol',
            'reply':
                'فهمت أنك تريد البحث عن pandol. سأحتاج إلى نتائج البحث من النظام.',
            'guidance': null,
          },
        }),
        'فهمت أنك تريد البحث عن pandol. سأحتاج إلى نتائج البحث من النظام.',
      );
    });

    test('reads a reply at the top level (the assistant service format)', () {
      expect(
        ChatbotRepositoryImpl.replyText({
          'intent': 'greeting',
          'drug_name': null,
          'reply': 'أهلًا وسهلًا! أنا مساعد دواني. كيف بقدر أساعدك اليوم؟',
          'guidance': null,
        }),
        'أهلًا وسهلًا! أنا مساعد دواني. كيف بقدر أساعدك اليوم؟',
      );
    });

    test('prefers the assistant reply over the endpoint message', () {
      expect(
        ChatbotRepositoryImpl.replyText({
          'success': false,
          'message': 'لم أتمكن من تحديد اسم الدواء.',
          'analysis': {'intent': 'greeting', 'reply': 'أهلًا وسهلًا!'},
        }),
        'أهلًا وسهلًا!',
      );
    });

    test('falls back to the endpoint message when there is no reply', () {
      expect(
        ChatbotRepositoryImpl.replyText({
          'success': false,
          'message': 'لم أتمكن من تحديد اسم الدواء.',
        }),
        'لم أتمكن من تحديد اسم الدواء.',
      );
    });

    test('puts a guidance text after the reply', () {
      expect(
        ChatbotRepositoryImpl.replyText({
          'analysis': {'reply': 'راجع الطبيب', 'guidance': 'اتصل بالإسعاف 101'},
        }),
        'راجع الطبيب\n\nاتصل بالإسعاف 101',
      );
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

    test(
      'returns null when the body has no text, instead of inventing one',
      () {
        expect(
          ChatbotRepositoryImpl.replyText({'success': false, 'analysis': {}}),
          isNull,
        );
        expect(
          ChatbotRepositoryImpl.replyText({
            'analysis': {'reply': '  '},
          }),
          isNull,
        );
        expect(ChatbotRepositoryImpl.replyText(null), isNull);
      },
    );
  });
}
