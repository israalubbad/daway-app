/// Where the phone-as-scanner flow is: waiting to read the QR code on the web
/// screen, sending barcodes to the session it joined, or finished because the
/// session ended.
enum PhoneScannerPhase { pairing, scanning, ended }

class PhoneScannerState {
  final PhoneScannerPhase phase;

  /// A request is in flight: pairing, or sending a barcode.
  final bool isBusy;

  /// What to tell the user: the last result, or why it failed.
  final String? message;
  final bool isError;

  /// The last barcode that was sent, and how many have been.
  final String? lastBarcode;
  final int sentCount;

  const PhoneScannerState({
    this.phase = PhoneScannerPhase.pairing,
    this.isBusy = false,
    this.message,
    this.isError = false,
    this.lastBarcode,
    this.sentCount = 0,
  });

  PhoneScannerState copyWith({
    PhoneScannerPhase? phase,
    bool? isBusy,
    String? message,
    bool clearMessage = false,
    bool? isError,
    String? lastBarcode,
    int? sentCount,
  }) {
    return PhoneScannerState(
      phase: phase ?? this.phase,
      isBusy: isBusy ?? this.isBusy,
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
      lastBarcode: lastBarcode ?? this.lastBarcode,
      sentCount: sentCount ?? this.sentCount,
    );
  }
}
