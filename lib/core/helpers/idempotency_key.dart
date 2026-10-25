import 'dart:math';

final _random = Random.secure();

/// A fresh random key for a mutating request the server must not apply twice
/// (checkout). Generate one per attempt and reuse it when retrying that same
/// attempt.
String newIdempotencyKey() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
