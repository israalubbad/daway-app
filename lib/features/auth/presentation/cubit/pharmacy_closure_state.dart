import '../../domain/entities/closure_request.dart';

sealed class PharmacyClosureState {
  const PharmacyClosureState();
}

/// The pharmacy's request is being read.
class PharmacyClosureLoading extends PharmacyClosureState {
  const PharmacyClosureLoading();
}

/// The read failed. The settings row still works: sending a request does not
/// depend on knowing whether an earlier one exists.
class PharmacyClosureLoadFailure extends PharmacyClosureState {
  const PharmacyClosureLoadFailure();
}

class PharmacyClosureLoaded extends PharmacyClosureState {
  /// The pharmacy's request, or null when it never asked.
  final ClosureRequest? request;
  final bool isSubmitting;

  /// Why the last send failed, while the user is still looking at the sheet.
  final String? errorMessage;

  const PharmacyClosureLoaded({this.request, this.isSubmitting = false, this.errorMessage});
}

/// True for the change that means a request has just gone through: it was
/// being sent and now exists, with no error.
bool closureRequestJustSent(PharmacyClosureState previous, PharmacyClosureState current) =>
    previous is PharmacyClosureLoaded &&
    previous.isSubmitting &&
    current is PharmacyClosureLoaded &&
    current.errorMessage == null &&
    current.request != null;
