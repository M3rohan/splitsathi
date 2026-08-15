import 'package:equatable/equatable.dart';
import 'package:splitsathi/features/notifications/models/notification_model.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class NotificationsSubscriptionRequested extends NotificationEvent {
  final String userId;
  const NotificationsSubscriptionRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class NotificationsUpdated extends NotificationEvent {
  final List<NotificationModel> notifications;
  const NotificationsUpdated(this.notifications);
  @override
  List<Object?> get props => [notifications];
}

class NotificationMarkAllReadRequested extends NotificationEvent {
  final String userId;
  const NotificationMarkAllReadRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class NotificationsResetRequested extends NotificationEvent {
  const NotificationsResetRequested();
}
