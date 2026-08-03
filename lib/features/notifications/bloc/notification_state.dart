import 'package:equatable/equatable.dart';
import 'package:splitsathi/features/notifications/models/notification_model.dart';

class NotificationState extends Equatable {
  final List<NotificationModel> notifications;

  const NotificationState({this.notifications = const []});

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({List<NotificationModel>? notifications}) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
    );
  }

  @override
  List<Object?> get props => [notifications];
}
