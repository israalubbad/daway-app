import 'dart:math';

/// A fresh, unguessable key for a request that must not be applied twice
/// (an order): the server answers a repeat of the same key with the first
/// result instead of acting again. 128 random bits, so two devices — or two
/// orders — never share one.
String newIdempotencyKey() {
  final random = Random.secure();
  final hex = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'));
  return 'dawak-${hex.join()}';
}
