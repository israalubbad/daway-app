/// What the QR code on the web sales screen carries: which scan session to join
/// and the one-time token that proves the phone saw the code.
/// `daway://pair?sid=<uuid>&token=<64 characters>`
class ScanPairing {
  final String sessionId;
  final String pairingToken;

  const ScanPairing({required this.sessionId, required this.pairingToken});

  /// The pairing in [raw], or null when it is not a Daway pairing link.
  static ScanPairing? tryParse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    final sessionId = uri.queryParameters['sid']?.trim();
    final token = uri.queryParameters['token']?.trim();
    if (sessionId == null || sessionId.isEmpty || token == null || token.isEmpty) return null;
    return ScanPairing(sessionId: sessionId, pairingToken: token);
  }
}

/// A phone that is paired to a scan session: [deviceToken] is what lets it send
/// barcodes to [sessionId], and nothing else.
class PairedScanner {
  final String sessionId;
  final String deviceToken;

  const PairedScanner({required this.sessionId, required this.deviceToken});
}
