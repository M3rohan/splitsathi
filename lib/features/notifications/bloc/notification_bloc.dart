import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitsathi/features/notifications/bloc/notification_event.dart';
import 'package:splitsathi/features/notifications/bloc/notification_state.dart';
import 'package:splitsathi/features/notifications/repository/notification_repository.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;
  StreamSubscription? _subscription;

  NotificationBloc({required NotificationRepository notificationRepository})
    : _notificationRepository = notificationRepository,
      super(const NotificationState()) {
    on<NotificationsSubscriptionRequested>(_onSubscriptionRequested);
    on<NotificationsUpdated>(_onUpdated);
    on<NotificationMarkAllReadRequested>(_onMarkAllRead);
  }

  Future<void> _onSubscriptionRequested(
    NotificationsSubscriptionRequested event,
    Emitter<NotificationState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _notificationRepository
        .watchNotifications(event.userId)
        .listen((notifications) => add(NotificationsUpdated(notifications)));
  }

  void _onUpdated(NotificationsUpdated event, Emitter<NotificationState> emit) {
    emit(state.copyWith(notifications: event.notifications));
  }

  Future<void> _onMarkAllRead(
    NotificationMarkAllReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    await _notificationRepository.markAllAsRead(event.userId);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
