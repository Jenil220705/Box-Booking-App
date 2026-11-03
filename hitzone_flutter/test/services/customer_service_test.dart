import 'package:flutter_test/flutter_test.dart';
import 'package:hitzone_flutter/core/utils/errors.dart';
import 'package:hitzone_flutter/services/customer_service.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeBookingRepository bookings;
  late FakeCustomerRepository customers;
  late CustomerService service;

  setUp(() {
    bookings = FakeBookingRepository();
    customers = FakeCustomerRepository();
    service = CustomerService(customers: customers, bookings: bookings);
  });

  test('add stores trimmed values with "Never" as last visit', () async {
    final c = await service.add(
      name: '  Amit Patel ',
      phone: '9876543210',
      notes: ' Corporate ',
    );
    expect(c.name, 'Amit Patel');
    expect(c.notes, 'Corporate');
    expect(c.last, 'Never');
    expect(c.cnt, 0);
    expect(customers.rows, hasLength(1));
  });

  test('add validates name and phone', () async {
    await expectLater(
      service.add(name: '', phone: '9876543210'),
      throwsA(isA<ValidationException>()),
    );
    await expectLater(
      service.add(name: 'A', phone: ''),
      throwsA(isA<ValidationException>()),
    );
    await expectLater(
      service.add(name: 'A', phone: '12345'),
      throwsA(isA<ValidationException>()),
    );
    expect(customers.rows, isEmpty);
  });

  test('add rejects a phone number that already belongs to someone', () async {
    customers.seed(name: 'Existing', phone: '9876543210');
    await expectLater(
      service.add(name: 'New', phone: '9876543210'),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('Existing'),
        ),
      ),
    );
  });

  test('update changes name, phone and notes', () async {
    final c = customers.seed(name: 'Old', phone: '9000000001');
    await service.update(c, name: 'New', phone: '9000000002', notes: 'VIP');
    final updated = customers.rows.single;
    expect(
      (updated.name, updated.phone, updated.notes),
      ('New', '9000000002', 'VIP'),
    );
  });

  test(
    'update may keep its own phone but not take another customer\'s',
    () async {
      final a = customers.seed(name: 'A', phone: '9000000001');
      customers.seed(name: 'B', phone: '9000000002');
      await service.update(a, name: 'A2', phone: '9000000001');
      await expectLater(
        service.update(a, name: 'A2', phone: '9000000002'),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test('delete removes a customer without bookings', () async {
    final c = customers.seed(phone: '9000000001');
    await service.delete(c);
    expect(customers.rows, isEmpty);
  });

  test('delete is blocked while the customer still has bookings', () async {
    final c = customers.seed(phone: '9000000001');
    bookings.seed(phone: '9000000001');
    bookings.seed(phone: '9000000001', start: '14:00', end: '15:00');
    await expectLater(
      service.delete(c),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.message,
          'message',
          'Customer has 2 bookings. Delete bookings first.',
        ),
      ),
    );
    expect(customers.rows, hasLength(1));
  });
}
