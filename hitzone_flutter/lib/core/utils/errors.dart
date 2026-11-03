import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Base class for every error shown to the user.
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = 'No connection. Check your internet and try again.',
  ]);
}

/// Thrown when a new booking would overlap an existing one on the same box.
class SlotConflictException extends AppException {
  const SlotConflictException(super.message, {this.dates = const []});

  /// Offending dates (`yyyy-MM-dd`) – several for recurring bookings.
  final List<String> dates;
}

/// Runs a Supabase call and converts low level failures into [AppException]s.
Future<T> guardSupabase<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on AppException {
    rethrow;
  } on PostgrestException catch (e) {
    // 23505 = unique violation – the database also guards against double booking.
    if (e.code == '23505') {
      throw const SlotConflictException('Slot already booked');
    }
    throw AppException(e.message);
  } on AuthException catch (e) {
    throw AppException(e.message);
  } on SocketException {
    throw const NetworkException();
  } on TimeoutException {
    throw const NetworkException('The request timed out. Please try again.');
  } catch (e) {
    final text = e.toString();
    if (text.contains('ClientException') ||
        text.contains('SocketException') ||
        text.contains('Failed host lookup')) {
      throw const NetworkException();
    }
    throw AppException(text);
  }
}

String errorMessage(Object error) {
  if (error is AppException) return error.message;
  final text = error.toString();
  if (text.contains('SocketException') || text.contains('ClientException')) {
    return const NetworkException().message;
  }
  return text.replaceFirst('Exception: ', '');
}
