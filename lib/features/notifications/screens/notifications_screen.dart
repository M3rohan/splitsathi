import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:splitsathi/core/di/service_locator.dart';
import 'package:splitsathi/core/router/app_routes.dart';
import 'package:splitsathi/core/theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:splitsathi/features/auth/bloc/auth_bloc.dart';
import 'package:splitsathi/features/notifications/bloc/notification_bloc.dart';
import 'package:splitsathi/features/notifications/bloc/notification_event.dart';
import 'package:splitsathi/features/notifications/bloc/notification_state.dart';
import 'package:splitsathi/features/notifications/models/notification_model.dart';
import 'package:splitsathi/features/notifications/repository/notification_repository.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationBloc>.value(
      value: getIt<NotificationBloc>(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final userId = getIt<AuthBloc>().state.user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('notifications'.tr()),
        actions: [
          TextButton(
            onPressed: () => context.read<NotificationBloc>().add(
              NotificationMarkAllReadRequested(userId),
            ),
            child: Text('mark_all_read'.tr()),
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state.notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsetsGeometry.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 56,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'no_notifications'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.notifications.length,
            itemBuilder: (context, index) {
              final notification = state.notifications[index];
              return _NotificationTile(
                notification: notification,
                userId: userId,
              ).animate().fadeIn(delay: (index * 40).ms);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final String userId;

  const _NotificationTile({required this.notification, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Theme.of(context).colorScheme.surface
            : AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(notification.body),
        trailing: notification.createdAt != null
            ? Text(
                timeago.format(notification.createdAt!),
                style: Theme.of(context).textTheme.bodySmall,
              )
            : null,
        onTap: () {
          if (!notification.isRead) {
            getIt<NotificationRepository>().markAsRead(userId, notification.id);
          }
          context.pushNamed(
            AppRoutes.groupDetailName,
            pathParameters: {'groupId': notification.groupId},
          );
        },
      ),
    );
  }
}
