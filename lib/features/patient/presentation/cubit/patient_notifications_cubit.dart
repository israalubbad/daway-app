import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/patient_notification.dart';
import '../../domain/usecases/get_patient_notifications_usecase.dart';
import '../../domain/usecases/mark_patient_notification_read_usecase.dart';
import 'patient_notifications_state.dart';

class PatientNotificationsCubit extends Cubit<PatientNotificationsState> {
  final GetPatientNotificationsUseCase _getPatientNotificationsUseCase;
  final MarkPatientNotificationReadUseCase _markReadUseCase;

  PatientNotificationsCubit(this._getPatientNotificationsUseCase, this._markReadUseCase)
      : super(const PatientNotificationsLoading()) {
    load();
  }

  Future<void> load() async {
    emit(const PatientNotificationsLoading());
    final result = await _getPatientNotificationsUseCase();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(PatientNotificationsLoaded(data));
      case ApiError(:final failure):
        emit(PatientNotificationsLoadFailure(failure.message));
    }
  }

  /// Marks [notification] read: shown as read at once, and put back as unread
  /// if the backend refuses, so the list never claims more than the server has.
  Future<void> markAsRead(PatientNotification notification) async {
    if (notification.isRead) return;
    _replace(notification.id, isRead: true);
    final result = await _markReadUseCase(notification.id);
    if (isClosed) return;
    if (result is ApiError) _replace(notification.id, isRead: false);
  }

  void _replace(int id, {required bool isRead}) {
    final current = state;
    if (current is! PatientNotificationsLoaded) return;
    emit(
      PatientNotificationsLoaded([
        for (final n in current.notifications)
          if (n.id == id)
            PatientNotification(
              id: n.id,
              type: n.type,
              message: n.message,
              isRead: isRead,
              createdAt: n.createdAt,
            )
          else
            n,
      ]),
    );
  }
}
