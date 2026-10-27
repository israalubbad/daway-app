import 'package:daway_app/features/patient/presentation/screens/payment_method_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BankLogo.assetFor', () {
    test('matches the three known methods however they are spelled', () {
      expect(
        BankLogo.assetFor('بنك فلسطين'),
        endsWith('bank_of_palestine.png'),
      );
      expect(
        BankLogo.assetFor('Bank of Palestine'),
        endsWith('bank_of_palestine.png'),
      );
      expect(BankLogo.assetFor('محفظة PalPay'), endsWith('palpay.png'));
      expect(BankLogo.assetFor('محفظة بال باي'), endsWith('palpay.png'));
      expect(BankLogo.assetFor('محفظة Jawwal Pay'), endsWith('jawwal_pay.png'));
      expect(BankLogo.assetFor('جوال  باي'), endsWith('jawwal_pay.png'));
    });

    test('has no logo for an unknown method', () {
      expect(BankLogo.assetFor('بنك آخر'), isNull);
    });
  });
}
