import '../core/utils/errors.dart';
import '../core/utils/formatters.dart';
import '../models/customer.dart';
import '../repositories/booking_repository.dart';
import '../repositories/customer_repository.dart';

class CustomerService {
  CustomerService({required this._customers, required this._bookings});

  final CustomerRepository _customers;
  final BookingRepository _bookings;

  static void validate(String name, String phone) {
    if (name.trim().isEmpty || phone.isEmpty) {
      throw const ValidationException('Name and phone required');
    }
    if (!isValidPhone(phone)) {
      throw const ValidationException('Enter valid 10 digit mobile number');
    }
  }

  Future<Customer> add({
    required String name,
    required String phone,
    String notes = '',
  }) async {
    validate(name, phone);
    final existing = await _customers.findByPhone(phone);
    if (existing != null) {
      throw ValidationException(
        '${existing.name} already uses this mobile number',
      );
    }
    return _customers.insert(
      name: name.trim(),
      phone: phone,
      notes: notes.trim(),
      last: 'Never',
    );
  }

  Future<void> update(
    Customer customer, {
    required String name,
    required String phone,
    String notes = '',
  }) async {
    validate(name, phone);
    if (phone != customer.phone) {
      final clash = await _customers.findByPhone(phone);
      if (clash != null && clash.id != customer.id) {
        throw ValidationException(
          '${clash.name} already uses this mobile number',
        );
      }
    }
    await _customers.update(
      customer.id,
      name: name.trim(),
      phone: phone,
      notes: notes.trim(),
    );
  }

  /// A customer who still has bookings cannot be deleted (original rule).
  Future<void> delete(Customer customer) async {
    final bookings = await _bookings.countByPhone(customer.phone);
    if (bookings > 0) {
      throw ValidationException(
        'Customer has $bookings bookings. Delete bookings first.',
      );
    }
    await _customers.delete(customer.id);
  }
}
