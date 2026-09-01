import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/notifications/notification_service.dart';

void main() {
  test('an instalment payload routes to the loan with its shortfall', () {
    expect(
      loanPaymentPath({
        'loan_id': 'l1',
        'installment_id': 'i2',
        'amount': '3000000',
      }),
      '/loan-pay?loan_id=l1&amount=3000000',
    );
  });

  test('a payload with no amount still routes to the loan', () {
    expect(loanPaymentPath({'loan_id': 'l1'}), '/loan-pay?loan_id=l1');
    expect(
      loanPaymentPath({'loan_id': 'l1', 'amount': ''}),
      '/loan-pay?loan_id=l1',
    );
  });

  test('a recurring reminder payload is left to the other branch', () {
    // Both kinds arrive through the same handler; only the loan one carries a
    // loan_id, and mistaking one for the other would send the user to the
    // wrong screen.
    expect(
      loanPaymentPath({
        'reminder_id': 'r1',
        'category_id': 'food',
        'note': 'Tiền nhà',
        'amount': '5000000',
      }),
      isNull,
    );
    expect(loanPaymentPath(const {}), isNull);
    expect(loanPaymentPath({'loan_id': ''}), isNull);
  });

  test('an id that would break the query string is escaped', () {
    expect(
      loanPaymentPath({'loan_id': 'a&b=c'}),
      '/loan-pay?loan_id=a%26b%3Dc',
    );
  });
}
