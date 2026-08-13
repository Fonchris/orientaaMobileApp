import 'package:cloud_functions/cloud_functions.dart';

/// Signature of the underlying callable invocation. Injectable in tests so
/// services can be unit-tested without a live Firebase emulator.
typedef HttpsCallableInvoker =
    Future<dynamic> Function(String name, Map<String, dynamic> data);

/// Thin wrapper around `FirebaseFunctions.httpsCallable(...)`.
///
/// Screens never talk to Cloud Functions directly — they go through this
/// client so error handling and test seams live in one place.
class FunctionsClient {
  FunctionsClient({HttpsCallableInvoker? invoker})
      : _invoker = invoker ?? _defaultInvoker;

  final HttpsCallableInvoker _invoker;

  static Future<dynamic> _defaultInvoker(
    String name,
    Map<String, dynamic> data,
  ) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable(name)
        .call(data);
    return result.data;
  }

  /// Invokes a callable with the given payload and returns the `data` field
  /// of the result. Throws [FunctionCallException] on any failure, wrapping
  /// the underlying error with a stable message.
  Future<dynamic> call(String name, Map<String, dynamic> data) async {
    try {
      return await _invoker(name, data);
    } on FirebaseFunctionsException catch (e) {
      throw FunctionCallException(e.code, e.message ?? e.code);
    } on FunctionCallException {
      rethrow; // preserve codes thrown by injected/fake invokers
    } catch (e) {
      throw FunctionCallException('unknown', '$e');
    }
  }
}

/// A failed Cloud Function invocation. `code` mirrors the Firebase
/// functions error code (e.g. `unavailable`, `not-found`, `permission-denied`).
class FunctionCallException implements Exception {
  const FunctionCallException(this.code, this.message);

  final String code;
  final String message;

  /// True when the network/function was unreachable — the moment the offline
  /// cache should step in.
  bool get isUnavailable =>
      code == 'unavailable' || code == 'unknown' || code == 'internal';

  @override
  String toString() => 'FunctionCallException($code): $message';
}
