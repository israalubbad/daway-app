import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/usecases/submit_pharmacy_rating_usecase.dart';
import 'rate_experience_state.dart';

/// "قيم تجربتك معنا" — collects a star rating and optional notes for
/// [pharmacyId] and sends them with `POST /ratings`. The app itself is not
/// rated: the API has nowhere to put that.
class RateExperienceCubit extends Cubit<RateExperienceState> {
  final int pharmacyId;
  final SubmitPharmacyRatingUseCase _submitPharmacyRatingUseCase;

  RateExperienceCubit(this.pharmacyId, this._submitPharmacyRatingUseCase)
      : super(const RateExperienceState());

  void pharmacyRatingChanged(int stars) =>
      emit(state.copyWith(pharmacyRating: stars, clearError: true));

  void notesChanged(String notes) => emit(state.copyWith(notes: notes));

  Future<void> submit() async {
    if (state.isSubmitting) return;
    if (state.pharmacyRating == 0) {
      emit(state.copyWith(errorMessage: 'يرجى اختيار تقييم للصيدلية'));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final notes = state.notes.trim();
    final result = await _submitPharmacyRatingUseCase(
      pharmacyId: pharmacyId,
      stars: state.pharmacyRating,
      comment: notes.isEmpty ? null : notes,
    );
    if (isClosed) return;

    switch (result) {
      case Success():
        emit(state.copyWith(isSubmitting: false, submitted: true));
      case ApiError(:final failure):
        emit(state.copyWith(isSubmitting: false, errorMessage: failure.message));
    }
  }
}
