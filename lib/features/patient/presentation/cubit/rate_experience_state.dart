class RateExperienceState {
  final int pharmacyRating;
  final String notes;
  final bool isSubmitting;
  final String? errorMessage;
  final bool submitted;

  const RateExperienceState({
    this.pharmacyRating = 0,
    this.notes = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.submitted = false,
  });

  RateExperienceState copyWith({
    int? pharmacyRating,
    String? notes,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool? submitted,
  }) {
    return RateExperienceState(
      pharmacyRating: pharmacyRating ?? this.pharmacyRating,
      notes: notes ?? this.notes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      submitted: submitted ?? this.submitted,
    );
  }
}
